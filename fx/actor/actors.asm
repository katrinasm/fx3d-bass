scope actorVTables: {
	// INIT, FN_0, FN_1, DROP, init flags
	// null actor - only spawned in error, dropped instantly.
	dw 0,0,0,0;
	dw ACTOR_FLAGS.DROP;
	// #0001 player
	dw player.Init, player.Fn0, basicNpc.Fn1, 0;
	dw ACTOR_FLAGS.COLLIDES_WITH_ACTORS | ACTOR_FLAGS.COLLIDES_WITH_WORLD;
	// #0002 basic npc
	dw basicNpc.Init, basicNpc.Fn0, basicNpc.Fn1, 0;
	dw ACTOR_FLAGS.COLLIDES_WITH_ACTORS | ACTOR_FLAGS.COLLIDES_WITH_WORLD;
	// #0003 rock
	dw rock.Init, rock.Fn0, 0, 0;
	dw ACTOR_FLAGS.COLLIDES_WITH_ACTORS | ACTOR_FLAGS.NO_GRAVITY;
	// #0004 decorative object pair
	dw rock.Init, decoPair.Fn0, 0, 0;
	dw ACTOR_FLAGS.NO_GRAVITY;
}

scope player {
	constant ANIM_TIME(8);
	constant IS_PLAYER(6);
	scope Init: {
		addk(2, 9, ACTOR.VIZ_FLAGS);
		sub %r0, %r0;
		stw %r0, [%r2]; inc %r2; inc %r2;
		stw %r0, [%r2]; inc %r2; inc %r2;
		ldw %r0, #$2040;
		stw %r0, [%r2];
		addk(2, 9, IS_PLAYER);
		ldb %r0, #$01;
		rts; stw %r0, [%r2];
	}

	scope Fn0: {
		addk(3, 9, ACTOR.VIZ_FLAGS);
		ldw %r4, [%r3];
		ldw %r5, joy.fx.p1.held;
		ldw %r1, #joy.DPAD_L|joy.DPAD_R;
		and %r0, %r5, %r1; beq nodirx; nop;
		ldw %r1, #joy.DPAD_R;
		bic %r4, #VIZ_FLAG.FACING_X;
		and %r0, %r1;
		beq +; nop; inc %r4; +;
	nodirx:

		ldw %r1, #joy.DPAD_D|joy.DPAD_U;
		and %r0, %r5, %r1; beq nodiry; nop;
		ldw %r1, #joy.DPAD_U;
		bic %r4, #VIZ_FLAG.FACING_Z;
		and %r0, %r1;
		beq +; nop; orr %r4, #VIZ_FLAG.FACING_Z; +;
	nodiry:
		stw %r4, [%r3];

		ldw %r5, #joy.BUTTON_Y|joy.BUTTON_X;
		ldw %r0, joy.fx.p1.held;
		and %r5, %r0, %r5;

		ldw %r0, joy.fx.p1.axes.lr;
		asr %r1, %r0; asr %r1; adc %r0, %r1;
		tst %r5;
		beq +; nop; add %r1, %r0, %r0; add %r0, %r1; +;
		addk(2, 9, ACTOR.SPD_X);
		stw %r0, [%r2]; inc %r2; inc %r2;
		ldw %r1, #joy.BUTTON_B;
		ldw %r0, joy.fx.p1.depress;
		and %r0, %r1; beq nojump; nop;
		ldw %r0, #$0500;
		stw %r0, [%r2];
	nojump:
		inc %r2; inc %r2;
		ldw %r0, joy.fx.p1.axes.ud;
		asr %r1, %r0; asr %r1; adc %r0, %r1;
		tst %r5;
		beq +; nop; add %r1, %r0, %r0; add %r0, %r1; +;
		rts; stw %r0, [%r2];
	}
}

