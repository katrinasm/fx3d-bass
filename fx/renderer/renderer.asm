scope OuterRaster: {
	psh %r11;

	jsr BillboardCull; nop;
	jsr TriCull; nop;

	ldb %r1, #RASTER.REF_Z;
	jsr ZPrep; nop;
	ldw %r2, #rasterList;
	ldw %r0, rasterEndPtr;
	sub %r0, %r2;
	lsr %r3, %r0;
	jsr Sort; nop;

rasterLoop:
	jsr RasterPrepro; nop;
	jsr Rasterize; nop;
	ldw %r2, #rasterList;
	ldw %r0, rasterBtmPtr;
	sub %r0, %r2; bne rasterLoop; nop;

finish:
	pul %r15; nop;
}

scope WorldspaceCull: {
	addr.printlab(WorldspaceCull);
	ldw %r12, itriCount;
	dec %r12; bpl +; inc %r12;
		rts; nop;
	+;

	cache;
	stw %r11, [%r10];
	sms %r10, w15;

	ldw %r3, #camera + OBJ.ROT_I;
	ldw %r0, [%r3]; inc %r3; inc %r3;
	ldw %r1, [%r3]; inc %r3; inc %r3;
	orr %r0, %r1;
	ldw %r1, [%r3];
	orr %r0, %r1;
	beq +; sub %r0, %r0;
		inc %r0;
+;
	inc %r0;
	sms %r0, w0;

	ldw %r0, #cameraZVector;
	ldw %r1, [%r0]; inc %r0; inc %r0;
	ldw %r2, [%r0]; inc %r0; inc %r0;
	ldw %r3, [%r0];


	// the /$100 here is to account for the $100 units between the camera
	// and the 1x magnification plane
	ldw %r6, #$10000*(SCREEN_W/2)/$100;
	mlf %r0, %r1, %r6;
	sms %r0, w1;
	mlf %r0, %r2, %r6;
	sms %r0, w2;
	mlf %r0, %r3, %r6;
	sms %r0, w3;

	ldw %r6, #$10000*(SCREEN_H/2)/$100;
	mlf %r0, %r1, %r6;
	sms %r0, w4;
	mlf %r0, %r2, %r6;
	sms %r0, w5;
	mlf %r0, %r3, %r6;
	sms %r0, w6;

	ldw %r10, #itriBuffer;
	scope wcbody: {
		ldb %r1, #RFLAG.TYPE | RFLAG.VALID;
		ldw %r3, [%r10];
		and %r3, %r1;
		ldb %r0, #RFLAG.FLATRI | RFLAG.VALID;
		sub %r0, %r3;
		beq wctri; nop;
		ldb %r0, #RFLAG.TEXTRI | RFLAG.VALID;
		sub %r0, %r3;
		beq wctri; nop;
		ldb %r0, #RFLAG.BILLBD | RFLAG.VALID;
		sub %r0, %r3;
		bne wccontinue; nop;
	wcbillboard:
		addk(0, 10, BILLBOARD.REF_LOC);
		bsr getPoint; nop;
		addk(0, 10, BILLBOARD.RELOC_X);
		ldw %r1, [%r0];
		lob %r0, %r1;
		add %r7, %r0;
		hib %r0, %r1;
		ldb %r3, #$40;
		add %r0, %r3;
		add %r8, %r0;
		addr.printloc("getXDist call");
		bsr getXDist; nop;
		movs %r1, %r1;
		beq wccull; sub %r0, %r3;
		bcs wccull; // link ...
		jsr getYDist; nop;
		sub %r0, %r3;
		bcs wccull; nop;
		bch wccontinue; nop;
	wctri:
		ldb %r3, #$40;
		addk(0, 10, ITRI.POINT_A);
		bsr checkPoint; nop;
		sub %r0, %r3;
		bcc wccontinue; nop;
		addk(0, 10, ITRI.POINT_B);
		bsr checkPoint; nop;
		sub %r0, %r3;
		bcc wccontinue; nop;
		addk(0, 10, ITRI.POINT_C);
		bsr checkPoint; nop;
		sub %r0, %r3;
		bcc wccontinue; nop;
	wccull:
		sub %r0, %r0;
		stw %r0, [%r10];
	wccontinue:
		addk(10, 10, ITRI.SIZE - 1);
		dec %r12;
		bne wcbody; inc %r10;
	wcend:
	}

	lms %r10, w15;
	ldw %r15, [%r10]; nop;

	scope checkPoint: {
		sms %r11, w14;
		bsr getPoint; nop;
		bsr getXDist; nop;
		bne reject; nop;
		bsr getYDist; nop;
	reject:
		lms %r15, w14; nop;
	}

	scope getPoint: {
		ldw %r9, [%r0];
		ldw %r0, [%r9]; inc %r9; inc %r9;
		ldw %r7, camera + OBJ.POS_X;
		sub %r7, %r0, %r7;
		ldw %r0, [%r9]; inc %r9; inc %r9;
		ldw %r8, camera + OBJ.POS_Y;
		sub %r8, %r0, %r8;
		ldw %r0, [%r9];
		ldw %r9, camera + OBJ.POS_Z;
		sub %r9, %r0, %r9;
		rts; nop;
	}

	scope getXDist: {
		lms %r0, w0;
		add %r0, %r0; beq norot; nop;

		sms %r11, w13;
		ldw %r1, #cameraXVector;
		bsr pointDotAbs; nop;
		mov %r2, %r0;
		ldb %r1, #2; // #w1
		bsr pointDotAbs; nop;
	TAIL:
		sub %r0, %r2, %r0;
		bpl offscreen; nop;
			sub %r0, %r0;
	offscreen:
		lms %r15, w13; nop;

	norot:
		ldb %r1, #1;
		movs %r0, %r9;
		bpl +; nop;
			not %r0; inc %r0;
			dec %r1;
	+;
		ldw %r6, #$10000*(SCREEN_W/2)/$100;
		mlf %r2, %r0, %r6;

		movs %r0, %r7;
	NOROT_TAIL:
		bpl +; nop;
			not %r0; inc %r0;
	+;
		sub %r0, %r2;
		bpl +; nop;
			sub %r0, %r0;
			sub %r0, %r2;
	+;
		rts; nop;
	}

	scope getYDist: {
		lms %r0, w0;
		add %r0, %r0; beq norot; nop;

		sms %r11, w13;
		ldw %r1, #cameraYVector;
		bsr pointDotAbs; nop;
		mov %r2, %r0;
		ldb %r1, #8; // #w4
		ldw %r11, #getXDist.TAIL;
		bch pointDotAbs; nop;

	norot:
		ldb %r1, #1;
		movs %r0, %r9;
		bpl +; nop;
			sub %r0, %r0;
			sub %r0, %r9;
			dec %r1;
	+;
		ldw %r6, #$10000*(SCREEN_H/2)/$100;
		mlf %r2, %r0, %r6;
		sub %r0, %r0;
		addr.printloc("bch NOROT_TAIL");
		bch getXDist.NOROT_TAIL; add %r0, %r8;
	}

	scope pointDotAbs: {
		ldw %r6, [%r1]; inc %r1; inc %r1;
		mll %r13, %r7, %r6;
		mov %r5, %r4;
		ldw %r6, [%r1]; inc %r1; inc %r1;
		mll %r0, %r8, %r6;
		add %r5, %r4;
		adc %r13, %r0;
		ldw %r6, [%r1];
		mll %r0, %r9, %r6;
		add %r4, %r5;
		adc %r0, %r13;
		lob %r13, %r0;
		xbr %r13;
		hib %r4;
		orr %r4, %r13;
		xbr %r0;
		sxb %r0;
		div2 %r0;
		bne huge; add %r0, %r4;
		bpl +; nop;
			ldb %r1, #0;
			sub %r0, %r1, %r4;
	+;
		rts; nop;

	huge:
		sub %r0, %r0;
		lsr %r0;
		rts; dec %r0;
	}
}

