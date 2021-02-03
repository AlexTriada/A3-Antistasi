if (isDedicated) exitWith {};

private _oldUnit = param [1];

if (isNull _oldUnit) exitWith {};

private _newUnit = param [0];

waitUntil { sleep 0.1; alive player };

/* -------------------------------------------------------------------------- */
/*                                   defines                                  */
/* -------------------------------------------------------------------------- */

#define GLOBAL 0
#define SERVER 2
#define FIRED_DIST 300
#define UNKNOWN 1.4
#define SIZE_MULT 1.5
// TODO localize
#define TITLE "Static Deployed"
#define TEXT_HINT1 "Static weapon has been deployed for use in a nearby zone, and will be used by garrison militia if you leave it here the next time the zone spawns"
#define REMOTE_TITLE "Remote AI"
#define REMOTE_TEXT "Died while remote controlling AI"

/* -------------------------------------------------------------------------- */
/*                               event handlers                               */
/* -------------------------------------------------------------------------- */

// When LAN hosting, Bohemia's Zeus module code will cause the player lose Zeus
// access if the body is deleted after respawning. This is a workaround that
// re-assigns curator to the player if their body is deleted. It will only run
// on LAN hosted MP, where the hoster is *always* admin, so we shouldn't run
// into any issues.
private _eh_deleted =
{
	[] spawn
	{
		// should ensure that the bug unassigns first
		sleep 1;
		{ player assignCurator _x; } forEach allCurators;
	};
};

