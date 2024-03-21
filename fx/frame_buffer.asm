cachealign();
scope ZeroFrameBuffers: {
	cache;
	ldb %r0, #frameBuf.even>>16; ramb;
	ldw %r1, #frameBuf.even;
	ldw %r12, #28*24*$20;
	sub %r0, %r0;
	setl; {
		stb [%r1];
		loop; inc %r1;
	};

	ldb %r0, #frameBuf.odd>>16; ramb;
	ldw %r1, #frameBuf.odd;
	ldw %r12, #28*24*$20;
	sub %r0, %r0;
	setl; {
		stb [%r1];
		loop; inc %r1;
	};

	sub %r12, %r1;
	not %r0;
	setl; {
		stb [%r1];
		loop; inc %r1;
	};

	sub %r0, %r0;
	ramb %r0;

	rts; nop;
FEND:
}

cachealign();
scope PlotWholeScreen: {
	cache;
	ldw %r1, #0;         // left x
	ldb %r2, #0;         // top y
	ldw %r3, #SCREEN_W;  // width
	ldw %r4, #SCREEN_H;  // height
	ldw %r13, #row.col;
	scope row: {
		mov %r12, %r3;
		ldb %r1, #0; // left x
		scope col: {
			loop;
			plot;
		}
		rpix;
		dec %r4;
		bne row; inc %r2;
	}
	rts;
}