// %r1 - pointer to camera object
scope ProjectPoints: {
	constant DPLANE_X(SCREEN_W/2);
	constant DPLANE_Y(SCREEN_H/2);
	ldw %r0, vertexCount;
	movs %r12, %r0; bne +; nop; rts; nop; +;
	cache;
	psh %r11;

	ldw %r9, #vertexBuffer;
	inc %r1; inc %r1; // skips model id
	psh %r1;

	addk(5, 1, OBJ.ROT_R - OBJ.POS_X);
	ldw %r1, [%r5]; inc %r5; inc %r5;
	ldw %r2, [%r5]; inc %r5; inc %r5;
	ldw %r3, [%r5]; inc %r5; inc %r5;
	ldw %r4, [%r5];

	scope camLoop: {
		// %r1  - quion w
		// %r2  - quion x
		// %r3  - quion y
		// %r4  - quion z
		// %r5  - camera addr
		// %r6  - vector x
		// %r7  - vector y
		// %r8  - vector z
		// %r9  - vertex addr
		addk(0, 10, 2);
		ldw %r5, [%r0];

		ldw %r6, [%r9]; addk(0, 9, 2);
		ldw %r7, [%r0]; inc %r0; inc %r0;
		ldw %r8, [%r0];
		psh %r9;

		ldw %r0, [%r5]; inc %r5; inc %r5;
		sub %r6, %r0;
		ldw %r0, [%r5]; inc %r5; inc %r5;
		sub %r7, %r0;
		ldw %r0, [%r5];
		sub %r8, %r0;

		psh %r12;
		jsr localQuionApply; nop;
		pul %r12;
		pul %r9;

		stw %r6, [%r9]; inc %r9; inc %r9;
		stw %r7, [%r9]; inc %r9; inc %r9;
		stw %r8, [%r9];
		addk(9, 9, VERTEX.SIZE - VERTEX.POS_Z);

		dec %r12; bne camLoop; nop;
	}

	inc %r10; inc %r10;

	// %r1  -
	// %r2  - vertex buffer ptr
	// %r3  -
	// %r4  - mul trash
	// %r5  -
	// %r6  - mul trash
	ldw %r12, vertexCount;
	ldw %r2, #vertexBuffer;
	ldb %r0, #table.recip>>16; romb %r0;

	setl; scope pointLoop: {
		add %r0, %r2, #4; ldw %r0, [%r0]; // %r0 = point z
		movs %r0, %r0; bmi skip; nop;
		ldw %r1, #table.RECIP_MAX;
		cmp %r0, %r1;
		bcc +; nop; mov %r0, %r1; +;
		mov %r11, %r0;
		add %r0, %r0;

		ldw %r4, #table.recip;
		add %r14, %r0, %r4;
		getb %r6; inc %r14; // recip lo

		ldw %r0, [%r2]; // %r0 = point x

		getbh %r6; // recip hi
		// d.x/d.z = d.x * recip(d.z)
		mll %r0, %r0, %r6;

		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r1, %r0; ror %r4;

		ldw %r0, #DPLANE_X<<4; add %r0, %r4;
		adc %r1, #0; beq +; nop;
			inc %r1; beq +; dec %r1;
			ldw %r0, #$7fff;
			bpl +; nop;
			ldw %r0, #$8000;
		+;
		stw %r0, [%r2]; inc %r2; inc %r2;

		sub %r0, %r0;
		ldw %r4, [%r2]; // %r4 = point y
		sub %r0, %r4;   // %r0 = -y
		mll %r0, %r0, %r6;

		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r1, %r0; ror %r4;

		ldw %r0, #DPLANE_Y<<4; add %r0, %r4;
		adc %r1, #0; beq +; nop;
			inc %r1; beq +; dec %r1;
			ldw %r0, #$7fff;
			bpl +; nop;
			ldw %r0, #$8000;
		+;
		stw %r0, [%r2]; inc %r2; inc %r2;

		stw %r11, [%r2]; add %r2, #VERTEX.SIZE-VERTEX.POS_Z;
		loop; nop;
		bch end; nop;

	skip:
		addk(2, 2, VERTEX.SIZE);
		loop; nop;
	end:
	}
	pul %r15; nop;
FEND:
}

// %r1  - quion w
// %r2  - quion x
// %r3  - quion y
// %r4  - quion z
// %r6  - vector x
// %r7  - vector y
// %r8  - vector z
scope localQuionApply: {
	orr %r0, %r2, %r3;
	orr %r0, %r4;
	bne +; nop; rts; +;
	psh %r11;
	sms %r10, w0;
	mov %r9, %r4;
	mov %r13, %r6;

	// %r9  - quion z
	// %r13 - vector x

	// %r10 - product x
	// %r11 - product y
	// %r12 - product z

	// t = (2*q.xyz) × v

	// t.y = 2 * q.z * v.x
	add %r0, %r4, %r4;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r11, %r0, %r4;
	// t.z = -2 * q.y * v.x
	sub %r0, %r0; sub %r0, %r3; sub %r0, %r3;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r12, %r0, %r4;

	mov %r6, %r7;
	// t.z += 2 * q.x * v.y
	add %r0, %r2, %r2;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r12, %r0;

	// t.x = -2 * q.z * v.y
	sub %r0, %r0; sub %r0, %r9; sub %r0, %r9;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r10, %r0, %r4;

	mov %r6, %r8;
	// t.x += 2 * q.y * v.z
	add %r0, %r3, %r3;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r10, %r0;

	// t.y -= 2 * q.x * v.z
	add %r0, %r2, %r2;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r11, %r0;

	mov %r6, %r1;

	mll %r0, %r10, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r13, %r0;

	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r7, %r0;

	mll %r0, %r12, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r8, %r0;

	mov %r6, %r12;
	// v.x += q.y * t.z
	mll %r0, %r3, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r13, %r0;

	// v.y -= q.x * t.z
	mll %r0, %r2, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r7, %r0;

	mov %r6, %r10;
	// v.y += q.z * t.x;
	mll %r0, %r9, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r7, %r0;

	// v.z -= q.y * t.x;
	mll %r0, %r3, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r8, %r0;

	mov %r6, %r11;
	// v.z += q.x * t.y;
	mll %r0, %r2, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r8, %r0;

	// v.x -= q.z * t.y;
	mll %r0, %r9, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r6, %r13, %r0;

	mov %r4, %r9;
	lms %r10, w0;
	pul %r15; nop;
}

