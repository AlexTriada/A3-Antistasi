/* -------------------------------------------------------------------------- */
/*                                   defines                                  */
/* -------------------------------------------------------------------------- */

#define SURRENDER_DISTANCE 50

/* -------------------------------------------------------------------------- */
/*                              local procedures                              */
/* -------------------------------------------------------------------------- */

private _fleeing = {

	params ["_unit", "_enemy"];

	if (isNull _enemy) exitWith {};

	if (_unit distance _enemy < SURRENDER_DISTANCE
		&& { vehicle _unit == _unit })
	then
	{
		[_unit] spawn A3A_fnc_surrenderAction;
	}
	else
	{
		if (_unit == leader _groupX)
		then
		{
			private _marker = (leader _groupX) getVariable "markerX";
			private _super = !(isNil "_marker") && { _marker in airportsX };

			if (vehicle _killer == _killer)
			then
			{
				[getPosASL _enemy, side _unit, "Normal", _super]
					remoteExec ["A3A_fnc_patrolCA", 2];
			}
			else
			{
				private _attackType = "Normal";

				if (vehicle _killer isKindOf "Air")
				then { _attackType = "Air"; };

				if (vehicle _killer isKindof "Tank")
				then { _attackType = "Tank"; };

				[getPosASL _enemy, side _unit, _attackType, _super]
					remoteExec ["A3A_fnc_patrolCA", 2];
			};
		};

		if (([primaryWeapon _unit] call BIS_fnc_baseWeapon) in allMachineGuns)
		then { [_unit, _enemy] call A3A_fnc_suppressingFire; }
		else { [_unit, _unit, _enemy] spawn A3A_fnc_chargeWithSmoke; };
	};
};

private _notFleeing = {

	params ["_unit", "_enemy"];

	if (isNull _enemy)
	then
	{
		if (sunOrMoon < 1
			&& { !haveNV
			&& { hasIFA
			&& { (typeOf _unit) in squadLeaders
			|| { count (getArray (configfile >> "CfgWeapons" >>
				primaryWeapon _unit >> "muzzles")) == 2 } }}})
		then { [_unit] spawn A3A_fnc_useFlares; };
	}
	else
	{
		if (([primaryWeapon _unit] call BIS_fnc_baseWeapon) in allMachineGuns)
		then
		{
			[_unit, _enemy] spawn A3A_fnc_suppressingFire;
		}
		else
		{
			if (sunOrMoon == 1 || { haveNV })
			then
			{
				[_unit, _unit, _enemy] spawn A3A_fnc_chargeWithSmoke;
			}
			else
			{
				if (hasIFA
					&& { (typeOf _unit) in squadLeaders
					|| { count (getArray (configfile >> "CfgWeapons" >>
						primaryWeapon _unit >> "muzzles")) == 2 }})
				then { [_unit, _enemy] spawn A3A_fnc_useFlares; };
			};
		};
	};
}

/* -------------------------------------------------------------------------- */
/*                                    main                                    */
/* -------------------------------------------------------------------------- */

params ["_groupX", "_killer"];

{
	if ([_x] call A3A_fnc_canFight)
	then
	{
		if (fleeing _x)
		then { [_x, _x findNearestEnemy _x] call _fleeing; }
		else { [_x, _x findNearestEnemy _x] call _notFleeing; };
	};

	sleep 1 + (random 1);
} forEach (units _groupX);
