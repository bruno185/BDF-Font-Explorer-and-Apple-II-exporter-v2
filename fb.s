* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*                        DEMO PROGRAMM                          *
*            DISPLAYING BDF FONT TRANSLATED FROM WINDOWS ENV.   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*   Go to my Git archieve to get Windows program that produce   *
*             Apple II compatible date from BDF fonts           *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

                org $4000
                put equ

* Use these equ if font data (in binary format) is loaded at a fix address ($6000 in this example)
*numglyph        equ $6000
*gwidth          equ numglyph+2
*gheight         equ gwidth+1
*font            equ gheight+1
*
* Otherwise put font data (in source format) at the end of this source file
* (see end of this file)
* Labels must be the same in both cases (numglyph, gwidth, gheight, font)

ptr             equ $06

*** const ***
topmargin       equ 70
leftmargin      equ 10
charindex       equ $0042

* color masks
purple1         equ $D5                 ; or blue             
purple2         equ $AA
green1          equ $AA                 ; or red
green2          equ $D5
white1          equ $FF
white2          equ $FF

* calculate a glyph size (in bytes) 
* glyphsize/glyphsize+1 = gwidth * gheight
                lda #0
                sta glyphsize
                sta glyphsize+1

                ldx gwidth 
*<sym>
calcsize        lda glyphsize
                clc 
                adc gheight 
                sta glyphsize
                lda #0
                adc glyphsize+1
                sta glyphsize+1
                dex 
                bne calcsize

* init vars
                lda #topmargin          ; init top margin
                sta line
                clc 
                adc gheight
                sta maxv

                lda #leftmargin         ; init left margin
                sta rowcnt
                clc
                adc gwidth
                sta maxh 

*<sym>
the_glyph
                lda #<charindex         ; glyph index in A,X (A = low byte, X = hi byte)
                ldx #>charindex
                jsr getgaddr            ; calculte strating address of glyph data 
                                        ; and make gindex/gindex+1 point to it

                jsr copyglyph           ; copy glyph data to memory address gbuffer
                                        ; add 0 at the end of each line
                jsr shift               ; pre shift glyph

*<sym>
shapeindex   
                lda #topmargin          ; init top margin
                sta line

*<sym>
setcolor
* purple
                lda #purple1            ; uncomment to set this color (comment others)
                sta color1
                lda #purple2
                sta color2              
* green
                lda #green1            ; uncomment to set this color (comment others)
                sta color1
                lda #green2
                sta color2
                ;jmp colordone
* white
                lda #white1
                sta color1
                lda #white2
                sta color2
colordone

*<bp>
indexsh         lda #0                  ; shape # in A
                jsr printshglyph        ; print pre shifted glyph 

nokey           lda kbd		        ; check for key press
                bpl nokey               ; if none, continue waiting
                bit kbdstrb             ; clear kbd
                lda indexsh+1           ; get shape #
                clc
                adc #1
                ;inc                    ; replaced by 2 previous lines (compatibility) 
                cmp #7                  ; = 7 ?
                beq finprg              ; yes : exit
                sta indexsh+1           ; no : inc shape #
                jmp shapeindex          ; and loop

finprg          rts                     ; END


***************************************************************************
* pre shift glypg
* input : first glyph shape (shape 0, not shifted glyph) is already at gbuffer location.
* claculate 6 other postions of glyph
* a table of shapes addresses is built on the fly at shift_tbl location.

*<sym>
shift 
                lda #0                  ; shift counter
                sta shapes
                
                lda #<gbuffer           ; set glyph input address (= copied glyph)
                sta inputb+1            ; set address of byte to load (modify code)
                sta tempo
                sta shift_tbl           ; set firt address of shapes table
                lda #>gbuffer
                sta inputb+2
                sta tempo+1
                sta shift_tbl+1

                ldx gwidth              ; tempo/tempo+1 = @gbuffer + size of glyph 
                inx                     ; (size = gheight+1 * gwidth  size of glyph)