scope basicNpc {
	constant ANIM_TIME(8);
	constant IS_PLAYER(6);
	scope Init: {
		addk(2, 9, ACTOR.VIZ_FLAGS);
		addk(3, 9, IS_PLAYER);
		sub %r0, %r0;
		stw %r0, [%r2];
		stw %r0, [%r3];
		addk(2, 2, ACTOR.VIZ_FRAME - ACTOR.VIZ_FLAGS);
		stw %r0, [%r2];
		addk(2, 2, ACTOR.VIZ_ID - ACTOR.VIZ_FRAME);
		ldw %r0, [%r1];
		stw %r0, [%r2];
		inc %r1; inc %r1;
		ldw %r0, [%r1];
		rts; stw %r0, [%r9];
	}

	scope Fn0: {
		rts; nop;
	}

	scope Fn1: {
		ldb %r0, #Fn1>>16; romb %r0;
		addk(7, 9, ANIM_TIME);
		addk(8, 9, ACTOR.SPD_X);
		ldw %r0, [%r8]; inc %r8; inc %r8;
		mov %r2, %r0;
		ldw %r3, [%r8]; inc %r8; inc %r8;
		orr %r0, %r3;
		ldw %r3, [%r8];
		orr %r0, %r3;
		beq stationary; sub %r0, %r0;
	moving:
		addr.printlab(moving);
		ldw %r0, [%r7];
		ldw %r1, physicFieldCount;
		add %r0, %r1;
		lob %r0;
		stw %r0, [%r7];
		mov %r5, %r0;
		ldw %r4, #$0180;
		movs %r0, %r2;
		bpl +; nop;
			sub %r0, %r0; sub %r0, %r2;
		+;
		sub %r0, %r4;
		with %r5; bge running; to %r0;
		movs %r0, %r3;
		bpl +; nop;
			sub %r0, %r0; sub %r0, %r3;
		+;
		sub %r0, %r4;
		with %r5; blt walking; to %r0;
	running:
		lsr %r0; lsr %r0; lsr %r0;
		and %r0, #3;
		add %r7, %r0, #4;
		bch gotframe; nop;

	walking:
		lsr %r0; lsr %r0; lsr %r0;
		and %r7, %r0, #3;
		lsr %r0; lsr %r0; bcc +; nop;
			add %r0, %r7, %r7;
			and %r7, %r0, %r7;
		+;
		bch gotframe; nop;

	stationary:
		stw %r0, [%r7];
		ldb %r7, #0;
	gotframe:
		ldw %r0, vertexCount;
		inc %r0;
		sbk %r0; // -> vertexCount;

		dec %r0;
		ldb %r6, #VERTEX.SIZE;
		mll %r0, %r6;
		ldw %r0, #vertexBuffer;
		add %r1, %r0, %r4;
		mov %r2, %r1;

		addk(8, 9, ACTOR.POS_X);
		ldw %r0, [%r8];
		stw %r0, [%r1];
		addk(8, 8, ACTOR.POS_Y - ACTOR.POS_X);
		inc %r1; inc %r1;
		ldw %r0, [%r8];
		stw %r0, [%r1];
		addk(8, 8, ACTOR.POS_Z - ACTOR.POS_Y);
		inc %r1; inc %r1;
		ldw %r0, [%r8];
		stw %r0, [%r1];

		ldw %r0, itriCount;
		inc %r0; inc %r0;
		stw %r0, itriCount;
		dec %r0; dec %r0;
		ldb %r6, #ITRI.SIZE;
		mll %r0, %r6;
		ldw %r0, #itriBuffer;
		add %r3, %r0, %r4;
		add %r4, %r3, %r6;

		ldw %r0, #headOffsets;
		add %r14, %r0, %r7;
		ldw %r0, #RFLAG.VALID | RFLAG.BILLBD;
		stw %r0, [%r3]; inc %r3; inc %r3;
		stw %r0, [%r4]; inc %r4; inc %r4;
		stw %r2, [%r3]; inc %r3; inc %r3;
		stw %r2, [%r4]; inc %r4; inc %r4;
		sub %r0, %r0;
		stb %r0, [%r3]; inc %r3;
		stw %r0, [%r4]; inc %r4; inc %r4;
		getb %r0;
		stb %r0, [%r3]; inc %r3;
		sub %r0, %r0;
		addk(8, 9, ACTOR.VIZ_FLAGS);
		ldb %r2, [%r8];
		and %r0, %r2, #VIZ_FLAG.FACING_X;
		stb %r0, [%r3]; inc %r3; inc %r3;
		stb %r0, [%r4]; inc %r4;
		add %r7, %r7;
		and %r2, #VIZ_FLAG.FACING_Z;
		beq +; inc %r4; inc %r7; ldb %r2, #1; +;
		addk(8, 8, ACTOR.VIZ_ID - ACTOR.VIZ_FLAGS);
		ldw %r5, [%r8];
		lob %r0, %r5;
		add %r0, %r2;
		stw %r0, [%r3];
		hib %r0, %r5;
		add %r0, %r7;
		stw %r0, [%r4];

		addk(2, 9, IS_PLAYER);
		ldb %r0, [%r2];
		lsr %r0; bcc noCamera; nop;
	setCamera:
		ldw %r0, #cameraZVector;
		ldw %r3, [%r0]; inc %r0; inc %r0;
		ldw %r4, [%r0]; inc %r0; inc %r0;
		ldw %r5, [%r0];
		ldb %r0, #-$38;
		add %r4, %r0, %r4;
		ldw %r6, #camera + OBJ.POS_X;
		addk(2, 9, ACTOR.POS_X);
		ldw %r0, [%r2]; inc %r2; inc %r2;
		sub %r0, %r3;
		stw %r0, [%r6]; inc %r6; inc %r6;
		ldw %r0, [%r2]; inc %r2; inc %r2;
		sub %r0, %r4;
		stw %r0, [%r6]; inc %r6; inc %r6;
		ldw %r0, [%r2];
		sub %r0, %r5;
		stw %r0, [%r6];
	noCamera:
		rts; nop;

	headOffsets:
		db $18, $17, $17, $00, $18, $17, $18, $17
	FEND:
	}
}

