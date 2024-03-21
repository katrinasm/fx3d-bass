//
// Macros for use in handling the particularities of the SNES
// that bass doesn't handle on its own.
//
scope addr: {

	constant stacktop($1fff)

	// Translates a LoROM address to a pc file offset.
	// This doesn't work quite right if anything crosses a bank boundary
	// - it overflows from $ffff to $0000 instead of $ffff to $8000,
	// which is what it should do, but bass has no way to fix that.
	macro seek(evaluate offset) {
		if {offset} < $40'0000 {
			origin (({offset} & $7fff) | (({offset} & $3f'0000) >> 1))
			base {offset}
		} else {
			origin ({offset} & $1f'ffff)
			base {offset}
		}
	}

	// If the PC is not currently aligned to the start of a bank,
	// move to the next bank.
	// This is useful for storing large power-of-two sized data structures.
	macro alignbank() {
		addr.seek((pc() & $ff8000) + $010000)
	}

	// Prints a 24-bit address in hexadecimal, a feature which bass,
	// for some reason, does not have.
	macro scope print(evaluate addr) {
		variable i(0);
		variable c(0);
		print "$"
		while i < 6 {
			c = ({addr} >> (4 * (5-i))) & $0f;

			if c < 10 {
				putchar(c + 48);
			} else {
				putchar(c - 10 + 97);
			}

			i = i + 1;
		}
	}

	macro println(evaluate addr) {
		addr.print({addr});
		print "\n";
	}

	macro printloc(define name, evaluate addr) {
		print "# {name}: ";
		addr.print({addr});
		print "\n";
	}

	macro printloc(define name) {
		addr.printloc({name}, pc());
	}

	macro printlab(define label) {
		print "{label}: ";
		addr.print({label});
		print "\n";
	}

	macro Jslp(ptr) {
		phk; pea .retp{#}-1;
		jmp [{ptr}];
		.retp{#}:;
	}

	macro child6k(define parent, define child, variable ofs) {
		constant {parent}.sc.{child}({parent}.sc + ofs);
		constant {parent}.fx.{child}({parent}.fx + ofs);
	}

	// Static memory allocation macros.
	//
	// The "targ" in these macros is a constant name
	// to define with an unused memory location.
	//
	// alloczp returns an address for use as direct page memory.
	//   Its use should be sparse.
	// allocmb gives an address for use as data bank memory.
	// alloc7e gives an address for use as long memory,
	//   intended for large long-lived data structures.

	constant firstzp($20);
	constant firstmb($0110);
	constant first6k($6200);
	constant first7e($7e2100);
	constant first70($702000);
	constant first71($710000);

	variable freezp($20);
	variable freemb($0110);
	variable free6k($6200);
	variable free7e($7e2100);
	variable free70($702000);
	variable free71($710000);
	macro alloczp(targ, variable size) {
		constant {targ}(addr.freezp);
		addr.freezp = addr.freezp + size;
		if addr.freezp > $ff {
			print "Direct page memory overflowed ({targ}, "
			addr.print(addr.freezp);
			print ")\n";
			error "(memory error)";
		}
	}
	macro allocmb(targ, variable size) {
		constant {targ}(addr.freemb);
		addr.freemb = addr.freemb + size;
		if addr.freemb > $1cff {
			print "Bank-mirrored memory overflowed ({targ}, "
			addr.print(addr.freemb);
			print ")\n";
			error "(memory error)";
		}
	}
	macro alloc6k(targ, variable size) {
		if addr.free6k & 1 != 0 {
			addr.free6k = addr.free6k + 1;
		}
		constant {targ}.sc(addr.free6k);
		constant {targ}.fx(addr.free6k-$6000+$70'0000);
		constant {targ}.long(addr.free6k-$6000+$70'0000);
		addr.free6k = addr.free6k + size;
		if addr.free6k > $7cff {
			print "Bank-mirrored memory $6000 overflowed ({targ}, "
			addr.print(addr.free6k);
			print ")\n";
			error "(memory error)";
		}
	}
	macro alloc7e(targ, variable size) {
		constant {targ}(addr.free7e);
		addr.free7e = addr.free7e + size;
		if addr.free7e > $7e7fff {
			print "Bank 7e static memory overflowed ({targ}, "
			addr.print(addr.free7e);
			print ")\n";
			error "(memory error)";
		}
	}
	macro alloc70(targ, variable size, variable alignment) {
		if addr.free70 & ((1 << alignment) - 1) != 0 {
			addr.free70 = (addr.free70 & ~((1 << alignment) - 1)) + (1 << alignment);
		}
		constant {targ}(addr.free70);
		constant {targ}.sc(addr.free70);
		constant {targ}.fx(addr.free70);
		constant {targ}.long(addr.free70);
		addr.free70 = addr.free70 + size;
		if addr.free70 >= $70e800 {
			print "Bank 70 static memory overflowed ({targ}, "
			addr.print(addr.free70);
			print ")\n";
			error "(memory error)";
		}
	}

	macro crossdecl(targ, variable address) {
		constant {targ}(address);
		constant {targ}.sc(address);
		constant {targ}.fx(address);
		constant {targ}.long(address);
	}

	// macro alloc71(targ, variable size, variable alignment) {
		// if addr.free71 & ((1 << alignment) - 1) != 0 {
			// addr.free71 = (addr.free71 & ~((1 << alignment) - 1)) + (1 << alignment);
		// }
		// constant {targ}(addr.free71);
		// constant {targ}.sc(addr.free71);
		// constant {targ}.fx(addr.free71);
		// constant {targ}.long(addr.free71);
		// addr.free71 = addr.free71 + size;
		// if addr.free71 > $71ffff {
			// print "Bank 71 static memory overflowed ({targ}, "
			// addr.print(addr.free71);
			// print ")\n";
			// error "(memory error)";
		// }
	// }
}