// call with:
// %r0: u16 = alloc size;
// returns:
// %r0: *mut u8 = allocated memory if successful, 0 if failed
// zero flag set if allocation unsuccessful
constant SMALL_ALLOC_SHIFT(3);
constant SMALL_ALLOC_SIZE(1<<SMALL_ALLOC_SHIFT);
constant MAX_SMALL_ALLOCS(96);
constant LARGE_ALLOC_REGION_SIZE(1024 * 8);
addr.alloc70(smallAllocFlags, MAX_SMALL_ALLOCS / 8, 1);
addr.alloc70(smallAllocRegion, SMALL_ALLOC_SIZE * MAX_SMALL_ALLOCS, 1);
addr.alloc70(largeAllocRegion, LARGE_ALLOC_REGION_SIZE, 1);

constant smallAllocEnd(smallAllocRegion + SMALL_ALLOC_SIZE * MAX_SMALL_ALLOCS);
constant largeAllocEnd(largeAllocRegion + LARGE_ALLOC_REGION_SIZE);

scope ALLOC_HEADER {
	constant NEXT(0); // ptr to next allocation's header
	constant LEN(2);  // length of the allocation
	constant SIZE(4); // size of the header, not the allocation
}

cachealign();
scope InitAllocator: {
	cache;
	ldw %r4, #smallAllocRegion;
	ldw %r12, #MAX_SMALL_ALLOCS/16;
	sub %r0, %r0;
	setl;
		stw %r0, [%r4];
		inc %r4;
		loop; inc %r4;

	// header of the front allocation
	stw %r0, largeAllocRegion + ALLOC_HEADER.NEXT;
	stw %r0, largeAllocRegion + ALLOC_HEADER.LEN;
	rts; nop;
FEND:
}

align_exact(4);
scope Alloc: {
	movs %r1, %r0;
	// check if alloc is >= $8000 (don't want any overflow junk)
	bmi allocLarge.cantAlloc; nop;
	// check if we are the zero-sized alloc
	beq allocLarge.returnInc; sub %r0, %r0;

realAlloc:
	ldb %r5, #SMALL_ALLOC_SIZE;
	sub %r0, %r5, %r1;
	// if the search size is odd, we increase it by 1
	// this gives us always-even search sizes, which makes sure everything
	// stays word-aligned
	bcc allocLarge; inc %r1;
	scope allocSmall: {
		ldw %r2, #smallAllocFlags;
		ldw %r3, #MAX_SMALL_ALLOCS/16;
		ldw %r4, #smallAllocRegion-SMALL_ALLOC_SIZE;
		ldb %r0, #1;
		ldw %r13, #wordLoop.bitLoop;
		scope wordLoop: {
			ldw %r7, [%r2];
			ldb %r12, #16;
			scope bitLoop: {
				and %r6, %r0, %r7;
				with %r4; beq foundSmallAlloc; add %r5;
				loop; add %r0, %r0;
			}
			inc %r2;
			dec %r3; bne wordLoop; inc %r2;
		}
		// jmp allocLarge;
	}

	scope allocLarge: {
		// make sure the search size is even
		bic %r1, #1;
		ldw %r2, #largeAllocRegion;
		ldb %r12, #0;
		ldb %r6, #2;
		add %r8, %r1, #ALLOC_HEADER.SIZE;
		setl;
		nodeLoop: {
			// %r0 = 0 on loop start
			ldw %r0, [%r2];
			movs %r3, %r0;
			to %r7; from %r2; bne nonNullNext; add %r6;
		nullNext:
			ldw %r3, #largeAllocEnd;
			inc %r12; // exit the loop after this
		nonNullNext:
			ldw %r0, [%r7];
			// %r5 = start of this allocation
			add %r5, %r7, %r6;
			// %r4 = location of free space after allocation
			add %r4, %r0, %r5;
			// %r0 = length of free space
			sub %r0, %r3, %r4;
			// big enough?
			sub %r0, %r8; bcs foundSpace; nop;
			mov %r2, %r3;
			// if 'next' was null %r12 = 1 (doesn't loop)
			// otherwise %r12 = 0          (loops)
			// `loop` decrements %r12 and then it gets `inc`ed again instantly,
			// so this is invariant across iterations
			loop; inc %r12;
		}
	cantAlloc:
		rts; sub %r0, %r0;

	foundSpace:
		// %r0 == 0
		// %r12 = 1 if null next, 0 otherwise
		// dec %r12 makes it so %r12 = $0000 if null next, $ffff otherwise
		// %r5 == %r4 when the node is empty, which implies
		// it's the front node since that's the only empty node allowed to
		// exist
		sub %r0, %r5, %r4; beq emptyNode; dec %r12;
		stw %r4, [%r2];
		and %r0, %r3, %r12;
		stw %r0, [%r4];
		add %r0, %r4, %r6;
		stw %r1, [%r0];
		inc %r0;
	returnInc:
		rts; inc %r0;

	emptyNode:
		stw %r1, [%r7];
		// %r0 == 0 here,
		// so we can get %r4 this way
		rts; add %r0, %r4;
	}

	// this should be in allocSmall but im cursed
	foundSmallAlloc:
		orr %r0, %r7;
		stw %r0, [%r2];
		sub %r0, %r0;
		rts; add %r0, %r4;
FEND:
}

scope Free: {
	// if we are freeing address $0001 (zero-sized),
	// or address $0000 (null),
	// don't do anything
	lsr %r0; beq return; rol %r0;
realFree:
	mov %r1, %r0;
	// check if we are small
	ldw %r2, #smallAllocRegion;
	ldw %r3, #smallAllocEnd-smallAllocRegion;
	sub %r0, %r2;
	sub %r0, %r3; bcs large; add %r0, %r3;
small:
	lsr %r0; lsr %r0; lsr %r0; // which allocation?
	and %r12, %r0, #7;         // which flag bit?
	lsr %r0; lsr %r0; lsr %r0; // which flag byte?
	ldw %r2, #smallAllocFlags;
	add %r2, %r0;
	// %r0 = 1 << bit
	inc %r12;
	sub %r0, %r0; // sets %r0 = 0, carry = 1
	setl; loop; rol %r0;
	not %r1, %r0;
	ldb %r0, [%r2];
	and %r0, %r1;
	stb %r0, [%r2];
return:
	rts; nop;

large:
	// the address of the node we're looking for
	// is just below the address of the actual allocation
	sub %r1, #ALLOC_HEADER.SIZE;
	ldw %r2, #largeAllocRegion;
	sub %r0, %r1, %r2;
	bne notTheFront; sub %r0, %r0;
itsTheFront:
	inc %r2; inc %r2;
	rts; stw %r0, [%r2];

notTheFront:
	scope nodeLoop: {
		sub %r0, %r1, %r2;
		beq foundIt; ldw %r0, [%r2];
		mov %r5, %r2;
		// checking for nulls is technically unnecessary, in the sense
		// that avoiding undefined behavior is technically unnecessary
		movs %r2, %r0;
		bne nodeLoop; nop;
	}
	rts; nop;

foundIt:
	rts; stw %r0, [%r5];

FEND:
}

