arch "arch/null.arch";
// ^ this file only contains macros, so it shouldn't have any
//   arch-dependent statements on its own

// aligns to 16-byte boundary, minus one byte,
// to make room for a cache instruction without
// putting the cache instruction itself in the cache
macro cachealign() {
	while pc() & $0f != $0f {
		// using $01 instead of `nop` to allow use in arch-neutral files
		db $01;
	}
}

macro scope align_exact(variable bits) {
	variable mask((1 << bits) - 1);
	while pc() & mask != 0 {
		// using $01 instead of `nop` to allow use in arch-neutral files
		db $01;
	}
}

macro scope string_constant(define s) {
	dw end-begin;
begin:
	db {s};
end:
}

macro mid_cache() {
	if pc() & $0f <= $0d {
		bch #($10 - (pc() & $0f) - 1); cache;
		while pc() & $0f != 0 {
			nop;
		}
	} else {
		while pc() & $0f != $0f {
			nop;
		}
		cache;
	}
}

macro r0_swap(define ra, define rb) {
	mov %r0, {ra};
	mov {ra}, {rb};
	mov {rb}, %r0;
}

macro scope funinfo(define lab) {
	variable end({lab}.FEND);

	print "{lab}: ";
	addr.print({lab});
	print "  # ... ";
	addr.print(end);
	print ". ", end-({lab}), " bytes.\n";
}

macro scope addk(define rd, define rs, variable k) {
	variable rdn({rd});
	variable rsn({rs});
	k = k & $ffff;

	if k > $8000 {
		subk({rd}, {rd}, -k);
	} else if rdn == rsn {
		if k == 0 {
			// no operation necessary
		} else if k == 1 {
			inc %r{rd};
		} else if k == 2 {
			inc %r{rd};
			inc %r{rd};
		} else if k < $10 {
			// %r0 - alt; add. 2 cycles (same as inc; inc).
			// otherwise - with; alt; add. 3 cycles (same as inc; inc; inc).
			add %r{rd}, #k;
		} else {
			add %r{rd}, #$f;
			addk({rd}, {rd}, k - $f);
		}
	} else {
		if k == 0 {
			mov %r{rd}, %r{rs};
		} else if k == 1 {
			// this is with; to; inc.
			// %r{rd} = %r0: shortest alternative is from; alt; add.
			// %r{rs} = %r0: shortest alternative is to; alt; add.
			// all others: shortest alternative is to; from; alt; add.
			mov %r{rd}, %r{rs};
			inc %r{rd};
		} else if k < $10 {
			// with mov-inc, k = 2 would be: with; to; inc; inc (4).
			// it goes up one cycle as k goes up one.
			// this is:
			//  %r{rd} = %r0: from; alt; add. (3)
			//  %r{rs} = %r0: to; alt; add. (3)
			//  all others:   to; from; alt; add. (4)
			add %r{rd}, %r{rs}, #k;
		} else if k < $80 {
			ldb %r{rd}, #k;      // 2
			// %r{rd} = %r0: add. (1)
			// all others:   with; add. (2)
			// total is 3/4.
			add %r{rd}, %r{rs};
		} else {
			ldw %r{rd}, #k;     // 3
			// %r{rd} = %r0: add. (1)
			// all others:   with; add. (2)
			// total is 4/5.
			add %r{rd}, %r{rs};
		}
	}
}

macro scope subk(define rd, define rs, variable k) {
	variable rdn({rd});
	variable rsn({rs});
	k = k & $ffff;

	// -$8000 = $8000,
	// so we still sub it.
	if k > $8000 {
		addk({rd}, {rs}, -k);
	} else if rdn == rsn {
		if k == 0 {
			// no operation necessary
		} else if k == 1 {
			dec %r{rd};
		} else if k == 2 {
			dec %r{rd};
			dec %r{rd};
		} else if k < $10 {
			sub %r{rd}, #k;
		} else {
			sub %r{rd}, #$f;
			subk({rd}, {rd}, k - $f);
		}
	} else {
		if k == 0 {
			mov %r{rd}, %r{rs};
		} else if k == 1 {
			mov %r{rd}, %r{rs};
			dec %r{rd};
		} else if k < $10 {
			sub %r{rd}, %r{rs}, #k;
		} else if k <= $80 {
			ldb %r{rd}, #-k;
			add %r{rd}, %r{rs};
		} else {
			ldw %r{rd}, #-k;
			add %r{rd}, %r{rs};
		}
	}
}
