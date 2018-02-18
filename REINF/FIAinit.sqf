private ["_unit","_muerto","_killer","_skill","_nombre","_tipo"];

_unit = _this select 0;

[_unit] call initRevive;
_unit setVariable ["GREENFORSpawn",true,true];

_unit allowFleeing 0;
_tipo = typeOf _unit;
_skill = if (_tipo in sdkTier1) then {(skillFIA * 0.2)} else {if (_tipo in sdkTier2) then {0.1 + (skillFIA * 0.2)} else {0.1 + (skillFIA * 0.2)}};
if (not((uniform _unit) in uniformsSDK)) then {[_unit] call reDress};

if ((!isMultiplayer) and (leader _unit == stavros)) then {_skill = _skill + 0.1};
_unit setSkill _skill;
if (_tipo in SDKSniper) then
	{
	removeAllWeapons _unit;
	[_unit, sniperRifle, 8, 0] call BIS_fnc_addWeapon;
	_unit addPrimaryWeaponItem "optic_KHS_old";
	}
else
	{
	if (_unit skill "aimingAccuracy" > 0.35) then {_unit setSkill ["aimingAccuracy",0.35]};
	if (_tipo in SDKMil) then
		{
		_rifleFinal = unlockedRifles call BIS_fnc_selectRandom;
		if (_rifleFinal != primaryWeapon _unit) then
			{
			_magazines = getArray (configFile / "CfgWeapons" / (primaryWeapon _unit) / "magazines");
			{_unit removeMagazines _x} forEach _magazines;
			/*
			_mag = _magazines select 0;
			for "_i" from 1 to ({_x == _mag} count magazines _unit) do
				{
				_unit removeMagazine _mag;
				};
			*/
			_unit removeWeaponGlobal (primaryWeapon _unit);
			[_unit, _rifleFinal, 6, 0] call BIS_fnc_addWeapon;
			if (loadAbs _unit < 340) then
				{
				if ((random 20 < skillFIA) and ({_x in titanLaunchers} count unlockedWeapons > 0)) then
					{
					_unit addbackpack "B_AssaultPack_blk";
					[_unit, "launch_I_Titan_F", 2, 0] call BIS_fnc_addWeapon;
					removeBackpack _unit;
					};
				};
			};
		}
	else
		{
		if ((activeGREF) and (!(_tipo in SDKMG))) then
			{
			_rifleFinal = unlockedRifles call BIS_fnc_selectRandom;
			if (_rifleFinal != primaryWeapon _unit) then
				{
				_magazines = getArray (configFile / "CfgWeapons" / (primaryWeapon _unit) / "magazines");
				{_unit removeMagazines _x} forEach _magazines;
				_unit removeWeaponGlobal (primaryWeapon _unit);
				[_unit, _rifleFinal, 6, 0] call BIS_fnc_addWeapon;
				if (loadAbs _unit < 340) then
					{
					if ((random 20 < skillFIA) and ({_x in titanLaunchers} count unlockedWeapons > 0)) then
						{
						_unit addbackpack "B_AssaultPack_blk";
						[_unit, "launch_I_Titan_F", 2, 0] call BIS_fnc_addWeapon;
						removeBackpack _unit;
						};
					};
				};
			};
		if (_tipo in SDKExp) then
			{
			/*_unit setUnitTrait ["engineer",true];*/ _unit setUnitTrait ["explosiveSpecialist",true];
			}
		else
			{
			if ((_tipo in SDKMG) and (activeGREF)) then
				{
				_magazines = getArray (configFile / "CfgWeapons" / (primaryWeapon _unit) / "magazines");
				{_unit removeMagazines _x} forEach _magazines;
				_unit removeWeaponGlobal (primaryWeapon _unit);
				[_unit, "rhs_weap_pkm", 6, 0] call BIS_fnc_addWeapon;
				}
			else
				{
				if (_tipo in SDKMedic) then
					{
					_unit setUnitTrait ["medic",true]
					}
				else
					{
					if (_tipo in SDKATman) then
						{
						_rlauncher = selectRandom ((rlaunchers + mlaunchers) select {(_x in unlockedWeapons) and (getNumber (configfile >> "CfgWeapons" >> _x >> "lockAcquire") == 0)});
						if (_rlauncher != secondaryWeapon _unit) then
							{
							_magazines = getArray (configFile / "CfgWeapons" / (secondaryWeapon _unit) / "magazines");
							{_unit removeMagazines _x} forEach _magazines;
							_unit removeWeaponGlobal (secondaryWeapon _unit);
							[_unit, _rlauncher, 4, 0] call BIS_fnc_addWeapon;
							};
						};
					};
				};
			};
		};
	if (count unlockedOptics > 0) then
		{
		_compatibles = [primaryWeapon _unit] call BIS_fnc_compatibleItems;
		_posibles = unlockedOptics select {_x in _compatibles};
		_unit addPrimaryWeaponItem (selectRandom _posibles);
		};
	};
_unit setUnitTrait ["camouflageCoef",0.8];
_unit setUnitTrait ["audibleCoef",0.8];

