arch "arch/scpu.arch";
include "arch/fx-support.asm";
include "addr_fx.asm";

// Blank the ROM, making an empty 2MB file.
addr.seek($008000);
fill 1024 * 1024 * 2;

addr.seek($008000);

// Interrupts need to be included specially, because they /must/ be in bank 0.
// The rest of the game engine is in bank $01.
include "interrupt.asm";

RESET:
	clc; xce;	// Exit 6502 emu mode
	rep #$20;
	lda #>0; tad;
	lda #>addr.stacktop; tas; // Update stack position
	sep #$20;
	rep #$10;	// The game uses 16-bit addresses when possible.

	phk; plb;
	stz $4200;
	lda $4210;
	lda $4211;

	jsl UploadWram;

	cli;
	lda #$25; sta <fx.screenmode;
	ora #$18; sta <fx.pausemode;
	lda #$01; sta $3039;
	stz $3037;
	lda #$08; sta $3038;
	lda #<fx.Boot>>16; ldy #>fx.Boot;
	jsl mainw.FxCall;
	lda #<(Main>>16); pha; plb;
	jsl Main;
	stp;

// this file contains an internal seek
include "wram.asm";

addr.seek($43'0000);
fxstuff_begin:
include "fx/include.asm";
fxstuff_end:

addr.seek($01'8000);
eng_begin:
include "main.asm";
eng_end:

addr.seek($00'9000);
include "automatic.asm";

addr.seek($42'0000);
include "tables.asm"

addr.seek($56'0000);
insert fontbank, "res/fontbank.bin";

addr.seek($57'0000);
include "texturedata.asm";

include "header.asm";

include "debugprints.asm";

if {defined MEMUSE} {
	print "\nROM usage: \n"
	print "    Engine: ", (eng_end-eng_begin), " B \n"
	print "RAM usage:\n"
	print "    ZP: "; addr.print(addr.freezp - addr.firstzp); print " B\n";
	print "    MB: "; addr.print(addr.freemb - addr.firstmb); print " B\n";
	print "    7E: "; addr.print(addr.free7e - addr.first7e); print " B\n";
	print "    6K: "; addr.print(addr.free6k - addr.first6k); print " B\n";
	print "    70: "; addr.print(addr.free70 - addr.first70); print " B\n";
	print "    71: "; addr.print(addr.free71 - addr.first71); print " B\n";
}
