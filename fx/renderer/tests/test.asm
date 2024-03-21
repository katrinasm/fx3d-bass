arch "arch/fx.arch";

framerate:
	string_constant("N/f: %02d | f/s: %02d | %s");

addr.alloc70(ramBuildString, 32, 4);

cachealign();
scope InitTestScene: {
	ldw %r12, #OBJ.SIZE;
	ldw %r14, #initCamera;
	ldb %r2, #initCamera>>16;

	ldw %r0, #camera;
	ldb %r1, #camera>>16;
	jsr RomCopy; nop;

	sub %r0, %r0; stw %r0, physicFieldCount;

	stw %r0, cameraSpin + ROTATION.RATE;
	stw %r0, cameraSpin + ROTATION.REPS;

	jsr GetTestObjs; nop;

	jsr SpawnTestActors; nop;

	ldb %r0, #automatic.builddate>>16; romb %r0;
	ldw %r14, #automatic.builddate;
	ldw %r1, #ramBuildString+2;
	ldw %r2, #30;
	jsr StrToRam; nop;
	stw %r0, ramBuildString;

	jsr SetCameraVectors; nop;

	stp; nop;

initCamera:
	dw 0;
	dw $0000, $0000, $0000;
	dw $0100;
	// 1 + 0i + 0j + 0k
	dw +$01'00,  $00'00,  $00'00,  $00'00;
}

scope SpawnTestActors: {
	ldb %r1, #testActors>>16;
	romb %r1;
	psh %r11;
	ldw %r14, #testActors;
	scope actorloop: {
		getb %r0; inc %r14;
		getbh %r0;
		xbr %r0;
		beq end; // link; ...
		bsr SpawnTestActor; dec %r14;
		addk(0, 0, actor.SPAWN_RQ.SIZE);
		bch actorloop; nop;
	end:
	}
	pul %r15; nop;

	scope testActors: {
		// dw $0003, $0000, $0000, $0000; dw $0003,$0000;
		dw $0001, $0000, $0000, $0020; dw $0000,$f0e0;
		dw $0002, $0020, $0020, $00c0; dw $2042,$f1e1;
		dw $0002, $0040, $0040, $00a0; dw $2044,$f2e2;
		dw $0002, $0100, $0000, $005e; dw $2046,$f3e3;
		dw $0004, $0080, $0000, $0000; dw $0018,$8018;
		// dw $0003,-$00a0, $0047, $007d; dw $001a,$0020;
		dw $0004,-$0064, $0000,-$0008; dw $4017,$0017;

		dw $0004, $00d0, $005c, $003e; dw $401b,$001c;
		dw 0;
	}
}

// %romb:%r14: source address
scope SpawnTestActor: {
	psh %r11;
	ldw %r0, actor.spawnRqCount;
	inc %r0;
	stw %r0, actor.spawnRqCount;
	dec %r0;

	ldb %r6, #actor.SPAWN_RQ.SIZE;
	mll %r0, %r6;
	ldw %r9, #actor.spawnRqBuffer;
	add %r9, %r4;
	addk(9, 9, actor.SPAWN_RQ.ID);
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	addk(9, 9, actor.SPAWN_RQ.POS_X - actor.SPAWN_RQ.ID);
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	addk(9, 9, actor.SPAWN_RQ.POS_Y - actor.SPAWN_RQ.POS_X);
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	addk(9, 9, actor.SPAWN_RQ.POS_Z - actor.SPAWN_RQ.POS_Y);
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	addk(9, 9, actor.SPAWN_RQ.PARAMS - actor.SPAWN_RQ.POS_Z);
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	inc %r9; inc %r9;
	getb %r0; inc %r14;
	getbh %r0; inc %r14;
	stw %r0, [%r9];
	pul %r15; stw %r0, [%r9];
}

