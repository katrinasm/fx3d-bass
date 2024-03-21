arch "arch/null.arch";

scope tex {
	constant HEADER_CMODE(0);
	constant HEADER_UVMASK(1);
	constant HEADER_ADDR(3);
	constant HEADER_ADDRK(5);
	constant HEADER_COLOR(6);

	constant DEFAULT_CMODE($08);
	macro texheader(variable addr, variable co, variable w, variable h, variable cm) {
		db cm | DEFAULT_CMODE; // 0
		db w-1;                // 1
		db h-1;                // 2
		dl addr;               // 3
		db co;                 // 6
		fill 9;                // 7...
	}

	macro texempty() {
		texheader(genbank+$ff'ff, $00,  1,  1, 0);
	}

	headers: {
		// $00: 16-color gradients
		texheader(genbank+$00'00, $11, 16, 16, 0);
		// $01: checkerboard
		texheader(genbank+$10'00, $25, 16, 16, 0);
		// $02: larger 16-color gradients
		texheader(genbank+$00'10, $11, 32, 32, 0);
		// $03: billboard origin pointer
		texheader(genbank+$20'00, $bd, 16, 16, 0);
		// $04: sample protagonist
		texheader(genbank+$00'20, $00, 32, 32, 0);
		// $05: sample 2
		texheader(genbank+$00'40, $00, 32, 32, 0);
		// $06: sample 3
		texheader(genbank+$00'60, $00, 32, 32, 0);
		// $07: skybox sample
		texheader(genbank+$40'00, $00, 64, 64, 0);

		// $08: horizontal lines 1234
		texheader(genbank+$01'00, $14,   1,  4, 0);
		// $09: horizontal lines 5678
		texheader(genbank+$05'00, $58,   1,  4, 0);
		// $0a: horizontal lines 9abc
		texheader(genbank+$09'00, $9c,   1,  4, 0);
		// $0b: horizontal lines cdef
		texheader(genbank+$0c'00, $cf,   1,  4, 0);

		// $0c: test cube sides
		texheader(genbank+$30'00, $00, 64, 16, 0);
		// $0d: test cube top
		texheader(genbank+$30'40, $00, 16, 16, 0);
		// $0e: test cube bottom
		texheader(genbank+$30'50, $00, 16, 16, 0);
		// $07
		texempty();

		// $10: grass
		texheader(genbank+$80'00, $07, 32, 32, 0);
		// $11: hanging grass
		texheader(genbank+$80'60, $11, 16, 16, 0);
		// $12: wall
		texheader(genbank+$80'30, $03, 32, 32, 0);
		// $13: bottom wall
		texheader(genbank+$a0'30, $03, 32, 32, 0);

		// $14
		texempty();
		// $15
		texempty();
		// $16
		texempty();
		// $17: wide fence
		texheader(genbank+$80'40, $00, 64, 32, 0);
		// $18: lamppost
		texheader(genbank+$40'60, $00, 16, 64, 0);
		// $19: fence
		texheader(genbank+$40'40, $00, 32, 32, 0);
		// $1a: subway times
		texheader(genbank+$80'00, $00, 64, 32, 0);
		// $1b: smoov sign strawberry
		texheader(genbank+$a0'00, $00, 32, 32, 0);
		// $1c: smoov sign text
		texheader(genbank+$a0'20, $00, 64, 32, 0);
		// $1d
		texempty();
		// $1e
		texempty();
		// $1f
		texempty();

		// $20: school uniform standing front
		texheader(chabank+$40'00, $00, 32, 32, 0);
		// $21: school uniform standing back
		texheader(chabank+$40'80, $00, 32, 32, 0);
		// $22: school uniform walking 1 front
		texheader(chabank+$40'20, $00, 32, 32, 0);
		// $23: school uniform walking 1 back
		texheader(chabank+$40'a0, $00, 32, 32, 0);
		// $24: school uniform walking 2 front
		texheader(chabank+$40'40, $00, 32, 32, 0);
		// $25: school uniform walking 2 back
		texheader(chabank+$40'c0, $00, 32, 32, 0);
		// $26
		texempty();
		// $27
		texempty();
		// $28: school uniform running 0 front
		texheader(chabank+$60'00, $00, 32, 32, 0);
		// $29: school uniform running 0 back
		texheader(chabank+$60'80, $00, 32, 32, 0);
		// $2a: school uniform running 1 front
		texheader(chabank+$60'20, $00, 32, 32, 0);
		// $2b: school uniform running 1 back
		texheader(chabank+$60'a0, $00, 32, 32, 0);
		// $2c: school uniform running 2 front
		texheader(chabank+$60'40, $00, 32, 32, 0);
		// $2d: school uniform running 2 back
		texheader(chabank+$60'c0, $00, 32, 32, 0);
		// $2e: school uniform running 3 front
		texheader(chabank+$60'60, $00, 32, 32, 0);
		// $2f: school uniform running 3 back
		texheader(chabank+$60'e0, $00, 32, 32, 0);
		// $30: unimplemented alt standing front
		texheader(chabank+$80'00, $00, 32, 32, 0);
		// $31: unimplemented alt standing back
		texheader(chabank+$80'80, $00, 32, 32, 0);
		// $32: unimplemented alt walking 1 front
		texheader(chabank+$80'20, $00, 32, 32, 0);
		// $33: unimplemented alt walking 1 back
		texheader(chabank+$80'a0, $00, 32, 32, 0);
		// $34: unimplemented alt walking 2 front
		texheader(chabank+$80'40, $00, 32, 32, 0);
		// $35: unimplemented alt walking 2 back
		texheader(chabank+$80'c0, $00, 32, 32, 0);
		// $36
		texempty();
		// $37
		texempty();

		// $38: unimplemented alt running 0 front
		texheader(chabank+$a0'00, $00, 32, 32, 0);
		// $39: unimplemented alt running 0 back
		texheader(chabank+$a0'80, $00, 32, 32, 0);
		// $3a: unimplemented alt running 1 front
		texheader(chabank+$a0'20, $00, 32, 32, 0);
		// $3b: unimplemented alt running 1 back
		texheader(chabank+$a0'a0, $00, 32, 32, 0);
		// $3c: unimplemented alt running 2 front
		texheader(chabank+$a0'40, $00, 32, 32, 0);
		// $3d: unimplemented alt running 2 back
		texheader(chabank+$a0'c0, $00, 32, 32, 0);
		// $3e: unimplemented alt running 3 front
		texheader(chabank+$a0'60, $00, 32, 32, 0);
		// $3f: unimplemented alt running 3 back
		texheader(chabank+$a0'e0, $00, 32, 32, 0);

		// $40: lynne's head
		texheader(chabank+$00'00, $00, 32, 32, 0);
		// $41: lynne's head back
		texheader(chabank+$00'80, $00, 32, 32, 0);
		// $42: pura's head
		texheader(chabank+$00'20, $00, 32, 32, 0);
		// $43: pura's head back
		texheader(chabank+$00'a0, $00, 32, 32, 0);
		// $44: emi's head
		texheader(chabank+$00'40, $00, 32, 32, 0);
		// $45: emi's head back
		texheader(chabank+$00'c0, $00, 32, 32, 0);
		// $46: green head
		texheader(chabank+$00'60, $00, 32, 32, 0);
		// $47: green head back
		texheader(chabank+$00'e0, $00, 32, 32, 0);
	}

	addr.seek((pc() + $ffff) & $ff0000);
	insert genbank, "res/genbank.bin";
	addr.seek((pc() + $ffff) & $ff0000);
	insert chabank, "res/chabank.bin";
}
