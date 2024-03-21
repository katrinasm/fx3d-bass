scope Boot: {
	cache;

	ldb %r0, #1;
	ramb %r0;
	sub %r0, %r0;
	ldw %r12, #$8000;
	ldb %r1, #0;
	setl; {
		stw %r0, [%r1]; inc %r1;
		loop; inc %r1;
	};

	sub %r0, %r0;
	ramb %r0;

	ldw %r12, #$8000;
	ldb %r1, #0;
	setl; {
		stw %r0, [%r1]; inc %r1;
		loop; inc %r1;
	};

	ldw %r10, #$01fe;

	jsr ZeroFrameBuffers; nop;

	jsr InitAllocator; nop;

	stp; nop;
}

cachealign();
scope ClearOam: {
	cache;
	ldw %r12, #128;
	ldw %r0, oamBufPtr.fx;
	sub %r1, %r0, #3;
	ldb %r0, #$e0;
	ldb %r3, #4;
	ldw %r13, #body;
	with %r1;
	body: {
		add %r3;
		stb %r0, [%r1];
		loop;
		with %r1;
	}
	nop;
	stp; nop;
}

cachealign();
scope CompressOamBits: {
	ldw %r0, oamBufPtr.fx;
	ldw %r10, #$0220;
	add %r1, %r0, %r10;
	ldw %r10, #$0200;
	add %r2, %r0, %r10;

	ldb %r12, #32;
	setl; {
		ldb %r0, [%r1]; inc %r1;
		add %r0, %r0; add %r3, %r0, %r0;

		ldb %r3, [%r1]; inc %r1;
		orr %r0, %r3;
		add %r0, %r0; add %r0, %r0;

		ldb %r3, [%r1]; inc %r1;
		orr %r0, %r3;
		add %r0, %r0; add %r0, %r0;

		ldb %r3, [%r1]; inc %r1;
		orr %r0, %r3;

		stb %r0, [%r2];

		loop; inc %r2;
	}

	stp; nop;
};
