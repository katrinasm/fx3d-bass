constant GRAVITY(-$00'40);

cachealign();
scope MoveActors: {
	cache;
	psh %r11;
	ldw %r12, actorCount;
	ldw %r0, physicFieldCount;
	mov %r6, %r0;
	ldw %r11, #GRAVITY;
	mll %r11, %r6;
	mov %r11, %r4;
	xbr %r6, %r0;

	ldw %r5, #actorList;
	setl; {
		// regs:
		//  00 01 02 03 04 05 06 07 08 09 10 11 12 13
		//  -- -- -- -- ML LP FC -- -- -- -- GV LC LA
		ldw %r0, [%r5];
		ldb %r3, #ACTOR.FLAGS;
		add %r3, %r0;      // %r3 = FLAGS
		ldb %r7, #ACTOR.POS_X;
		add %r7, %r0;      // %r7 = POS_X
		ldb %r0, #6;
		add %r8, %r0, %r7; // %r8 = POS_XF
		add %r9, %r0, %r8; // %r9 = SPD_X

		// X update
		ldw %r1, [%r8];
		ldw %r0, [%r9]; inc %r9; inc %r9;
		mll %r0, %r6;
		add %r1, %r4;
		stw %r1, [%r8]; inc %r8; inc %r8;
		ldw %r1, [%r7];
		adc %r0, %r1;
		stw %r0, [%r7]; inc %r7; inc %r7;

		// Y update. notice: gravity, floor
		ldw %r1, [%r8];
		ldw %r2, [%r9];
		ldw %r0, [%r3];
		not %r3, %r0;
		ldw %r0, #ACTOR_FLAGS.NO_GRAVITY;
		and %r0, %r3;
		cmovl %r0, ne, %r11;
		add %r0, %r2;
		bvc noTerminalVel; nop;
		ldw %r0, #-$8000;
	noTerminalVel:
		stw %r0, [%r9];
		mll %r0, %r2, %r6;
		add %r1, %r4;
		ldw %r2, [%r7];
		adc %r0, %r2;
		bpl aboveFloor; inc %r9;
		sub %r0, %r0;
		ldb %r1, #0;
		// this stores to an odd address,
		// but it's fine bc byteswapped $0000 = $0000
		stw %r0, [%r9];
	aboveFloor:
		inc %r9;
		stw %r1, [%r8]; inc %r8; inc %r8;
		stw %r0, [%r7]; inc %r7; inc %r7;

		// Z update
		ldw %r1, [%r8];
		ldw %r0, [%r9];
		mll %r0, %r6;
		add %r1, %r4;
		stw %r1, [%r8];
		ldw %r1, [%r7];
		adc %r0, %r1;
		stw %r0, [%r7];

		inc %r5;
		loop; inc %r5;
	}
	pul %r15; nop;
FEND:
}

