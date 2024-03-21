// %r0 - id
// %r1 - pos x
// %r2 - pos y
// %r3 - pos z
align_exact(4);
scope MakeSpawnRq: {
	ldw %r5, spawnRqCount;
	inc %r5;
	stw %r5, spawnRqCount;
	dec %r5;
	add %r5, %r5;
	ldw %r4, #spawnRqBuffer;
	add %r5, %r4;
	addk(5, 5, SPAWN_RQ.ID);
	stw %r0, [%r5];
	addk(5, 5, SPAWN_RQ.POS_X - SPAWN_RQ.ID);
	stw %r1, [%r5];
	addk(5, 5, SPAWN_RQ.POS_Y - SPAWN_RQ.POS_X);
	stw %r2, [%r5];
	addk(5, 5, SPAWN_RQ.POS_Z - SPAWN_RQ.POS_Y);
	stw %r3, [%r5];
	rts; nop;
}

addr.alloc70(lastCall, 2, 1);
// %r1 - pointer to spawn rq
scope SpawnActor: {
	ldb %r0, #actorVTables>>16; romb %r0;

	ldw %r3, #actorBuffer;
	ldw %r4, #actorList;
	ldw %r0, actorCount;
	inc %r0;
	stw %r0, actorCount;
	dec %r0;
	ldb %r9, #ACTOR.SIZE;
	mul %r9, %r0, %r9;
	add %r9, %r3;
	add %r0, %r0;
	add %r0, %r4;
	stw %r9, [%r0];

	addk(3, 9, ACTOR.FN_0);
	addk(5, 9, ACTOR.POS_X);

	ldb %r6, #10;
	addk(1, 1, SPAWN_RQ.ID);
	ldw %r0, [%r1];
	mll %r0, %r6;
	ldw %r0, #actorVTables;
	add %r14, %r0, %r4;
	addk(1, 1, SPAWN_RQ.POS_X - SPAWN_RQ.ID);
	ldw %r0, [%r1];
	stw %r0, [%r5];
	getb %r0; inc %r14;
	addk(1, 1, SPAWN_RQ.POS_Y - SPAWN_RQ.POS_X);
	getbh %r8, %r0; inc %r14;
	ldw %r0, [%r1];
	addk(5, 5, ACTOR.POS_Y - ACTOR.POS_X);
	stw %r0, [%r5];
	getb %r0; inc %r14;
	addk(1, 1, SPAWN_RQ.POS_Z - SPAWN_RQ.POS_Y);
	getbh %r0; inc %r14;
	stw %r0, [%r3];
	addk(5, 5, ACTOR.POS_Z - ACTOR.POS_Y);
	ldw %r0, [%r1];
	stw %r0, [%r5];
	getb %r0; inc %r14;
	addk(3, 3, ACTOR.FN_1 - ACTOR.FN_0);
	getbh %r0; inc %r14;
	stw %r0, [%r3];
	getb %r0; inc %r14;
	addk(3, 3, ACTOR.DROP - ACTOR.FN_1);
	getbh %r0; inc %r14;
	stw %r0, [%r3];
	addk(3, 3, ACTOR.FLAGS - ACTOR.DROP);
	getb %r0; inc %r14;
	getbh %r0;
	stw %r0, [%r3];
	sub %r0, %r0;
	addk(5, 5, ACTOR.SPD_X - ACTOR.POS_Z);
	stw %r0, [%r5];
	addk(5, 5, ACTOR.SPD_Y - ACTOR.SPD_X);
	stw %r0, [%r5];
	addk(5, 5, ACTOR.SPD_Z - ACTOR.SPD_Y);
	stw %r0, [%r5];
	addk(1, 1, SPAWN_RQ.PARAMS - SPAWN_RQ.POS_Z);
	movs %r0, %r8;
	bne dontdie; nop;
	rts; nop;
dontdie:
	ldw %r0, lastCall;
	stw %r8, lastCall;
	sub %r0, %r8;
	bic %r0, #$f;
	beq noCache;
	jmp [%r8];
	cache;
noCache:
	nop;
}

