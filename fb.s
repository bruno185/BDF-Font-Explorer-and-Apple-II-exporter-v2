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
charindex       equ $0040

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
*<bp>
                lda #topmargin                  ; init top margin
                sta line
                clc 
                adc gheight
                sta maxv

                lda #leftmargin                         ; init left margin
                sta rowcnt
                clc
                adc gwidth
                sta maxh 

*<sym>
the_glyph
                lda #<charindex                 ; glyph index in A,X (A = low byte, X = hi byte)
                ldx #>charindex
                jsr getgaddr                    ; calculte strating address of glyph data 
                                                ; and make gindex/gindex+1 point to it
                ;jsr printglyph
                ;rts
*<bp>
                jsr copyglyph                   ; copy glyph data, add 0 at the end of each line
                jsr shift                       ; pre shift glyph

*<sym>
shapeindex   
                lda #70                         ; init top margin
                sta line
indexsh         lda #0                         ; shape # in A
dopsh
                jsr printshglyph                ; print pre shifted glyph 

nokey
                lda kbd		                ; check for key press
                bpl nokey		        ; if none, continue waiting
                bit kbdstrb     ; clear kbd
                lda indexsh+1
                inc 
                cmp #7
                beq finprg
                sta indexsh+1
                jmp shapeindex

finprg          rts


***************************************************************************
* pre shift glypg
* first gshape (not shifted glyph) is already at gbuffer location.
* a table of shapes addresses is built at shift_tbl location.
*<sym>
shift 
                lda #0                  ; shift counter
                sta shapes
                
                lda #<gbuffer           ; set glyph input address (= copied glyph)
                sta inputb+1
                sta tempo
                sta shift_tbl           ; first shape already at gbuffer
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

                lda tempo                ; set ouput address, just after glyph
                sta ouputb+1
                lda tempo+1
                sta ouputb+2

*<sym>
shapeloop
                inc shapes              ; now start second shape 
                lda shapes
                cmp #7
                bne goshape
                rts
*<sym>
goshape
                asl
                tax 
                lda ouputb+1
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

                inc inputb+1            ; update input and output code
                bne noinc01
                inc inputb+2
*<sym>
noinc01
                inc ouputb+1
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
* This 0 byte is needed when glyph is shifted.
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
                asl
                tax
                lda shift_tbl,x 
                sta gdata+1
                inx 
                lda shift_tbl,x 
                sta gdata+2

                lda maxh
                inc
                sta tempo

gdata           lda $FFFF
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
                inc gdata+1
                bne noinc2
                inc gdata+2
noinc2
                lda rowcnt              ; colomn = leftmargin + glyph width ?
                cmp tempo
                bne gdata           ; no loop

                lda #leftmargin         ; reset col.
                sta rowcnt
                inc line                ; next line 
                lda line                ; 
                cmp maxv                ; line = top margin + glyph heignt ?
                bne gdata             ; no : loop
                      
                rts


*<sym>
getgaddr
* calcultate base address of the glyph, put it in gindex var
* gindex = glyph size * gindexcnt/gindexcnt+1                   
                sta gindexcnt                   ; init counter with glyph #
                stx gindexcnt+1

                lda #0 
                sta gindex                      ; init result
                sta gindex+1
*<sym>
setbaseaddress
                lda gindexcnt                   ; test counter
                ora gindexcnt+1
                beq next1                       ; end of loop

                lda glyphsize                   ; get size of a glyph bitmap
                clc 
                adc gindex                      ; add it to gl
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
                lda gindex                      ; add font address offset
                clc
                adc #<font
                sta gindex
                lda gindex+1
                adc #>font
                sta gindex+1

* gindex now points to the first byte of the selected glyph image.
                rts


*<sym>
printglyph   

                lda gindex             ; get base address of data in pointer
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
shapes          ds 1


        put lohi
        put font                ; here is the data, in source format.
*<m1>
*<sym>
shift_tbl                       ; table of shifted glyph address
                ds 7*2

*<sym>
gbuffer equ *

        