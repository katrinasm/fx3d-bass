arch "arch/scpu.arch"

addr.allocmb(uploadFrameInfo, 2);
addr.allocmb(frameFlags, 2);
addr.allocmb(fieldCount, 2);
addr.allocmb(frameFieldCount, 2);
constant frameFlags.even(frameFlags);
constant frameFlags.odd(frameFlags+1);

scope frameBuf {
	addr.crossdecl(even, $70e400);
	addr.crossdecl(odd, $717000);
	// addr.alloc71(even, 28*24*$20, 10);
	// addr.alloc71(odd, 28*24*$20, 10);
}

scope oamBuf {
	addr.alloc6k(even, $2a0);
	addr.alloc6k(odd, $2a0);
}

scope bgOfsBuf {
	addr.alloc7e(even, 32 * 2);
	addr.alloc7e(odd, 32 * 2);
}

addr.alloc6k(oamBufPtr, 2);

addr.alloc6k(joy, 32);
addr.child6k(joy, p1,          0 +  0);
addr.child6k(joy, p1.held,     0 +  0);
addr.child6k(joy, p1.depress,  0 +  2);
addr.child6k(joy, p1.release,  0 +  4);
addr.child6k(joy, p1.axes,     0 +  6);
addr.child6k(joy, p1.axes.ud,  0 +  8);
addr.child6k(joy, p1.axes.lr,  0 + 10);
addr.child6k(joy, p1.heldBuf,  0 + 12);
addr.child6k(joy, p1.touched,  0 + 14);
addr.child6k(joy, p2,         16 +  0);
addr.child6k(joy, p2.held,    16 +  0);
addr.child6k(joy, p2.depress, 16 +  2);
addr.child6k(joy, p2.release, 16 +  4);
addr.child6k(joy, p2.axes,    16 +  6);
addr.child6k(joy, p2.axes.ud, 16 +  8);
addr.child6k(joy, p2.axes.lr, 16 + 10);
addr.child6k(joy, p2.heldBuf, 16 + 12);
addr.child6k(joy, p2.touched, 16 + 14);