cachealign();
scope DrawTestScene: {
// DRAW STEPS:
// models -> points, itris
//     points at this stage are 3x i16
// project points
//     points go 3x i16 -> 3x i12.4
// split triangles using projected points (itris -> stris)
//     points are "erased", become properties of stris
//     slopes are i8.8
//     positions are u8.8
// sort stris
// draw stris
	addr.alloc6k(ofs, 2);
	addr.alloc70(fc1, 2, 1);
	addr.alloc70(fc2, 2, 1);
	addr.alloc70(fc3, 2, 1);
	ldb %r0, #CMODE_DITHER | CMODE_PLOT_0;
	cmode %r0;

	ldw %r0, ofs.fx; lsr %r0;
	ldb %r0, #$0a;
	bcs +; nop; ldb %r0, #$0a; +;
	color %r0;
	jsr PlotWholeScreen; nop;

	ldb %r0, #0;//CMODE_DITHER;
	cmode %r0;

	jsr InitCounters; nop;

	jsr GetTestRasters; nop;

	// jsr HeckSpin; nop;
	jsr JoyTest; nop;

	ldw %r8, #camera + OBJ.ROT_R;
	ldw %r9, #cameraSpin;
	jsr RotationApply; nop;
	beq +; nop;
		jsr SetCameraVectors; nop;
+;

	jsr GetObjModels; nop;

	jsr GetLightVector; nop;

	jsr actor.HandleFrame; nop;

	jsr WorldspaceCull; nop;

	ldw %r1, #camera;
	jsr ProjectPoints; nop;

	nop;
	ldw %r0, ramBuildString;
	psh %r0;
	ldw %r0, #ramBuildString + 2;
	psh %r0;

	ldb %r0, #table.recip>>16; romb %r0;

	ldw %r0, physicFieldCount;
	ldw %r1, fc1;
	stw %r0, fc1;
	ldw %r2, fc2;
	stw %r1, fc2;
	ldw %r3, fc3;
	stw %r2, fc3;

	add %r0, %r1;
	add %r0, %r2;
	add %r1, %r0, %r3;
	ldw %r2, #table.recip;
	add %r0, %r1, %r1;
	add %r14, %r0, %r2;
	getb %r0; inc %r14; getbh %r0;
	ldw %r6, #60*16;
	mlf %r0, %r6;
	adc %r0, #0;
	lsr %r0; lsr %r0;
	psh %r0;
	ldw %r1, physicFieldCount;
	psh %r1;

	ldb %r0, #framerate>>16; romb %r0;
	ldw %r14, #framerate;
	jsr text.FormatStringToScreen; nop;

	jsr OuterRaster; nop;

	rpix;
	ldw %r0, [%r0];

	stp; nop;
}

scope GetLightVector: {
	psh %r11;
	ldw %r6, #-$00'45;
	ldw %r7, #$00'a7;
	ldw %r8, #-$00'b5;
	ldw %r9, #$00'10;
	ldw %r0, #lightVector;
	stw %r6, [%r0]; inc %r0; inc %r0;
	stw %r7, [%r0]; inc %r0; inc %r0;
	stw %r8, [%r0]; inc %r0; inc %r0;
	stw %r9, [%r0];
	pul %r15; nop;
}

scope SetCameraVectors: {
	stw %r11, [%r10];
	dec %r10;
	ldw %r0, #camera + OBJ.ROT_R;
	ldw %r1, [%r0]; inc %r0; inc %r0;
	ldw %r2, [%r0]; inc %r0; inc %r0;
	ldw %r3, [%r0]; inc %r0; inc %r0;
	ldw %r4, [%r0];
	sub %r0, %r0;
	sub %r2, %r0, %r2;
	sub %r3, %r0, %r3;
	sub %r4, %r0, %r4;

	ldw %r6, #$01'00;
	ldb %r7, #0;
	ldb %r8, #0;
	jsr QuionApply; dec %r10;
	ldw %r0, #cameraXVector;
	stw %r6, [%r0]; inc %r0; inc %r0;
	stw %r7, [%r0]; inc %r0; inc %r0;
	stw %r8, [%r0];

	ldb %r6, #0;
	ldw %r7, #$01'00;
	ldb %r8, #0;
	jsr QuionApply; nop;
	ldw %r0, #cameraYVector;
	stw %r6, [%r0]; inc %r0; inc %r0;
	stw %r7, [%r0]; inc %r0; inc %r0;
	stw %r8, [%r0];

	ldb %r6, #0;
	ldb %r7, #0;
	ldw %r8, #$01'00;
	jsr QuionApply; nop;
	ldw %r0, #cameraZVector;
	stw %r6, [%r0]; inc %r0; inc %r0;
	stw %r7, [%r0]; inc %r0; inc %r0;
	stw %r8, [%r0];

	pul %r15; nop;
}

