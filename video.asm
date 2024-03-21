arch "arch/scpu.arch"

scope video {
	scope vram {
		scope gfx {
			constant bg1($0000);
			constant bg2($8000);
			constant bg3($0000);
			constant bg4($0000);
			constant obj($c000);
		}
		scope tm {
			constant bg1($e000);
			constant bg2($e800);
			constant bg3($e800);
			constant bg4($0000);
		}
	}

	constant topIrq($1f);
	constant bottomIrq($c0);

	constant windowLeft(16);
	constant windowRight($ef);

	addr.allocmb(hdmaEn, 1);
	addr.allocmb(mosaic, 1);
	addr.allocmb(brightness, 1);
	addr.allocmb(cgwsel, 1);
	addr.allocmb(cgadsub, 1);
	addr.allocmb(subscr, 1);
	addr.allocmb(mainscr, 1);
	addr.allocmb(screenmode, 1);
	addr.allocmb(obj, $220);

	addr.alloc7e(palette, $200);

	scope camera {
		addr.alloc6k(posX, 2);
		addr.alloc6k(posY, 2);
		addr.alloc6k(posZ, 2);
		addr.alloc6k(lastPosX, 2);
		addr.alloc6k(lastPosZ, 2);
		addr.alloc6k(lastCol, 2);
		addr.alloc6k(lastRow, 2);
	}

	addr.allocmb(mode7mir, 1);
	addr.allocmb(mode7a, 2);
	addr.allocmb(mode7b, 2);
	addr.allocmb(mode7c, 2);
	addr.allocmb(mode7d, 2);
	addr.allocmb(mode7x, 2);
	addr.allocmb(mode7y, 2);

	// Copy all the PPU mirrors into the appropriate PPU registers.
	// This has the notable exception of brightness, which, if enabled, causes weird problems.
	// So brightness should be handled separately.
	MirrorZp: {
		lda >video.subscr; sta $212d;
		lda >video.mainscr; sta $212c;
		lda >video.cgwsel; sta $2130;
		lda >video.cgadsub; sta $2131;
		lda >video.screenmode; sta $2105;
		lda >video.camera.posX.sc; sta $210d; lda >video.camera.posX.sc+1; sta $210d;
		lda >video.camera.posX.sc; sta $210f; lda >video.camera.posX.sc+1; sta $210f;
		lda >video.camera.posX.sc; sta $2111; lda >video.camera.posX.sc+1; sta $2111;
		lda >video.camera.posZ.sc; sta $210e; lda >video.camera.posZ.sc+1; sta $210e;
		lda >video.camera.posZ.sc; sta $2110; lda >video.camera.posZ.sc+1; sta $2110;
		lda >video.camera.posZ.sc; sta $2112; lda >video.camera.posZ.sc+1; sta $2112;

		lda >video.mode7mir; beq +;
		lda >video.mode7a; sta $211b; lda >video.mode7a+1; sta $211b;
		lda >video.mode7b; sta $211c; lda >video.mode7b+1; sta $211c;
		lda >video.mode7c; sta $211d; lda >video.mode7c+1; sta $211d;
		lda >video.mode7d; sta $211e; lda >video.mode7d+1; sta $211e;
		lda >video.mode7x; sta $211f; lda >video.mode7x+1; sta $211f;
		lda >video.mode7y; sta $2120; lda >video.mode7y+1; sta $2120;
	+;

		rtl;
	}

	Mirror: {
		phd;
		pea $0000; pld;
		jsl MirrorZp;
		pld;
		rtl;
	}

	scope PpuInit: {
		phd;
		pea $2100; pld;
		lda #$80; sta $00;
		stz $33;
		lda #$e0; sta $32;
		stz $31; stz >cgadsub;
		lda #$80; sta $30; sta >cgwsel;

		lda #$11; sta $2c; sta >mainscr;
		stz $2d; stz >subscr;
		sta $2e;
		stz $2f;

		stz $2b;
		stz $2a;

		lda #<windowRight; sta $29; sta $27;
		lda #<windowLeft; sta $28; sta $26;

		lda #$ff;
		sta $25;
		sta $24;
		sta $23;

		lda #$01;
		stz $1b; sta $1b;
		stz $1c; stz $1c;
		stz $1d; stz $1d;
		stz $1e; sta $1e;

		stz $1a;

		ldy #$0000; sty >camera.posX.sc;
		ldy #$ffff; sty >camera.posZ.sc;
		tya;
		sta $14; sta $14;
		stz $13; stz $13;
		sta $12; sta $12;
		stz $11; stz $11;
		sta $10; sta $10;
		stz $0f; stz $0f;
		sta $0e; sta $0e;
		stz $0d; stz $0d;

		lda #<(((vram.gfx.bg3>>13)&$0f)|((vram.gfx.bg4>>9)&$f0)); sta $0c;
		lda #<(((vram.gfx.bg1>>13)&$0f)|((vram.gfx.bg2>>9)&$f0)); sta $0b;

		lda #<((vram.tm.bg4>>9)&$fc); sta $0a;
		lda #<((vram.tm.bg3>>9)&$fc); sta $09;
		lda #<((vram.tm.bg2>>9)&$fc); sta $08;
		lda #<((vram.tm.bg1>>9)&$fc); sta $07;

		stz $06;

		lda #$03; sta $05; sta >screenmode;

		ldy #>0; sty $02;
		lda #<((vram.gfx.obj>>14)&$03); sta $01;

		pld;
		rtl;
	}
}