private _eh_fired =
{
	_this spawn
	{
		private _unit = param [0];

		if !(captive _unit) exitWith {};

		if (allUnits findIf { (side _x) in [Occupants, Invaders]
				&& { _x distance player < FIRED_DIST }} != -1)
		then
		{
			[_unit, false] remoteExec ["setCaptive", GLOBAL, _unit];
		}
		else
		{
			private _city = [citiesX, _unit] call BIS_fnc_nearestPosition;
			private _size = [_city] call A3A_fnc_sizeMarker;
			private _data = server getVariable _city;

			if (random 100 >= _data # 2) exitWith {};
			if (_unit distance (getMarkerPos _city) >= _size * SIZE_MULT)
			exitWith {};

			private _vehicle = vehicle _unit;

			if (_vehicle == _unit)
			exitWith { [_unit, false] remoteExec ["setCaptive", GLOBAL, _unit]; };

			private _vehUnits = assignedCargo _vehicle + crew _vehicle;

			{
				if (isPlayer _x)
				then { [_x, false] remoteExec ["setCaptive", GLOBAL, _x]; };
			} forEach _vehUnits;
		};
	};
};

private _eh_inventoryOpened =
{
	_this spawn
	{
		private _playerX = param [0];

		if !(captive _playerX) exitWith {};

		private _containerX = param [1];
		private _typeX = typeOf _containerX;

		if !(_containerX isKindOf "CAManBase"
			&& { !(alive _containerX)
			|| { _typeX in [NATOAmmoBox, CSATAmmoBox] }}) exitWith {};

		if (allUnits findIf { (side _x) in  [Invaders, Occupants]
				&& { _x knowsAbout _playerX > UNKNOWN }} != -1)
		then
		{
			[_playerX, false] remoteExec ["setCaptive", GLOBAL, _playerX];
		}
		else
		{
			private _city = [citiesX, _playerX] call BIS_fnc_nearestPosition;
			private _size = [_city] call A3A_fnc_sizeMarker;
			private _dataX = server getVariable _city;

			if (random 100 >= _dataX # 2) exitWith {};
			if (_playerX distance (getMarkerPos _city) >= _size * SIZE_MULT)
			exitWith {};

			[_playerX, false] remoteExec ["setCaptive", GLOBAL, _playerX];
		};
	};

	false
};

private _eh_handleHeal =
{
	_this spawn
	{
		private _player = param [0];

		if !(captive _player) exitWith {};

		if (allUnits findIf { (side _x) in [Invaders, Occupants]
				&& { _x knowsAbout player > UNKNOWN }} != -1)
		then
		{
			[_player, false] remoteExec ["setCaptive", GLOBAL, _player];
		}
		else
		{
			private _city = [citiesX, _player] call BIS_fnc_nearestPosition;
			private _size = [_city] call A3A_fnc_sizeMarker;
			private _dataX = server getVariable _city;

			if (random 100 >= _dataX # 2) exitWith {};
			if (_player distance (getMarkerPos _city) >= _size * SIZE_MULT)
			exitWith {};

			[_player, false] remoteExec ["setCaptive", GLOBAL, _player];
		};
	};
};

private _eh_weaponAssembled =
{
	_this spawn
	{
		private _veh = param [1];
		[_veh, teamPlayer] call A3A_fnc_AIVEHinit;

		if !(_veh isKindOf "StaticWeapon") exitWith {};

		if !(_veh in staticsToSave)
		then
		{
			staticsToSave pushBack _veh;
			publicVariable "staticsToSave";
		};

		_markersX = markersX select
			{ sidesX getVariable [_x, sideUnknown] == teamPlayer };
		_pos = position _veh;

		if (_markersX findIf { _pos inArea _x } != -1)
		then { [TITLE, TEXT_HINT1] call A3A_fnc_customHint; };
	};
};

private _eh_weaponDisassembled =
{
	[param [1]] remoteExec ["A3A_fnc_postmortem", SERVER];
	[param [2]] remoteExec ["A3A_fnc_postmortem", SERVER];
};
/* -------------------------------------------------------------------------- */
/*                                    start                                   */
/* -------------------------------------------------------------------------- */

if (isServer)
then { _oldUnit addEventHandler ["Deleted", _eh_deleted]; };

[_oldUnit] spawn A3A_fnc_postmortem;

_oldUnit setVariable ["incapacitated", false, true];
_newUnit setVariable ["incapacitated", false, true];

if (side (group player) == teamPlayer)
then
{
	_owner = _oldUnit getVariable ["owner", _oldUnit];

	if (_owner != _oldUnit)
	exitWith
	{
		[REMOTE_TITLE, REMOTE_TEXT] call A3A_fnc_customHint;
		selectPlayer _owner;
		disableUserInput false;
		deleteVehicle _newUnit;
	};

	[0, -1, getPos _oldUnit] remoteExec ["A3A_fnc_citySupportChange", SERVER];

	private _score = _oldUnit getVariable ["score", 0];
	private _punish = _oldUnit getVariable ["punish", 0];
	private _moneyX = _oldUnit getVariable ["moneyX", 0];
	_moneyX = round (_moneyX - (_moneyX * 0.15));
	private _eligible = _oldUnit getVariable ["eligible", true];
	private _rankX = _oldUnit getVariable ["rankX", "PRIVATE"];

	if (_moneyX < 0) then { _moneyX = 0; };

	_newUnit setVariable ["score", _score - 1, true];
	_newUnit setVariable ["owner", _newUnit, true];
	_newUnit setVariable ["punish", _punish, true];
	_newUnit setVariable ["respawning", false];
	_newUnit setVariable ["moneyX", _moneyX, true];
	_newUnit setVariable ["compromised", 0];
	_newUnit setVariable ["eligible", _eligible, true];
	_oldUnit setVariable ["eligible", false, true];
	_newUnit setVariable ["spawner", true, true];
	_oldUnit setVariable ["spawner", nil, true];
	[_newUnit, false] remoteExec ["setCaptive", GLOBAL, _newUnit];
	_newUnit setCaptive false;
	_newUnit setRank (_rankX);
	_newUnit setVariable ["rankX", _rankX, true];
	_newUnit setUnitTrait ["camouflageCoef", 0.8];
	_newUnit setUnitTrait ["audibleCoef", 0.8];

	{ _newUnit addOwnedMine _x; } count getAllOwnedMines (_oldUnit);

	{
		if (_x getVariable ["owner", ObjNull] == _oldUnit)
		then { _x setVariable ["owner", _newUnit, true]; };
	} forEach (units group player);

	disableUserInput false;

	if (_oldUnit == theBoss)
	then { [_newUnit, true] remoteExec ["A3A_fnc_theBossTransfer", SERVER]; };


	removeAllItemsWithMagazines _newUnit;

	{ _newUnit removeWeaponGlobal _x; } forEach weapons _newUnit;

	removeBackpackGlobal _newUnit;
	removeVest _newUnit;
	removeAllAssignedItems _newUnit;

	_newUnit linkItem "ItemMap";

	if !(isPlayer (leader group player))
	then { (group player) selectLeader player; };

	player addEventHandler ["FIRED", _eh_fired];

	player addEventHandler ["InventoryOpened", _eh_inventoryOpened];

	if (hasInterface)
	then
	{
		[player] call A3A_fnc_punishment_FF_addEH;
		[] spawn A3A_fnc_outOfBounds;
	};

	player addEventHandler ["HandleHeal", _eh_handleHeal];
	player addEventHandler ["WeaponAssembled", _eh_weaponAssembled];
	player addEventHandler ["WeaponDisassembled", _eh_weaponDisassembled];

	[true] spawn A3A_fnc_reinitY;
	[player] execVM "OrgPlayers\unitTraits.sqf";
	[] spawn A3A_fnc_statistics;

	if (LootToCrateEnabled) then { call A3A_fnc_initLootToCrate; };
}
else
{
	_oldUnit setVariable ["spawner", nil, true];
	_newUnit setVariable ["spawner", true, true];

	[player] call A3A_fnc_dress;

	if (hasACE) then { call A3A_fnc_ACEpvpReDress; };
};