scope GetTestObjs: {
	ldb %r0, #testscenes.bunchacubes>>16; romb %r0;
	ldw %r14, #testscenes.bunchacubes;
	ldw %r1, #objBuffer;
	sub %r0, %r0; stw %r0, objCount;

	setl; {
		getb %r0; inc %r14;
		getbh %r0; inc %r14;
		xbr %r0; beq done; xbr %r0;

		stw %r0, [%r1]; inc %r1; inc %r1; // model

		getb %r0; inc %r14; getbh %r0; inc %r14;
		stw %r0, [%r1]; inc %r1; inc %r1; // x
		getb %r0; inc %r14; getbh %r0; inc %r14;
		stw %r0, [%r1]; inc %r1; inc %r1; // y
		getb %r0; inc %r14; getbh %r0; inc %r14;
		stw %r0, [%r1]; inc %r1; inc %r1; // z

		ldw %r0, #$01'00;
		stw %r0, [%r1]; inc %r1; inc %r1; // scale

		sub %r0, %r0;
		ldw %r2, #$01'00;
		stw %r2, [%r1]; inc %r1; inc %r1; // r
		stw %r0, [%r1]; inc %r1; inc %r1; // i
		stw %r0, [%r1]; inc %r1; inc %r1; // j
		stw %r0, [%r1]; inc %r1; inc %r1; // k

		ldw %r0, objCount;
		inc %r0;
		jmp [%r13]; sbk %r0;
	done:
	}
	rts; nop;
}

scope InitCounters: {
	sub %r0, %r0;
	stw %r0, itriCount;
	stw %r0, vertexCount;
	ldw %r0, #rasterList;
	stw %r0, rasterEndPtr;
	rts; nop;
}

scope GetTestRasters: {
	sub %r0, %r0;
	stw %r0, vertexCount;
	stw %r0, itriCount;
	rts; nop;

	psh %r11;

	ldw %r12, #verts.size;
	ldw %r14, #verts;
	ldb %r2, #verts>>16;

	ldw %r0, #vertexBuffer;
	ldb %r1, #vertexBuffer>>16;
	jsr RomCopy; nop;

	ldw %r12, #tris.size;
	ldw %r14, #tris;
	ldb %r2, #tris>>16;

	ldw %r0, #itriBuffer;
	ldb %r1, #itriBuffer>>16;
	jsr RomCopy; nop;

	ldw %r0, #verts.size/VERTEX.SIZE; stw %r0, vertexCount;
	ldw %r0, #tris.size/ITRI.SIZE; stw %r0, itriCount;

	pul %r15; nop;

	scope verts: {
		dw  $0000, +$0000,  $0000; db $01,$01; // 0
		dw  $0000, +$0000,  $0100; db $01,$01; // 1
		constant size(pc()-verts);
	}

	macro tri(variable a, variable b, variable c, variable co) {
		dw RFLAG.VALID | RFLAG.FLATRI;
		dw vertexBuffer+VERTEX.SIZE*a, vertexBuffer+VERTEX.SIZE*b, vertexBuffer+VERTEX.SIZE*c; db co; db 0;
		fill 6; // normal to be filled later
	}

	macro ttri(variable a, variable b, variable c, variable tx) {
		dw RFLAG.VALID | RFLAG.TEXTRI;
		dw vertexBuffer+VERTEX.SIZE*a, vertexBuffer+VERTEX.SIZE*b, vertexBuffer+VERTEX.SIZE*c;
		dw tx;
		fill 6; // to be filled later
	}

	macro bill(variable a, variable tx, variable rx, variable ry) {
		dw RFLAG.VALID | RFLAG.BILLBD;
		dw vertexBuffer+VERTEX.SIZE*a;
		db rx, ry;
		fill 2;
		dw tx;
		db 16, 16;
		dw $01'00, $01'00;
	}

	macro ground(variable a, variable tm) {
		dw RFLAG.VALID | RFLAG.GROUND;
		dw vertexBuffer+VERTEX.SIZE*a;
		fill 4;
		dw tm;
		fill 4;
		dw 0; // reference Z overwritten
	}

	scope tris: {
		// ground($01, $0000);
		// bill($01, $0024, $00, $19);
		bill($00, $0006, $00, $00);
		constant size(pc()-tris);
	}
}

