align_exact(4);
// %r1 - buffer address
// %r2 - buffer length
// returns length in %r0
scope StrToRam: {
	getb %r0; inc %r14;
	getbh %r12, %r0; inc %r14;
	sub %r0, %r12, %r2;
	cmov %r12, cs, %r2;
	movs %r3, %r12; beq end; nop;
	mov %r4, %r1;
	setl;
		getb %r0; inc %r14;
		stb %r0, [%r4];
		loop; inc %r4;
end:
	sub %r0, %r0;
	rts; add %r0, %r3;
}

// %r1 - buffer address
// %r2 - buffer length
// %romb:%r14 - format string
// the format string should be preceded by its own length
// as a word, not null-terminated
// returns length of output string in %r0
align_exact(4);
scope StrFormat: {
	addr.alloc70(retaddr, 2, 1);
	addr.alloc70(bytesleft, 2, 1);
	movs %r0, %r2;
	beq endearly; nop;
	getb %r0; inc %r14;
	mov %r3, %r1;
	add %r2, %r1;
	stw %r11, retaddr;
	getbh %r12, %r0; inc %r14;
	bch scanl.enter; inc %r12;
endearly:
	rts; nop;

	// %r3 - buffer start address
	// %r6 - format specifier
	// %r8 - value #$25 = #'%' OR local return address
	// %r9 - entire function return address
	// this is the largest possible number of iterations,
	// not the actual number
	scope scanl: {
	// if not %, just put the character
	// note that this "returns" to sretp
		getb %r0; inc %r14;
		sub %r0, %r8; bne put; add %r0, %r8;
		dec %r12; beq continue;
		bsr getformat; nop;
		ldw %r12, bytesleft;
	continue:
	enter:
		ldw %r13, #scanl;
		link #2;
		ldb %r8, #$25;
	sretp:
		loop; nop;
	}
end:
	sub %r0, %r1, %r3;
	ldw %r15, retaddr; nop;

	scope put: {
		cmp %r1, %r2;
		bcs noput; nop;
		stb %r0, [%r1];
	noput:
		rts; inc %r1;
	}

	// digits are stored right-to-left
	scope putdigit: {
		cmp %r7, %r2;
		bcs nodigit; nop;
		stb %r0, [%r7];
	nodigit:
		rts; dec %r7;
	}

	scope getformat: {
	// %r5: flags
	// ----~~~~----~~~~
	// -------------0#+
	// %r4: length
		tst %r12; beq endformat; nop;
		ldb %r4, #0;
		ldb %r5, #0;
		ldb %r7, #10;
		mov %r8, %r11;
		setl;
	floop:
		stw %r12, bytesleft;
		getb %r6; inc %r14;
		ldb %r0, #$23;
		sub %r0, %r6, %r0;
		beq itsAHash; dec %r0;       // $23 = #
		dec %r0;
		beq itsAPercent; nop;        // $23+2 = $25 = %
		sub %r0, #5;
		beq itsAStar; dec %r0;       // $25+5 = $2a = *
		beq itsAPlus; nop;           // $2a+1 = $2b = +
		sub %r0, #5;
		beq itsAZero; nop;           // $2b+5 = $30 = 0
		sub %r0, %r7;
		bcc itsADigit; add %r0, %r7; // $30-$39: digits
		ldb %r0, #$58;
		sub %r0, %r6;                // $58 = X
		beq itsHex; nop;
		ldb %r0, #$63;
		sub %r0, %r6, %r0;
		beq itsAChar; dec %r0;       // $63 = c
		beq itsDecimal; nop;         // $63+1 = $63 = d
		sub %r0, #5;
		beq itsDecimal; nop;         // $64+5 = $69 = i
		sub %r0, #7;
		beq itsAPointer; nop;        // $69+7 = $70 = p
		sub %r0, #3;
		beq itsAString; dec %r0;     // $70+3 = $73 = s
		dec %r0;
		beq itsUnsigned; nop;        // $73+2 = $75 = u
		sub %r0, #3;
		beq itsHex; nop;             // $75+3 = $78 = x
	fmtcontinue:
		loop; nop;
	endformat:
		rts; nop;

	itsAHash:
		with %r5; alt2;
		bch fmtcontinue; orr ?2;
	itsAPercent:
		bch put; add %r0, %r6;
	itsAStar:
		inc %r10; inc %r10;
		to %r4;
		bch fmtcontinue; ldw [%r10];
	itsAPlus:
		with %r5; alt2;
		bch fmtcontinue; orr ?1;

	itsAZero:
		dec %r4; bpl itsADigit; inc %r4;
		with %r5; alt2;
		bch fmtcontinue; orr ?4;

	itsADigit:
		mov %r6, %r4;
		mll %r7, %r6;
		with %r4;
		bch fmtcontinue; add %r0;

	itsAPointer:
	itsHex:
		bch hex; nop;
	itsAChar:
		jmp char; nop;
	itsAString:
		jmp string; nop;

	itsDecimal:
		scope decimal_i: {
			ldb %r6, #0;
			pul %r0;
			movs %r9, %r0;
			bpl decimal_main_j; nop;
			// '-'
			ldb %r6, #$2d;
			sub %r0, %r0;
			sub %r0, %r9;
			mov %r9, %r0;
			jmp decimal_main; stw %r0, [%r10];
		}
	itsUnsigned:
		scope decimal_u: {
			ldb %r6, #0;
			pul %r9;
		}
	decimal_main_j:
		jmp decimal_main; nop;

		scope octal: {
			pul %r0;
			ldb %r7, #0;
		getlength:
			lsr %r0; lsr %r0; lsr %r0;
			bne getlength; inc %r7;

			jsr numlengthadjust; nop;

			ldw %r5, [%r10];
			ldb %r6, #$30;
			setl; scope main: {
				and %r0, %r5, #$7;
				jsr putdigit; add %r0, %r6;
				lsr %r0, %r5; lsr %r0; lsr %r5, %r0;
				loop; nop;
			}

			jmp [%r8]; nop;
		}

		scope hex: {
			pul %r0;
			ldb %r7, #0;
		getlength:
			lsr %r0; lsr %r0; lsr %r0; lsr %r0;
			bne getlength; inc %r7;

			xbr %r6;
			and %r0, %r5, #2;
			beq +; nop; ldb %r0, #$24; orr %r6, %r0, %r6; +;
			jsr numlengthadjust; nop;

			// changes 'x'->'a','X'->'A'
			hib %r0, %r6;
			ldb %r6, #$17;
			sub %r6, %r0, %r6;
			// '0' + $0a to make up for the sub
			ldb %r4, #$3a;
			ldw %r5, [%r10];
			setl; scope main: {
				and %r0, %r5, #$f;
				sub %r0, #$a;
				cfrom cs, %r6, %r4; add %r0;
				jsr putdigit; nop;
				lsr %r0, %r5; lsr %r0; lsr %r0; lsr %r5, %r0;
				loop; nop;
			}

			jmp [%r8]; nop;
		}

		scope string: {
			add %r0, %r10, #4;
			ldw %r7, [%r0];
			jsr padleft; nop;
			pul %r7;
			pul %r12;
			setl;
				ldb %r0, [%r7];
				jsr put; inc %r7;
				loop; nop;
			jmp [%r8]; nop;
		}

		scope decimal_main: {
			lsr %r0, %r5; bcc noplus; nop;
		maybeplus:
			movs %r0, %r9; bmi noplus; nop;
			// '+'
			ldb %r6, #$2b;
		noplus:
			// that's right folks
			ldb %r7, #0;
			sub %r0, %r9, #10; bcc gotlength; inc %r7;
			ldb %r0, #99; sub %r0, %r9; bcs gotlength; inc %r7;
			ldw %r0, #999; sub %r0, %r9; bcs gotlength; inc %r7;
			ldw %r0, #9999; sub %r0, %r9; bcs gotlength; inc %r7;
			inc %r7;
		gotlength:
			jsr numlengthadjust; nop;
			ldw %r5, [%r10];

			setl; scope main: {
				ldw %r6, #$6667;
				// %r9 = %r5 / #10
				lsr %r0, %r5;
				mlf %r0, %r6;
				lsr %r9, %r0;
				// %r4 = (%r5 / #10) * #10
				ldb %r6, #10;
				mll %r0, %r9, %r6;
				// the difference of %r5 and the product above
				// is %r5 % #10
				sub %r0, %r5, %r4;
				// #'0'
				ldb %r6, #$30;
				jsr putdigit; add %r0, %r6;
				mov %r5, %r9;
				loop; nop;
			}
			jmp [%r8]; nop;
		}
	}


	// %r4 = column width
	// %r5 = flags
	// %r6 = prefix (+/-/$), if it exists, 0 otherwise
	// %r7  = digits in number
	scope numlengthadjust: {
		and %r0, %r5, #4;
		with %r11; beq zerosDisabled; to %r9;
		scope zerosEnabled: {
			lob %r0, %r6; beq noprefix; nop;
		prefixed:
			jsr put; nop;
			// dec %r4 unless it's already zero
			tst %r4; beq +; nop; dec %r4; +;
		noprefix:
			// %r7 = max(%r4,%r7)
			sub %r0, %r4, %r7;
			cmov %r7, cs, %r4;
			bch posadjust; nop;
		}

		scope zerosDisabled: {
			lob %r0, %r6; beq +; nop; inc %r7; +;
			bsr padleft; nop;
			lob %r0, %r6; beq noprefix;
		prefixed:
			jsr put; dec %r7;
		noprefix:
		}
	posadjust:
		mov %r12, %r7;
		add %r7, %r1;
		mov %r1, %r7;
		jmp [%r9]; dec %r7;
	}

	// %r4 = column width
	// %r7 = length of thing to print
	scope padleft: {
		// if the thing is too wide for the column,
		// don't pad
		sub %r12, %r4, %r7;
		beq dontpad; nop;
		bcc dontpad; nop;
		// if padding length > buffer length,
		// only pad to the end of the buffer
		sub %r0, %r2, %r3;
		sub %r0, %r12;
		bcs dopad; nop;
		add %r12, %r0;
		ldw %r11, #end;
	dopad:
		ldb %r0, #$5f;
		setl;
			stb %r0, [%r1];
			loop; inc %r1;
	dontpad:
		rts; nop;
	}

	scope char: {
		ldb %r7, #1;
		inc %r10;
		jsr padleft; inc %r10;
		mov %r11, %r8;
		jmp put; ldw %r0, [%r10];
	}
FEND:
}