cachealign();
scope DrawPoints: {
	cache;
	mov %r8, %r11;
	ldw %r12, itriCount;
	ldw %r9, #plotPoint;
	ldw %r7, #itriBuffer;
	ldw %r3, #(SCREEN_W-3)<<4;
	ldw %r4, #(SCREEN_H-3)<<4;
	setl; {
		addk(0, 7, ITRI.CTEX);
		ldb %r0, [%r0];
		color %r0;

		addk(7, 7, ITRI.POINT_A);
		ldw %r0, [%r7];
		inc %r7;
		jsr [%r9]; inc %r7;

		ldw %r0, [%r7];
		inc %r7;
		jsr [%r9]; inc %r7;

		jsr [%r9]; ldw %r0, [%r7];

		addk(7, 7, ITRI.SIZE-ITRI.POINT_C);

		loop; nop;
	}

	rpix;
	jmp [%r8]; nop;

	scope plotPoint: {
		ldw %r1, [%r0];
		tst %r1; beq dont; nop;
		cmp %r1, %r3; bcs dont; nop;
		inc %r0; inc %r0;
		ldw %r2, [%r0];
		tst %r2; beq dont; nop;
		cmp %r2, %r4; bcs dont; nop;

		lsr %r0, %r1; lsr %r0; lsr %r0; lsr %r1, %r0;
		lsr %r0, %r2; lsr %r0; lsr %r0; lsr %r2, %r0;

		dec %r1;
		plot; plot; plot;

		dec %r2;
		dec %r1; dec %r1;
		plot;
		inc %r2; inc %r2;
		dec %r1;
		rts;
		plot;

	dont:
		rts;
		nop;
	}
}

cachealign();
scope BillboardCull: {
	addr.printlab(BillboardCull);
	cache;
	ldw %r12, itriCount;
	dec %r12; bpl +; inc %r12;
		rts; nop;
	+;

	psh %r11;
	sms %r10, w15;

	ldw %r10, #itriBuffer;

	ldw %r7, #tex.headers + tex.HEADER_UVMASK;
	setl;
	scope bcbody: {
		ldb %r1, #RFLAG.TYPE | RFLAG.VALID;
		ldb %r2, #RFLAG.BILLBD | RFLAG.VALID;
		ldw %r0, [%r10];
		and %r0, %r1;
		sub %r0, %r2;
		// bne bccontinue; nop;
		beq +; nop; jmp bccontinue; nop; +;

		addk(0, 10, BILLBOARD.REF_LOC);
		ldw %r9, [%r0];
		ldw %r1, [%r9]; inc %r9; inc %r9;
		ldw %r2, [%r9]; inc %r9;
		// the y coordinate is the bottom of the billboard,
		// so if it's negative or 0 it's going to get culled
		ldb %r0, #-$10;
		add %r0, %r2;
		bpl +; inc %r9; jmp bccull; nop; +;

		ldb %r0, #table.recip>>16; romb %r0;
		ldw %r9, [%r9];
		add %r14, %r9, %r9;
		bmi bccull; getb %r0;
		inc %r14;
		getbh %r6, %r0;

		ldb %r0, #tex.headers>>16; romb %r0;
		addk(0, 10, BILLBOARD.TEX);
		ldw %r0, [%r0];
		add %r0, %r0; add %r0, %r0; add %r0, %r0; add %r0, %r0;
		add %r14, %r0, %r7;

		ldw %r5, #SCREEN_W*16;

		addk(0, 10, BILLBOARD.RELOC_X);
		ldb %r0, [%r0];
		sxb %r0;
		getb %r8;
		inc %r8;
		add %r0, %r8;
		xbr %r0;
		mll %r0, %r6;
		// we need the texture's width/2 since x is in the middle
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;

		sub %r3, %r1, %r0;
		add %r1, %r0;
		// %r1 is the right edge; if negative, we are done
		bmi bccull; inc %r14;
		// %r3 is the left edge; if it's off the screen, we are done
		sub %r0, %r3, %r5;
		bge bccull; nop;

		// make sure %r1 doesn't go off the right
		sub %r0, %r1, %r5;
		cmov %r1, ge, %r5;
		addk(0, 10, BILLBOARD.RELOC_Y);
		ldb %r0, [%r0];
		xbr %r0;
		mll %r0, %r6;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		sub %r2, %r0;

		getb %r0;
		inc %r0;
		xbr %r0;
		mll %r0, %r6;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		add %r4, %r4; rol %r0;
		sub %r4, %r2, %r0;

		mov %r6, %r9;

		// %r4 is the top edge; if it's off the screen, we are done
		ldw %r9, #SCREEN_H*16;
		sub %r0, %r4, %r9;
		blt bckeepgoing; inc %r14;

	bccull:
		sub %r0, %r0;
		stw %r0, [%r10];
	bccontinue:
		addk(10, 10, BILLBOARD.SIZE - 1);
		loop; inc %r10;
		jmp bcend; nop;

	bckeepgoing:
		// make sure %r2 doesn't go off the bottom
		sub %r0, %r2, %r9;
		cmov %r2, ge, %r9;
		asr %r0, %r1; asr %r0; asr %r0; asr %r1, %r0;
		asr %r0, %r2; asr %r0; asr %r0; asr %r2, %r0;
		asr %r0, %r3; asr %r0; asr %r0; asr %r3, %r0;
		asr %r0, %r4; asr %r0; asr %r0; asr %r4, %r0;

		not %r0, %r3; inc %r0;
		bpl +; nop; sub %r0, %r0; +;
		mov %r5, %r0;
		add %r0, %r3;

		addk(10, 10, BILLBOARD.SCREEN_X);
		stb %r0, [%r10];
		sub %r0, %r1, %r0;
		addk(10, 10, BILLBOARD.WIDTH - BILLBOARD.SCREEN_X);
		stb %r0, [%r10];

		sub %r0, %r0; sub %r0, %r4;
		bpl +; nop; sub %r0, %r0; +;
		mov %r3, %r0;
		add %r0, %r4;
		addk(10, 10, BILLBOARD.SCREEN_Y - BILLBOARD.WIDTH);
		ldb %r9, [%r10];
		stb %r0, [%r10];
		sub %r0, %r2, %r0;
		bpl +; nop; sub %r0, %r0; +;
		addk(10, 10, BILLBOARD.HEIGHT - BILLBOARD.SCREEN_Y);
		stb %r0, [%r10];

		mll %r3, %r6;
		hib %r3, %r4;
		tst %r9; beq +; sub %r0, %r0;
			sub %r6, %r0, %r6;
			add %r0, %r8;
	+;	mll %r5, %r6;
		hib %r5, %r4;
		add %r0, %r5;

		getb %r5; inc %r14;
		add %r0, %r5;
		addk(10, 10, BILLBOARD.TEX_U - BILLBOARD.HEIGHT);
		stb %r0, [%r10];
		getb %r0; inc %r14;
		add %r0, %r3;
		addk(10, 10, BILLBOARD.TEX_V - BILLBOARD.TEX_U);
		stb %r0, [%r10];
		getb %r0;
		addk(10, 10, BILLBOARD.TEX_K - BILLBOARD.TEX_V);
		stb %r0, [%r10];
		ldb %r0, #$20;
		addk(10, 10, BILLBOARD.PAL - BILLBOARD.TEX_K);
		stb %r0, [%r10];
		addk(10, 10, BILLBOARD.DELTA_U - BILLBOARD.PAL);
		stw %r6, [%r10];
		addk(10, 10, BILLBOARD.SIZE - BILLBOARD.DELTA_U);
		loop; nop;
	}
bcend:
	lms %r10, w15;
	pul %r15; nop;
FEND:
}

