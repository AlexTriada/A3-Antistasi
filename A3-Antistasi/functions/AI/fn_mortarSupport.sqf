private _unit = param [0];
private _mortar = vehicle _unit;

if (_mortar == _unit)
exitWith {};

if !(alive _mortar)
exitWith { (group _unit) setVariable ["mortarsX", objNull]; };

if !(unitReady _unit)
exitWith {};

private _position = param [1];
private _rounds = param [2];
private _config = configfile >> "CfgVehicles" >> (typeOf _mortar) >> "Turrets"
	>> "MainTurret" >> "magazines";
private _typeAmmunition = (getArray _config) # 0;

if ((magazinesAmmo _mortar) findIf { _x # 0 == _typeAmmunition } == -1)
exitWith
{
	moveOut _unit;
	(group _unit) setVariable ["mortarsX", objNull];
};

if !(_position inRangeOfArtillery [[_mortar], (getArtilleryAmmo [_mortar]) # 0])
exitWith {};

_mortar commandArtilleryFire [_position, _typeAmmunition, _rounds];
