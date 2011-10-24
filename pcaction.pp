unit pcaction;
	{This unit contains procedures which define the various}
	{actions that the PC can take.}

	{Most of these routines are boolean functions. A value}
	{of TRUE implies that the PC has taken some action;}
	{advance the time counter and let the monsters have their}
	{turn. A value of FALSE is for cancelled actions or game}
	{options; it doesn't use the PC's action.}

interface

uses crt,rpgdice,rpgtext,rpgmenus,texmodel,texmaps,looker,spells,dcitems,dcchars,critters,gamebook,dccombat,backpack,zapspell,charts,cwords;

Procedure PCMeleeAttack(SC: ScenarioPtr; TX,TY: Integer);
Function PCOpenDoor(SC: ScenarioPtr): Boolean;
Function PCCloseDoor(SC: ScenarioPtr): Boolean;
Function PCMove(SC: ScenarioPtr; d: Integer): Boolean;
Function PCReCenter(SC: ScenarioPtr): Boolean;
Function PCShooting(SC: ScenarioPtr; SeekModel: Boolean): Boolean;
Function PCTosser(SC: ScenarioPtr): Boolean;
Function PCInvScreen(SC: ScenarioPtr; StartWithInv: Boolean): Boolean;
Function PCPickUp(SC: ScenarioPtr): Boolean;
Function PCDisarmTrap(SC: ScenarioPtr): Boolean;
Function PCSearch(SC: ScenarioPtr): Boolean;
Function PCUsePsi(SC: ScenarioPtr; UseMenu: Boolean): Boolean;
Function PCLookAround(SC: ScenarioPtr): Boolean;
Function PCEnter(SC: ScenarioPtr): Boolean;
Function PCRepeat(SC: ScenarioPtr): Boolean;
Function PCProcessRepeat(SC: ScenarioPtr): Boolean;
Function PCCheckXP(SC: ScenarioPtr): Boolean;
Function PCInfoScreen(SC: ScenarioPtr): Boolean;
Procedure ScanUnknownInv( SC: ScenarioPtr );
Function PCHandyMap(SC: ScenarioPtr): Boolean;


implementation

uses mdlogon,texutil;

Const
	SpotDoorTarget = 30;
	SpotTrapTarget = 25;
	AvoidTrapTarget = 35;
	AvoidVisibleTrap = 10;
	StepOnBlood: Integer = 0;	{How many bloody tiles the PC has walked on.}
			{This constant is used to prevent boring the}
			{PC by printing the same message over and over again.}

Procedure CheckMonsterMemory(SC: ScenarioPtr);
	{The player has either moved or otherwise changed the}
	{field of vision.}
var
	X,Y,X1,Y1,X2,Y2: Integer;
	M: ModelPtr;
	C: CritterPtr;
begin
	{Set the boundaries for our search.}
	X1 := SC^.PC^.M^.X - SC^.GB^.POV.Range;
	if X1 < 1 then X1 := 1;
	Y1 := SC^.PC^.M^.Y - SC^.GB^.POV.Range;
	if Y1 < 1 then Y1 := 1;
	X2 := SC^.PC^.M^.X + SC^.GB^.POV.Range;
	if X2 > XMax then X2 := XMax;
	Y2 := SC^.PC^.M^.Y + SC^.GB^.POV.Range;
	if Y2 > YMax then Y2 := YMax;

	for X := X1 to X2 do begin
		for Y := Y1 to Y2 do begin
			{First, check that the square is visible, there's a model present and that it's on the screen.}
			if TileLOS(SC^.GB^.POV,X,Y) and SC^.GB^.mog[X,Y] and OnTheScreen(SC^.GB,X,Y) then begin
				M := FindModelXY(SC^.GB^.MList,X,Y);
				if M^.Kind = MKIND_Critter then begin
					C := LocateCritter(M,SC^.CList);
					if C^.Target = SC^.PC^.M then SC^.PC^.RepCount := 0;
					if not C^.Spotted then begin
						{Seeing an unknown creature will cause the PC to stop repeditive actions.}
						SC^.PC^.RepCount := 0;
						UpdateMonsterMemory(SC,C);
					end;
				end;
			end;
		end;
	end;

end;

