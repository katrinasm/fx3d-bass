arch "arch/null.arch";

constant SCREEN_W(224);
constant SCREEN_H(160);

constant CMODE_OBJ($10);
constant CMODE_FIX_HIGH_N($08);
constant CMODE_USE_HIGH_N($04);
constant CMODE_DITHER($02);
constant CMODE_PLOT_0($01);

scope fx {
	addr.alloczp(screenmode, 1);
	addr.alloczp(pausemode, 1);
	addr.alloc70(physicFieldCount, 2, 1);
	addr.alloc6k(deathFlag, 2);

	include "fxmacros.asm";

	arch "arch/fx.arch";
	include "./boot_calls.asm";
	include "./frame_buffer.asm";
	include "./mem.asm";
	include "./quion_vector.asm";
	include "./sort.asm";
	include "./alloc.asm";
	include "./text.asm";
	include "./strings.asm";
	include "./actor/include.asm";
	include "./renderer/include.asm";
}