cachealign();
scope TriCull: {
	cache;
	ldw %r12, itriCount;
	dec %r12; bpl +; inc %r12;
		rts; nop;
	+;

	psh %r11;
	sms %r10, w15;

	ldw %r10, #itriBuffer;
	ldw %r11, rasterEndPtr;

	scope body: {
		stw %r10, [%r11]; inc %r11;
		ldw %r0, [%r10];
		and %r1, %r0, #8; bne +; inc %r11; jmp continue; nop; +;

		ldb %r13, #$10;

		addk(10, 10, ITRI.POINT_A - ITRI.FLAGS);
		ldw %r9, [%r10]; inc %r10; inc %r10; // point a
		ldw %r1, [%r9]; inc %r9; inc %r9;
		ldw %r2, [%r9]; inc %r9; inc %r9;
		ldw %r0, [%r9];
		sub %r4, %r0, %r13;

		ldw %r9, [%r10]; inc %r10; inc %r10; // point b
		ldw %r3, [%r9]; inc %r9; inc %r9;
		ldw %r5, [%r9]; inc %r9; inc %r9;
		ldw %r0, [%r9];
		sub %r0, %r13;
		orr %r4, %r0, %r4;

		ldw %r9, [%r10];                     // point c
		addk(10, 10, ITRI.FLAGS - ITRI.POINT_C);
		ldw %r7, [%r9]; inc %r9; inc %r9;
		ldw %r8, [%r9]; inc %r9; inc %r9;
		ldw %r0, [%r9];
		sub %r0, %r13;
		orr %r0, %r4;

		bmi cull; dec %r13;
		not %r13;

		and %r2, %r13;
		and %r5, %r13;
		and %r8, %r13;

		sub %r0, %r3, %r1;
		sub %r6, %r8, %r2;
		mll %r9, %r0, %r6;
		mov %r13, %r4;

		sub %r0, %r7, %r1;
		sub %r6, %r5, %r2;
		mll %r0, %r0, %r6;

		sub %r4, %r13;
		sbc %r0, %r9;
		blt cull; nop;
		orr %r6, %r0, %r4;
		beq cull; nop;
		ldw %r7, #$0100;
		sub %r7, %r4;
		ldb %r7, #0;
		sbc %r7, %r0;
		bcs cull; nop;
		tst %r0;
		beq maybeflatten; nop;
	flatdone:

	keep:

		sub %r0, %r8, %r2;
		blt rotate; nop;
		sub %r0, %r2, %r5;
		bge rotate; nop;
	rotdone:
		ldw %r0, #SCREEN_H*16;
		sub %r0, %r2;
		blt cull; nop;

		sub %r0, %r5, %r8;
		csel %r0, ge, %r5, %r8;
		tst %r0;
		bmi cull; nop;
		beq cull; nop;

	continue:
		dec %r12;
		beq end; nop;
		addk(10, 10, ITRI.SIZE - ITRI.FLAGS);
		jmp body; nop;

	cull:
		sub %r0, %r0;
		stw %r0, [%r10];
		dec %r11;
		bch continue; dec %r11;

	rotate:
		// abc -> acb
		r0_swap(%r5, %r8);

		addk(6, 10, ITRI.POINT_A - ITRI.FLAGS);
		ldw %r0, [%r6]; add %r4, %r6, #2;
		ldw %r13, [%r4]; stw %r0, [%r4]; inc %r4; inc %r4;

		// acb -> cab
		r0_swap(%r5, %r2);
		ldw %r0, [%r4]; stw %r13, [%r4];
		bch keep; stw %r0, [%r6];

	maybeflatten:
		ldb %r0, [%r10];
		and %r0, #RFLAG.TEXTURE_BIT; beq flatdone; nop;

		mov %r7, %r11;
		hib %r13, %r4;

		ldw %r1, #$00f0;
		sub %r1, %r13;
		bsr ge, flatten; nop;

		mov %r11, %r7;
		bch flatdone; sub %r0, %r0;
	}

end:
	stw %r11, rasterEndPtr;
	lms %r10, w15;
	pul %r15; nop;

	scope flatten: {
		ldb %r0, #tex.headers>>16; romb %r0;
		addk(6, 10, ITRI.CTEX - ITRI.FLAGS);
		ldw %r0, [%r6];
		add %r0, %r0;
		add %r0, %r0;
		add %r0, %r0;
		add %r0, %r0;
		ldw %r3, #tex.headers+tex.HEADER_COLOR;
		add %r14, %r0, %r3;
		ldb %r0, [%r10];
		getb %r3;
		tst %r3;
		beq nope;
		stw %r3, [%r6];
		bic %r0, #RFLAG.TEXTURE_BIT;
		stb %r0, [%r10];
	nope:
		rts; nop;
	}

FEND:
}

// %r1 - field offset
cachealign();
scope ZPrep: {
	cache;
	ldw %r0, rasterEndPtr;
	ldw %r9, #rasterList;
	sub %r0, %r9;
	beq dont; nop;
	lsr %r12, %r0;
	setl; {
		ldw %r8, [%r9]; inc %r9; inc %r9;
		ldw %r0, [%r8];
		and %r0, #RFLAG.TRIANGLE_BIT; beq notatri; nop;
		addk(7, 8, ITRI.POINT_A);
		ldw %r0, [%r7]; inc %r7; inc %r7;
		addk(0, 0, VERTEX.POS_Z);
		ldw %r2, [%r0];
		ldw %r0, [%r7]; inc %r7;
		addk(0, 0, VERTEX.POS_Z);
		ldw %r0, [%r0];
		sub %r0, %r2;
		blt +; inc %r7; add %r0, %r2; mov %r2, %r0; +;

		ldw %r0, [%r7];
		addk(0, 0, VERTEX.POS_Z);
		ldw %r0, [%r0];
		cmp %r0, %r2;
		cmov %r0, lt, %r2;

		add %r8, %r1;
		loop; stw %r0, [%r8];
		rts; nop;
	notatri:
		addk(0, 8, RASTER.REF_LOC);
		ldw %r0, [%r0];
		addk(0, 0, VERTEX.POS_Z);
		ldw %r0, [%r0];
		add %r8, %r1;
		loop; stw %r0, [%r8];
	}
dont:
	rts; nop;
}