Procedure CheckForTraps(SC: ScenarioPtr; Mode: Byte);
	{Check the PC's immediate vicinity for traps. Reveal any}
	{that are found. Use Mode = 0 for walking, Mode = 1 for}
	{searching.}
const
	NumMsg = 3;
	TrapDetectionMsg: Array [1..NumMsg] of string = (
		'You have detected a trap!',
		'There are security countermeasures in use here.',
		'You notice a sensor beam.'
	);
var
	X,Y: Integer;
begin
	for X := SC^.PC^.M^.X -1 to SC^.PC^.M^.X + 1 do begin
		for Y := SC^.PC^.M^.Y -1 to SC^.PC^.M^.Y + 1 do begin
			if OnTheMap(X,Y) and (SC^.gb^.map[X,Y].trap < 0) then begin
				if RollStep(PCDetection(SC^.PC)) >= (SpotTrapTarget - Mode*10) then begin
					{A trap has been detected!}
					DCGameMessage(TrapDetectionMsg[Random(NumMsg)+1]);
					RevealTrap(SC,X,Y);
					GamePause;
					{A Player who detects a trap will stop repeated actions.}
					SC^.PC^.RepCount := 0;
					DoleExperience(SC,2);
				end;
			end;
		end;
	end;
end;

Procedure CheckForSecretDoors(SC: ScenarioPtr; Mode: Byte);
	{Check the PC's immediate vicinity for secret doors. Reveal}
	{any that are found. Use Mode = 0 for walking, Mode = 1 for}
	{searching.}
var
	X,Y: Integer;
begin
	for X := SC^.PC^.M^.X -1 to SC^.PC^.M^.X + 1 do begin
		for Y := SC^.PC^.M^.Y -1 to SC^.PC^.M^.Y + 1 do begin
			if OnTheMap(X,Y) and (SC^.gb^.map[X,Y].terr = HiddenServicePanel) then begin
				if RollStep(PCDetection(SC^.PC)) >= (SpotDoorTarget - Mode*5) then begin
					{A door has been detected!}
					DCGameMessage('You have discovered a service panel.');
					SC^.gb^.map[X,Y].terr := ClosedServicePanel;
					DisplayTile(SC^.gb,X,Y);
					GamePause;
					DoleExperience(SC,1);
					{A Player who detects a secret door will stop repeated actions.}
					SC^.PC^.RepCount := 0;
				end;
			end;
		end;
	end;
end;

Procedure MightActivateTrap(SC: ScenarioPtr);
	{The PC has just stepped on a trap. It might be activated.}
	{Check and see.}
var
	R: Boolean;
	LS: Integer;
begin
	{R stands for Revealed. It's true if the trap is visible}
	{to the player, false if it's still hidden.}
	R := SC^.gb^.map[SC^.PC^.M^.X,SC^.PC^.M^.Y].trap > 0;

	{A trap which the player has detected isn't likely to go off,}
	{but it still might. A trap which hasn't been detected}
	{by the PC will almost certainly go off.}

	LS := RollStep(PCLuckSave(SC^.PC));

	if R and (LS < AvoidVisibleTrap) then
		SpringTrap(SC,SC^.PC^.M^.X,SC^.PC^.M^.Y)
	else if not R and (LS < AvoidTrapTarget) then
		SpringTrap(SC,SC^.PC^.M^.X,SC^.PC^.M^.Y)
	else if not R then
		RevealTrap(SC,SC^.PC^.M^.X,SC^.PC^.M^.Y);
end;

Procedure PCMeleeAttack(SC: ScenarioPtr; TX,TY: Integer);
	{This procedure allows the PC to attack something with the}
	{equipped close combat weapon.}
var
	AR: AttackRequest;
	Rep: AttackReport;
begin
	{Note that a person making melee attacks will burn up calories}
	{far more quickly than normal. But, it won't make you starve.}
	if SC^.PC^.Carbs > 10 then Dec(SC^.PC^.Carbs);

	AR.HitRoll := PCMeleeSkill(SC^.PC);
	AR.Damage := PCMeleeDamage(SC^.PC);
	AR.Range := -1;
	AR.Attacker := SC^.PC^.M;
	AR.Tx := TX;
	AR.TY := TY;
	AR.DF := DF_Physical;
	AR.C := LightRed;
	AR.ATT := '';

	{Generate the description for the PC's attack.}
	if SC^.PC^.Eqp[ES_MeleeWeapon] = Nil then begin
		if Random(99)=69 then AR.Desc := 'bite'
		else if Random(3) = 2 then AR.Desc := 'kick'
		else AR.Desc := 'punch';
	end else begin
		AR.Desc := 'swing '+ItemNameShort(SC^.PC^.Eqp[ES_MeleeWeapon])+' at';
		AR.ATT := CWep[SC^.PC^.Eqp[ES_MeleeWeapon]^.icode].ATT;
	end;

	Rep := ProcessAttack(SC,AR);
end;

Function PCOpenDoor(SC: ScenarioPtr): Boolean;
	{This procedure first looks for a closed door in close}
	{proximity to the PC. If there is only one, that door is}
	{automatically selected for opening. If there is more than}
	{one, the player is prompted for a direction. If the door}
	{is locked, the player is informed of that fact.}
	Function IsClosedDoor(X,Y: Integer): Boolean;
	var
		it: Boolean;
	begin
		case GetTerr(SC^.gb,X,Y) of
			ClosedDoor: it := true;
			ClosedServicePanel: it := true;
			else it := false;
		end;
		IsClosedDoor := it;
	end;
var
	X,Y: Integer;
	D,DoorD: Integer;
begin
	DCGameMessage('Open Door -');
	DoorD := 0;

	X := SC^.PC^.M^.X;
	Y := SC^.PC^.M^.Y;

	{Locate the door}
	for D := 1 to 9 do begin
		if IsClosedDoor(X + VecDir[D,1],Y + VecDir[D,2]) then begin
			if DoorD = 0 then DoorD := D
			else DoorD := -1;
		end;
	end;

	{Do some checks now on the state of our door.}
	if DoorD = -1 then begin
		DCAppendMessage(' Direction?');
		DoorD := DirKey;

		{ Check to make sure this location points to an actual door. }
		if ( DoorD <> 0 ) and not OnTheMap(X + VecDir[DoorD,1],Y + VecDir[DoorD,2]) then begin
			DoorD := 0;
		end else if (DoorD<>0) and not IsClosedDoor(X + VecDir[DoorD,1],Y + VecDir[DoorD,2]) then begin
			DoorD := 0;
		end;
	end;

	if DoorD = 0 then begin
		{No door found. Inform the player of this.}
		DCAppendMessage(' Not found!');
		Exit(False);
	end;

	Dec(SC^.gb^.map[X+VecDir[DoorD,1],Y+VecDir[DoorD,2]].terr);
	DisplayTile(SC^.gb,X+VecDir[DoorD,1],Y+VecDir[DoorD,2]);
	UpdatePOV(SC^.gb^.pov,SC^.gb);
	ApplyPOV(SC^.gb^.pov,SC^.gb);
	DCAppendMessage(' Done.');

	{Check the Monster Memory}
	CheckMonsterMemory(SC);

	PCOpenDoor := True;
end;

Function PCCloseDoor(SC: ScenarioPtr): Boolean;
	{This procedure first looks for a closed door in close}
	{proximity to the PC. If there is only one, that door is}
	{automatically selected for opening. If there is more than}
	{one, the player is prompted for a direction. If the door}
	{is locked, the player is informed of that fact.}
	Function IsOpenDoor(X,Y: Integer): Boolean;
	var
		it: Boolean;
	begin
		case GetTerr(SC^.gb,X,Y) of
			OpenDoor: it := true;
			OpenServicePanel: it := true;
			else it := false;
		end;
		IsOpenDoor := it;
	end;
var
	X,Y: Integer;
	D,DoorD: Integer;
begin
	DCGameMessage('Close Door -');
	DoorD := 0;

	X := SC^.PC^.M^.X;
	Y := SC^.PC^.M^.Y;

	{Locate the door}
	for D := 1 to 9 do begin
		if IsOpenDoor(X + VecDir[D,1],Y + VecDir[D,2]) then begin
			if DoorD = 0 then DoorD := D
			else DoorD := -1;
		end;
	end;

	{Do some checks now on the state of our door.}
	if DoorD = -1 then begin
		DCAppendMessage(' Direction?');
		DoorD := DirKey;

		if ( DoorD <> 0 ) and not OnTheMap(X + VecDir[DoorD,1],Y + VecDir[DoorD,2]) then begin
			DoorD := 0;
		end else if (DoorD<>0) and not IsOpenDoor(X + VecDir[DoorD,1],Y + VecDir[DoorD,2]) then begin
			DoorD := 0;
		end;
	end;

	if DoorD = 0 then begin
		{No door found. Inform the player of this.}
		DCAppendMessage(' Not found!');
		Exit(False);
	end;

	{One last check to perform- if there's a model in the way,}
	{the door can't be closed.}
	if not SC^.gb^.mog[X+VecDir[DoorD,1],Y+VecDir[DoorD,2]] then begin
		Inc(SC^.gb^.map[X+VecDir[DoorD,1],Y+VecDir[DoorD,2]].terr);
		DisplayTile(SC^.gb,X+VecDir[DoorD,1],Y+VecDir[DoorD,2]);
		UpdatePOV(SC^.gb^.pov,SC^.gb);
		ApplyPOV(SC^.gb^.pov,SC^.gb);
		DCAppendMessage(' Done.');
	end else begin
		DCAppendMessage(' Blocked!');
	end;

	PCCloseDoor := True;
end;

Function PCMove(SC: ScenarioPtr; d: Integer): Boolean;
	{This procedure allows the PC to walk.}
var
	X2,Y2: Integer;
	WR: WalkReport;
begin
	X2 := SC^.PC^.m^.X + VecDir[D,1];
	Y2 := SC^.PC^.m^.Y + VecDir[D,2];
	wr := MoveModel(SC^.PC^.m,sc^.gb,X2,Y2);

	If wr.m <> Nil then begin
		if wr.m^.kind = MKIND_Critter then begin
			PCMeleeAttack(SC,wr.m^.X,wr.m^.Y)
		end else if wr.m^.kind = MKIND_MPU then begin
			MDSession( SC , wr.m );
		end else if wr.m <> SC^.PC^.M then begin
			DCGameMessage('Blocked.');
		end;
	end else if wr.go then begin
		{Add special terrain messages and effects here.}
		if SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y] <> Nil then begin
			{There's an item on the floor here.}
			if SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y]^.Next <> Nil then begin
				{There are multiple items on the floor here.}
				DCGameMessage('There are several items on the floor here.')
			end else begin
				{There is a single item on the floor here.}
				if Mergeable( SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y] ) and ( SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y]^.Charge > 1 ) then begin
					DCGameMessage('You find ' + ItemNameLong(SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y]) + ' on the floor here.');
				end else begin
					DCGameMessage('There is a ' + ItemNameShort(SC^.ig^[SC^.PC^.M^.X,SC^.PC^.M^.Y]) + ' on the floor here.');
				end;
			end;
		end else if GetTerr(SC^.gb,SC^.PC^.M^.X,SC^.PC^.M^.Y) = 10 then begin
			if Dice(10) > StepOnBlood then DCGameMessage('There are blood stains on the floor here.');
			if StepOnBlood < 20 then Inc(StepOnBlood);
		end else if GetTerr(SC^.gb,SC^.PC^.M^.X,SC^.PC^.M^.Y) = Chair then begin
			DCGameMessage('There is a chair here.');
		end;

		if wr.trap <> 0 then begin
			{There's a trap here. The PC might just set it off!}
			MightActivateTrap(SC);
		end;

		{Make sure the PC is still alive before providing}
		{more information.}
		if SC^.PC^.HP > 0 then begin
			{Check the Monster Memory}
			CheckMonsterMemory(SC);
			CheckForTraps(SC,0);
			CheckForSecretDoors(SC,0);

			{Activate any plot points here.}
			if SC^.gb^.map[SC^.PC^.M^.X,SC^.PC^.M^.Y].special >0 then begin
				SetTrigger( SC , PLT_MapSquare , SC^.gb^.map[SC^.PC^.M^.X,SC^.PC^.M^.Y].special );
			end;
		end;

	end else if (wr.m = Nil) and (TerrPass[GetTerr(SC^.gb,X2,Y2)] > 0) then begin
		{We haven't moved, and we didn't hit a model, so...}
		{it must be terrain stopping us!!!}
		DCGameMessage('Slow progress...')
	end else if d <> 5 then begin
		{This is a catch all, for walls and other miscellaneous things.}
		DCGameMessage('Blocked.');
	end;
	PCMove := True;
end;

Function PCReCenter(SC: ScenarioPtr): Boolean;
	{The player wants to recenter the display on his current position.}
	{Facilitate this request.}
begin
	RecenterPOV(SC^.GB);
	DisplayMap(SC^.GB);
	CheckMonsterMemory(SC);
	PCReCenter := False;
end;

Function PCShooting(SC: ScenarioPtr; SeekModel: Boolean): Boolean;
	{The player wants to shoot something. Select a target and}
	{let fly!}
var
	TP: Point;	{The Target of the attack.}
	AR: AttackRequest;
	Rep: AttackReport;
begin
	{Error check- make sure the PC has a missile weapon equipped!}
	if SC^.PC^.Eqp[ES_MissileWeapon] = Nil then begin
		DCGameMessage('No missile weapon equipped!');
		Exit(False);
	end else if SC^.PC^.Eqp[ES_MissileWeapon]^.Charge = 0 then begin
		DCGameMessage('Out of ammo!');
		Exit(False);
	end;

	DCGameMessage('Targeting - Select Target: ');
	TP := SelectPoint(SC,True,SeekModel,SC^.PC^.Target);

	{Check to make sure a target was selected, and also}
	{the the player isn't trying to shoot himself.}
	if TP.X = -1 then Exit(False);
	if (TP.X = SC^.PC^.M^.X) and (TP.Y = SC^.PC^.M^.Y) then Exit(False);

	AR.HitRoll := PCMissileSkill(SC^.PC);
	AR.Damage := PCMissileDamage(SC^.PC);
	AR.Range := PCMissileRange(SC^.PC);
	AR.Attacker := SC^.PC^.M;
	AR.Tx := TP.X;
	AR.TY := TP.Y;
	AR.DF := DF_Physical;
	AR.C := LightRed;
	if SC^.PC^.Eqp[ES_MissileWeapon]^.state <> 0 then begin
		{If special ammunition is being used, add its attack attributes to the string.}
		AR.Damage := AR.Damage + CSpecAmmo[Abs(SC^.PC^.Eqp[ES_MissileWeapon]^.state)].DMG;
		if AR.Damage < 1 then AR.Damage := 1;
		AR.HitRoll := AR.HitRoll + CSpecAmmo[Abs(SC^.PC^.Eqp[ES_MissileWeapon]^.state)].ACC;
		if AR.HitRoll < 1 then AR.HitRoll := 1;
		AR.ATT := CSpecAmmo[Abs(SC^.PC^.Eqp[ES_MissileWeapon]^.state)].ATT + CGuns[SC^.PC^.Eqp[ES_MissileWeapon]^.icode].Att;
	end else begin
		AR.ATT := CGuns[SC^.PC^.Eqp[ES_MissileWeapon]^.icode].Att;
	end;
	if (Pos(AA_LineAttack,AR.ATT) > 0) or (Pos(AA_BlastAttack,AR.ATT) > 0) or (Pos(AA_SmokeAttack,AR.ATT) > 0) then
		AR.Desc := 'fire '+ItemNameShort(SC^.PC^.Eqp[ES_MissileWeapon])
	else
		AR.Desc := 'fire '+ItemNameShort(SC^.PC^.Eqp[ES_MissileWeapon])+' at';

	Rep := ProcessAttack(SC,AR);

	{Reduce the weapon's AMMO count, unless using infinite shot weapon.}
	if SC^.PC^.EQP[ES_MissileWeapon]^.Charge > -1 then
		Dec(SC^.PC^.EQP[ES_MissileWeapon]^.Charge);

	PCShooting := True;
end;

Function PCTosser(SC: ScenarioPtr): Boolean;
	{The PC wants to throw a grenade.}
	{The majority of this unit was simply copied from above.}
var
	TP: Point;	{The Target of the attack.}
	Grn: DCItemPtr;	{The grenade to be tossed.}
	AR: AttackRequest;
	Rep: AttackReport;
begin
	{Select a grenade to toss.}
	Grn := PromptItem(SC,IKIND_Grenade);
	if Grn = Nil then Exit(False);

	{Start the standard firing stuff.}
	DCGameMessage('Throw grenade - Select Target: ');
	TP := SelectPoint(SC,True,True,SC^.PC^.Target);

	{Check to make sure a target was selected, and also}
	{the the player isn't trying to shoot himself.}
	if TP.X = -1 then Exit(False);
	if (TP.X = SC^.PC^.M^.X) and (TP.Y = SC^.PC^.M^.Y) then Exit(False);

	{Check to make sure the target point is within the PC's}
	{maximum throwing range.}
	if Range(SC^.PC^.M,TP.X,TP.Y) > PCThrowRange(SC^.PC) then begin
		DCPointMessage('Out of range!');
		Exit(False);
	end;

	AR.HitRoll := PCThrowSkill(SC^.PC);
	AR.Damage := CGrn[Grn^.icode].Dmg;
	AR.Range := CGrn[Grn^.icode].Rng;
	AR.Attacker := SC^.PC^.M;
	AR.Tx := TP.X;
	AR.TY := TP.Y;
	AR.DF := DF_Physical;
	AR.C := Yellow;
	AR.ATT := CGrn[Grn^.icode].ATT;
	if (Pos(AA_LineAttack,AR.ATT) > 0) or (Pos(AA_BlastAttack,AR.ATT) > 0) or (Pos(AA_SmokeAttack,AR.ATT) > 0) then
		AR.Desc := 'throw '+ItemNameShort(Grn)
	else
		AR.Desc := 'throw '+ItemNameShort(Grn)+' at';

	Rep := ProcessAttack(SC,AR);

	{Consume the grenade.}
	ConsumeDCItem(SC^.PC^.Inv,Grn,1);

	PCTosser := True;
end;

Function PCInvScreen(SC: ScenarioPtr; StartWithInv: Boolean): Boolean;
	{Do the PC's Inventory screen. I moved that to a separate}
	{unit, since the whole shebang is a little involved.}
begin
	Inventory(SC,StartWithInv);
	PCReCenter(SC);
	PCStatLine(SC);
	PCInvScreen := False;
end;

Function PCPickUp(SC: ScenarioPtr): Boolean;
	{The PC is gonna pick up something. Return FALSE if there}
	{is no item present, or if the picking up is canceled.}
var
	it: Boolean;
	I,I2: DCItemPtr;
begin
	it := False;

	DCGameMessage('Get Item - ');

	if SC^.IG^[SC^.PC^.M^.X,SC^.PC^.M^.Y] <> Nil then begin
		{There's at least one item here. See if there's more.}
		if SC^.IG^[SC^.PC^.M^.X,SC^.PC^.M^.Y]^.next = Nil then begin
			{Simple case. There's only one item here.}
			{Grab it.}
			I := SC^.IG^[SC^.PC^.M^.X,SC^.PC^.M^.Y];
			DCAppendMessage('Got '+ItemNameLong(I)+'.');
			RetrieveDCItem(SC^.gb,SC^.ig,I,SC^.PC^.M^.X,SC^.PC^.M^.Y);
			MergeDCItem(SC^.PC^.Inv,I);
			it := true;
		end else begin
			{Difficult case. There's multiple items.}
			{List through them and prompt for picking up.}
			DCAppendMessage('Multiple items.');
			I2 := SC^.IG^[SC^.PC^.M^.X,SC^.PC^.M^.Y];
			while I2 <> Nil do begin
				I := I2;
				I2 := I2^.Next;
				DCGameMessage('Pick up '+ItemNameLong(I)+'? (Y/N)');
				if YesNo then begin
					RetrieveDCItem(SC^.gb,SC^.ig,I,SC^.PC^.M^.X,SC^.PC^.M^.Y);
					MergeDCItem(SC^.PC^.Inv,I);
					DCAppendMessage(' Done.');
				end else begin
					DCAppendMessage(' Nope.');
				end;
			end;
		end;
	end else begin
		DCAppendMessage('Not found!');
	end;

	PCPickUp := it;
end;

Function PCDisarmTrap(SC: ScenarioPtr): Boolean;
	{The player wants to disarm a trap. Make the appropriate}
	{roll, then either remove the selected trap (success) or}
	{walk the player over onto it (failure).}
var
	X,Y,DT: Integer;
	D,TrapD: Integer;
begin
	DCGameMessage('Disarm Trap -');
	TrapD := 0;

	X := SC^.PC^.M^.X;
	Y := SC^.PC^.M^.Y;

	{Locate the trap}
	for D := 1 to 9 do begin
		if SC^.gb^.map[X + VecDir[D,1],Y + VecDir[D,2]].trap > 0 then begin
			if TrapD = 0 then TrapD := D
			else TrapD := -1;
		end;
	end;

	{Do some checks now on the state of our trap.}
	if TrapD = -1 then begin
		DCAppendMessage(' Direction?');

		TrapD := DirKey;

		if ( TrapD <> 0 ) and not OnTheMap(X + VecDir[TrapD,1],Y + VecDir[TrapD,2]) then begin
			TrapD := 0;
		end else if (TrapD<>0) and (SC^.gb^.Map[X + VecDir[TrapD,1],Y + VecDir[TrapD,2]].trap < 1) then begin
			TrapD := 0;
		end;
	end;

	if TrapD = 0 then begin
		{No trap found. Inform the player of this.}
		DCAppendMessage(' Not found!');
		Exit(False);
	end;

	{Set X and Y to the location of the trap.}
	X := X+VecDir[TrapD,1];
	Y := Y+VecDir[TrapD,2];

	{One last check to perform- if there's a model in the way,}
	{the trap can't be disarmed.}
	if not SC^.gb^.mog[X,Y] then begin
		{Do the trap disarming stuff here.}
		{Roll the skill dice first.}
		DT := RollStep(PCDisarmSkill(SC^.PC));

		if DT >= TrapMan[Abs(SC^.gb^.map[X,Y].trap)].disarm then begin
			{The player gets some XP for having done this.}
			DoleExperience(SC,TrapMan[Abs(SC^.gb^.map[X,Y].trap)].disarm div 2);

			{Disarming was successful.}
			SC^.gb^.map[X,Y].trap := 0;
			DisplayTile(SC^.gb,X,Y);
			DCAppendMessage('Done.');

			{A Player who disarms a trap will stop repeated actions.}
			SC^.PC^.RepCount := 0;

		end else if DT < (TrapMan[Abs(SC^.gb^.map[X,Y].trap)].disarm div 3) then begin
			{Disarming critically failed.}
			DCAppendMessage('Failed.');
			PCMove(SC,TrapD);

			{A Player who sets off a trap will stop repeated actions.}
			SC^.PC^.RepCount := 0;
		end else begin
			{Disarming failed.}
			DCAppendMessage('Failed.');
		end;
	end else begin
		DCAppendMessage(' Blocked!');
	end;

	PCDisarmTrap := True;
end;

Function PCSearch(SC: ScenarioPtr): Boolean;
	{The player wants to perform a deliberate search for}
	{traps and secret doors.}
begin
	DCGameMessage('Searching...');
	CheckForTraps(SC,1);
	CheckForSecretDoors(SC,1);
	PCSearch := True;
end;

Function PCUsePsi(SC: ScenarioPtr; UseMenu: Boolean): Boolean;
	{The PC wants to invoke a psychic power. Call the procedure}
	{in the psi powers unit...}
begin
	PCUsePsi := CastSpell(SC,UseMenu);
end;

Function PCLookAround(SC: ScenarioPtr): Boolean;
	{The PC is just looking at the stuff around.}
begin
	DCGameMessage('Look: ');
	SelectPoint(SC,False,False,SC^.PC^.Target);
	DCPointMessage('Done.');
	PCLookAround := False;
end;

Function PCEnter(SC: ScenarioPtr): Boolean;
	{The player just hit the "enter location" key- < or >}
	{All this procedure does is to set up a trigger.}
begin
	SetTrigger( SC , PLT_EnterCom , GetTerr(SC^.gb,SC^.PC^.M^.X,SC^.PC^.M^.Y) );
	PCEnter := True;
end;

Function RepMove(SC: ScenarioPtr; D: Integer): Boolean;
	{The player is using a repeat command with movement.}
const
	In_A_Room = 1;
	In_A_Hall = 2;
	MvCmd: Array [1..9] of char = ('1','2','3','4','5','6','7','8','9');
{Local Procedures}
	function MoveBlocked(MX,MY: Integer): Boolean;
		{Check location MX,MY to see if the PC can move there.}
	var
		it: Boolean;
	begin
		if (TerrPass[GetTerr(SC^.gb,MX,MY)] < 1) or ModelPresent(SC^.gb^.mog,MX,MY) then
			it := true
		else it := false;
		MoveBlocked := it;
	end;
var
	X,Y,N,D2: Integer;
	Act: Boolean;
begin
	Act := False;

	if D = 5 then begin
		{This is a special case.}
		PCMove(SC,D);

		{Check to see if the PC is fully recovered.}
		{If so, stop resting.}
		if (SC^.PC^.HP >= SC^.PC^.HPMax) and (SC^.PC^.MP >= SC^.PC^.MPMax) then begin
			SC^.PC^.RepCount := 0;
		end;

		{Exit before any of the rest of this stuff can execute.}
		{I know, I could stick the main part of this procedure}
		{in an ELSE BEGIN...END block, but this way of doing}
		{things looks prettier to me.}
		Exit(True);
	end;

	{Determine the Repeat State. If 0, we need to set it.}
	if SC^.PC^.RepState = 0 then begin
		{Determine whether the PC is in a hall or in}
		{a room.}
		if MoveBlocked(SC^.PC^.M^.X+VecDir[D,2],SC^.PC^.M^.Y-VecDir[D,1]) and MoveBlocked(SC^.PC^.M^.X-VecDir[D,2],SC^.PC^.M^.Y+VecDir[D,1]) then begin
			SC^.PC^.RepState := In_A_Hall;
		end else begin
			SC^.PC^.RepState := In_A_Room;
		end;
	end;

	if SC^.PC^.RepState = In_A_Hall then begin
		X := SC^.PC^.M^.X + VecDir[D,1];
		Y := SC^.PC^.M^.Y + VecDir[D,2];

		{ Movement will stop if the PC steps on an item or trap. }
		if ( SC^.ig^[X,Y] <> Nil ) or ( SC^.gb^.map[X,Y].trap > 0 ) then begin
			SC^.PC^.RepCount := 0;

		end else if MoveBlocked(X,Y) then begin
			D2 := 0;
			for N := 1 to 9 do begin
				if not MoveBlocked(SC^.PC^.M^.X + VecDir[N,1],SC^.PC^.M^.Y + VecDir[N,2]) then begin
					{Check to make sure this isn't the same direction we just came from.}
					if (N <> (10-D)) then begin
						if D2 = 0 then D2 := N
						else D2 := -1;
					end;
				end;
			end;

			if D2 > 0 then begin
				{There's only one direction to go in.}
				SC^.PC^.LastCmd := MvCmd[D2];
				PCMove(SC,D2);
				Act := True;
			end else begin
				{End the movement here.}
				SC^.PC^.RepCount := 0;
			end;
		end else begin
			{Movement isn't blocked, but maybe there's}
			{an intersection here. That will stop movement too.}
			{Check the two normals to see if that is the case.}
			if not MoveBlocked(SC^.PC^.M^.X+VecDir[D,2],SC^.PC^.M^.Y-VecDir[D,1]) then begin
				SC^.PC^.RepCount := 0;
			end else if not MoveBlocked(SC^.PC^.M^.X-VecDir[D,2],SC^.PC^.M^.Y+VecDir[D,1]) then begin
				SC^.PC^.RepCount := 0;
			end else begin
				PCMove(SC,D);
				Act := True;
			end;
		end;
	end else begin
		{The PC must be in a room. Or something is}
		{seriously wrong. In any case, assume a room,}
		{since that's the safest bet.}
		X := SC^.PC^.M^.X + VecDir[D,1];
		Y := SC^.PC^.M^.Y + VecDir[D,2];

		if MoveBlocked(X,Y) or ( SC^.ig^[X,Y] <> Nil ) or ( SC^.gb^.map[X,Y].trap > 0 ) then begin
			{ The path is blocked, or there's an item on the }
			{ floor, or a visible trap or something. }
			{ Movement ends here.}
			SC^.PC^.RepCount := 0;
		end else begin
			{Actually complete the movement.}
			PCMove(SC,D);
			Act := True;
		end;
	end;

	RepMove := Act;
end;

Function PCRepeat(SC: ScenarioPtr): Boolean;
	{The PC wants to do something or another repeatedly.}
begin
	SC^.PC^.RepCount := 80;
	SC^.PC^.RepState := 0;
	PCRepeat := False;
end;

Function PCProcessRepeat(SC: ScenarioPtr): Boolean;
	{The PC has set up a repeating action. Process it.}
begin
	if SC^.PC^.LastCmd = KMap[1].Key then RepMove(SC,1)
	else if SC^.PC^.LastCmd = KMap[2].Key then RepMove(SC,2)
	else if SC^.PC^.LastCmd = KMap[3].Key then RepMove(SC,3)
	else if SC^.PC^.LastCmd = KMap[4].Key then RepMove(SC,4)
	else if SC^.PC^.LastCmd = KMap[5].Key then RepMove(SC,5)
	else if SC^.PC^.LastCmd = KMap[6].Key then RepMove(SC,6)
	else if SC^.PC^.LastCmd = KMap[7].Key then RepMove(SC,7)
	else if SC^.PC^.LastCmd = KMap[8].Key then RepMove(SC,8)
	else if SC^.PC^.LastCmd = KMap[9].Key then RepMove(SC,9)

	else if SC^.PC^.LastCmd = KMap[19].Key then PCSearch(SC)

	{If the command entered was not a repeatable one,}
	{set the counter to 0.}
	else SC^.PC^.RepCount := 0;

	PCProcessRepeat := True;
end;

Function PCCheckXP(SC: ScenarioPtr): Boolean;
	{Display XP level, current XP, and XP needed.}
var
	S1,S2,S3: String;
begin
	Str(SC^.PC^.Lvl,S1);
	Str(SC^.PC^.XP,S2);
	Str(XPNeeded(SC^.PC^.Lvl + 1),S3);

	DCGameMessage('Level '+S1+' : '+S2+' / '+S3+' XP.');

	PCCheckXP := False;
end;

Function PCInfoScreen(SC: ScenarioPtr): Boolean;
	{Display all important data for the PC.}
const
	C2X1 = 41;
	Y1 = 5;
	NumQD = 6;
	QD: Array [0..6] of string = (
		'miserable','bad','fair','okay','good',
		'very good','excellent'
	);
	NumFS = 8;
	FSN: Array [1..NumFS] of String = (
		'Fighting','Shooting','Detection','Stealth',
		'Hacking','Technology','Identify','Psi Control'
	);
	FSI: Array [1..NumFS] of Byte = (
		SKILL_MeleeAttack, SKILL_MissileAttack, SKILL_Detection, SKILL_Stealth,
		SKILL_DisarmTrap, SKILL_Technical, SKILL_Identify, SKILL_PsiSkill
	);
var
	T,N: Integer;
begin
	CLearMapArea;

	TextColor( LightGreen );
	GotoXY( 5 , Y1 );
	writeln( SC^.PC^.Name );
	TextColor( Green );
	write( '          level ' + BStr( SC^.PC^.Lvl ) + ' ' + JobName[ SC^.PC^.Job ] );
	GotoXY( 45 , Y1 + 1 );
	write( 'HP: ' + BStr( SC^.PC^.HP ) + '/' + BStr( SC^.PC^.HPMax ));
	GotoXY( 60 , Y1 + 1 );
	write( 'MP: ' + BStr( SC^.PC^.MP ) + '/' + BStr( SC^.PC^.MPMax ));

	for t := 1 to 8 do begin
		GotoXY( 5 , Y1 + 2 + T );
		TextColor( Green );
		Write( StatName[ T ] );
		GotoXY( 20, Y1 + 2 + T );
		TextColor( LightGreen );
		Write( SC^.PC^.Stat[ T ] );
	end;

	{ Display the Featured Skills }
	for t := 1 to NumFS do begin
		GotoXY( C2X1 , Y1 + 2 + T );
		TextColor( Green );
		Write( FSN[T] );
		GotoXY( C2X1 + 12 , Y1 + 2 + T );
		TextColor( LightGreen );
		N := SC^.PC^.Skill[ FSI[T] ];
		if N < 0 then N := 0
		else if N > NumQD then N := NumQD;
		Write( QD[N] );
	end;

	RPGKey;

	{Restore the display, and exit the function.}
	PCReCenter(SC);
	PCStatLine(SC);
	PCInfoScreen := False;
end;

Procedure ScanUnknownInv( SC: ScenarioPtr );
	{ Check through the items in the PC's inventory, and try to ID any }
	{ of them that are currently unknown. }
var
	didit: Boolean;		{ Well? Dideedoit!? }
	I,I2: DCItemPtr;
	T: Integer;
begin
	{ Initialize values. }
	didit := False;
	I := SC^.PC^.Inv;

	{ Scan inventory }
	while I <> Nil do begin
		I2 := I^.Next;

		{ If this item hasn't been identified, we want to examine it. }
		if not I^.ID then begin
			AttemptToIdentify( SC , I );

			{ If the attempt was successful, merge this item into }
			{ the main inventory. }
			if I^.ID then begin
				didit := True;
				DelinkDCItem( SC^.PC^.Inv , I );
				MergeDCItem( SC^.PC^.Inv , I );
			end;
		end;

		I := I2;
	end;

	for t := 1 to NumEquipSlots do begin
		if ( SC^.PC^.Eqp[t] <> Nil ) and not SC^.PC^.Eqp[t]^.ID then begin

			AttemptToIdentify( SC , SC^.PC^.Eqp[t] );

			{ If the attempt was successful, merge this item into }
			{ the main inventory. }
			if SC^.PC^.Eqp[t]^.ID then begin
				didit := True;
			end;
		end;
	end;

	if didit then DCGameMessage('You learn something about the items you are carrying...');
end;

Function PCHandyMap(SC: ScenarioPtr): Boolean;
	{ Do the HandyMap display, then restore the view afterwards. }
begin
	if HasItem( SC^.PC^.Inv , IKIND_Electronics , 1 ) then begin
		DCGameMessage( 'Accessing Handymap.' );
		HandyMap( SC );

		{Restore the display, and exit the function.}
		PCReCenter(SC);
		PCStatLine(SC);
	end else begin
		DCGameMessage( 'You don''t have a Handymap!' );
	end;

	PCHandyMap := False;
end;

end.