doadd           lda gheight
                clc
                adc tempo
                sta tempo
                lda #0
                adc tempo+1
                sta tempo+1
                dex 
                bne doadd

                lda tempo                ; set ouput address, just after glyph (by code modifying)
                sta ouputb+1
                lda tempo+1
                sta ouputb+2

*<sym>
shapeloop
                inc shapes              ; next shape 
                lda shapes
                cmp #7                  ; all shapes done ?
                bne goshape             ; no, go on
                rts                     ; yes : exit 
*<sym>
goshape
                asl                     ; shap index * 2 to get offset in shapes table
                tax 
                lda ouputb+1            ; 
                sta shift_tbl,x 
                inx 
                lda ouputb+2
                sta shift_tbl,x 

nextshape
                ldy gheight             ; y = line counter


nextline                                ; line loop
                ldx gwidth              ; get glyph width
                inx                     ; +1 for shifting
                clc                     ; set first input bit to 0
                php                     ; save carry
*<sym>
shline                                  ; row loop
inputb          lda $FFFF               ; get byte to shift 
                pha                     ; save it
                and #$80
                sta tempo               ; store bit 7 in tempo
                pla                     ; restore byte to shift 
                plp                     ; get input bit
                rol                     ; put it at position 0
                asl                     ; bit 7 in carry 
                php                     ; save carry for next byte
                lsr                     ; now we can reset byte in good position
                ora tempo               ; restore saved bit 7 
*<sym>       
ouputb          sta $FFFF

                inc inputb+1            ; update input code
                bne noinc01
                inc inputb+2
*<sym>
noinc01
                inc ouputb+1            ; update output code
                bne noinc02
                inc ouputb+2
*<sym>
noinc02
                dex                     ; dec number of bytes to process in current line
                bne shline              ; end of row loop

                plp                     ; to keep stack ok
                dey                     ; dec line counter
                bne nextline            ; end of line loop
                jmp shapeloop

***************************************************************************
* Copy glyph bitmap data to gbuffer, insert 0 at the end of each line.
* This extra byte is needed when glyph is shifted.
*<sym>
copyglyph
                lda gindex              ; set glyph input address
                sta loadbyte+1
                lda gindex+1
                sta loadbyte+2

                lda #<gbuffer           ; set glyph output address
                sta storbyte+1
                lda #>gbuffer
                sta storbyte+2

                ldy gheight             ; y = vertical (lines) counter            
*<sym>
movegg          ldx gwidth              ; x = horizontal counter (bytes in a line of glyph)

*<sym>
moveg
loadbyte        lda $FFFF               ; modified by code
storbyte        sta $FFFF               ; modified by code
                inc loadbyte+1          ; next input address 
                bne :1
                inc loadbyte+2
:1
                inc storbyte+1          ; next output address
                bne :2
                inc storbyte+2
