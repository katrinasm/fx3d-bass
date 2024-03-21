arch "arch/scpu.arch";

UploadWram: {
	phb;
	lda #$00; pha; plb;

	ldx #>interruptw; stx $2181;
	lda #<interruptw>>16; sta $2183;

	ldx #$8000; stx $4300;
	ldx #>interruptw_rom_begin; stx $4302;
	lda #<interruptw_rom_begin>>16; sta $4304;
	ldx #>interruptw_rom_end-interruptw_rom_begin; stx $4305;
	lda #$01; sta $420b;

	ldx #>mainw; stx $2181;
	lda #<mainw>>16; sta $2183;
	ldx #>mainw_rom_begin; stx $4302;
	lda #<mainw_rom_begin>>16; sta $4304;
	ldx #>mainw_rom_end-mainw_rom_begin; stx $4305;
	lda #$01; sta $420b;

	plb;
	rtl;
}

interruptw_rom_begin:
	push base
	base $000100
	scope interruptw: {
		brk:
			jml mainw.brk;
		cop:
			jml mainw.cop;
		nmi:
			jml mainw.nmi;
		irq:
			jml mainw.irq;
	}
	pull base
interruptw_rom_end:

addr.seek($02'8000);
mainw_rom_begin:
	push base
	base $7e8000

	scope mainw: {
		constant bankofs(mainw-mainw_rom_begin);

		addr.alloc7e(fxWait, 2);

		brk:
		cop:
		nmi:
			rti;

		scope FxCall: {
			php;
			phb;
			sta $003034;
			lda #$00; pha; plb;
			lda #$01; sta ^fxWait;
			lda >fx.screenmode; ora #$18; sta >fx.screenmode; sta $303a;
			sty $301e;
		iloop:
			wai;
			lda ^fxWait; bne iloop;

			plb;
			plp;
			rtl;
		}

		scope FxCallNoWait: {
			php;
			sta $003034;
			lda #$01; sta ^fxWait;
			lda ^fx.screenmode; ora #$18; sta ^fx.screenmode; sta $00303a;
			rep #$20;
			tya;
			sta $00301e;
			plp;
			rtl;
		}

		scope FxWait: {
			php;
			sep #$20;
		iloop:
			wai;
			lda ^fxWait; bne iloop;
			plp;
			rtl;
		}

		scope ClaimMemory: {
			lda ^fx.screenmode; and #$e7; sta ^fx.screenmode; sta $00303a;
			rtl;
		}

		scope irq: {
			addr.allocmb(sel, 2);
		prologue:
			rep #$30;
			pha;
			lda $003030; bmi fxIrq;
			phx;
			phy;
			phd;
			phb;
			lda #$4200; tcd;
			lda #$0000;
			phk; plb;
		select:
			sep #$20;
			lda $11;
			lda >sel; tay;
			ldx >bodyPtrs,y;
			pea retp-1;
			phx;
			rts;
		retp:
			lda >sel;
			eor #$02;
			sta >sel;
		end:
			rep #$30;
			plb;
			pld;
			ply;
			plx;
			pla;
			rti;

		fxIrq:
			lda #$0000; sta ^fxWait;
			pla;
			rti;

		bodyPtrs:
			dw top-1, bottom-1;

			scope top: {
				jsr videoMirror;
				lda #$00; pha; plb;
				lda #<video.bottomIrq; sta <$4209;
				lda >video.brightness;
			-;	bit <$4212; bvc -;
				sta $2100;
				lda >fx.screenmode; ora #$10; and #$f7; sta >fx.screenmode; sta $303a;
				rep #$20;
				lda $4218; sta >joy.sc.p1.heldBuf; tsb >joy.sc.p1.touched;
				lda $421a; sta >joy.sc.p2.heldBuf; tsb >joy.sc.p2.touched;
				sep #$20;
				lda >fx.screenmode; ora #$18; sta >fx.screenmode; sta $303a;
				inc >fieldCount;
				inc >frameFieldCount;
				rts;
			}

			scope bottom: {
				lda #<video.topIrq; sta <$004209;
			-;	bit <$4212; bvc -;
				lda #$80; sta $002100;
				jsr frameUpload;
				rts;
			}

			scope videoMirror: {
				phd;
				pea $2100; pld;
				lda >video.subscr; sta $2d;
				lda >video.mainscr; sta $2c;
				lda >video.cgwsel; sta $30;
				lda >video.cgadsub; sta $31;
				lda >video.screenmode; sta $05;
				// phk; pla; cmp #$7e; bcs +;
				// stz $0d; stz $0d;
				// // lda >video.camera.posX.sc; sta $0d; lda >video.camera.posX.sc+1; sta $0d;
				// lda >video.camera.posX.sc; sta $0f; lda >video.camera.posX.sc+1; sta $0f;
				// lda >video.camera.posX.sc; sta $11; lda >video.camera.posX.sc+1; sta $11;
				// lda #$ff; sta $0e; sta $0e;
				// // lda >video.camera.posZ.sc; sta $0e; lda >video.camera.posZ.sc+1; sta $0e;
				// lda >video.camera.posZ.sc; sta $10; lda >video.camera.posZ.sc+1; sta $10;
				// lda >video.camera.posZ.sc; sta $12; lda >video.camera.posZ.sc+1; sta $12;
			// +;
				lda >video.mode7mir; beq +;
				lda >video.mode7a; sta $1b; lda >video.mode7a+1; sta $1b;
				lda >video.mode7b; sta $1c; lda >video.mode7b+1; sta $1c;
				lda >video.mode7c; sta $1d; lda >video.mode7c+1; sta $1d;
				lda >video.mode7d; sta $1e; lda >video.mode7d+1; sta $1e;
				lda >video.mode7x; sta $1f; lda >video.mode7x+1; sta $1f;
				lda >video.mode7y; sta $20; lda >video.mode7y+1; sta $20;
			+;
				pld;
				rts;
			}

			scope frameUpload: {
				ldy >uploadFrameInfo;
				ldx >flagAddrs,y;
				lda $00,x; bne upload;
				rts;

			upload:
				lda >fx.screenmode; ora #$10; and #$f7; sta >fx.screenmode; sta $00303a;
				ldx #$0100;
				lda #$80; sta $002115;
				rep #$21;
				lda >targets,y; sta $002116;
				lda #$1801; sta $00,x;
				lda >sourcesLo,y; sta $02,x;
				lda >sizes,y; sta $05,x;
				sep #$20;
				lda >sourcesHi,y; sta $04,x;
				lda #$01; sta $0b;
				tya; bit #$04; beq +;
					and #$08; lsr; adc #<((video.vram.tm.bg1>>9)&$fc); sta $002107;

					// rep #$20;
					// lda #>(video.vram.tm.bg3)>>1; sta $002116;
					// lda >ofsSources,y; sta $02,x;
					// lda #$0040; sta $05,x;
					// sep #$20;
					// lda #<(bgOfsBuf.even>>16); sta $04,x;
					// lda #$01; sta $0b;

					// rep #$20;
					// lda #$0000; sta $002102;
					// lda #$0400; sta $00,x;
					// lda >oamSources,y; sta $02,x;
					// lda #$0220; sta $05,x;
					// sep #$20;
					// lda #<(oamBuf.even.long>>16); sta $04,x;
					// lda #$01; sta $0b;

					ldx flagAddrs,y; stz $00,x;
				+;
				lda >fx.screenmode; ora #$18; sta >fx.screenmode; sta $00303a;
				tya; bit #$04; beq +; inc; inc; +; inc; inc; and #$0e; sta >uploadFrameInfo;
				rts;

			sourcesLo:
				dw frameBuf.even.long, frameBuf.even.long+$1c00, frameBuf.even.long+$1c00+$3800, -1;
				dw frameBuf.odd.long+$3800+$3800, frameBuf.odd.long+$3800, frameBuf.odd.long, -1;
			sourcesHi:
				dw (frameBuf.even.long)>>16, (frameBuf.even.long+$1c00)>>16, (frameBuf.even.long+$1c00+$3800)>>16, -1;
				dw (frameBuf.odd.long+$3800+$3800)>>16, (frameBuf.odd.long+$3800)>>16, (frameBuf.odd.long)>>16, -1;
			targets:
				dw $0000>>1, $1c00>>1, $5400>>1, -1;
				dw $c400>>1, $8c00>>1, $5400>>1, -1;
			sizes:
				dw $1c00, $3800, $3800, -1;
				dw $1c00, $3800, $3800, -1;
			flagAddrs:
				dw frameFlags.even-$4200, frameFlags.even-$4200, frameFlags.even-$4200, frameFlags.even-$4200;
				dw frameFlags.odd-$4200, frameFlags.odd-$4200, frameFlags.odd-$4200, frameFlags.odd-$4200;
			oamSources:
				dw -1, -1, -1, oamBuf.even.long;
				dw -1, -1, -1, oamBuf.odd.long;
			// ofsSources:
				// dw 0, bgOfsBuf.even;
				// dw 0, bgOfsBuf.odd;
			}
		}

		scope DoDrawCall: {
			phb;
			phk; plb;
			ldy #$0000;
			ldx flagTargets,y; lda $00,x; beq +;
			ldy #$0008;
			ldx flagTargets,y; lda $00,x; beq +;
			plb;
			clc;
			rtl;
		+;

			sty $00;
			// lda fx.test.DrawTestScene.ofs.long; inc; sta fx.test.DrawTestScene.ofs.long;
			// lda ^fieldCount; sta fx.test.DrawTestScene.ofs.long;
			sta $02;

			rep #$21;
			lda >frameFieldCount; sta fx.physicFieldCount.long;
			stz >frameFieldCount;
			lda #$0008;
			and #$00ff; asl; tax;
			lda ^table.tan,x; eor #$ffff; inc; sta $04;
			sep #$20;

			lda drawTargets,y; sta $003038;
			phy;

			jsl JoyHandle;

			lda #$07; sta >fx.screenmode;
			ora #$18; sta >fx.pausemode;
			ldy #>fx.renderer.test.DrawTestScene;
			lda #<(fx.renderer.test.DrawTestScene>>16);
			jsl FxCallNoWait;
			jsr StuffToDoWhileDrawing;
			jsl FxWait;
			ply;
			lda #$01;
			ldx flagTargets,y; sta $00,x;

			plb;
			sec;
			rtl;

		drawTargets:
			// draw in the odd buffer while uploading even frames,
			// and the even buffer while uploading odd frames
			dw frameBuf.even>>10, frameBuf.even>>10, frameBuf.even>>10, -1;
			dw frameBuf.odd>>10, frameBuf.odd>>10, frameBuf.odd>>10, -1;
		flagTargets:
			dw frameFlags.even, frameFlags.even, frameFlags.even, frameFlags.even;
			dw frameFlags.odd, frameFlags.odd, frameFlags.odd, frameFlags.odd;
		}

		scope StuffToDoWhileDrawing: {
			phb;
			phk; plb;
			ldy $00;


			rep #$21;
			lda $04; and #$8000; bpl +; lda #$ffff; +; sta $06;
			asl $04; rol $06;
			asl $04; rol $06;
			asl $04; rol $06;
			lda $04; sta $08;
			lda $06; sta $0a;


			lda ofsBufs,y; clc; adc #>16*2; tax; dec; dec; tay;
			lda #>16; sta $0e;
			loop: {
				lda #$0080; clc; adc $09; and #$03ff; ora #$4000; sta $0000,x;
				lda #$0080; sec; sbc $09; and #$03ff; ora #$4000; sta $0000,y;
				lda $08; clc; adc $04; sta $08;
				lda $0a; adc $06; sta $0a;
				inx; inx;
				dey; dey;
				dec $0e; bne loop;
			}
			sep #$20;
			plb;
			rts;

			ofsBufs:
				dw bgOfsBuf.even, bgOfsBuf.even, bgOfsBuf.even, bgOfsBuf.even;
				dw bgOfsBuf.odd, bgOfsBuf.odd, bgOfsBuf.odd, bgOfsBuf.odd;
		}

		scope pauseHdmaAddrA: {
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;

			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;

			db $60; dw fx.screenmode;
			db $40; dw fx.screenmode;

			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;

			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode; db 1; dw fx.screenmode;
			db 0;
		}

		scope pauseHdmaAddrB: {
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;

			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;

			db $60; dw fx.pausemode;
			db $40; dw fx.pausemode;

			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;

			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode; db 1; dw fx.pausemode;
			db 0;
		}

		scope pauseHdmaScmr: {
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;

			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;

			db $60; dw $303a;
			db $40; dw $303a;

			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;

			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;
			db 1; dw $303a; db 1; dw $303a; db 1; dw $303a; db 1; dw $303a;

			db 0;
		}
	}

	pull base
mainw_rom_end: