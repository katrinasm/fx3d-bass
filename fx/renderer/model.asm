scope GetObjModels: {
	psh %r11;

	ldw %r0, objCount;
	psh %r0;

	ldw %r1, #objBuffer;

	ldw %r0, vertexCount;
	ldb %r6, #VERTEX.SIZE;
	mll %r0, %r6;
	ldw %r0, #vertexBuffer;
	add %r2, %r0, %r4;

	ldw %r0, itriCount;
	ldb %r6, #ITRI.SIZE;
	mll %r0, %r6;
	ldw %r0, #itriBuffer;
	add %r3, %r0, %r4;

	jsr LoadModel_encache; cache;

	inc %r10;
	do: {
		inc %r10;
		ldw %r0, [%r10];
		dec %r0;
		bmi done; stw %r0, [%r10];
		dec %r10;
		jsr LoadModel; dec %r10;
		bch do; inc %r10;
	done:
	}

	pul %r15; nop;
FEND:
}

cachealign(); nop;
LoadModel_encache:
	rts; nop;
// arguments:
// %r1         - ptr to object
// %r2         - point buffer
// %r3         - itri buffer
scope LoadModel: {
	ldb %r0, #test.testmodels>>16; romb %r0;
	ldw %r4, #test.testmodels;

	ldw %r0, [%r1];
	add %r5, %r0, %r0;
	add %r0, %r5;
	add %r14, %r0, %r4;

	getb %r4; inc %r14;

	psh %r11;
	psh %r1;

	sms %r3, w3;

	psh %r2;

	mov %r5, %r1;
	sms %r2, w2;

	getbh %r4; inc %r14;

	getb %r0; romb %r0;
	mov %r14, %r4;

	getb %r6; inc %r14;
	addk(0, 1, OBJ.SCALE);
	ldw %r0, [%r0];
	getbh %r6; inc %r14;
	mll %r0, %r6;
	hib %r4; lob %r0; xbr %r0; orr %r0, %r4;
	sms %r0, w6;

	addk(9, 1, OBJ.ROT_R);
	ldw %r1, [%r9]; inc %r9; inc %r9;
	ldw %r2, [%r9]; inc %r9; inc %r9;
	ldw %r3, [%r9]; inc %r9; inc %r9;
	ldw %r4, [%r9];

	getb %r0; inc %r14;
	sms %r0, w15;
	scope vertloop: {
		lms %r0, w15; dec %r0; bmi vdone; sbk %r0;
		bsr getVert; nop;
		bch vertloop; nop;
	vdone:
	}

	pul %r0; sms %r0, w1;

	getb %r0; inc %r14;
	sms %r0, w15;
	scope triloop: {
		lms %r0, w15; dec %r0; bmi tdone; sbk %r0;

		jsr ModelTristrip; nop;

		bch triloop; nop;
	tdone:
	}

	pul %r1;
	ldb %r0, #OBJ.SIZE;
	add %r1, %r0;

	lms %r2, w2;
	lms %r3, w3;
	pul %r15; nop;

	scope getVert: {
		lms %r6, w6;
		psh %r11;
		mov %r12, %r4;
		getb %r0; inc %r14;
		xbr %r0;
		mlf %r13, %r0, %r6;
		getb %r0; inc %r14;
		xbr %r0;
		mlf %r7, %r0, %r6;
		getb %r0;
		xbr %r0;
		mlf %r8, %r0, %r6;
		mov %r4, %r12;
		mov %r6, %r13;
		jsr QuionApply; inc %r14;
		lms %r11, w2;
		addk(9, 5, OBJ.POS_X);
		ldw %r0, [%r9]; inc %r9; inc %r9;
		add %r0, %r6;
		stw %r0, [%r11]; inc %r11; inc %r11;
		ldw %r0, [%r9]; inc %r9; inc %r9;
		add %r0, %r7;
		stw %r0, [%r11]; inc %r11; inc %r11;
		ldw %r0, [%r9];
		add %r0, %r8;
		stw %r0, [%r11]; inc %r11; inc %r11;
		getb %r0; inc %r14;
		stb %r0, [%r11]; inc %r11;
		getb %r0; inc %r14;
		stb %r0, [%r11]; inc %r11;
		sms %r11, w2;
		ldw %r0, vertexCount;
		inc %r0;
		sbk %r0;
		pul %r15; nop;
	}
FEND:
}

