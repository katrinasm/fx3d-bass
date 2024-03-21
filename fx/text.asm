scope text: {
	constant FONT_SEGMENTS(249);
	constant FONT_HEADER_SIZE(2 * FONT_SEGMENTS);
	constant MSG_LEN(512);
	addr.alloc70(testingTextBuf, MSG_LEN, 1);
	addr.alloc70(testingTextRenBuf, MSG_LEN*2, 1);

	// %r2: u16        = *mut REN_STR
	// %r7: *const u8  = string addr
	// %r12: u16       = string length
	cachealign();
	scope LoadWholeRenStr: {
		cache;
		movs %r0, %r12;
		bne doit; nop; rts; nop;
	doit:
		psh %r11;
		ldb %r8, #$3f;
		setl; {
			ldb %r0, [%r7];
			sxb %r1, %r0; bpl ascii; inc %r7;
			ldb %r4, #$40;
			and %r4, %r0, %r4;
			beq twoByte; dec %r12;
		threeByte:
			and %r0, #$f;
			xbr %r0;
			add %r0, %r0;
			add %r0, %r0;
			add %r0, %r0;
			add %r0, %r0;
			ldb %r1, [%r7]; inc %r7;
			and %r1, %r8;
			xbr %r1;
			lsr %r1;
			lsr %r1;
			orr %r0, %r1;
			bch lowestByte; dec %r12;
		twoByte:
			and %r0, %r8;
			xbr %r0;
			lsr %r0; lsr %r0;
		lowestByte:
			ldb %r1, [%r7]; inc %r7;
			and %r1, %r8;
			orr %r1, %r0, %r1;
		ascii:
			bsr AppendCharToRenStr; nop;
			loop; nop;
		}
		pul %r15; nop;
	}

	// %r1 - char
	// %r2 - *mut REN_STR
	scope AppendCharToRenStr: {
		ldb %r0, #fontbank>>16; romb %r0;
		ldw %r0, #FONT_HEADER_SIZE;
		add %r3, %r2, #REN_STR.FONT;
		ldb %r6, [%r3];
		mll %r0, %r6;
		add %r14, %r4, #2;
		getb %r0; inc %r14;
		getbh %r5, %r0;

		add %r0, %r1, %r1;
		hib %r6, %r0;
		beq ascii; nop;
	notAscii:
		hib %r0, %r1;
		ldw %r6, #$e0;
		sub %r0, %r6; bcc notUpperSeg; add %r0, %r6;
	upperSeg:
		ldb %r6, #($e0-$d8);
		sub %r0, %r6;
	notUpperSeg:
		bne notLatin1; add %r0, %r0;
	itsLatin1:
		ldb %r6, #-$80;
		add %r1, %r6;
	notLatin1:
		add %r14, %r0, %r5;
		getb %r0; inc %r14;
		lob %r1;
		getbh %r6, %r0;
		mll %r0, %r1, %r6;
		add %r0, %r4, %r14;
		bch gotOfs; inc %r0;

	ascii:
		ldb %r4, #$40;
		sub %r0, %r4;
		add %r14, %r0, %r5;
		getb %r0; inc %r14;
		getbh %r0;
	gotOfs:
		mov %r4, %r0;
		addk(3, 3, REN_STR.RSTR_BEGIN - REN_STR.FONT);
		ldw %r0, [%r3];
		addk(3, 3, REN_STR.LEN - REN_STR.RSTR_BEGIN);
		ldw %r6, [%r3];
		add %r0, %r6;
		add %r0, %r6;
		stw %r4, [%r0];
		inc %r6;
		stw %r6, [%r3];
		rts; nop;
	FEND:
	}

	align_exact(4);
	scope FormatStringToScreen: {
		addr.alloc70(retaddr, 2, 1);
		stw %r11, retaddr;
		ldw %r1, #testingTextBuf;
		ldw %r2, #MSG_LEN;
		jsr StrFormat; cache;
		mov %r12, %r0;

		ldb %r0, #VERTEX.SIZE;
		ldw %r6, vertexCount;
		mll %r0, %r6;
		inc %r6;
		stw %r6, vertexCount;
		ldw %r1, #vertexBuffer;
		add %r1, %r4;

		ldb %r0, #RASTER.SIZE;
		ldw %r6, itriCount;
		mll %r0, %r6;
		inc %r6;
		stw %r6, itriCount;
		ldw %r2, #itriBuffer;
		add %r2, %r4;

		ldw %r0, rasterEndPtr;
		stw %r2, [%r0];
		inc %r0;
		inc %r0;
		stw %r0, rasterEndPtr;

		ldw %r0, #RFLAG.VALID | RFLAG.REN_STR;
		// addk(2, 2, REN_STR.FLAGS);
		stw %r0, [%r2];
		inc %r2; inc %r2; // addk(2, 2, REN_STR.REF_LOC - REN_STR.FLAGS);
		stw %r1, [%r2];

		ldw %r0, #$000'0; stw %r0, [%r1]; inc %r1; inc %r1;
		ldw %r0, #$094'0; stw %r0, [%r1]; inc %r1; inc %r1;
		ldw %r0, #$000'0; stw %r0, [%r1];

		inc %r2; inc %r2; // addk(2, 2, REN_STR.STR_BEGIN - REN_STR.REF_LOC);
		ldw %r7, #testingTextBuf;
		stw %r7, [%r2];
		inc %r2; inc %r2; // addk(2, 2, REN_STR.STR_END - REN_STR.STR_BEGIN);
		add %r0, %r7, %r12;
		stw %r0, [%r2];
		inc %r2; inc %r2; // addk(2, 2, REN_STR.FONT - REN_STR.STR_END);
		ldb %r0, #0;
		stb %r0, [%r2];
		inc %r2; // addk(2, 2, REN_STR.WIDTH - REN_STR.FONT);
		ldb %r0, #200;
		stb %r0, [%r2];
		inc %r2; // addk(2, 2, REN_STR.RSTR_BEGIN - REN_STR.WIDTH);
		ldw %r0, #testingTextRenBuf;
		stw %r0, [%r2];
		inc %r2; inc %r2; // addk(2, 2, REN_STR.LEN - REN_STR.RSTR_BEGIN);
		sub %r0, %r0;
		stw %r0, [%r2];

		sub %r2, #REN_STR.LEN;
		ldw %r11, retaddr;
		jmp LoadWholeRenStr; nop;
	FEND:
	}
}
