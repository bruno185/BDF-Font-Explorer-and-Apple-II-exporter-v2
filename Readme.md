# BDF Font Explorer for Windows and Apple II 

BDF (Glyph Bitmap Distribution Format) fonts are bitmap fonts created by Adobe a long time ago. Many can be found on the Internet.

Delphi software can read BDF files and explore their contents, including displaying glyphs.

It also lets you export one or more glyphs in a format that can be easily read by an Apple II.

## Usage
Launch the application BDF_Analyser.exe and drag and drop a BDF file onto the window.
I've included some BDF fonts in this archive (see "Some BDF fonts.rar").
You can also find more BDF fonts here :

https://github.com/olikraus/u8g2/tree/master/tools/font/bdf

https://github.com/farsil/ibmfonts
...


Drag and drop a BDF file ovre the application.

Font characters are displayed in the lower part of the window, while the entire file is displayed on the right. Font information is displayed on the left.
Clicking on a character gives more information about it, displays it in larger size, and displays the corresponding text from the original file on the right.

To export one or a series of glyphs in Apple II format, select the range and click on the "Export" button. 
In the dialog window, choose the format: binary (.bin) or source (.s).

Binary format: 
The first two bytes represent the number of glyphs.
The next byte represents the width (in bytes) of each glyph.
The next byte represents the height (in bytes) of each glyph.
The following bytes represent the raw glyph bitmap data, without separator.

Source format :
The structure is the same as that of the binary format. Labels are added; and data are represented in hexadecimal format (Merlin's "hex" opcode).

Example :     
numglyph hex 6900    
gwidth hex 05   
gheight hex 22  
font   
glyph0
 
 hex 7F00403F00   
 hex 7800400F00   
 hex 7801400700   
 hex 7801600700   
 hex 7801600700   
 hex 7803300700   
 ...   
 glyph1
 
 hex 7F00400F00   
 hex 7800400F00   
 hex 7801400700   
 hex 0801600700   
 hex 0801600700   
 hex 0803300700 
 ...

## Apple II
A very simple program is provided to display a glyph on an Apple II. The program is well commented. It is provided as an example to demonstrate the use of exported glyphs.
Note that the Delphi program "inverts" the bit order of the pixels, to make them conform to the way the Apple II handles the display. So much work that doesn't have to be done by the 65(C)02 or 65816.


## Requirements to compile and run
The Delphi program is produced with the Community Edition of Embarcadero. The source files are here:
https://github.com/bruno185/BDF-Analyser

Here is my configuration for Apple II cross developement :

* Visual Studio Code with 2 extensions :

-> [Merlin32 : 6502 code hightliting](marketplace.visualstudio.com/items?itemName=olivier-guinart.merlin32)

-> [Code-runner :  running batch file with right-clic.](marketplace.visualstudio.com/items?itemName=formulahendry.code-runner)

* [Merlin32 cross compiler](brutaldeluxe.fr/products/crossdevtools/merlin)

* [Applewin : Apple IIe emulator](github.com/AppleWin/AppleWin)

* [Applecommander ; disk image utility](applecommander.sourceforge.net)

* [Ciderpress ; disk image utility](a2ciderpress.com)

Compilation notes :

DoMerlin.bat puts it all together. If you want to compile yourself, you will have to adapt the path to the Merlin32 directory, to Applewin and to Applecommander in DoMerlin.bat file.

DoMerlin.bat is to be placed in project directory.
It compiles source (*.s) with Merlin32, copy 6502 binary to a disk image (containg ProDOS), and launch Applewin with this disk in S6,D1.

