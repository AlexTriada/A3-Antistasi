private _group = _this;
private _leader = leader _group;
private _enemySides = (side _group) call BIS_fnc_enemySides;

private _objectives = (_leader nearTargets  500) select
	{ (_x # 2) in _enemySides && { [_x # 4] call A3A_fnc_canFight } };

_objectives = [_objectives, [_leader], { _input0 distance (_x # 0) }, "ASCEND"]
	call BIS_fnc_sortBy;

_group setVariable ["objectivesX", _objectives];

_objectives