align_exact(4);
scope RasterPrepro: {
	stw %r11, [%r10];
	sms %r10, w15;

	ldw %r0, #triDataBuffer;
	stw %r0, triDataEndPtr;

	ldw %r10, rasterEndPtr;
	bch cachebase; cache;

end:
	nop;
	lms %r10, w15;
	ldw %r15, [%r10];
	cachealign(); nop;

done:
	lms %r10, w14;
cachebase:
addr.printloc("prepro cache base", pc()&~$f);
_loop:
	stw %r10, rasterBtmPtr;
	ldw %r0, #rasterList;
	sub %r0, %r10;
	bcs end;

	sub %r10, #2;
	sms %r10, w14;

	ldw %r10, [%r10];

	ldb %r0, [%r10];
	lsr %r1, %r0;
	bcc done; inc %r10;
	and %r0, #$d;
	add %r15, %r0; inc %r10;
jumps:
	jmp done; nop; // jmp ground; nop;
	jmp billboard; nop;
	jmp flat; nop;
	jmp tex; nop;

	// scope ground: {
		// jmp done; nop;
	// }
	scope billboard: {
		// ldb %r0, #table.recip; romb %r0;
		// ldw %r0, [%r10];
		// addk(0, 0, VERTEX.POS_Z);
		// ldw %r0, [%r0];
		// add %r14, %r0, %r0;

		jmp done; nop;
	}
	scope flat: {
		ldw %r9, triDataEndPtr;
		ldb %r0, #MDATA.SIZE;
		add %r0, %r9;
		ldw %r1, #triDataBuffer+TRI_DATA_LEN;
		sub %r0, %r1; bcs overbuffer; add %r0, %r1;
		sbk %r0;
		addk(0, 10, ITRI.UV_DATA - ITRI.POINT_A);
		stw %r9, [%r0];
		jsr getTopSlopes; nop;

		ldb %r0, #shadeMaps>>16; romb %r0;
		ldw %r13, #shadeMaps;

		addk(8, 10, ITRI.SHADE - ITRI.POINT_A);
		ldb %r0, [%r8];
		lsr %r0; lsr %r0; lsr %r0; lsr %r1, %r0;

		addk(8, 10, ITRI.CTEX - ITRI.POINT_A);
		ldw %r0, [%r8];
		add %r0, %r0; add %r0, %r0;
		add %r0, %r0; add %r0, %r0;
		add %r0, %r1;
		add %r14, %r0, %r13;
		getb %r0;
		jmp done; stw %r0, [%r8];
	overbuffer:
		jmp end; nop;
	}

	scope tex: {
		ldw %r9, triDataEndPtr;
		ldb %r0, #MDATA.SIZE+UVDATA.SIZE;
		add %r0, %r9;
		ldw %r1, #triDataBuffer+TRI_DATA_LEN;
		sub %r0, %r1; bcs overbuffer; add %r0, %r1;
		sbk %r0;
		addk(0, 10, ITRI.UV_DATA - ITRI.POINT_A);
		stw %r9, [%r0];
		jsr getTopSlopes; nop;

		addk(8, 10, ITRI.SHADE - ITRI.POINT_A);
		ldb %r0, [%r8];
		lsr %r0; lsr %r0; bic %r0, #$f;
		stb %r0, [%r8];

		ldw %r9, triDataEndPtr;
		ldb %r0, #UVDATA.SIZE;
		sub %r9, %r0;
		jsr getTopUvds; nop;
	overbuffer:
		jmp end; nop;
	}

	scope getTopSlopes: {
		ldb %r0, #table.coord_recip>>16; romb %r0;
		ldw %r13, #table.coord_recip;
		ldw %r6, #$1000;

		ldw %r0, [%r10]; inc %r10; inc %r10;  // a
		ldw %r1, [%r0]; inc %r0; inc %r0;     //  .x
		ldw %r0, [%r0];                       //  .y
		mlf %r2, %r0, %r6;

		ldw %r0, [%r10]; inc %r10; inc %r10;  // b
		ldw %r3, [%r0]; inc %r0; inc %r0;     //  .x
		ldw %r0, [%r0];                       //  .y
		mlf %r5, %r0, %r6;

		ldw %r0, [%r10];                      // c
		ldw %r7, [%r0]; inc %r0; inc %r0;     //  .x
		ldw %r0, [%r0];                       //  .y
		mlf %r8, %r0, %r6;

		addk(4, 9, MDATA.HAND);
		sub %r0, %r0;
		stw %r0, [%r4]; inc %r4; inc %r4;
		sub %r10, #4;
		stw %r3, [%r4];

		sub %r12, %r7, %r3;
		sub %r0, %r8, %r5;
		bge notlefty; with %r8;
			ldb %r0, #1;
			stw %r7, [%r4];
			dec %r4; dec %r4;
			stw %r0, [%r4];
			sub %r12, %r3, %r7;
			sub %r0, %r5, %r8;
			with %r5;
	notlefty:
		to %r4;

		add %r0, %r0;
		add %r14, %r0, %r13;
		addk(9, 9, MDATA.Y2);
		stw %r4, [%r9];
		getb %r0; inc %r14;
		getbh %r6, %r0;
		sub %r0, %r8, %r2;
		add %r0, %r0;
		add %r14, %r0, %r13;
		mll %r12, %r6;
		getb %r0; inc %r14;
		addk(9, 9, MDATA.BTM_MF - MDATA.Y2);
		stw %r4, [%r9];
		addk(9, 9, MDATA.BTM_MI - MDATA.BTM_MF);
		stw %r12, [%r9];
		sub %r12, %r7, %r1;
		getbh %r6, %r0;
		sub %r0, %r5, %r2;
		add %r0, %r0;
		add %r14, %r0, %r13;
		mll %r12, %r6;
		addk(9, 9, MDATA.RGT_MF - MDATA.BTM_MI);
		stw %r4, [%r9]; inc %r9; inc %r9;
		stw %r12, [%r9];
		getb %r6; inc %r14;
		sub %r0, %r3, %r1;
		getbh %r6;
		addk(9, 9, MDATA.LFT_MF - MDATA.RGT_MI);
		mll %r0, %r6;
		stw %r4, [%r9]; inc %r9; inc %r9;
		stw %r0, [%r9];
		addk(9, 9, MDATA.Y1 - MDATA.LFT_MI);

		sub %r0, %r2, %r8;
		beq noTop; // ...

		sub %r0, %r5, %r8;
		csel %r0, lt, %r5, %r8;
		stw %r0, [%r9]; inc %r9; inc %r9;
		mov %r0, %r1;
		stw %r0, [%r9]; inc %r9; inc %r9;
		rts; stw %r0, [%r9];

	noTop:
		stw %r2, [%r9]; inc %r9; inc %r9;
		stw %r1, [%r9]; inc %r9; inc %r9;
		stw %r7, [%r9];
		rts; nop;
	}

	scope getTopUvds: {
		ldb %r0, #table.recip>>16; romb %r0;
		sms %r11, w31;
		sms %r10, w30;

		ldw %r0, [%r10]; inc %r10; inc %r10;
		addk(0, 0, VERTEX.POS_Y);
		ldw %r7, [%r0]; inc %r0; inc %r0;
		ldw %r12, [%r0];
		addk(0, 0, VERTEX.TEX_U - VERTEX.POS_Z);
		ldw %r1, [%r0];

		jsr fetchVert2; nop;
		inc %r10; inc %r10;
		sms %r10, w28;
		mov %r3, %r2;
		sms %r8, w29;

		asr %r0, %r12; asr %r0; asr %r0; asr %r0;
		add %r14, %r0, %r0;
		getb %r12; inc %r14; getbh %r12;

		asr %r0, %r13; asr %r0; asr %r0; asr %r0;
		add %r14, %r0, %r0;
		getb %r13; inc %r14; getbh %r13;
		mov %r5, %r13;

		jsr uvLineCalc; nop;

		lms %r10, w28;
		jsr fetchVert2; nop;
		asr %r0, %r13; asr %r0; asr %r0; asr %r0;
		add %r14, %r0, %r0;
		getb %r13; inc %r14; getbh %r13;

		sms %r8, w28;
		jsr uvLineCalc; nop;

		lms %r8, w28;

		mov %r1, %r3;
		mov %r12, %r5;
		lms %r7, w29;
		sub %r0, %r8, %r7;
		bge notlefty; nop;
		lefty: {
			r0_swap(%r7, %r8);
			r0_swap(%r1, %r2);
			r0_swap(%r12, %r13);
		}
	notlefty:
		jsr uvLineCalc; nop;

		lms %r10, w30;
		lms %r15, w31; nop;

		scope fetchVert2: {
			ldw %r0, [%r10];
			addk(0, 0, VERTEX.POS_Y);
			ldw %r8, [%r0]; inc %r0; inc %r0;
			ldw %r13, [%r0];
			addk(0, 0, VERTEX.TEX_U - VERTEX.POS_Z);
			ldw %r2, [%r0];
			rts; nop;
		}

		// %r1  uv top
		// %r2  uv btm
		// %r7  y top
		// %r8  y btm (clobbered)
		// %r9  out ptr
		// %r12 1/z top
		// %r13 1/z btm
		scope uvLineCalc: {
			bic %r7, #$f;
			bic %r8, #$f;
			sub %r0, %r8, %r7;
			lsr %r0; lsr %r0; lsr %r0; lsr %r0;
			add %r14, %r0, %r0;

			sub %r0, %r0; stw %r0, [%r9]; inc %r9; inc %r9;
			getb %r6; inc %r14; getbh %r6;
			mov %r10, %r6;
			sub %r0, %r13, %r12;
			stw %r12, [%r9]; inc %r9; inc %r9;
			mll %r0, %r6;
			stw %r4, [%r9]; inc %r9; inc %r9;
			stw %r0, [%r9]; inc %r9; inc %r9;

			// lob %r1
			mov %r6, %r12; lob %r0, %r1;
			xbr %r0; mll %r8, %r0, %r6;
			stw %r4, [%r9]; inc %r9; inc %r9;
			stw %r8, [%r9]; inc %r9; inc %r9;
			// lob %r2
			mov %r6, %r13; lob %r0, %r2;
			xbr %r0; mlf %r0, %r6;
			sub %r0, %r8;
			mov %r6, %r10;
			mll %r0, %r6;
			stw %r4, [%r9]; inc %r9; inc %r9;
			stw %r0, [%r9]; inc %r9; inc %r9;

			// hib %r1
			mov %r6, %r12; hib %r0, %r1;
			xbr %r0; mll %r8, %r0, %r6;
			stw %r4, [%r9]; inc %r9; inc %r9;
			stw %r8, [%r9]; inc %r9; inc %r9;
			// hib %r2
			mov %r6, %r13; hib %r0, %r2;
			xbr %r0; mlf %r0, %r6;
			sub %r0, %r8;
			mov %r6, %r10;
			mll %r0, %r6;
			stw %r4, [%r9]; inc %r9; inc %r9;
			stw %r0, [%r9]; inc %r9;
			rts; inc %r9;
		}
	}
FEND:
}