scope rock {
	scope Init: {
		ldw %r0, [%r1];
		stw %r0, [%r9];
		inc %r1; inc %r1;
		inc %r9; inc %r9;
		ldw %r0, [%r1];
		rts; stw %r0, [%r9];
	}

	scope Fn0: {
		ldw %r0, vertexCount;
		inc %r0;
		sbk %r0; // -> vertexCount;

		dec %r0;
		ldb %r6, #VERTEX.SIZE;
		mll %r0, %r6;
		ldw %r0, #vertexBuffer;
		add %r1, %r0, %r4;
		mov %r2, %r1;

		addk(8, 9, ACTOR.POS_X);
		ldw %r0, [%r8];
		stw %r0, [%r1];
		addk(8, 8, ACTOR.POS_Y - ACTOR.POS_X);
		inc %r1; inc %r1;
		ldw %r0, [%r8];
		stw %r0, [%r1];
		addk(8, 8, ACTOR.POS_Z - ACTOR.POS_Y);
		inc %r1; inc %r1;
		ldw %r0, [%r8];
		stw %r0, [%r1];

		ldw %r0, itriCount;
		inc %r0;
		stw %r0, itriCount;
		dec %r0;
		ldb %r6, #ITRI.SIZE;
		mll %r0, %r6;
		ldw %r0, #itriBuffer;
		add %r3, %r0, %r4;

		ldw %r0, #RFLAG.VALID | RFLAG.BILLBD;
		stw %r0, [%r3]; inc %r3; inc %r3;
		stw %r2, [%r3]; inc %r3; inc %r3;
		sub %r0, %r0;
		stw %r0, [%r3]; inc %r3; inc %r3;
		stb %r0, [%r3]; inc %r3; inc %r3;
		ldw %r0, [%r9];
		stw %r0, [%r3];
		inc %r3; inc %r3;
		inc %r9; inc %r9;
		ldb %r0, [%r9];
		xbr %r0;
		rts; stw %r0, [%r3];
	}
}

scope decoPair {
	scope Fn0: {
		ldw %r0, vertexCount;
		add %r0, #2;
		sbk %r0; // -> vertexCount;

		sub %r0, #2;
		ldb %r6, #VERTEX.SIZE;
		mll %r0, %r6;
		ldw %r0, #vertexBuffer;
		add %r1, %r0, %r4;
		mov %r2, %r1;
		add %r5, %r2, %r6;

		addk(8, 9, ACTOR.POS_X);
		ldw %r0, [%r8];
		inc %r9;
		ldb %r4, [%r9];
		stw %r0, [%r1];
		bic %r4, #$f;
		add %r0, %r4;
		stw %r0, [%r5];
		inc %r9; inc %r9;

		addk(8, 8, ACTOR.POS_Y - ACTOR.POS_X);
		inc %r1; inc %r1;
		inc %r5; inc %r5;
		ldw %r0, [%r8];
		stw %r0, [%r1];
		stw %r0, [%r5];
		addk(8, 8, ACTOR.POS_Z - ACTOR.POS_Y);
		inc %r1; inc %r1;
		inc %r5; inc %r5;
		ldw %r0, [%r8];
		ldb %r4, [%r9];
		stw %r0, [%r1];
		bic %r4, #$f;
		add %r0, %r4;
		stw %r0, [%r5];
		dec %r9; dec %r9;
		dec %r9;

		ldw %r0, itriCount;
		add %r1, %r0, #2;
		stw %r1, itriCount;
		ldb %r6, #ITRI.SIZE;
		mll %r0, %r6;
		ldw %r0, #itriBuffer;
		add %r3, %r0, %r4;
		add %r4, %r3, %r6;

		ldw %r1, #$0fff;

		ldw %r0, #RFLAG.VALID | RFLAG.BILLBD;
		stw %r0, [%r3]; inc %r3; inc %r3;
		stw %r0, [%r4]; inc %r4; inc %r4;
		stw %r2, [%r3]; inc %r3; inc %r3;
		addk(0, 2, VERTEX.SIZE);
		stw %r0, [%r4]; inc %r4; inc %r4;
		sub %r0, %r0;
		stw %r0, [%r3]; inc %r3; inc %r3;
		stw %r0, [%r4]; inc %r4; inc %r4;
		stb %r0, [%r3]; inc %r3; inc %r3;
		stb %r0, [%r4]; inc %r4; inc %r4;
		ldw %r0, [%r9];
		and %r0, %r1;
		stw %r0, [%r3]; inc %r3; inc %r3;
		inc %r9; inc %r9;
		ldw %r0, [%r9];
		and %r0, %r1;
		stw %r0, [%r4]; inc %r4; inc %r4;
		sub %r0, %r0;
		stw %r0, [%r3];
		rts; stw %r0, [%r4];
	}
}
