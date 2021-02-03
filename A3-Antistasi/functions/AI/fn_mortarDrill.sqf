private ["_gunner", "_helper"];
private _fnc_isAllAlive = { alive _gunner && { alive _helper } };

{
	if (_x getVariable ["typeOfSoldier", ""] == "StaticMortar")
	then { _gunner = _x; }
	else { _helper = _x; }
} forEach _this;

private _group = group _gunner;

while {true}
do
{
	private _enemy = _group call A3A_fnc_nearEnemy;

	if (isNull _enemy) exitWith {};
	if (_enemy distance _gunner > 50) exitWith {};
	if !(call _fnc_isAllAlive) exitWith {};

	sleep 30;
};

if !(call _fnc_isAllAlive) exitWith {};

private _mortarType = [CSATMortar, NATOMortar] # (side _gunner == Occupants);
private _position = [];

waitUntil
{
	_position = position _gunner findEmptyPosition [1, 30, _mortarType];

	if !(_position isEqualTo []) exitWith { true };
	if !(call _fnc_isAllAlive) exitWith { true };

	sleep 30;

	false
};

if !(alive _gunner && { alive _helper }) exitWith {};

_gunner setVariable ["maneuvering", true];

while { true }
do
{
	if (_gunner distance _position < 5) exitWith {};
	_gunner doMove _position;
	_helper doMove _position;
	if !(alive _gunner && { alive _helper }) exitWith {};
	sleep 10;
};

if (!(alive _helper) && { alive _gunner })
then
{
	_gunner setVariable ["maneuvering", false];
	_movable = _group getVariable ["movable", []];
	_movable pushBack _gunner;
	_group setVariable ["movable", _movable];
	_flankers = _group getVariable ["flankers", []];
	_flankers pushBack _gunner;
	_group setVariable ["flankers", _flankers];
	_gunner call A3A_fnc_recallGroup;
};

if (alive _helper && !{ alive _gunner })
then
{
	_movable = _group getVariable ["movable", []];
	_movable pushBack _helper;
	_group setVariable ["movable", _movable];
	_flankers = _group getVariable ["flankers", []];
	_flankers pushBack _helper;
	_group setVariable ["flankers", _flankers];
	_helper call A3A_fnc_recallGroup;
};

if !(call _fnc_isAllAlive) exitWith {};

private _mortar = _mortarType createVehicle _position;
removeBackpackGlobal _gunner;
removeBackpackGlobal _helper;
_group addVehicle _mortar;
_gunner assignAsGunner _mortar;
[_gunner] orderGetIn true;
[_gunner] allowGetIn true;
[_mortar, side _group] call A3A_fnc_AIVEHinit;
_movable = _group getVariable ["movable", []];
_movable pushBack _helper;
_group setVariable ["movable", _movable];
_flankers = _group getVariable ["flankers", []];
_flankers pushBack _helper;
_group setVariable ["flankers", _flankers];
_helper call A3A_fnc_recallGroup;

waitUntil
{
	sleep 1;
	if (vehicle _gunner == _mortar) exitWith { true };
	if !(alive _gunner) exitWith { true };
	if !(alive _mortar) exitWith { true };
	false
};

if !(alive _gunner) exitWith {};

if !(alive _mortar) exitWith { _gunner call A3A_fnc_recallGroup; };

_group setVariable ["mortarsX", _gunner];

_gunner addEventHandler ["Killed", { (group (param [0])) setVariable ["mortarsX", objNull]; }];