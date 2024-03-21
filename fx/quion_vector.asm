addr.alloc6k(quionSp, 2);
// %r1  - quion w
// %r2  - quion x
// %r3  - quion y
// %r4  - quion z
// %r6  - vector x
// %r7  - vector y
// %r8  - vector z
// product is placed in %r6-%r8
// preserves: %r1-%r4, %r5
// clobbers: %r0, %r9, %r12, %r13
scope QuionApply: {
	orr %r0, %r2, %r3;
	orr %r0, %r4;
	bne +; nop; rts; +;

	psh %r11;
	sms %r10, w0;
	mov %r9, %r4;
	mov %r13, %r6;

	// %r9  - quion z
	// %r13 - vector x

	// %r10 - product x
	// %r11 - product y
	// %r12 - product z

	// t = (2*q.xyz) × v

	// t.y = 2 * q.z * v.x
	add %r0, %r4, %r4;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r11, %r0, %r4;
	// t.z = -2 * q.y * v.x
	sub %r0, %r0; sub %r0, %r3; sub %r0, %r3;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r12, %r0, %r4;

	mov %r6, %r7;
	// t.z += 2 * q.x * v.y
	add %r0, %r2, %r2;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r12, %r0;

	// t.x = -2 * q.z * v.y
	sub %r0, %r0; sub %r0, %r9; sub %r0, %r9;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r10, %r0, %r4;

	mov %r6, %r8;
	// t.x += 2 * q.y * v.z
	add %r0, %r3, %r3;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r10, %r0;

	// t.y -= 2 * q.x * v.z
	add %r0, %r2, %r2;
	mll %r0, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r11, %r0;

	mov %r6, %r1;

	mll %r0, %r10, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r13, %r0;

	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r7, %r0;

	mll %r0, %r12, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r8, %r0;

	mov %r6, %r12;
	// v.x += q.y * t.z
	mll %r0, %r3, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r13, %r0;

	// v.y -= q.x * t.z
	mll %r0, %r2, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r7, %r0;

	mov %r6, %r10;
	// v.y += q.z * t.x;
	mll %r0, %r9, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r7, %r0;

	// v.z -= q.y * t.x;
	mll %r0, %r3, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r8, %r0;

	mov %r6, %r11;
	// v.z += q.x * t.y;
	mll %r0, %r2, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	add %r8, %r0;

	// v.x -= q.z * t.y;
	mll %r0, %r9, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4;
	sub %r6, %r13, %r0;

	mov %r4, %r9;
	lms %r10, w0;
	pul %r15; nop;
FEND:
}

// scope QuionApply: {
	// psh %r11;
	// ldb %r5, #0;
	// psh %r1;
	// psh %r2;
	// psh %r3;
	// stw %r4, [%r10]; dec %r10;
	// jsr QuionMul; dec %r10;
	// ldb %r8, #0; pul %r0; sub %r8, %r0;
	// ldb %r7, #0; pul %r0; sub %r7, %r0;
	// ldb %r6, #0; pul %r0; sub %r6, %r0;
	// pul %r5;

	// jsr QuionMul; nop;
	// pul %r15; nop;
// }

// %r1  - left w
// %r2  - left x
// %r3  - left y
// %r4  - left z
// %r5  - right w
// %r6  - right x
// %r7  - right y
// %r8  - right z
// product is placed in %r1-%r4