_unit selectWeapon (primaryWeapon _unit);
/*
_aiming = _skill;
_spotD = _skill;
_spotT = _skill;
_cour = _skill;
_comm = _skill;
_aimingSh = _skill;
_aimingSp = _skill;
_reload = _skill;


//_emptyUniform = false;
_skillSet = 0;
*/
if (!haveRadio) then
	{
	if ((_unit != leader _unit) and (_tipo != staticCrewBuenos)) then {_unit unlinkItem "ItemRadio"};
	};
if ({if (_x in humo) exitWith {1}} count unlockedMagazines > 0) then {_unit addMagazines [selectRandom humo,2]};

if (sunOrMoon < 1) then
	{
	if (haveNV) then
		{
		_unit linkItem "NVGoggles";
		if ("acc_pointer_IR" in unlockedItems) then
			{
			_unit addPrimaryWeaponItem "acc_pointer_IR";
	        _unit assignItem "acc_pointer_IR";
	        _unit enableIRLasers true;
	        };
		}
	else
		{
		_compatibles = [primaryWeapon _unit] call BIS_fnc_compatibleItems;
		_array = lamparasSDK arrayIntersect _compatibles;
		if (count _array > 0) then
			{
			_compatible = _array select 0;
			_unit addPrimaryWeaponItem _compatible;
		    _unit assignItem _compatible;
		    _unit enableGunLights _compatible;
			};
	    };
	};
/*
if ((_tipo != "B_G_Soldier_M_F") and (_tipo != "B_G_Sharpshooter_F")) then {if (_aiming > 0.35) then {_aiming = 0.35}};

_unit setskill ["aimingAccuracy",_aiming];
_unit setskill ["spotDistance",_spotD];
_unit setskill ["spotTime",_spotT];
_unit setskill ["courage",_cour];
_unit setskill ["commanding",_comm];
_unit setskill ["aimingShake",_aimingSh];
_unit setskill ["aimingSpeed",_aimingSp];
_unit setskill ["reloadSpeed",_reload];
*/
if (player == leader _unit) then
	{
	_unit setVariable ["owner",player];
	_EHkilledIdx = _unit addEventHandler ["killed", {
		_muerto = _this select 0;
		[_muerto] spawn postmortem;
		_killer = _this select 1;
		arrayids pushBackUnique (name _muerto);
		if (side _killer == malos) then
			{
			_nul = [0.25,0,getPos _muerto] remoteExec ["citySupportChange",2];
			[-0.25,0] remoteExec ["prestige",2];
			}
		else
			{
			if (side _killer == muyMalos) then {[0,-0.25] remoteExec ["prestige",2]};
			};
		_muerto setVariable ["GREENFORSpawn",nil,true];
		}];
	if (typeOf _unit != SDKUnarmed) then
		{
		_idUnit = arrayids call BIS_Fnc_selectRandom;
		arrayids = arrayids - [_idunit];
		_unit setIdentity _idUnit;
		};
	if (captive player) then {[_unit] spawn undercoverAI};

	_unit setVariable ["rearming",false];
	if ((!haveRadio) and (!hayTFAR) and (!hayACRE)) then
		{
		while {alive _unit} do
			{
			sleep 10;
			if (("ItemRadio" in assignedItems _unit) and ([player] call hasRadio)) exitWith {_unit groupChat format ["This is %1, radiocheck OK",name _unit]};
			if (unitReady _unit) then
				{
				if ((alive _unit) and (_unit distance (getMarkerPos "respawn_guerrila") > 50) and (_unit distance leader group _unit > 500) and ((vehicle _unit == _unit) or ((typeOf (vehicle _unit)) in arrayCivVeh))) then
					{
					hint format ["%1 lost communication, he will come back with you if possible", name _unit];
					[_unit] join rezagados;
					if ((vehicle _unit isKindOf "StaticWeapon") or (isNull (driver (vehicle _unit)))) then {unassignVehicle _unit; [_unit] orderGetIn false};
					_unit doMove position player;
					_tiempo = time + 900;
					waitUntil {sleep 1;(!alive _unit) or (_unit distance player < 500) or (time > _tiempo)};
					if ((_unit distance player >= 500) and (alive _unit)) then {_unit setPos (getMarkerPos "respawn_guerrila")};
					[_unit] join group player;
					};
				};
			};
		};
	}
else
	{
	if (_unit == leader _unit) then
		{
		_unit setskill ["courage",_skill + 0.2];
		_unit setskill ["commanding",_skill + 0.2];
		};
	_EHkilledIdx = _unit addEventHandler ["killed", {
		_muerto = _this select 0;
		_killer = _this select 1;
		[_muerto] remoteExec ["postmortem",2];
		if ((isPlayer _killer) and (side _killer == buenos)) then
			{
			if (!isMultiPlayer) then
				{
				_nul = [0,20] remoteExec ["resourcesFIA",2];
				_killer addRating 1000;
				};
			}
		else
			{
			if (side _killer == malos) then
				{
				_nul = [0.25,0,getPos _muerto] remoteExec ["citySupportChange",2];
				[-0.25,0] remoteExec ["prestige",2];
				}
			else
				{
				if (side _killer == muyMalos) then {[0,-0.25] remoteExec ["prestige",2]};
				};
			};
		_muerto setVariable ["GREENFORSpawn",nil,true];
		}];
	};


