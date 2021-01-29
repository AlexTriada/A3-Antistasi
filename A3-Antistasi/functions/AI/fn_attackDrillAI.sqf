/* -------------------------------------------------------------------------- */
/*                                   defines                                  */
/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */
/*                                  functions                                 */
/* -------------------------------------------------------------------------- */

private _fnc_getFriendlySides = {
	private _side = side _group;

	if (_side in [Occupants, teamPlayer])
	then { [_side, civilian] }
	else { [_side] };
};

private _fnc_fillSupidArrays = {
	{
		_unit = _x;

		switch (true)
		do
		{
			case (!(alive _unit)): {};

			_unit setVariable ["maneuvering", false];
			_typeOfSoldier = _unit call A3A_fnc_typeOfSoldier;

			case (_typeOfSoldier == "Normal"):
			{
				_movable pushBack _unit;
				_flankers pushBack _unit;
			};

			case (_typeOfSoldier == "StaticMortar"):
			{
				_mortars pushBack _unit;
			};

			_movable pushBack _unit;
			_baseOfFire pushBack _unit;

			case (_typeOfSoldier == "StaticGunner"):
			{
				_mgs pushBack _unit;
			};
		};
	} forEach (units _group);

	if (count _mortars == 1)
	then
	{
		_mortars append ((units _group) select
			{ _x getVariable ["typeOfSoldier",""] == "StaticBase" });

		if (count _mortars > 1)
		then
		{
			_mortars spawn A3A_fnc_staticMGDrill;
		}
		else
		{
			_movable pushBack (_mortars # 0);
			_flankers pushBack (_mortars # 0);
		};
	};

	if (count _mgs == 1)
	then
	{
		_mgs append ((units _group) select
			{ _x getVariable ["typeOfSoldier",""] == "StaticBase" });

		if (count _mgs == 2)
		then
		{
			_mgs spawn A3A_fnc_staticMGDrill;
		}
		else
		{
			_movable pushBack (_mgs # 0);
			_flankers pushBack (_mgs # 0);
		};
	};

	_group setVariable ["movable", _movable];
	_group setVariable ["baseOfFire", _baseOfFire];
	_group setVariable ["flankers", _flankers];

	if (side _group == teamPlayer)
	then { _group setVariable ["autoRearmed", time + 300]; };

	{
		if (vehicle _x != _x
			&& { !((vehicle _x) isKindOf "Air")
			&& { (assignedVehicleRole _x) # 0 == "Cargo"
			&& { isNull (_group getVariable ["transporte", objNull]) }}})
		then { _group setVariable ["transporte", vehicle _x]; };
	} forEach units _group;

};

/* -------------------------------------------------------------------------- */
/*                                    start                                   */
/* -------------------------------------------------------------------------- */

private _group = _this;
_group setVariable ["taskX", "Patrol"];
private _mortars = [];
private _mgs = [];
private _movable = [leader _group];
private _baseOfFire = [leader _group];
private _flankers = [];
private "_typeOfSoldier";
private "_unit";

/* ------------------------------- fill arrays ------------------------------ */

private _objectives = _group call A3A_fnc_enemyList;
private _friendlies = call BIS_fnc_friendlySides;

call _fnc_fillSupidArrays;

/* ------------------------------ endless cycle ----------------------------- */

while { true }
do
{
	if !(isPlayer (leader _group))
	then
	{
		_movable = _movable select {[_x] call A3A_fnc_canFight};
		_baseOfFire = _baseOfFire select {[_x] call A3A_fnc_canFight};
		_flankers = _flankers select {[_x] call A3A_fnc_canFight};
		_objectives = _group call A3A_fnc_enemyList;
		_group setVariable ["objectivesX", _objectives];

		if !(_objectives isEqualTo [])
		then
		{
			_air = objNull;
			_tanksX = objNull;

			{
				_eny = assignedVehicle (_x # 4);

				if (_eny isKindOf "Tank")
				then
				{
					_tanksX = _eny;
				}
				else
				{
					if (_eny isKindOf "Air")
					then
					{
						if (count (weapons _eny) > 1)
						then { _air = _eny; };
					};
				};

				if (!(isNull _air) && { !(isNull _tanksX) }) exitWith {};
			} forEach _objectives;

			_LeaderX = leader _group;
			_allNearFriends = allUnits select { _x distance _LeaderX < (distanceSPWN / 2)
				&& { (side (group _x)) in _friendlies }};

			{
				_unit = _x;

				{
					_objectiveX = _x # 4;

					if (_LeaderX knowsAbout _objectiveX >= 1.4)
					then
					{
						_know = _unit knowsAbout _objectiveX;

						if (_know < 1.2)
						then { _unit reveal [_objectiveX, _know + 0.2]; };
					};
				} forEach _objectives;
			} forEach (_allNearFriends select {_x == leader _x}) - [_LeaderX];

			_numNearFriends = count _allNearFriends;
			_numObjectives = count _objectives;
			_taskX = _group getVariable ["taskX","Patrol"];
			_nearX = _group call A3A_fnc_nearEnemy;
			_soldiers = ((units _group) select {[_x] call A3A_fnc_canFight}) - [_group getVariable ["mortarX",objNull]];
			_numSoldiers = count _soldiers;

			if !(isNull _air)
			then
			{
				if (_allNearFriends findIf {(_x call A3A_fnc_typeOfSoldier == "AAMan")
					|| (_x call A3A_fnc_typeOfSoldier == "StaticGunner")} == -1)
				then
				{
					if (_side != teamPlayer)
					then {[getPosASL _LeaderX, _side, "Air", false] remoteExec ["A3A_fnc_patrolCA", 2]};
				};

				_group setVariable ["taskX", "Hide"];
				_taskX = "Hide";
			};

			if !(isNull _tanksX)
			then
			{
				if (_allNearFriends findIf {_x call A3A_fnc_typeOfSoldier == "ATMan"} == -1)
				then
				{
					_mortarX = _group getVariable ["mortarsX", objNull];

					if (!(isNull _mortarX) && { [_mortarX] call A3A_fnc_canFight })
					then
					{
						if (_allNearFriends findIf { _x distance _tanksX < 100 } == -1)
						then { [_mortarX, getPosASL _tanksX, 4] spawn A3A_fnc_mortarSupport; };
					}
					else
					{
						if (_side != teamPlayer)
						then
						{
							[getPosASL _LeaderX, _side, "Tank", false]
								remoteExec ["A3A_fnc_patrolCA", 2];
						};
					};
				};

				_group setVariable ["taskX","Hide"];
				_taskX = "Hide";
			};

			if (_numObjectives > 2*_numNearFriends)
			then
			{
				if !(isNull _nearX)
				then
				{
					if (_side != teamPlayer)
					then { [getPosASL _LeaderX, _side, "Normal", false] remoteExec ["A3A_fnc_patrolCA", 2]; };

					_mortarX = _group getVariable ["mortarsX", objNull];

					if (!(isNull _mortarX) && { [_mortarX] call A3A_fnc_canFight })
					then
					{
						if (_allNearFriends findIf { _x distance _nearX < 100 } == -1)
						then { [_mortarX, getPosASL _nearX, 1] spawn A3A_fnc_mortarSupport; };
					};
				};

				_group setVariable ["taskX", "Hide"];
				_taskX = "Hide";
			};

			_transporte = _group getVariable ["transporte", objNull];

			if (isNull (_group getVariable ["transporte", objNull]))
			then
			{
				_exit = false;

				{
					_veh = vehicle _x;

					if (_veh != _x
						&& { !(_veh isKindOf "Air")
						&& { (assignedVehicleRole _x) # 0 == "Cargo" }})
					then
					{
						_group setVariable ["transporte", _veh];
						_transporte = _veh;
						_exit = true;
					};

					if (_exit) exitWith {};

				} forEach units _group;
			};

			if !(isNull _transporte)
			then
			{
				if !(_transporte isKindOf "Tank")
				then
				{
					_driver = driver (_transporte);

					if !(isNull _driver)
					then { [_driver]  allowGetIn false; };
				};

				((units _group) select {(assignedVehicleRole _x) # 0 == "Cargo"})
					allowGetIn false;
			};

			if (_taskX == "Patrol")
			then
			{
				if (_nearX distance _LeaderX < 150
				&& { !(isNull _nearX) })
				then
				{
					_group setVariable ["taskX","Assault"];
					_taskX = "Assault";
				}
				else
				{
					if (_numObjectives > 1)
					then
					{
						_mortarX = _group getVariable ["mortarsX", objNull];

						if (!(isNull _mortarX)
							&& { [_mortarX] call A3A_fnc_canFight })
						then
						{
							if (_allNearFriends findIf { _x distance _nearX < 100 } == -1)
							then { [_mortarX, getPosASL _nearX, 1] spawn A3A_fnc_mortarSupport; };
						};
					};
				};
			};

			if (_taskX == "Assault")
			then
			{
				if (_nearX distance _LeaderX < 50)
				then
				{
					_group setVariable ["taskX","AssaultClose"];
					_taskX = "AssaultClose";
				}
				else
				{
					if (_nearX distance _LeaderX > 150)
					then
					{
						_group setVariable ["taskX", "Patrol"];
					}
					else
					{
						if !(isNull _nearX)
						then
						{
							{
								[_x, _nearX] call A3A_fnc_suppressingFire;
							} forEach _baseOfFire select { _x getVariable ["typeOfSoldier",""] == "MGMan"
								|| { _x getVariable ["typeOfSoldier", ""] == "StaticGunner" }};

							if (sunOrMoon < 1)
							then
							{
								if !(haveNV)
								then
								{
									if (hasIFA)
									then
									{
										if (([_LeaderX] call A3A_fnc_canFight)
											&& { (typeOf _LeaderX) in squadLeaders })
										then { [_LeaderX, _nearX] call A3A_fnc_useFlares; };
									}
									else
									{
										{
											[_x, _nearX] call A3A_fnc_suppressingFire;
										} forEach _baseOfFire select {(_x getVariable ["typeOfSoldier",""] == "Normal")
											&& { count (getArray (configfile >> "CfgWeapons" >> primaryWeapon _x >> "muzzles")) == 2 }};
									};
								};
							};
							_mortarX = _group getVariable ["mortarsX", objNull];

							if (!(isNull _mortarX) && { [_mortarX] call A3A_fnc_canFight })
							then
							{
								if (_allNearFriends findIf { _x distance _nearX < 100 } == -1)
								then { [_mortarX, getPosASL _nearX, 1] spawn A3A_fnc_mortarSupport; };
							};
						};
					};
				};
			};

			if (_taskX == "AssaultClose")
			then
			{
				if (_nearX distance _LeaderX > 150)
				then
				{
					_group setVariable ["taskX","Patrol"];
				}
				else
				{
					if (_nearX distance _LeaderX > 50)
					then
					{
						_group setVariable ["taskX","Assault"];
					}
					else
					{
						if !(isNull _nearX)
						then
						{
							_flankers = _flankers select {!(_x getVariable ["maneuvering",false])};
							if (count _flankers != 0) then
								{
								{
								[_x,_x,_nearX] spawn A3A_fnc_chargeWithSmoke;
								} forEach (_baseOfFire select {(_x getVariable ["typeOfSoldier",""] == "Normal")});
								if ([getPosASL _nearX] call A3A_fnc_isBuildingPosition) then
									{
									_engineerX = objNull;
									_building = nearestBuilding _nearX;
									if !(_building getVariable ["assaulted",false]) then
										{
										{
										if ((_x call A3A_fnc_typeOfSoldier == "Engineer") and {_x != leader _x} and {!(_x getVariable ["maneuvering",true])} and {_x distance _nearX < 50}) exitWith {_engineerX = _x};
										} forEach _baseOfFire;
										if !(isNull _engineerX) then
											{
											[_engineerX,_nearX,_building] spawn A3A_fnc_destroyBuilding;
											}
										else
											{
											[[_flankers,_nearX] call BIS_fnc_nearestPosition,_nearX,_building] spawn A3A_fnc_assaultBuilding;
											};
										};
									}
								else
									{
									[_flankers,_nearX] spawn A3A_fnc_doFlank;
									};
								};
							};
					};
				};
			};

			if (_taskX == "Hide") then
				{
				if ((isNull _tanksX) and {isNull _air} and {_numObjectives <= 2*_numNearFriends}) then
					{
					_group setVariable ["taskX","Patrol"];
					}
				else
					{
					_movable = _movable select {!(_x getVariable ["maneuvering",false])};
					_movable spawn A3A_fnc_hideInBuilding;
					};
				};
		}
		else
			{
			if (_group getVariable ["taskX","Patrol"] != "Patrol") then
				{
				if (_group getVariable ["taskX","Patrol"] == "Hide") then {_group call A3A_fnc_recallGroup};
				_group setVariable ["taskX","Patrol"];
				};
			if (side _group == teamPlayer) then
				{
				if (time >= _group getVariable ["autoRearm",time]) then
					{
					_group setVariable ["autoRearm",time + 120];
					{[_x] spawn A3A_fnc_autoRearm; sleep 1} forEach (_movable select {!(_x getVariable ["maneuvering",false])});
					};
				};
			if !(isNull(_group getVariable ["transporte",objNull])) then
				{
				(units _group select {vehicle _x == _x}) allowGetIn true;
				};
			};
		//diag_log format ["taskX:%1.Movable:%2.Base:%3.Flankers:%4",_group getVariable "taskX",_group getVariable "movable",_group getVariable "baseOfFire",_group getVariable "flankers"];
		sleep 30;
		_movable =  (_group getVariable ["movable",[]]) select {alive _x};
		if ((_movable isEqualTo []) or (isNull _group)) exitWith {};
		_group setVariable ["movable",_movable];
		_baseOfFire = (_group getVariable ["baseOfFire",[]]) select {alive _x};
		_group setVariable ["baseOfFire",_baseOfFire];
		_flankers = (_group getVariable ["flankers",[]]) select {alive _x};
		_group setVariable ["flankers",_flankers];
	};
};