align_exact(4);
scope Rasterize: {
	stw %r11, [%r10];
	sms %r10, w15;

	ldw %r10, rasterEndPtr;
	bch cachebase; cache;

end:
	nop;
	stw %r10, rasterEndPtr;
	lms %r10, w15;
	rpix %r0;
	ldw %r15, [%r10];
	cachealign(); nop;

drawdone:
	lms %r10, w14;
_loop:
	ldw %r0, rasterBtmPtr;
	sub %r0, %r10;
	bcs end;

	sub %r10, #2;
	sms %r10, w14;

	ldw %r10, [%r10];

	ldb %r0, [%r10];
	lsr %r1, %r0;
	bcc drawdone; inc %r10;
	and %r0, #$d;
	add %r15, %r0; inc %r10;
jumps:
	jmp RenStr; cache;
	jmp Billboard; sub %r0, %r0;
	jmp DrawFlat; sub %r0, %r0;
	jmp DrawTex; sub %r0, %r0;

cachebase:
addr.printloc("draw cache base", pc()&~$f);
	bch _loop; nop;

	scope Billboard: {
		cmode %r0;
		addk(0, 10, BILLBOARD.PAL - BILLBOARD.REF_LOC);
		ldb %r0, [%r0];
		color %r0;
		ldb %r0, #CMODE_FIX_HIGH_N;
		cmode %r0;

		addk(10, 10, BILLBOARD.SCREEN_X - BILLBOARD.REF_LOC);
		ldb %r11, [%r10];
		addk(10, 10, BILLBOARD.WIDTH - BILLBOARD.SCREEN_X);
		ldb %r5, [%r10];
		addk(10, 10, BILLBOARD.SCREEN_Y - BILLBOARD.WIDTH);
		ldb %r2, [%r10];
		addk(10, 10, BILLBOARD.HEIGHT - BILLBOARD.SCREEN_Y);
		ldb %r6, [%r10];
		addk(10, 10, BILLBOARD.TEX_U - BILLBOARD.HEIGHT);
		ldb %r0, [%r10];
		xbr %r8, %r0;
		addk(10, 10, BILLBOARD.TEX_V - BILLBOARD.TEX_U);
		ldb %r0, [%r10];
		xbr %r7, %r0;
		addk(10, 10, BILLBOARD.TEX_K - BILLBOARD.TEX_V);
		ldw %r0, [%r10];
		romb %r0;
		addk(10, 10, BILLBOARD.DELTA_U - BILLBOARD.TEX_K);
		ldw %r9, [%r10];

		movs %r0, %r6; beq quitbillboardbcitsgotnoarea; sub %r0, %r0;
		add %r0, %r5; beq quitbillboardbcitsgotnoarea; nop;

		lob %r0, %r9; xbr %r3, %r0;
		hib %r0, %r9; sxb %r4, %r0;
		bpl +; sub %r0, %r0;
			sub %r9, %r0, %r9;
			inc %r0; xbr %r0; // %r0 = #$0100
			sub %r8, %r0;
	+;	ldw %r13, #lines.pixels;
		scope lines: {
			merge %r14;
			mov %r1, %r11;
			mov %r12, %r5;
			sub %r0, %r0;
			scope pixels: {
				add %r0, %r3;
				getc;
				adc %r14, %r4;
				loop;
				plot;
			}
			add %r7, %r9;
			dec %r6; bne lines; inc %r2;
		}
	// addr.printloc("billboard height check");
		// ldw %r0, #-(SCREEN_H-8);
		// add %r0, %r2;
		// blt quitbillboard; nop;
			// stw %r10, fx.deathFlag.fx;
			// ldw %r0, [%r0];
			// stp; nop;
	// quitbillboard:
	quitbillboardbcitsgotnoarea:
		jmp drawdone; nop;
	}

	scope DrawFlat: {
		cmode %r0;
		addk(0, 10, ITRI.CTEX-ITRI.POINT_A);
		ldb %r0, [%r0];
		jsr getTopSlopes; color %r0;
		jsr fillFlat; nop;
		jsr getBtmSlopes; nop;
		ldw %r11, #drawdone;
		jmp fillFlat; nop;
	}

	// %r2  - y0
	// %r3  - y1
	// %r4  - x0f
	// %r5  - x0i
	// %r6  - x1f
	// %r7  - x1i
	// %r8  - m0f
	// %r9  - m0i
	// %r10 - m1f
	// %r12 - m1i
	scope fillFlat: {
		ldw %r13, #retp;
		bch fillprecheck; nop;
	retp:
		ldw %r13, #rowloop.pxloop;
		dec %r3;
		scope rowloop: {
			ldw %r12, #SCREEN_W;
			movs %r1, %r5;
			bpl +; nop; ldb %r1, #0; +;
			sub %r0, %r1, %r12;
			cmov %r1, cs, %r12;

			movs %r0, %r7;
			bpl +; nop; sub %r0, %r0; +;
			cmp %r0, %r12;
			cmov %r0, cs, %r12;

			sub %r12, %r0, %r1;
			dec %r12;
			bmi continue; inc %r12;

		pxloop:
			loop; plot;

		continue:
			add %r4, %r8;
			adc %r5, %r9;
			add %r6, %r10;
			adc %r7, %r11;

			sub %r0, %r2, %r3;
			blt rowloop; inc %r2;
		}
		mov %r12, %r11;
		lms %r15, w12; nop;
	}

	scope fillprecheck: {
		ldw %r0, #SCREEN_H-1;
		cmp %r0, %r2;
		blt earlyEnd;
		sub %r0, %r3;
		bge +; nop;
			ldw %r3, #SCREEN_H;
		+;

		sub %r0, %r2, %r3;
		bge earlyEnd; sub %r0, %r0;
		tst %r3;
		bpl +; nop;
			mov %r0, %r3;
			mov %r13, %r11;
		+;

		sms %r11, w12;
		mov %r11, %r12;
		tst %r2;
		bpl noAdv;
		sub %r0, %r2;
		adv: {
			add %r4, %r8;
			adc %r5, %r9;
			add %r6, %r10;
			adc %r7, %r11;
			dec %r0; bne adv; inc %r2;
		}
	noAdv:
		jmp [%r13]; nop;

	earlyEnd:
		rts; nop;
	}

	scope getTopSlopes: {
		mov %r13, %r11;
		ldw %r0, [%r10];
		inc %r0; inc %r0;
		ldw %r0, [%r0];
		asr %r0; asr %r0; asr %r0; asr %r2, %r0;
		addk(0, 10, ITRI.UV_DATA-ITRI.POINT_A);
		ldw %r10, [%r0];
		tst %r10; beq yikes; nop;
		ldw %r3, [%r10]; inc %r10; inc %r10;
		ldw %r0, [%r10]; inc %r10;
		bsr coordsplit; inc %r10;
		mov %r4, %r0;
		mov %r5, %r1;
		ldw %r0, [%r10]; inc %r10;
		bsr coordsplit; inc %r10;
		mov %r6, %r0;
		mov %r7, %r1;
		ldw %r8, [%r10]; inc %r10; inc %r10;
		ldw %r9, [%r10]; inc %r10; inc %r10;
		ldw %r0, [%r10]; inc %r10; inc %r10;
		ldw %r12, [%r10]; inc %r10; inc %r10;
		sms %r10, w7;
		mov %r10, %r0;
		jmp [%r13]; nop;

	yikes:
		jmp drawdone; nop;

		coordsplit: {
			mov %r1, %r0;
			sub %r0, %r0;
			asr %r1; ror %r0;
			asr %r1; ror %r0;
			asr %r1; ror %r0;
			asr %r1;
			rts; ror %r0;
		}
	}

	scope fillTex: {
		ldw %r13, #retp;
		jmp fillprecheck; nop;
	retp:
		sms %r11, w27;
		jsr prestores; dec %r3;

		scope rowloop: {
			ldw %r10, #SCREEN_W;

			ldb %r5, #2*20; // w20
			jsr oneEnd; nop;
			mov %r13, %r9;
			mov %r1, %r0;
			jsr oneEnd; nop;
			sub %r0, %r1;
			sms %r0, w19;

			ldb %r0, #table.recip>>16; romb %r0;
			sub %r3, %r9, %r13;

			lms %r5, w4;
			bsr oneCoord; nop;
			mov %r7, %r9;
			mov %r8, %r10;

			lms %r5, w5;
			bsr oneCoord; nop;

			add %r14, %r3, %r3;

			lms %r12, w19;
			getb %r0; inc %r14;
			dec %r12;
			bmi continue; inc %r12;

			getbh %r6, %r0;
			sub %r9, %r7;
			mlf %r9, %r6;
			sub %r10, %r8;
			mlf %r10, %r6;

			jsr texinit; nop;

			setl;
		pxloop:
			add %r7, %r9;
			add %r8, %r10;
			merge %r0;
			and %r0, %r5;
			getc;
			add %r14, %r0, %r6;
			loop; plot;

		continue:
			lms %r3, w11;
			sub %r0, %r2, %r3;
			blt rowloop; inc %r2;
			jmp finish; nop;
		}

		scope oneCoord: {
			mov %r12, %r11;
			bsr fetchAdvance; nop;
			lsr %r0, %r9; lsr %r0; lsr %r0; lsr %r0; add %r14, %r0, %r0;
			getb %r6;
			bsr fetchAdvance; inc %r14;
			getbh %r6;
			add %r0, %r6, %r6; add %r0, %r0; add %r0, %r0; add %r6, %r0, %r0;
			mll %r0, %r9, %r6;
			hib %r4; lob %r0; xbr %r0;
			link #4; to %r10; bch fetchAdvance; orr %r4;
			mll %r0, %r9, %r6;
			hib %r4; lob %r0; xbr %r0; orr %r9, %r0, %r4;
			jmp [%r12]; nop;
		}

		scope oneEnd: {
			mov %r12, %r11;
			bsr fetchAdvance; nop;
			movs %r0, %r9;
			bpl +; nop; jmp [%r12]; sub %r0, %r0; +;
			cmp %r0, %r10;
			cmov %r0, cs, %r10;
			jmp [%r12]; nop;
		}

		scope fetchAdvance: {
			mov %r4, %r5;
			addk(5, 5, 4);
			ldw %r0, [%r5];
			ldw %r9, [%r4];
			add %r0, %r9;
			stw %r0, [%r4];
			inc %r4; inc %r4;
			inc %r5; inc %r5;

			ldw %r0, [%r5];
			ldw %r9, [%r4];
			adc %r0, %r9;
			stw %r0, [%r4];
			inc %r5;
			rts; inc %r5;
		}

		scope texinit: {
			ldb %r0, #tex.headers>>16; romb %r0;
			lms %r14, w13;
			getb %r0; inc %r14;
			cmode %r0;
			getb %r0; inc %r14;
			getbh %r5, %r0; inc %r14;

			sub %r6, %r1, %r13;
			dec %r6;
			bmi noLeftEdge; inc %r6;
			mll %r0, %r9, %r6;
			add %r7, %r4;
			mll %r0, %r10, %r6;
			add %r8, %r4;
		noLeftEdge:

			getb %r0; inc %r14;
			getbh %r6, %r0; inc %r14;
			getb %r0; romb %r0;

			merge %r0; and %r0, %r5; add %r14, %r0, %r6;
			rts; nop;
		}

		scope prestores: {
			sms %r3, w11;

			sms %r4, w20;
			sms %r5, w21;
			sms %r8, w22;
			sms %r9, w23;

			sms %r6, w24;
			sms %r7, w25;
			sms %r10, w26;
			rts; nop;
		}

	finish:
		lms %r3, w11;

		lms %r4, w20;
		lms %r5, w21;
		lms %r8, w22;
		lms %r9, w23;

		lms %r6, w24;
		lms %r7, w25;
		lms %r10, w26;
		lms %r12, w27;
		lms %r15, w12; nop;
	}

	scope DrawTex: {
		cmode %r0;
		addk(0, 10, ITRI.SHADE - ITRI.POINT_A);
		ldb %r0, [%r0];
		color %r0;

		addk(0, 10, ITRI.CTEX - ITRI.POINT_A);
		ldw %r0, [%r0];
		add %r0, %r0;
		add %r0, %r0;
		add %r0, %r0;
		add %r0, %r0;
		ldw %r1, #tex.headers;
		add %r0, %r1;
		sms %r0, w13;

		addk(0, 10, ITRI.UV_DATA - ITRI.POINT_A);
		ldw %r0, [%r0];
		ldb %r1, #MDATA.SIZE;
		add %r0, %r1;
		sms %r0, w4;
		addk(0, 0, UVDATA.RGT_Z);
		sms %r0, w5;
		jsr getTopSlopes; nop;

		jsr fillTex; nop;
		jsr getBtmUvds; nop;
		ldw %r11, #drawdone;
		jmp fillTex; nop;
		jmp drawdone; nop;
	}

	scope getBtmUvds: {
		lms %r0, w4;
		addk(3, 0, UVDATA.BTM_Z);
		lms %r0, w7;
		inc %r0; inc %r0;
		ldb %r0, [%r0];
		tst %r0;
		bne notlefty; nop;
	lefty:
		sms %r3, w4;
		bch getBtmSlopes; nop;
	notlefty:
		sms %r3, w5;
		// bch getBtmSlopes; nop;
	}

	scope getBtmSlopes: {
		lms %r1, w7;
		ldw %r3, [%r1]; inc %r1; inc %r1;
		ldb %r0, [%r1]; inc %r1;
		tst %r0; bne notlefty; inc %r1;
	lefty:
		ldw %r0, [%r1]; inc %r1; inc %r1;
		ldw %r8, [%r1]; inc %r1; inc %r1;
		ldw %r9, [%r1]; inc %r1; inc %r1;
		ldb %r4, #0;
		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r0; ror %r4;
		asr %r5, %r0; ror %r4;
		rts; nop;
	notlefty:
		ldw %r0, [%r1]; inc %r1; inc %r1;
		ldw %r10, [%r1]; inc %r1; inc %r1;
		ldw %r12, [%r1]; inc %r1; inc %r1;
		ldb %r4, #0;
		asr %r0; ror %r6;
		asr %r0; ror %r6;
		asr %r0; ror %r6;
		asr %r7, %r0; ror %r6;
		rts; nop;
	}

	scope Ground: {
		// addr.printlab(Rasterize.Ground);
		// addr.printloc("Ground cache base", Rasterize.Ground & ~$f);

		// ldb %r0, #table.recip>>16; romb %r0;

		// ldw %r9, #camera + OBJ.ROT_R;

		// ldw %r1, [%r9]; inc %r9; inc %r9; // %r1 = w
		// ldw %r2, [%r9]; inc %r9; inc %r9; // %r2 = x
		// ldw %r3, [%r9]; inc %r9; inc %r9; // %r3 = y
		// ldw %r6, [%r9];                   // %r6 = z

		// // Δy = (xy + wz) / (xx - zz)
		// // %r8:%r7 = zz
		// mll %r8, %r6, %r6;
		// mov %r7, %r4;

		// // %r5:%r9 = wz
		// mll %r5, %r1, %r6;
		// mov %r6, %r2;
		// mov %r9, %r4;

		// // %r0:%r7 = xx - zz
		// mll %r0, %r6, %r6;
		// sub %r7, %r4;
		// sbc %r0, %r8, %r0;

		// // get those bytes
		// lob %r0; xbr %r0; hib %r7; orr %r0, %r7;

		// // sign/recip
		// with %r7; bpl +; sub %r7;
			// not %r0; inc %r0;
			// dec %r7;
		// +;
		// add %r14, %r0, %r0;

		// // %r0:%r9 = (xy + wz)
		// mll %r0, %r3, %r6;
		// getb %r6; inc %r14;
		// add %r9, %r4;
		// adc %r0, %r5;

		// // get those bytes
		// lob %r0; xbr %r0; hib %r9; orr %r0, %r9;
		// getbh %r6;

		// tst %r7; bpl +; nop;
			// not %r0; inc %r0;
		// +;

		// // %r5:%r4 = Δy
		// mll %r5, %r0, %r6;

		// ldb %r0, #$25; color %r0;

		// sub %r0, %r0;
		// ldb %r1, #0;
		// ldw %r2, #SCREEN_H/2;
		// sub %r2, %r5;
		// lsr %r0; // clear carry for first loop
		// ldw %r3, #SCREEN_H;
		// ldw %r12, #SCREEN_W;
		// setl; {
			// adc %r2, %r5;
			// // cmp %r2, %r3;
			// alt3; from %r2;
			// bmi lineEnd; sub ?3;
			// bcs lineEnd; add %r0, %r4;
			// loop; plot;
		// lineEnd:
		// }

		// lms %r10, w14;
		// jmp cachebase; cache;
	}

	scope RenStr: {
	addr.printloc("RenStr cache base", Rasterize.RenStr & ~$f);
		ldb %r0, #fontbank>>16; romb %r0;
		sub %r0, %r0; cmode %r0;
		ldb %r0, #$20; color %r0;
		ldb %r0, #CMODE_FIX_HIGH_N; cmode %r0;

		ldw %r0, [%r10];
		ldw %r8, [%r0]; inc %r0; inc %r0;
		lsr %r8; lsr %r8; lsr %r8; lsr %r8;
		ldw %r2, [%r0];
		lsr %r2; lsr %r2; lsr %r2; lsr %r2;
		add %r10, #REN_STR.RSTR_BEGIN - REN_STR.REF_LOC;
		ldw %r7, [%r10]; inc %r10; inc %r10;
		ldw %r5, [%r10];

		ldb %r6, #-1;
		ldb %r10, #12;
		lineloop: {
			bsr drawfontline; inc %r6;
			dec %r10; bne lineloop; inc %r2;
		}

		lms %r10, w14;
		jmp cachebase; cache;
	};

	// %r5 - line length (in characters)
	// %r6 - font line
	// %r7 - pointer to line buffer
	// %r8 - start position of line
	scope drawfontline: {
		// a pointed character consists of:
		// header:
		//  stride, width, bg
		// followed by rows of <width> pixels,
		// with each row occupying <stride> bytes.
		// each character is followed by 1px of the <bg> color.
		mov %r1, %r8;
		mov %r3, %r5;
		ldw %r13, #charloop.pxloop;
		scope charloop: {
			ldw %r14, [%r7];
			getb %r0; inc %r14;
			mul %r0, %r6;
			inc %r0;
			getb %r12; inc %r14;
			inc %r7; inc %r7;
			getb %r4;
			add %r14, %r0;
			scope pxloop: {
				getc;     // 1
				inc %r14; // 1
				loop;     // 1
				plot;     // 1
			}
			color %r4;
			dec %r3;
			bne charloop; plot;
		}

		sub %r7, %r5;
		sub %r7, %r5;
		rts; nop;
	}
FEND:
}
