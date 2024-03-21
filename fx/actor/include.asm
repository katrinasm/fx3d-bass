scope actor {
	scope ACTOR {
		constant SELF_DATA(0);
		constant BOUNDING_HEIGHT(28);
		constant BOUNDING_RADIUS(30);
		constant VIZ_FLAGS(32);
		constant VIZ_FRAME(34);
		constant VIZ_ID(36);
		constant POS_X(38);
		constant POS_Y(40);
		constant POS_Z(42);
		constant POS_XF(44);
		constant POS_YF(46);
		constant POS_ZF(48);
		constant SPD_X(50);
		constant SPD_Y(52);
		constant SPD_Z(54);
		constant FN_0(56);
		constant FN_1(58);
		constant DROP(60);
		constant FLAGS(62);
		constant SIZE(64);
	}

	scope VIZ_FLAG {
		constant FACING_X(0b0000'0000'0000'0001);
		constant FACING_Z(0b0000'0000'0000'0010);
	}

	scope ACTOR_FLAGS {
		constant COLLIDES_WITH_ACTORS(0b1000'0000'0000'0000);
		constant COLLIDES_WITH_WORLD(0b0100'0000'0000'0000);
		constant NO_GRAVITY(0b0010'0000'0000'0000);
		constant DROP(0b0000'0000'1000'0000);
		constant STATIONARY(0b0000'0000'0100'0000);
	}

	constant MAX_ACTORS(64);
	addr.alloc70(actorCount, 2, 1);
	addr.alloc70(actorList, ACTOR.SIZE*2, 1);
	addr.alloc70(actorBuffer, ACTOR.SIZE*MAX_ACTORS, 4);

	scope SPAWN_RQ {
		constant ID(0);
		constant POS_X(2);
		constant POS_Y(4);
		constant POS_Z(6);
		constant PARAMS(8); // 4 bytes
		constant SIZE(12);
	}
	constant MAX_SPAWN_RQS(8);

	addr.alloc70(spawnRqCount, 2, 1);
	addr.alloc70(spawnRqBuffer, SPAWN_RQ.SIZE*MAX_SPAWN_RQS, 1);

	include "handlers.asm";
	include "movement.asm";
	include "actors.asm";
}