cachealign();
scope HandleFrame: {
	stw %r11, [%r10];
	dec %r10;
	sub %r0, %r0;
	stw %r0, lastCall;
	// process spawn requests
	ldw %r1, spawnRqCount;
	tst %r1;
	bsr ne, processSpawns; dec %r10;

	// process drop requests
	ldw %r12, actorCount;
	movs %r0, %r12;
	beq return; nop;
	cache;
	ldw %r4, #actorList;
	mov %r5, %r4;
	ldb %r6, #ACTOR.FLAGS;
	ldw %r7, #ACTOR_FLAGS.DROP;
	setl;
	scope dropLoop: {
		ldw %r9, [%r4];
		add %r0, %r9, %r6;
		ldb %r0, [%r0];
		and %r0, %r7;
		bne drop; inc %r4;
		stw %r9, [%r5];
		inc %r5;
		inc %r5;
	continue:
		loop; inc %r4;
	}

	ldw %r2, #actorList;
	sub %r0, %r5, %r2; beq return; lsr %r0;
	stw %r0, actorCount;

	ldb %r1, #ACTOR.FN_0;
	jsr processFn; nop;

	jsr MoveActors; nop;

	ldb %r1, #ACTOR.FN_1;
	jsr processFn; nop;
return:
	pul %r15; nop;

	scope drop: {
		// call DROP if it exists
		addk(0, 9, ACTOR.DROP - ACTOR.FLAGS);
		ldw %r0, [%r0];
		movs %r8, %r0; beq dropLoop.continue; nop;
		// call setup
		psh %r12;
		psh %r5;
		stw %r4, [%r10];
		dec %r10;
		jsr [%r8]; dec %r10;
		// reset our loop conditions
		pul %r4;
		pul %r5;
		pul %r12;
		ldb %r6, #ACTOR.FLAGS;
		ldw %r7, #ACTOR_FLAGS.DROP;
		ldw %r13, #dropLoop;
		bch dropLoop.continue; nop;
	}

	scope processSpawns: {
		psh %r11;
	do:
		psh %r1;
		dec %r1;
		ldb %r0, #SPAWN_RQ.SIZE;
		mul %r0, %r1;
		ldw %r1, #spawnRqBuffer;
		add %r1, %r0;
		jsr SpawnActor; nop;
	until:
		pul %r1;
		dec %r1;
		bne do; sub %r0, %r0;
		stw %r0, spawnRqCount;
		pul %r15; nop;
	}

	// %r1 - fn field
	scope processFn: {
		stw %r11, [%r10]; dec %r10;
		ldw %r2, #actorList;
		ldw %r3, actorCount;
		jsr Sort; dec %r10;
		ldw %r12, actorCount;

		ldw %r2, #actorList;
	fnloop:
		// this is 'followed' by inc %r2; inc %r2 eventually but it is spread
		// across delay slots. i apologize but this code is out-of-cache. pls
		ldw %r9, [%r2];
		add %r0, %r9, %r1;
		// %r8 = call target
		// call skipped if null
		ldw %r0, [%r0];
		movs %r8, %r0; beq continue; inc %r2;
		psh %r1;
		psh %r2;
		psh %r12;
		// %r0 = (call - lastCall) & ~$f;
		// z flag set if target cache base matches the last call's cache base
		ldw %r0, lastCall;
		sub %r0, %r8;
		bic %r0, #$f;
		sbk %r8; // -> lastCall

		link #4; // 4 bytes until fnreturn: BEQ XXX JMP CACHE

		// There is a jmp in a branch's delay slot.
		// The jmp, like the branch, has a delay slot.
		// So the branch is executed, its delay slot instruction (the jmp)
		// is executed, the jmp's delay slot instruction is executed,
		// and then execution begins at the jmp target.
		// if the branch is taken, this becomes:
		// beq noCache; jmp [%r8]; nop; /* called function */;
		// if the branch is not taken, this becomes:
		// beq noCache; jmp [%r8]; cache; /* called function */;
		beq noCache; jmp [%r8];
		cache;
	fnreturn:
		pul %r12;
		pul %r2;
		pul %r1;
	continue:
		dec %r12; bne fnloop; inc %r2;

		pul %r15; // delay slot is noCache: nop
	noCache:
		nop;
	}
FEND:
}