// w: lft.w * rgt.w - lft.x * rgt.x - lft.y * rgt.y - lft.z * rgt.z
// x: lft.w * rgt.x + lft.x * rgt.w + lft.y * rgt.z - lft.z * rgt.y
// y: lft.w * rgt.y - lft.x * rgt.z + lft.y * rgt.w + lft.z * rgt.x
// z: lft.w * rgt.z + lft.x * rgt.y - lft.y * rgt.x + lft.z * rgt.w
scope QuionMul: {
	psh %r11;
	stw %r10, quionSp.fx;
	mov %r9, %r4;
	mov %r11, %r6;
	mov %r6, %r1;

	// new mapping:
	// %r6  - left w
	// %r2  - left x
	// %r3  - left y
	// %r9  - left z

	// %r5  - right w
	// %r11 - right x
	// %r7  - right y
	// %r8  - right z

	// %r1  - product w
	// %r10 - product x
	// %r12 - product y
	// %r13 - product z

	// %r6  - current left item for multiply
	// %r4  - fractional part of product

	// product.w = lft.w * rgt.w
	mll %r0, %r5, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r1, %r0, %r4;
	// product.x = lft.w * rgt.x
	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r10, %r0, %r4;
	// product.y = lft.w * rgt.y
	mll %r0, %r7, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r12, %r0, %r4;
	// product.z = lft.w * rgt.z
	mll %r0, %r8, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r13, %r0, %r4;

	// left item: x
	mov %r6, %r2;

	// product.w -= lft.x * rgt.x
	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r1, %r0;
	// product.x += lft.x * rgt.w
	mll %r0, %r5, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r10, %r0;
	// product.y -= lft.x * rgt.z
	mll %r0, %r8, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r12, %r0;
	// product.z += lft.x * rgt.y
	mll %r0, %r7, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r13, %r0;

	// left item: y
	mov %r6, %r3;
	// product.w -= lft.y * rgt.y
	mll %r0, %r7, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r1, %r0;
	// product.x += lft.y * rgt.z
	mll %r0, %r8, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r10, %r0;
	// product.y += lft.x * rgt.w
	mll %r0, %r5, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r12, %r0;
	// product.z -= lft.x * rgt.x
	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r13, %r0;

	// left item: z
	mov %r6, %r9;
	// product.w -= lft.z * rgt.z
	mll %r0, %r8, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r1, %r0;
	// product.x -= lft.z * rgt.y
	mll %r0, %r7, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; sub %r2, %r10, %r0;
	// product.y += lft.z * rgt.x
	mll %r0, %r11, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r3, %r12, %r0;
	// product.z += lft.z * rgt.w
	mll %r0, %r5, %r6;
	lob %r0; xbr %r0; hib %r4; orr %r0, %r4; add %r4, %r13, %r0;

	ldw %r10, quionSp.fx;
	pul %r15; nop;
}

scope ROTATION {
	constant QUION(0);
	constant RATE(8);
	constant PROG(10);
	constant REPS(11);
	constant SIZE(12);
}
// %r8 - ptr to target quion
// %r9 - ptr to rotation
// returns zero flag clear if rotation actually performed
scope RotationApply: {
	addk(2, 9, ROTATION.RATE);
	ldw %r6, [%r2]; addk(2, 2, ROTATION.PROG - ROTATION.RATE);
	ldw %r0, [%r2];
	hib %r1, %r0;
	beq rotfinished;
	lob %r0; xbr %r0;
	ldw %r3, physicFieldCount;
	mll %r3, %r6;
	add %r0, %r4;
	hib %r0; stb %r0, [%r2];
	adc %r0, %r3, #0;
	beq noapply; inc %r2;
	psh %r11;
	psh %r8;
	cmp %r0, %r1;
	cmov %r0, cc, %r1;
	sub %r1, %r0;
	stb %r1, [%r2];
	psh %r9;
	psh %r0;
	ldw %r1, [%r8]; inc %r8; inc %r8;
	ldw %r2, [%r8]; inc %r8; inc %r8;
	ldw %r3, [%r8]; inc %r8; inc %r8;
	ldw %r4, [%r8];
spinloop:
	pul %r0;
	pul %r9; psh %r9;
	dec %r0; bmi loopdone; nop;
	stw %r0, [%r10]; dec %r10;
	ldw %r5, [%r9]; inc %r9; inc %r9;
	ldw %r6, [%r9]; inc %r9; inc %r9;
	ldw %r7, [%r9]; inc %r9; inc %r9;
	ldw %r8, [%r9];
	ldw %r11, #spinloop;
	jmp QuionMul; dec %r10;

noapply:
rotfinished:
	rts; sub %r0, %r0;

loopdone:
	pul %r9;
	jsr QuionFastHat; nop;
	pul %r8;
	stw %r1, [%r8]; inc %r8; inc %r8;
	stw %r2, [%r8]; inc %r8; inc %r8;
	stw %r3, [%r8]; inc %r8; inc %r8;
	stw %r4, [%r8];
	pul %r15; orr %r0, %r10;

FEND:
}