scope JoyTest: {
	ldw %r1, #joy.BUTTON_L;
	ldw %r2, #joy.BUTTON_R;
	ldw %r0, joy.fx.p1.held;
	and %r1, %r0, %r1;
	bne spinL;
	and %r0, %r2;
	bne spinR;
	nop;

	ldw %r1, #joy.BUTTON_X;
	ldw %r2, #joy.BUTTON_A;
	ldw %r0, joy.fx.p1.held;
	and %r1, %r0, %r1;
	bne rollW;
	and %r0, %r2;
	bne rollC;
	nop;

	rts; nop;

spinL:
	ldw %r5, #+$00'ff;
	ldw %r6, #0;
	ldw %r7, #+$00'06;
	ldw %r8, #0;
	bch spinMain; nop;

spinR:
	ldw %r5, #+$00'ff;
	ldw %r6, #0;
	ldw %r7, #-$00'06;
	ldw %r8, #0;
	bch spinMain; nop;

rollW:
	ldw %r5, #+$00'ff;
	ldw %r6, #0;
	ldw %r7, #0;
	ldw %r8, #+$00'06;
	bch spinMain; nop;

rollC:
	ldw %r5, #+$00'ff;
	ldw %r6, #0;
	ldw %r7, #0;
	ldw %r8, #-$00'06;

spinMain:
	stw %r5, cameraSpin;
	stw %r6, cameraSpin+2;
	stw %r7, cameraSpin+4;
	stw %r8, cameraSpin+6;

	ldw %r9, #cameraSpin+ROTATION.RATE;
	ldw %r0, #$10'00;
	stw %r0, [%r9];
	addk(9,9, ROTATION.REPS - ROTATION.RATE);
	ldb %r0, #$01;
	stb %r0, [%r9];

	rts; nop;
}

scope HeckSpin: {
	psh %r11;
	ldw %r0, objCount;
	lsr %r0;
	sms %r0, w0;

	scope spinLoop: {
		lms %r0, w0;
		dec %r0;
		bmi end; sbk %r0;
		ldb %r6, #OBJ.SIZE;
		mlu %r0, %r6;
		ldw %r9, #objBuffer+OBJ.ROT_R;
		add %r9, %r0;
		psh %r9;
		ldw %r1, [%r9]; inc %r9; inc %r9;
		ldw %r2, [%r9]; inc %r9; inc %r9;
		ldw %r3, [%r9]; inc %r9; inc %r9;
		ldw %r4, [%r9];
		ldw %r5, #+$00'ff;
		ldw %r6, #+$00'07;
		ldw %r7, #+$00'05;
		ldw %r8, #+$00'0b;
		jsr QuionMul; nop;
		jsr QuionFastHat; nop;
		pul %r9;
		stw %r1, [%r9]; inc %r9; inc %r9;
		stw %r2, [%r9]; inc %r9; inc %r9;
		stw %r3, [%r9]; inc %r9; inc %r9;
		stw %r4, [%r9];
		bch spinLoop; nop;
	end:
	}
	pul %r15; nop;
}