constant joy.BUTTON_R($00'10);
constant joy.BUTTON_L($00'20);
constant joy.BUTTON_X($00'40);
constant joy.BUTTON_A($00'80);

constant joy.DPAD_R($01'00);
constant joy.DPAD_L($02'00);
constant joy.DPAD_D($04'00);
constant joy.DPAD_U($08'00);

constant joy.SELECT($10'00);
constant joy.START($20'00);
constant joy.BUTTON_Y($40'00);
constant joy.BUTTON_B($80'00);

scope Main: {
	jsr InitStuff;
	rep #$20;
	lda #>video.topIrq; sta $4209;
	stz >mainw.irq.sel;
	sep #$20;
	lda #$21; sta $4200;
	cli;

intloop:
	jsr InnerMain;
	bra intloop;
}

scope InitStuff: {
	jsl video.PpuInit;
	lda #$ff; sta $2132;

	stz $2121;
	ldy #$2200; sty $4300;
	ldy #>palette; sty $4302;
	lda #<(palette>>16); sta $4304;
	ldy #$0200; sty $4305;
	lda #$01; sta $420b;

	ldy #$8101; sty $4340; sty $4360;
	ldy #>mainw.pauseHdmaAddrB; sty $4342;
	lda #<(mainw.pauseHdmaAddrB>>16); sta $4344;
	ldy #>mainw.pauseHdmaAddrA; sty $4362;
	lda #<(mainw.pauseHdmaAddrA>>16); sta $4364;

	ldy #$80c0; sty $4350; sty $4370;
	ldy #>mainw.pauseHdmaScmr; sty $4352; sty $4372;
	lda #<(mainw.pauseHdmaScmr>>16); sta $4354; sta $4374;
	lda #$00; sta $4357; sta $4377;

	lda #$7e; sta $2183;
	//lda #$f0; sta $420c;

	lda #$80; sta $2115;

	ldy #$1801; sty $4300;

	ldy #>(video.vram.tm.bg1>>1); sty $2116;
	ldy #>rendertm; sty $4302;
	lda #<(rendertm>>16); sta $4304;
	ldy #>rendertm.size; sty $4305;
	lda #$01; sta $420b;

	ldy #$0000;
	sty >fx.deathFlag.sc;
	sty >uploadFrameInfo;
	sty >frameFlags;

	// initialize odd oam buffer
	ldy #>oamBuf.odd.fx;
	sty >oamBufPtr.sc;
	ldy #>fx.ClearOam;
	lda #<(fx.ClearOam>>16);
	jsl mainw.FxCall;

	// initialize even oam buffer
	ldy #>oamBuf.even.fx;
	sty >oamBufPtr.sc;
	ldy #>fx.ClearOam;
	lda #<(fx.ClearOam>>16);
	jsl mainw.FxCall;

	ldy #>fx.renderer.test.InitTestScene;
	lda #<(fx.renderer.test.InitTestScene>>16);
	jsl mainw.FxCall;

	stz >video.brightness;

	ldy #$0000;
	sty >fieldCount;
	sty >frameFieldCount;
	rts;
}

scope InnerMain: {
	phk; plb;
	jsl mainw.ClaimMemory;

	jsl mainw.DoDrawCall;
	bcs +;
	rts;
+;

	lda >video.brightness; cmp #$0f; beq +;
	wai;
	wai;
	inc; sta >video.brightness;
+;
	rts;
}

scope JoyHandle: {
	php; phb;
	phk; plb;
	rep #$20;
	lda >joy.sc.p1.heldBuf; eor >joy.sc.p1.held;
	and >joy.sc.p1.heldBuf; sta >joy.sc.p1.depress;
	lda >joy.sc.p2.heldBuf; eor >joy.sc.p2.held;
	and >joy.sc.p2.heldBuf; sta >joy.sc.p2.depress;

	lda >joy.sc.p1.heldBuf; sta >joy.sc.p1.held;
	lda >joy.sc.p2.heldBuf; sta >joy.sc.p2.held;

	lda >joy.sc.p1.held; and #$0f00; xba; asl #2; tax;
	lda ^vals+0,x; sta >joy.sc.p1.axes.lr;
	lda ^vals+2,x; sta >joy.sc.p1.axes.ud;

	lda >joy.sc.p2.held; and #$0f00; xba; asl #2; tax;
	lda ^vals+0,x; sta >joy.sc.p2.axes.lr;
	lda ^vals+2,x; sta >joy.sc.p2.axes.ud;
	plb;
	plp;
	rtl;

vals:
	//               input: UDLR H  V
	// out:  H        V
	dw  $00'00,  $00'00; // 0000 0  0
	dw +$01'00,  $00'00; // 0001 1  0
	dw -$01'00,  $00'00; // 0010-1  0
	dw  $00'00,  $00'00; // 0011 0  0

	dw  $00'00, -$01'00; // 0100 0 -1
	dw +$00'b5, -$00'b5; // 0101 1 -1
	dw -$00'b5, -$00'b5; // 0110-1 -1
	dw  $00'00, -$01'00; // 0111 0 -1

	dw  $00'00, +$01'00; // 1000 0  1
	dw +$00'b5, +$00'b5; // 1001 1  1
	dw -$00'b5, +$00'b5; // 1010-1  1
	dw  $00'00, +$01'00; // 1011 0  1

	dw  $00'00,  $00'00; // 1100 0  0
	dw +$01'00,  $00'00; // 1101 1  0
	dw -$01'00,  $00'00; // 1110-1  0
	dw  $00'00,  $00'00; // 1111 0  0
}

include "video.asm";

insert palette, "res/palette.mw3";
insert rendertm, "res/bg1tm.bin";

