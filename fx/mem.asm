// %r0 - target address
// %r1 - target bank
// %r2 - source bank
// %r12 - length
// %r14 - source address
scope RomCopy: {
	romb %r2;
	ramb %r1;
	mov %r1, %r0;
	cache;
	mov %r14, %r14;
	setl; {
		getb %r0;
		inc %r14;
		stb %r0, [%r1];
		loop; inc %r1;
	}
	sub %r0;
	ramb %r0;
	rts; nop;
}
