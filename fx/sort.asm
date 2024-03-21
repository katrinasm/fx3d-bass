// %r1 - field offset
// %r2 - list address
// %r3 - number of elements
cachealign();
scope Sort: {
	cache;
	ldb %r0, #2;
	sub %r0, %r3;
	bcc +; nop; rts; nop; +;

	psh %r11;
	jsr isort; nop;
	pul %r15; nop;

	scope isort: {
		add %r0, %r3, %r3;
		add %r9, %r2, %r0;
		add %r8, %r2, #2;
		// %r2 - tri_begin
		// %r9 - tri_end
		// %r8 - pi
		// %r7 - pj
		// %r6 - z
		// %r5 - t
		scope outer: {
			sub %r0, %r8, %r9;
			bcs outdone; nop;
			ldw %r5, [%r8];
			add %r0, %r5, %r1;
			ldw %r6, [%r0];
			mov %r7, %r8;
			scope inner: {
				sub %r0, %r2, %r7;
				bcs indone; nop;
				sub %r0, %r7, #2;
				ldw %r4, [%r0];
				add %r0, %r4, %r1;
				ldw %r0, [%r0];
				sub %r0, %r6, %r0;
				bcs indone; nop;
				stw %r4, [%r7];
				dec %r7;
				bch inner; dec %r7;
			indone:
			}
			stw %r5, [%r7];
			inc %r8;
			bch outer; inc %r8;
		outdone:
		}
		rts; nop;
	}
FEND:
}

