/* -------------------------------------------------------------------------- */
/*                                   defines                                  */
/* -------------------------------------------------------------------------- */

// TODO localisation
#define POST_TITLE "Outposts/Roadblocks"
#define ONLY_ONE_TEXT "We can only deploy / delete one Observation Post or Roadblock at a time."
#define MAN_REQ_TITLE "Radio-man Required"
#define MAN_REQ_TEXT "You need a Radio Man in your group to be able to give orders to other squads"
#define RADIO_TITLE "Radio Required"
#define RADIO_TEXT "You need a radio in your inventory to be able to give orders to other squads"
#define DEPLOY_TEXT "Click on the position you wish to build the Observation Post or Roadblock. <br/><br/> Remember: to build Roadblocks you must click exactly on a road map section"
#define DELETE_TEXT "Click on the Observation Post or Roadblock to delete."
#define NO_POST_TEXT "No Posts or Roadblocks deployed to delete"
#define CANNOT_TEXT "You cannot delete a Post while enemies are near it"
#define NO_POST_TEXT "No post nearby"
#define LACK_OF_RESURCES_TEXT "You lack of resources to build this Outpost or Roadblock <br/><br/> %1 HR and %2 € needed"

/* -------------------------------------------------------------------------- */
/*                                    start                                   */
/* -------------------------------------------------------------------------- */

if (["outpostsFIA"] call BIS_fnc_taskExists)
exitWith { [POST_TITLE, ONLY_ONE_TEXT] call A3A_fnc_customHint; };

if !([player] call A3A_fnc_hasRadio)
exitWith
{
	if (hasIFA)
	then { [MAN_REQ_TITLE, MAN_REQ_TEXT] call A3A_fnc_customHint; }
	else { [RADIO_TITLE, RADIO_TEXT] call A3A_fnc_customHint; };
};

/* ------------------------------ input params ------------------------------ */

private _typeX = param [0];

/* ----------------------------------- map ---------------------------------- */

if !(visibleMap) then { openMap true; };

positionTel = [];

if (_typeX != "delete")
then { [POST_TITLE, DEPLOY_TEXT] call A3A_fnc_customHint; }
else { [POST_TITLE, DELETE_TEXT] call A3A_fnc_customHint; };

onMapSingleClick "positionTel = _pos; onMapSingleClick ''; true";

waitUntil
{
	sleep 1;

	if (count positionTel > 0) exitWith { true };
	if !(visiblemap) exitWith { true };

	false
};

if !(visibleMap) exitWith {};

private _positionTel = positionTel;

/* ---------------------------- check conditions ---------------------------- */

if (_typeX == "delete" && { count outpostsFIA < 1 })
exitWith { [POST_TITLE, NO_POST_TEXT] call A3A_fnc_customHint; };

if (_typeX == "delete" && {
	allUnits findIf
	{
		alive _x && {
		!captive _x && {
		_x distance _positionTel < 500 && {
		side _x == Occupants || {
		side _x == Invaders }}}}
	} != -1 })
exitWith { [POST_TITLE, CANNOT_TEXT] call A3A_fnc_customHint;};

/* ----------------------------- process actions ---------------------------- */

private _costs = 0;
private _hr = 0;
private _nearestPosition = [];

if (_typeX != "delete")
then
{
	private _isOnRoad = isOnRoad _positionTel;
	private _typeGroup = groupsSDKSniper;

	if (_isOnRoad)
	then
	{
		_typeGroup = groupsSDKAT;

		_costs = _costs + ([vehSDKLightArmed] call A3A_fnc_vehiclePrice) +
			(server getVariable staticCrewTeamPlayer);

		_hr = _hr + 1;
	};

	{
		_costs = _costs + (server getVariable (_x # 0));
		_hr = _hr + 1;
	} forEach _typeGroup;
}
else
{
	private _mrk = [outpostsFIA, _positionTel] call BIS_fnc_nearestPosition;

	if (_mrk isEqualTo [0, 0, 0])
	then { _nearestPosition = _mrk; }
	else { _nearestPosition = getMarkerPos _mrk; };


	if (_positionTel distance _nearestPosition > 10)
	exitWith { [POST_TITLE, NO_POST_TEXT] call A3A_fnc_customHint; };
};

private _resourcesFIA = server getVariable "resourcesFIA";
private _hrFIA = server getVariable "hr";

if (_typeX != "delete"
	&& { _resourcesFIA < _costs
	|| { _hrFIA < _hr } })
exitWith
{
	[POST_TITLE, format [LACK_OF_RESURCES_TEXT, _hr, _costs]]
		call A3A_fnc_customHint;
};

if (_typeX != "delete")
then { [- _hr, - _costs] remoteExec ["A3A_fnc_resourcesFIA", 2]; };

[_typeX, _positionTel] remoteExec ["A3A_fnc_createOutpostsFIA", 2];