// arguments:
// %r1        - object ptr
// %r2        - vertex buffer ptr
// %r3        - itri buffer ptr
// %romb:%r14 - tristrip
scope ModelTristrip: {
	// temporaries:
	// %r0       - misc
	// %r1       - object rotation quion w
	// %r2       - object rotation quion x
	// %r3       - object rotation quion y
	// %r4       - object rotation quion z
	// %r5       - ptr to object
	// %r6       - vertex x
	// %r7       - vertex y
	// %r8       - vertex z
	// %r9       - temporaries; clobbered by children
	// %r10      - %sp
	// %r11      - %ra
	// %r12      - temporaries; clobbered by children
	// %r13      - temporaries; clobbered by children
	// w1        - ptr to vertex 0
	// w3        - ptr to itri buffer
	// w4        - triangle parity
	// w6        - obj.scale * model's intrinsic scale
	// w8        - current-2 vertex
	// w9        - current-1 vertex
	psh %r11;
	sub %r0, %r0;
	sms %r0, w4;

	lms %r13, w1;
	ldb %r6, #VERTEX.SIZE;
	getb %r0; inc %r14; mlu %r0, %r6; add %r0, %r13; sms %r0, w8;
	getb %r0; inc %r14; mlu %r0, %r6; add %r0, %r13; sms %r0, w9;

	scope triLoop: {
		getb %r0;
		lob %r0; bne +; inc %r14; jmp done; nop; +;

		lms %r9, w3;
		stw %r0, [%r9]; inc %r9; inc %r9;

		// either verts[current - 1], verts[current - 2]
		//    or  verts[current - 2], verts[current - 1],
		// depending on parity
		rol %r0; // clear carry
		lms %r0, w4;
		and %r0, #1;
		ldb %r7, #9 * 2; // w9
		ldb %r8, #9 * 2; // w9
		cwith %r7, %r8, ne; sub #2;
		inc %r0; sms %r0, w4;

		ldw %r0, [%r7];
		stw %r0, [%r9]; inc %r9; inc %r9;
		ldw %r0, [%r8];
		stw %r0, [%r9]; inc %r9; inc %r9;

		// most recent vertex
		lms %r8, w1;
		ldb %r6, #VERTEX.SIZE;
		getb %r0; inc %r14;
		mlu %r0, %r6;
		add %r0, %r8;
		stw %r0, [%r9];
		lms %r8, w9;
		sms %r8, w8;
		sms %r0, w9;
		getb %r0; inc %r14;
		addk(9, 9, ITRI.CTEX - ITRI.POINT_C);
		getbh %r0; inc %r14;
		stw %r0, [%r9];
		addk(0, 9, ITRI.SHADE - ITRI.CTEX);
		psh %r0;

		getb %r0; inc %r14; getbh %r6, %r0; inc %r14;
		getb %r0; inc %r14; getbh %r7, %r0; inc %r14;
		getb %r0; inc %r14; getbh %r8, %r0;
		jsr QuionApply; inc %r14;
		mov %r9, %r4;
		ldw %r0, lightVector;
		mll %r0, %r0, %r6;
		mov %r11, %r4;
		ldw %r6, lightVector+2;
		mll %r7, %r6;
		add %r11, %r4;
		adc %r0, %r7;
		ldw %r6, lightVector+4;
		mll %r8, %r6;
		add %r11, %r4;
		adc %r0, %r8;
		hib %r11; lob %r0; xbr %r0; orr %r0, %r11;
		ldw %r8, lightVector+6;
		add %r0, %r8;
		bpl +; inc %r10; sub %r0, %r0; +;
		hib %r11, %r0; beq +; inc %r10; ldw %r0, #$00'ff; +;
		mov %r4, %r9;
		ldw %r9, [%r10];
		stw %r0, [%r9];
		addk(0, 9, ITRI.SIZE - ITRI.SHADE);
		sms %r0, w3;

		ldw %r0, itriCount;
		inc %r0;
		jmp triLoop; sbk %r0;
	done:
	}

	pul %r15; nop;
FEND:
}
