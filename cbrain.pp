unit cbrain;
	{This unit handles critter behavior and stuff.}

interface

uses crt,RPGDice,RPGText,TexModel,TexMaps,statusfx,spells,Critters,DCItems,DCChars,GameBook,dccombat,cwords;

Procedure CritterAction(SC: ScenarioPtr; var C: CritterPtr);
Procedure BrownianMotion(SC: ScenarioPtr);


implementation

uses plotbase;

Const
	AvoidTrapTarget = 15;	{Avoiding traps is easier for critters.}

Function WalkCritter(SC: ScenarioPtr; DX,DY: Integer): WalkReport;
	{Move the monster to wherever it's going. NOTE: C might be}
	{made Nil by this procedure, if killed by a trap!}
var
	it: WalkReport;
begin
	{Is there a door in the way? If so, forget movement... Open}
	{the door instead. If the monster can't open the door, attack}
	{it and maybe it'll be destroyed.}


	{Perform the movement.}
	it := MoveModel(SC^.CAct^.M,SC^.gb,SC^.CAct^.M^.X + DX,SC^.CAct^.M^.Y + DY);
	if it.go and not SC^.CAct^.Spotted then begin
		if TileLOS(SC^.GB^.POV,SC^.CAct^.M^.X,SC^.CAct^.M^.Y) and OnTheScreen(SC^.GB,SC^.CAct^.M^.X,SC^.CAct^.M^.Y) then begin
			UpdateMonsterMemory(SC,SC^.CAct);
		end;
	end;

	{Check for traps here. Robots & Zombies don't set off traps;}
	{other critter types might.}
	if it.go and (SC^.gb^.map[SC^.CAct^.M^.X,SC^.CAct^.M^.Y].trap <> 0) and (SC^.CAct^.M^.gfx <> 'R') and (SC^.CAct^.M^.gfx <> '@') then
		if RollStep(MonMan[SC^.CAct^.Crit].Sense) < AvoidTrapTarget then
			SpringTrap(SC,SC^.CAct^.M^.X,SC^.CAct^.M^.Y);

	WalkCritter := it;
end;

Function GetLockOnPC(SC: ScenarioPtr; C: CritterPtr): Boolean;
	{The critter in question is trying to get a "lock" on}
	{the PC. Make a Sense roll against the PC's Stealth}
	{skill.}
var
	O: Integer;
	it: Boolean;
begin
	{If the player is out of range, we can't get a lock.}
	if Range(C^.M,SC^.PC^.M) > (MonMan[C^.Crit].Sense *2) then Exit(False);

	O := CalcObscurement(C^.M,SC^.PC^.M,SC^.GB);
	if O > -1 then begin
		if RollStep(PCStealth(SC^.PC)) < (RollStep(MonMan[C^.Crit].Sense) - O) then it := true
		else it := false;
	end else begin
		{If there's no LOS, there's no lock.}
		it := False;
	end;
	GetLockOnPC := it;
end;

Function MoveOK(SC: ScenarioPtr; X,Y: Integer): Boolean;
	{Answer the question- is it okay to move here?}
var
	it: boolean;
begin
	{Begin by assuming that the move is OK.}
	it := true;

	{Check for models in the target space.}
	if SC^.GB^.Mog[X,Y] then begin
		it := FindModelXY(SC^.gb^.mlist,X,Y)^.CoHab;
	end;

	if (TerrPass[SC^.GB^.Map[X,Y].terr] < 1) then
		it := false;

	MoveOK := it;
end;

Function TacRange(C: CritterPtr): Integer;
	{Given critter C, determine its effective combat range.}
var
	it: Integer;
begin
	if (C^.Eqp <> Nil) and (C^.Eqp^.ikind = IKIND_Gun) then begin
		it := CGuns[C^.Eqp^.icode].rng;
	end else it := MonMan[C^.Crit].range;

	TacRange := it;
end;

Procedure CritterAttack(SC: ScenarioPtr; C: CritterPtr; TX,TY: Integer);
	{Critter C wants to attack whatever is in square TX,TY.}
var
	AR: AttackRequest;
	Rep: AttackReport;
begin
	{Fill out the Attack Request.}
	AR.Attacker := C^.M;
	AR.TX := TX;
	AR.TY := TY;
	AR.DF := DF_Physical;
	AR.C := LightRed;

	{Fill out the rest of the data dependant upon what equipment}
	{the creature is using.}
	if (C^.Eqp <> Nil) and (C^.Eqp^.ikind = IKIND_Gun) then begin
		AR.HitRoll := MonMan[C^.Crit].HitRoll + CGuns[C^.Eqp^.icode].ACC;
		AR.Damage := CGuns[C^.Eqp^.icode].DMG;
		AR.Range := CGuns[C^.Eqp^.icode].RNG;
		AR.ATT := CGuns[C^.Eqp^.icode].ATT;

		if Pos(AA_LineAttack,AR.ATT) > 0 then
			AR.Desc := 'fires '+ItemNameShort(C^.Eqp)
		else
			AR.Desc := 'fires '+ItemNameShort(C^.Eqp)+' at';

	end else if (C^.Eqp <> Nil) and (C^.Eqp^.ikind = IKIND_Wep) then begin
		AR.HitRoll := MonMan[C^.Crit].HitRoll + CWep[C^.Eqp^.icode].ACC;
		AR.Damage := MonMan[C^.Crit].Damage + CWep[C^.Eqp^.icode].DMG;
		AR.Range := -1;
		AR.Desc := 'swings '+ItemNameShort(C^.Eqp)+' at';
		AR.ATT := CWep[C^.Eqp^.icode].ATT;

	end else begin
		AR.HitRoll := MonMan[C^.Crit].HitRoll;
		AR.Damage := MonMan[C^.Crit].Damage;
		AR.Range := MonMan[C^.Crit].Range;
		AR.Desc := MonMan[C^.Crit].ADesc;
		AR.ATT := MonMan[C^.Crit].AtAt;
	end;

	{Process the attack. If a fatality is inflicted on the}
	{critter's target, the Excommunicate procedure will reset}
	{the target field to Nil.}
	Rep := ProcessAttack(SC,AR);
end;

Procedure ActPassive(SC: ScenarioPtr);
	{The critter is gonna be acting passively right now.}
	{Move it in a random direction; don't attack anything.}
var
	D,T: Integer;
begin
	D := Random(9) + 1;

	if D <> 5 then begin
		t := 1;
		while not MoveOK(SC,SC^.CAct^.M^.X+VecDir[D,1],SC^.CAct^.M^.Y+VecDir[D,2]) and (T <= 3) do begin
			D := Random(8) + 1;
			if D > 4 then D := D + 1;
			Inc(t);
		end;
	end;

	WalkCritter(SC,VecDir[D,1],VecDir[D,2]);
end;

Procedure ActAgressive(SC: ScenarioPtr; var C: CritterPtr);
	{This critter apparently has a target. Try to get as}
	{close to it as possible.}
var
	DX,DY: Integer;
	WR: WalkReport;
begin
	{Check, first of all, that we have a target.}
	if C^.Target = Nil then begin
		ActPassive(SC);
		Exit;
	end;

	{Next, on a random whim, check to make sure the target is}
	{still visible.}
	if (Random(3) = 1) and (C^.Target = SC^.PC^.M) and not C^.Spotted then begin
		DX := CalcObscurement(C^.M,C^.Target,SC^.GB);
		if (DX = -1) or (DX > MonMan[C^.Crit].Sense) then begin
			C^.Target := Nil;
			ActPassive(SC);
			Exit;
		end;

	end else if (Random(10) = 3) then begin
		if (C^.HP >= MonMan[C^.Crit].MaxHP) then begin
			DX := CalcObscurement(C^.M,C^.Target,SC^.GB);
			if (DX = -1) or (DX > MonMan[C^.Crit].Sense) then begin
				C^.Target := Nil;
				ActPassive(SC);
				Exit;
			end;
		end;
	end;

	{Check to see whether or not our critter is gonna try a missile attack.}
	if (TacRange(C) > 0) and (Random(2) = 1) and (CalcObscurement(C^.M,C^.Target,SC^.GB) > -1) then begin
		{ In addition to the above qualifiers, the critter will }
		{ only use a missile attack if its target is within visual }
		{ range or if it can be seen by the PC. }
		if ( Range( C^.M , C^.Target ) < MonMan[ C^.Crit ].Sense ) or TileLOS( SC^.gb^.pov , C^.M^.X , C^.M^.Y ) then begin
			CritterAttack(SC,C,C^.Target^.X,C^.Target^.Y);
			Exit;
		end;
	end;

	{We aren't gonna try a missile attack.}
	{Move towards the target.}
	if C^.Target^.X < C^.M^.X then DX := -1
	else if C^.Target^.X > C^.M^.X then DX := 1
	else DX := 0;

	if C^.Target^.Y < C^.M^.Y then DY := -1
	else if C^.Target^.Y > C^.M^.Y then DY := 1
	else DY := 0;

	{Check to see if we're in attack range.}
	if (C^.M^.X+DX <> C^.Target^.X) or (C^.M^.Y+DY <> C^.Target^.Y) then begin
		{Check for obstructions}
		if not MoveOK(SC,C^.M^.X+DX,C^.M^.Y+DY) then begin
			if MoveOK(SC,C^.M^.X+DX,C^.M^.Y) then DY := 0
			else if MoveOK(SC,C^.M^.X,C^.M^.Y+DY) then DX := 0
			else if Random(2) = 1 then begin
				ActPassive(SC);
				Exit;
			end;
		end;
	end;

	WR := WalkCritter(SC,DX,DY);
	if SC^.CAct = Nil then exit;

	if (WR.M <> Nil) then begin
		{The critter has walked into a model. Decide}
		{whether or not to attack.}

		{If the model is in the same square as the critter's target,}
		{it will be attacked. Before I just used to compare the}
		{target model with WR.M, but since adding clouds to the game}
		{I have to compare the position of WR.M to the position of}
		{the intended target. This is important just in case the}
		{critter is attempting to attack a hallucination-inducing}
		{cloud, and instead blunders into one of its own buddies...}

		if (WR.M^.X = C^.Target^.X) and (WR.M^.Y = C^.Target^.Y) then begin
			CritterAttack(SC,C,WR.M^.X,WR.M^.Y);
		end;
	end; 
end;

Procedure ActPCHunter(SC: ScenarioPtr; var C: CritterPtr);
	{The critter is gonna attempt to hunt down and destroy}
	{the player character, to the exclusion of all other}
	{targets. If the PC is not in sight, either track him}
	{(if within tracking range) or act passively.}
begin
	{Determine whether or not the monster can get a 'lock'}
	{on the player. To do this, we use the monster's Sense}
	{rating versus the player's Stealth rating.}
	if GetLockOnPC(SC,C) then C^.Target := SC^.PC^.M;

	if C^.Target <> Nil then
		ActAgressive(SC,C)
	else
		ActPassive(SC);
end;

Procedure ActChaos(SC: ScenarioPtr; var C: CritterPtr);
	{The critter is gonna be acting chaotically right now.}
var
	D,t: Integer;
	WR: WalkReport;
begin
	{Determine a direction to move in. We don't want dir 5}
	{to be a valid choice.}
	D := Random(8) + 1;
	if D > 4 then D := D + 1;

	t := 1;
	while (TerrPass[SC^.GB^.Map[C^.M^.X+VecDir[D,1],C^.M^.Y+VecDir[D,2]].terr] < 1) and (T <= 3) do begin
		D := Random(8) + 1;
		if D > 4 then D := D + 1;
		Inc(t);
	end;

	WR := WalkCritter(SC,VecDir[D,1],VecDir[D,2]);
	if SC^.CAct = Nil then exit;

	if (WR.M <> Nil) then begin
		{Chaotic critters usually won't attack others of}
		{their own kind... usually. As a lazy way of}
		{checking this and making alliances, assume that any}
		{two models using the same letter to represent them}
		{are friendly.}
		if (WR.M^.Kind = MKIND_Critter) and (WR.M^.Gfx = C^.M^.Gfx) and (Random(100) <> 23) then begin
			if TileLOS(SC^.GB^.POV,C^.M^.X,C^.M^.Y) and OnTheScreen(SC^.GB,C^.M^.X,C^.M^.Y) then begin
				DCGameMessage(MonMan[C^.Crit].Name + ' growls.');
			end;
		end else if (WR.M^.Kind = MKIND_Character) or (WR.M^.Kind = MKIND_Critter) then begin
			if Random(8) <> 5 then C^.Target := WR.M;
			CritterAttack(SC,C,WR.M^.X,WR.M^.Y);
		end;
	end;
end;

Procedure ActGuardian(SC: ScenarioPtr; C: CritterPtr);
	{This critter is the guardian of a room.}
var
	X,Y: Integer;
	M: ModelPtr;
begin
	{The guardian may try to acquire a target, or may remain in}
	{standby mode.}
	if Random(10) = 1 then begin
		{Try to acquire a target.}
		For X := C^.M^.X - MonMan[C^.Crit].sense to C^.M^.X + MonMan[C^.Crit].sense do begin
			For Y := C^.M^.Y - MonMan[C^.Crit].sense to C^.M^.Y + MonMan[C^.Crit].sense do begin
				if ModelPresent(SC^.gb^.mog,X,Y) then begin
					M := FindModelXY(SC^.gb^.mlist,X,Y);
					if M^.Kind = MKIND_Character then begin
						ActPCHunter(SC,C);
					end else if M^.Kind = MKIND_Critter then begin
						if (M^.gfx <> C^.M^.gfx) and (Random(3) = 1) and (CalcObscurement(C^.M,M,SC^.GB) > -1) then C^.Target := M;
					end;
				end;
			end;
		end;
	end;

	if C^.Target <> Nil then ActAgressive(SC,C);

	if Random(5) = 3 then ActChaos(SC,C)
	else if Random(3) = 2 then ActPassive(SC);
	{Else, just sit there and do nothing.}
end;

Procedure ActSlimy(SC: ScenarioPtr; var C: CritterPtr);
	{The big thing about a slime is that it never moves.}
	{It just sits there, and attacks whatever is within reach.}
	{Slimes give prefrence to attacking the PC. If the PC}
	{isn't nearby, it may attack other targets randomly.}
	Procedure SlimeDoNothing;
		{The slime is gonna do nothing, a la ACS.}
	const
		SlimeAct: Array [1..5] of string = ('quivers.','twitches.','emits a low groaning sound.','drips acid onto the floor.','suddenly goes very still...');
	begin
		if Random(64) = 9 then begin
			if TileLOS(SC^.GB^.POV,C^.M^.X,C^.M^.Y) and OnTheScreen(SC^.GB,C^.M^.X,C^.M^.Y) then begin
				DCGameMessage(MonMan[C^.Crit].Name + ' ' + SlimeAct[Random(5)+1]);
			end;
		end;
	end;
	Procedure SlimeAttack;
		{The Slime wants to attack something. Of course,}
		{given the fact that slimes can't move, this might}
		{not be possible.}
	begin
		{Slimes with ranged attacks may attack anyhow.}
		if ( TacRange(C) > -1 ) and ( Range( C^.M , C^.Target ) <= MonMan[C^.Crit].Sense ) and ( CalcObscurement( C^.M , C^.Target , SC^.gb ) > -1 ) then CritterAttack(SC,C,C^.Target^.X,C^.Target^.Y)
		else if (Abs(C^.M^.X - C^.Target^.X) <= 1) and (Abs(C^.M^.Y - C^.Target^.Y) <= 1) then CritterAttack(SC,C,C^.Target^.X,C^.Target^.Y)
		else SlimeDoNothing;
	end;
	{I just noticed something. For lower-order organisms,}
	{slimes sure is pretty complicated. Their behavior procedure}
	{is the biggest one so far. Maybe that's just because I}
	{like them...}
var
	D: Integer;
	M: ModelPtr;
begin
	{If the slime has a target, then attack it.}
	if C^.Target <> Nil then SlimeAttack;

	{If the slime has no target, try to get a lock on the PC.}
	if GetLockOnPC(SC,C) then begin
		C^.Target := SC^.PC^.M;
		SlimeAttack;
	end;

	{The slime hasn't got a target. Just lash out at anything nearby!}
	D := Random(8) + 1;
	if D>4 then Inc(D);
	if SC^.gb^.mog[C^.M^.X+VecDir[D,1],C^.M^.Y+VecDir[D,2]] then begin
		{Aha! There's a model here! Thwack it! Uhh... unless it's another slime, of course.}
		M := FindModelXY(SC^.gb^.mlist,C^.M^.X+VecDir[D,1],C^.M^.Y+VecDir[D,2]); 
		if (M^.gfx <> C^.M^.gfx) and (M^.Kind = MKIND_Critter) then begin
			CritterAttack(SC,C,C^.M^.X+VecDir[D,1],C^.M^.Y+VecDir[D,2]);
		end;
	end else SlimeDoNothing;
end;

Procedure ActHalfHunter(SC: ScenarioPtr; var C: CritterPtr);
	{This one is easy. Make a random roll, then branch to}
	{a different procedure.}
begin
	if Random(2) = 1 then ActPCHunter(SC,C)
	else ActChaos(SC,C);
end;

Procedure TryToBreed( SC: ScenarioPtr; C: CritterPtr );
	{ A breeding monster will reproduce if: }
	{  - there are less than the max number of monsters on board }
	{  - there is a free spot somewhere close to the breeder }
var
	D,X,Y: Integer;
begin
	if NumberOfCritters( SC^.CList ) < CHART_MaxMonsters then begin
		{ Determine a direction in which to generate the new }
		{ monster. The direction can't be "5". }
		D := Random( 8 ) + 1;
		if D > 4 then Inc( D );
		X := C^.M^.X + VecDir[ D , 1 ];
		Y := C^.M^.Y + VecDir[ D , 2 ];

		{ Do the checks to make sure this spot is good for adding }
		{ a monster. }
		if OnTheMap( X , Y ) and ( TerrPass[sc^.gb^.map[X,Y].terr] > 0 ) then begin
			if not SC^.gb^.mog[X,Y] then begin
				AddCritter( SC^.CList , SC^.GB , C^.Crit , X , Y );
			end;
		end;
	end;
end;

Function CritterActive(C: CritterPtr): Boolean;
	{Return TRUE if a given critter is capable of acting}
	{right now, FALSE if it is for any reason incapacitated.}
var
	it: Boolean;
begin
	it := true;
	if NAttValue(C^.SF,NAG_StatusChange,SEF_Paralysis) <> 0 then it := false
	else if NAttValue(C^.SF,NAG_StatusChange,SEF_Sleep) <> 0 then it := false;
	CritterActive := it;
end;

Procedure CritterAction(SC: ScenarioPtr; var C: CritterPtr);
	{Critter C is about to perform some sort of action. Yay!}
	{Decide what it's gonna do based on its AI type.}
begin
	SC^.CAct := C;

	if CritterActive(C) then begin
		if ( Pos(  XCT_Breeder , MonMan[C^.Crit].CT ) > 0 ) and ( Random( 15 ) = 1 ) then begin
			TryToBreed( SC , C );
		end else If (C^.Target <> Nil) and (C^.AIType <> AIT_Slime) then begin
			ActAgressive(SC,C);
		end else begin
			Case C^.AIType of
				AIT_Passive: ActPassive(SC);
				AIT_PCHunter: ActPCHunter(SC,C);
				AIT_Chaos: ActChaos(SC,C);
				AIT_Guardian: ActGuardian(SC,C);
				AIT_Slime: ActSlimy(SC,C);
				AIT_HalfHunter: ActHalfHunter(SC,C);
			end;
		end;
	end;
	{Protect against the case where the creature has already died}
	if SC^.CAct <> Nil then begin
	    {Update the critter's status.}
		if NAttValue(C^.SF,NAG_StatusChange,SEF_Poison) <> 0 then begin
			C^.HP := C^.HP - Random( 6 );
		end;
		UpdateStatusList( C^.SF );
	end;

	if C^.HP < 0 then CritterDeath(SC,C,False);
	C := SC^.CAct;
	SC^.CAct := Nil;
end;

Procedure BrownianMotion(SC: ScenarioPtr);
	{All of the clouds in the FOG section of the scenario are gonna}
	{drift around lonely as a cloud. Forcewalls are just gonna sit}
	{where they are.}
var
	C,C2: CloudPtr;
begin
	C := SC^.Fog;
	while C <> Nil do begin
		{Save the location of the next cloud in the list.}
		C2 := C^.Next;

		if SC^.ComTime >= C^.Duration then begin
			{This cloud has reached the end of its lifespan.}
			Excommunicate(SC,C^.M);
			RemoveCloud(SC^.Fog,C,SC^.gb);
		end else if CloudMan[C^.Kind].Pass then begin
			{Clouds which cannot be moved through are forcewalls,}
			{and stay where they're to. Other clouds drift.}
			{Do drifting now.}
			if Random(3) <> 1 then begin
				MoveModel(C^.M,SC^.gb,C^.M^.X+Random(2)-Random(2),C^.M^.Y+Random(2)-Random(2));
			end;
		end;

		{Move to the next cloud.}
		C := C2;
	end;
end;

end.
