arch "arch/null.arch";

addr.seek($00ffb0)
// ROM header information.
db  "KT"                    // 00..02 Maker code.
db  "TMPR"                  // 02..06 Game code.
db  0, 0, 0, 0, 0, 0, 0
db  $07                     // 0d     Expansion RAM.
db  0                       // 0e     Special Version.
db  0                       // 0f     Cartridge type.
db  "SUPERFX3D TESTING ROM" // 10..25 Title string.
db  %00100000               // 25     Map mode (LOROM)
db  $15                     // 26     ROM type (FX+ROM+SRAM)
db  $0b                     // 27     ROM size
db  $00                     // 28     SRAM size
db  0                       // 29     Sales code
db  $33                     // 2a     fixed
db  0                       // 2b     version number
dw  0                       // 2c..2e ~checksum
dw  -1                      // 2e..30 checksum
// ROM vector information.
// Native mode vectors.
dw  0, 0    // Unused vectors.
dw  interrupt.COP
dw  interrupt.BRK
dw  interrupt.ABORT
dw  interrupt.NMI
dw  RESET
dw  interrupt.IRQ
// Emulation mode vectors.
dw  0, 0    // Unused vectors.
dw  interrupt.COP
dw  interrupt.BRK
dw  interrupt.ABORT
dw  interrupt.NMI
dw  RESET
dw  interrupt.IRQ
