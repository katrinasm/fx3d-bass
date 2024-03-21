arch "arch/null.arch";

constant MAX_OBJS(128);
// an obj consists of:
scope OBJ {
	constant MODEL_ID(0);  // u16
	constant POS_X(2);     // i16
	constant POS_Y(4);     // i16
	constant POS_Z(6);     // i16
	constant SCALE(8);     // i8.8
	constant ROT_R(10);    // i8.8
	constant ROT_I(12);    // i8.8
	constant ROT_J(14);    // i8.8
	constant ROT_K(16);    // i8.8
	constant SIZE(18);
}

constant POLY_K(512);

constant MAX_VERTICES(3*POLY_K);
scope VERTEX {
	constant POS_X(0); // 16 bits; various formats
	constant POS_Y(2); // 16 bits; various formats
	constant POS_Z(4); // 16 bits; various formats
	constant TEX_U(6); // u8
	constant TEX_V(7); // u8
	constant SIZE(8);
}

constant MAX_RASTERS(POLY_K*2);
scope RASTER {
	constant FLAGS($00);     // u16
	constant REF_LOC($02);   // *point
	constant REF_Z($0e);     // coordinate
	constant SIZE(16);
}

constant MAX_ITRIS(POLY_K);
scope ITRI {
	constant FLAGS($00);     // u16
	constant POINT_A($02);   // *point
	constant POINT_B($04);   // *point
	constant POINT_C($06);   // *point
	constant CTEX($08);      // u16
	constant UV_DATA($0a)    // *uvdata
	constant SHADE($0c);     // u8
	constant SIZE(16);
}

constant TRI_DATA_LEN(POLY_K*MDATA.SIZE/8);

scope MDATA {
	constant Y1($00);
	constant LFT_X($02);
	constant RGT_X($04);
	constant LFT_MF($06);
	constant LFT_MI($08);
	constant RGT_MF($0a);
	constant RGT_MI($0c);

	constant Y2($0e);
	constant HAND($10);
	constant BTM_X($12);
	constant BTM_MF($14);
	constant BTM_MI($16);
	constant SIZE($18);
}

scope UVDATA {
	constant LFT_Z( $00);
	constant LFT_ZD($04);
	constant LFT_U( $08);
	constant LFT_UD($0c);
	constant LFT_V( $10);
	constant LFT_VD($14);

	constant RGT_Z( $18);
	constant RGT_ZD($1c);
	constant RGT_U( $20);
	constant RGT_UD($24);
	constant RGT_V( $28);
	constant RGT_VD($2c);

	constant BTM_Z( $30);
	constant BTM_ZD($34);
	constant BTM_U( $38);
	constant BTM_UD($3c);
	constant BTM_V( $40);
	constant BTM_VD($44);

	constant SIZE($48);
}

scope BILLBOARD {
	constant FLAGS($00);     // u16
	constant REF_LOC($02);   // *point
	constant RELOC_X($04);   // i8
	constant RELOC_Y($05);   // i8
	constant FLIP_X($06);    // bool
	constant SCREEN_X($04);  // u8 (replaces RELOC_X)
	constant WIDTH($05);     // i8 (replaces RELOC_Y)
	constant SCREEN_Y($06);  // u8 (replaces FLIP_X)
	constant HEIGHT($07);    // u8
	constant TEX($08);       // u16
	constant TEX_U($08);     // u8 (replaces TEX)
	constant TEX_V($09);     // u8 (replaces TEX)
	constant TEX_K($0a);     // u8
	constant PAL($0b);       // u8
	constant DELTA_U($0c);   // i8.8
	constant REF_Z($0e);     // coordinate
	constant SIZE(16);
}

scope REN_STR {
	constant FLAGS($00);      // u16
	constant REF_LOC($02);    // *point
	constant STR_BEGIN($04);  // *u8
	constant STR_END($06);    // *u8
	constant FONT($08);       // u8
	constant WIDTH($09);      // u8
	constant RSTR_BEGIN($0a); // *(*const character)
	constant LEN($0c);        // u16
	constant REF_Z($0e);      // coordinate
}

// scope GROUND_LAYER {
	// constant FLAGS($00);     // u16
	// constant REF_LOC($02);   // *point
	// constant TILEMAP($08);   // *const tilemap
	// constant REF_Z($0e);     // coordinate
// }

scope RFLAG {
	constant TYPE(  0b0000'0000'0000'1100);
	constant VALID( 0b0000'0000'0000'0001);

	// constant GROUND(0b0000'0000'0000'0000);
	constant REN_STR(0b0000'0000'0000'0000);
	constant BILLBD(0b0000'0000'0000'0100);
	constant FLATRI(0b0000'0000'0000'1000);
	constant TEXTRI(0b0000'0000'0000'1100);

	constant TEXTURE_BIT(0b0000'0000'0000'0100);
	constant TRIANGLE_BIT(0b0000'0000'0000'1000);
}

addr.alloc70(objCount, 2, 1);
addr.alloc70(rasterEndPtr, 2, 1);
addr.alloc70(rasterBtmPtr, 2, 1);
addr.alloc70(vertexCount, 2, 1);
addr.alloc70(itriCount, 2, 1);
addr.alloc70(triDataEndPtr, 2, 1);

addr.alloc70(camera, OBJ.SIZE, 1);
addr.alloc70(cameraSpin, ROTATION.SIZE, 1);
addr.alloc70(lightVector, 8, 1);
addr.alloc70(cameraXVector, 6, 1);
addr.alloc70(cameraYVector, 6, 1);
addr.alloc70(cameraZVector, 6, 1);

addr.alloc70(objBuffer, OBJ.SIZE * MAX_OBJS, 8);
addr.alloc70(rasterList, 2 * MAX_RASTERS, 4);
addr.alloc70(vertexBuffer, VERTEX.SIZE * MAX_VERTICES, 4);
addr.alloc70(itriBuffer, ITRI.SIZE * MAX_ITRIS, 4);
addr.alloc70(triDataBuffer, TRI_DATA_LEN, 4);

constant MSG_LENGTH(280);
addr.alloc70(mainMsgGlyphLen, 2, 4);
addr.alloc70(mainMsgGlyphBuf, MSG_LENGTH * 2, 1);

if {defined PRINTLABELS} {
addr.printlab(camera);
addr.printlab(cameraSpin);

addr.printlab(objCount);
addr.printlab(rasterEndPtr);
addr.printlab(rasterBtmPtr);
addr.printlab(vertexCount);
addr.printlab(itriCount);

addr.printlab(objBuffer);
addr.printlab(rasterList);
addr.printlab(vertexBuffer);
addr.printlab(itriBuffer);
addr.printlab(triDataBuffer);

addr.printlab(mainMsgGlyphBuf);
}

scope renderer {
	include "tests/include.asm";
	include "shademaps.asm";
	// we align to some ridiculous value so that our labels don't shift around too much just by
	// editing our tests or shade maps
	arch "arch/fx.arch";
	align_exact(12);
	include "model.asm";
	align_exact(12);
	include "renderer.asm";
}