// %r1  - left w
// %r2  - left x
// %r3  - left y
// %r4  - left z
// returns q/|q| where q is the input quaternion.
// result in %r1-%r4
scope QuionFastHat: {
	mov %r7, %r4;

	mov %r6, %r4;
	mll %r0, %r6, %r6;
	mov %r5, %r4;

	mov %r6, %r3;
	mll %r6, %r6;
	add %r5, %r4;
	adc %r0, %r6;

	mov %r6, %r2;
	mll %r6, %r6;
	add %r5, %r4;
	adc %r0, %r6;

	mov %r6, %r1;
	mll %r6, %r6;
	add %r5, %r4;
	adc %r0, %r6;

	hib %r5; lob %r0; xbr %r0; orr %r0, %r5;

	ldw %r6, #$03'00;
	sub %r6, %r0;
	lsr %r6;

	mll %r0, %r1, %r6;
	hib %r4; lob %r0; xbr %r0; orr %r1, %r0, %r4;

	mll %r0, %r2, %r6;
	hib %r4; lob %r0; xbr %r0; orr %r2, %r0, %r4;

	mll %r0, %r3, %r6;
	hib %r4; lob %r0; xbr %r0; orr %r3, %r0, %r4;

	mll %r0, %r7, %r6;
	hib %r4; lob %r0; xbr %r0; orr %r4, %r0, %r4;

	rts; nop;
}

// %r1  - left x
// %r2  - left y
// %r3  - left z
// %r6  - right x
// %r7  - right y
// %r8  - right z
// product integer in %r0, fraction in %r5
scope Vec3Dot: {
	mov %r9, %r6;

	mll %r0, %r1, %r6;
	mov %r5, %r4;

	mov %r6, %r2;
	mll %r6, %r7, %r6;
	add %r5, %r4;
	adc %r0, %r6;

	mov %r6, %r3;
	mll %r6, %r8, %r6;
	add %r5, %r4;
	adc %r0, %r6;

	mov %r6, %r9;
	rts; nop;
}

// %r1  - left x
// %r2  - left y
// %r3  - left z
// %r6  - right x
// %r7  - right y
// %r8  - right z
// product in %r6-%r8
// both inputs destroyed
scope Vec3Cross: {
	rts; nop;
	// sms %r11, w0;

	// mll %r0, %r3, %r6;
	// hib %r4; lob %r0; xbr %r0; orr %r5, %r0, %r4;
	// mll %r0, %r2, %r6;
	// hib %r4; lob %r0; xbr %r0; orr %r9, %r0, %r4;

	// mov %r6, %r1;
	// mll %r0, %r7, %r6;
	// hib %r4; lob %r0; xbr %r0; orr %r0, %r4;
	// sub %r9, %r0, %r9;

	// mll %r0, %r8, %r6;
	// hib %r4; lob %r0; xbr %r0; orr %r0, %r4;
	// sub %r5, %r0;

	// mov %r6, %r8;
	// mll %r0, %r2, %r6;
	// hib %r4; lob %r0; xbr %r0; orr %r0, %r4;

	// mov %r6, %r7;
	// mll %r6, %r2, %r6;
	// hib %r4; lob %r6; xbr %r6; orr %r6, %r4;
	// sub %r6, %r0;

	// mov %r7, %r5;
	// mov %r8, %r9;
	// lms %r15, w0; nop;
}
