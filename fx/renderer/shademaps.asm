arch "arch/null.arch";

// this makes debugging easier i swear
align_exact(4);
scope shadeMaps: {
	db $0d,$21,$22,$23,$24,$25,$26,$27, $28,$29,$2a,$2b,$2c,$2d,$2e,$2f; // hue 00: testing palette
	//  -8  -7  -6  -5  -4  -3  -2  -1    0   1   2   3   4   5   6   7
	db $01,$01,$01,$01,$11,$11,$11,$11, $21,$21,$21,$21,$31,$31,$31,$31; // texture hue 01: black-brown
	db $02,$02,$02,$02,$12,$12,$12,$12, $22,$22,$22,$22,$32,$32,$32,$32; // texture hue 02: dark brown
	db $03,$03,$03,$03,$13,$13,$13,$13, $23,$23,$23,$23,$33,$33,$33,$33; // texture hue 03: light brown
	db $04,$04,$04,$04,$14,$14,$14,$14, $24,$24,$24,$24,$34,$34,$34,$34; // texture hue 04: red
	db $05,$05,$05,$05,$15,$15,$15,$15, $25,$25,$25,$25,$35,$35,$35,$35; // texture hue 05: orange
	db $06,$06,$06,$06,$16,$16,$16,$16, $26,$26,$26,$26,$36,$36,$36,$36; // texture hue 06: yellow (green)
	db $07,$07,$07,$07,$17,$17,$17,$17, $27,$27,$27,$27,$37,$37,$37,$37; // texture hue 07: light green
	db $08,$08,$08,$08,$18,$18,$18,$18, $28,$28,$28,$28,$38,$38,$38,$38; // texture hue 08: dark green
	db $09,$09,$09,$09,$19,$19,$19,$19, $29,$29,$29,$29,$39,$39,$39,$39; // texture hue 09: light blue
	db $0a,$0a,$0a,$0a,$1a,$1a,$1a,$1a, $2a,$2a,$2a,$2a,$3a,$3a,$3a,$3a; // texture hue 0a: dark blue
	db $0b,$0b,$0b,$0b,$1b,$1b,$1b,$1b, $2b,$2b,$2b,$2b,$3b,$3b,$3b,$3b; // texture hue 0b: purple
	db $0c,$0c,$0c,$0c,$1c,$1c,$1c,$1c, $2c,$2c,$2c,$2c,$3c,$3c,$3c,$3c; // texture hue 0c: lavender
	db $0d,$0d,$0d,$0d,$1d,$1d,$1d,$1d, $2d,$2d,$2d,$2d,$3d,$3d,$3d,$3d; // texture hue 0d: pink
	db $0e,$0e,$0e,$0e,$1e,$1e,$1e,$1e, $2e,$2e,$2e,$2e,$3e,$3e,$3e,$3e; // texture hue 0e: light pink
	db $0f,$0f,$0f,$0f,$1f,$1f,$1f,$1f, $2f,$2f,$2f,$2f,$3f,$3f,$3f,$3f; // texture hue 0f: white

	db $03,$03,$03,$13,$13,$13,$22,$23, $23,$23,$23,$25,$25,$26,$26,$36; // hue 10: testing palette 2
	db $01,$01,$01,$11,$11,$02,$02,$21, $21,$21,$12,$22,$22,$13,$13,$23; // hue 11: black-brown
	db $01,$01,$02,$02,$02,$12,$12,$12, $12,$12,$13,$13,$23,$23,$23,$32; // hue 12: dark brown
	db $02,$12,$12,$03,$03,$13,$13,$23, $23,$23,$32,$32,$32,$33,$33,$35; // hue 13: light brown
	db $12,$04,$04,$04,$14,$14,$14,$24, $24,$34,$34,$34,$1e,$1e,$2e,$2e; // hue 14: red
	db $03,$13,$13,$05,$05,$15,$15,$25, $25,$25,$35,$35,$35,$36,$36,$36; // hue 15: orange
	db $08,$07,$06,$06,$16,$16,$16,$26, $26,$26,$26,$36,$36,$36,$36,$36; // hue 16: yellow (green)
	db $08,$08,$18,$18,$18,$28,$28,$27, $27,$27,$38,$38,$37,$37,$37,$36; // hue 17: light green
	db $02,$08,$08,$08,$18,$18,$28,$28, $28,$28,$27,$27,$27,$38,$38,$37; // hue 18: dark green
	db $0a,$0a,$09,$09,$19,$19,$19,$29, $29,$29,$29,$39,$39,$39,$3f,$3f; // hue 19: light blue
	db $0b,$0a,$0a,$0a,$1a,$1a,$1a,$2a, $2a,$2a,$2a,$29,$29,$29,$39,$39; // hue 1a: dark blue
	db $01,$0b,$0b,$1b,$1b,$1b,$2b,$2b, $2b,$2b,$1c,$1c,$1c,$2c,$2c,$3c; // hue 1b: purple
	db $0b,$0c,$0c,$0c,$1c,$1c,$1c,$2c, $2c,$2c,$3c,$3c,$3c,$3d,$3d,$3e; // hue 1c: lavender
	db $0c,$0c,$0d,$0d,$1d,$1d,$2d,$2d, $2d,$2d,$3d,$3d,$3d,$3e,$3e,$3e; // hue 1d: pink
	db $04,$14,$24,$0e,$0e,$1e,$1e,$1e, $2e,$2e,$2e,$3e,$3e,$3e,$3f,$3f; // hue 1e: light pink
	db $0f,$0f,$0f,$0f,$1f,$1f,$1f,$1f, $2f,$2f,$2f,$2f,$3f,$3f,$3f,$3f; // hue 1f: white
	db $01,$10,$10,$20,$20,$30,$30,$0f, $0f,$1f,$1f,$1f,$1f,$1f,$2f,$3f; // hue 20: light grey
	db $22,$31,$31,$23,$23,$32,$32,$33, $33,$33,$33,$35,$35,$35,$36,$36; // hue 21: beige
	db $01,$01,$01,$10,$10,$20,$20,$30, $30,$30,$0f,$0f,$0f,$1f,$2f,$3f; // hue 22: dark grey
}
