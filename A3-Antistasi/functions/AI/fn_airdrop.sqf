/* -------------------------------------------------------------------------- */
/*                                   defines                                  */
/* -------------------------------------------------------------------------- */

#define WP_STATEMENT3 "if !(local this) exitWith {}; deleteVehicle (vehicle this); {deleteVehicle _x} forEach thisList"
#define WP_STATEMENT5 "if !(local this) exitWith {}; (group this) spawn A3A_fnc_attackDrillAI"
#define WP_STATEMENT4 "if !(local this) exitWith {}; {if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"

/* -------------------------------------------------------------------------- */
/*                                    start                                   */
/* -------------------------------------------------------------------------- */

params ["_vehicle", "_group", "_marker", "_origin", ["_reinf", false, [true]]];

private _position = _marker;

if (_marker isEqualType "") then { _position = getMarkerPos _marker; };

private _pilotGroup = group (driver _vehicle);

{
	_x disableAI "TARGET";
	_x disableAI "AUTOTARGET";
} foreach units _pilotGroup;

private _dist = 500;
private _isHeli = _vehicle isKindOf "Helicopter";
private _engageDistance = [2000, 1000] # _isHeli;
private _exitDistance = [1000, 400] # _isHeli;
private _originPosition = getMarkerPos _origin;


private _engagePosition = [];
private _landPosition = [];
private _exitPosition = [];

private _randomAngle = random 360;

// FIX possible endless cycle
while { true }
do
{
 	_landPosition = _position getPos [_dist, _randomAngle];
 	if !(surfaceIsWater _landPosition) exitWith {};
   _randomAngle = _randomAngle + 1;
};

_randomAngle = _randomAngle + 90;

// FIX possible endless cycle
while {true}
do
{
 	_exitPosition = _position getPos [_exitDistance, _randomAngle];
 	_randomAngle = _randomAngle + 1;

 	if (!(surfaceIsWater _exitPosition)
	 	&& { _exitPosition distance _position > 300 })
	exitWith {};
};

_randomAngle = [_landPosition, _exitPosition] call BIS_fnc_dirTo;
_randomAngle = _randomAngle - 180;

_engagePosition = _landPosition getPos [_engageDistance, _randomAngle];

{ _x set [2, 300]; } forEach [_landPosition, _exitPosition, _engagePosition];
{ _x setBehaviour "CARELESS"; } forEach units _pilotGroup;

_vehicle flyInHeight 300;
_vehicle setCollisionLight false;

private _waypoint0 = _pilotGroup addWaypoint [_engagePosition, 0];
_waypoint0 setWaypointType "MOVE";

private _waypoint1 = _pilotGroup addWaypoint [_landPosition, 1];
_waypoint1 setWaypointType "MOVE";
_waypoint1 setWaypointSpeed "LIMITED";

private _waypoint2 = _pilotGroup addWaypoint [_exitPosition, 2];
_waypoint2 setWaypointType "MOVE";

private _waypoint3 = _pilotGroup addWaypoint [_originPosition, 3];
_waypoint3 setWaypointType "MOVE";
_waypoint3 setWaypointSpeed "NORMAL";
_waypoint3 setWaypointStatements ["true", WP_STATEMENT3];

{
	removebackpack _x;
	_x addBackpack "B_Parachute";
} forEach units _group;

/* ---------------------------------- pause --------------------------------- */

waitUntil
{
	sleep 1;

	if (currentWaypoint _pilotGroup == 3) exitWith { true };
	if !(alive _vehicle)  exitWith { true };
	if !(canMove _vehicle) exitWith { true };

	false
};

if (alive _vehicle)
then
{
	_vehicle setCollisionLight true;

	{
		// FIX possible pause and unexpected behaviour
		waitUntil
		{
			sleep 0.5;
			if !(surfaceIsWater (position _x)) exitWith { true };
			false
		};

		_x allowDamage false;
		unAssignVehicle _x;
		// Move them into alternating left/right positions,
		// so their parachutes are less likely to kill each other
		private _xCoord = [-7, 7] # (_forEachIndex % 2 == 0);
		private _modelPosition = _vehicle modeltoWorld [_xCoord, -20, -5];

		_x setPos _modelPosition;

		_x spawn { sleep 5; _this allowDamage true; };
  	} forEach units _group;
};


if (_reinf)
then
{
   _waypoint4 = _group addWaypoint [_position, 0];
   _waypoint4 setWaypointType "MOVE";
}
else
{
   _posLeader = position (leader _group);
   _posLeader set [2, 0];
   private _waypoint5 = _group addWaypoint [_posLeader, 0];
   _waypoint5 setWaypointType "MOVE";
   _waypoint5 setWaypointStatements ["true", WP_STATEMENT5];
   private _waypoint4 = _group addWaypoint [_position, 1];
   _waypoint4 setWaypointType "MOVE";
   _waypoint4 setWaypointStatements ["true", WP_STATEMENT4];
   _waypoint4 = _group addWaypoint [_position, 2];
   _waypoint4 setWaypointType "SAD";
};