:2
                dex                     ; test end of glyph row 
                bne moveg               ; loop until row is finished 
                lda storbyte+1          ; inc next ouput (to strore #0)
                sta storbyte0+1
                lda storbyte+2
                sta storbyte0+2

                lda #0                  ; now store 0 at end of row
storbyte0       sta $FFFF
                inc storbyte+1          ; inc output address 
                bne :3
                inc storbyte+2
:3           
                dey                     ; test end of glyph (all lines done) 
                bne movegg

                rts
* 

***************************************************************************
* print a pre shifted glyph
* input : a = index of shape
*<sym>
printshglyph 

                asl                     ; get shape # * 2
                tax                     ; = offset in shapes table
                lda shift_tbl,x 
                sta gdata+1             ; modifiy code 
                inx 
                lda shift_tbl,x 
                sta gdata+2

                lda #0                  ; oddeven is 0 or 1
                sta oddeven             ; for color1 and color1 masks, depending on column #

                lda maxh                ; +1 byte to make room for shifting
                clc 
                adc #1
                ;inc                    ; replaced by 2 previous lines (compatibility)
                sta tempo
*<sym>
gdata           lda $FFFF               ; modified load address
                pha                     ; save data byte
                
                ldx line                ; get screen address
                lda lo,x                ; ptr points to first byte of line of HGR screen
                sta ptr
                lda hi,x 
                sta ptr+1

                pla                     ; restore data byte
                ldy rowcnt              ; set column (horizontal offset)

                ldx oddeven             ; set color mask, upon color parity 
                bne oddcol
                and color1
                jmp evencol
*<sym>
oddcol          and color2

*<sym>
evencol   
                ;ora (ptr),y            ; uncoment to preserve background               
                sta (ptr),y             ; put byte on screen

                lda oddeven             
                eor #1                  ; 0 --> 1 or 1 --> 0
                sta oddeven

                inc rowcnt              ; next column
                inc gdata+1             ; prepare next data byte to load
                bne noinc2
                inc gdata+2
*<sym>
noinc2
                lda rowcnt              ; colomn = leftmargin + glyph width +1 ?
                cmp tempo
                bne gdata               ; no loop to finish row

                lda #0                  ; reinit oddeven var
                sta oddeven

                lda #leftmargin         ; reset col.
                sta rowcnt
                inc line                ; next line 
                lda line                ; 
                cmp maxv                ; line = top margin + glyph heignt ?
                bne gdata               ; no : loop
                      
                rts
*
***************************************************************************
* calcultate base address of the glyph, put it in gindex var
* gindex = glyph size * gindexcnt/gindexcnt+1
*<sym>
getgaddr                
                sta gindexcnt           ; init counter with glyph #
                stx gindexcnt+1

                lda #0 
                sta gindex              ; init result
                sta gindex+1
*<sym>
setbaseaddress
                lda gindexcnt           ; test counter
                ora gindexcnt+1
                beq next1               ; end of loop

                lda glyphsize           ; get size of a glyph bitmap
                clc 
                adc gindex              ; add it to gl
                sta gindex
                lda glyphsize+1                  
                adc gindex+1
                sta gindex+1

                lda gindexcnt
                bne notZ
                dec gindexcnt+1

*<sym>               
notZ            dec gindexcnt
                jmp setbaseaddress
*<sym>
next1
                lda gindex              ; add font address offset
                clc
                adc #<font
                sta gindex
                lda gindex+1
                adc #>font
                sta gindex+1

* gindex now points to the first byte of the selected glyph image.
                rts


***************************************************************************
*<sym>
printglyph   

                lda gindex              ; get base address of data in pointer
                sta getbyte+1
                lda gindex+1
                sta getbyte+2
display
getbyte         lda $FFFF               ; modified by code !

                pha                     ; save data byte

                ldx line                ; get screen address
                lda lo,x 
                sta ptr
                lda hi,x 
                sta ptr+1

                pla                     ; restore data byte

                ldy rowcnt              ; set column 
                ora (ptr),y  
                sta (ptr),y             ; put byte on screen

                inc rowcnt              ; next column
                inc getbyte+1
                bne noinc
                inc getbyte+2
noinc
                lda rowcnt              ; colomn = leftmargin + glyph width ?
                cmp maxh
                bne display             ; no loop

                lda #leftmargin          ; reset col.
                sta rowcnt
                inc line                ; next line 
                lda line                ; 
                cmp maxv                ; line = top margin + glyph heignt ?
                bne display             ; no : loop
                      
                rts
*<sym>
maxh            ds 1

*<sym>
maxv            ds 1

*<sym>
rowcnt          ds 1

*<sym>
line            ds 1

*<sym>
dataptr         ds 2

*<sym>
gindex          hex 0000
*<sym>
gindexcnt       hex 0000

*<m2>
*<sym>
glyphsize       ds 2

*<sym>
tempo           ds 2

*<sym>
oddeven         ds 1

*<sym>
color1         ds 1
color2         ds 1
                
*<sym>
shapes          ds 1

*
*
                put lohi
                put font                ; here is the data, in source format.
*<m1>
*<sym>
shift_tbl                               ; table of shifted glyph address
                ds 7*2

*<sym>
gbuffer equ *

        