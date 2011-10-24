unit dccombat;
	{This unit handles the main combat stuff for DeadCold.}
	{This includes attacking, damaging, etc, for both critters}
	{and the PC.}

	{Critters and PCs have hit points. Terrain features and}
	{inanimate models don't have hit points, but they still may}
	{be damaged by attacks.}

	{This unit also holds the definitions and procedures needed}
	{for traps in the game. Combat, traps, same thing, right?}

interface

uses rpgdice,rpgtext,texmodel,texmaps,texfx,statusfx,spells,critters,dcitems,dcchars,gamebook,charts,cwords,plotbase;

Type
	AttackRequest = Record
		HitRoll: Integer;	{HitRoll step number}
		Damage: Integer;	{Damage Roll step number}
		Range: Integer;		{Range of the attack.}
			{Used to calculate hit modifiers, and}
			{scatter in case of a miss.}
		Attacker: ModelPtr;	{The Attacker.}
		TX,TY: Integer;		{Target square.}
			{If there's a model in the target square,}
			{this procedure assumes that said model is the}
			{intended victim of the attack.}
		DF: Byte;		{What defense does this attack target?}
		C: Byte;		{Color of shot}
		ATT: String;		{Attack Attributes}
		Desc: String;		{An optional description.}
	end;
	AttackReport = Record
		{This record tells the results of the attack.}
		ItHit: Boolean;		{Did the attack hit?}
		Fatal: Boolean;		{Is the target dead?}
		Damage: Integer;	{The amount of damage done.}
		XPV: Integer;		{Amount of XP earned.}
	end;

	TrapDesc = Record
		{This record describes a trap. Duh.}
		Name: String;	{Used when looking at ID'd trap.}
		Desc: String;	{Used when trap is activated.}
		DMG: Integer;	{Damage done by trap.}
		Disarm: Integer;	{Target number to disarm.}
	end;

Const
	CDropEqp = 50;	{% chance that killed creature will drop Eqp item.}
	BlastBaseTarget = 5;	{Base target number for blast attacks.}
	TrapNum = 5;
	TrapMan: Array [1..TrapNum] of TrapDesc = (
		(	Name: 'Electrical Discharger';
			Desc: 'zapped with 10,000 volts of electricity';
			DMG: 2; Disarm: 10	),
		(	Name: 'Automated Sentry Turret';
			Desc: 'shot by a sentry gun';
			DMG: 8; Disarm: 5	),
		(	Name: 'Laser Guardwire';
			Desc: 'sliced by a beam of laser light';
			DMG: 16; Disarm: 10	),
		(	Name: 'Alarm';
			Desc: 'momentarily flashed by a spot light';
			DMG: 0; Disarm: 20	),
		(	Name: 'Plasma Barrier';
			Desc: 'immolated by a plasma field';
			DMG: 42; Disarm: 15	)
	);

Function DamagePC(SC: ScenarioPtr; MOS: Integer; ATT: String; var DMG: Integer): Boolean;
Procedure CritterDeath(SC: ScenarioPtr; C: CritterPtr; KilledByPC: Boolean);
Function ProcessAttack(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
Procedure RevealTrap(SC: ScenarioPtr; TX,TY: Integer);
Procedure SpringTrap(SC: ScenarioPtr; TX,TY: Integer);

implementation

uses Crt;

Function DamagePC(SC: ScenarioPtr; MOS: Integer; ATT: String; var DMG: Integer): Boolean;
	{Damage is about to be done to the PC. Woohoo! The monsters}
	{finally accomplished something!}
	{Return TRUE if the PC has been killed; FALSE if he's still}
	{standing.}
var
	E,FxRoll,V,Armor: Integer;
	gameover: Boolean;
begin
	{If the character is asleep, he/she will take double damage}
	{from a successful hit and be immediately woken up.}
	If NAttValue( SC^.PC^.SF , NAG_StatusChange, SEF_Sleep ) <> 0 then begin
		DMG := DMG * 2;
		SetNAtt( SC^.PC^.SF , NAG_StatusChange, SEF_Sleep , 0 );
	end;

	{If the PC is performing a continual action, that is cancelled.}
	SC^.PC^.RepCount := 0;

	{Calculate Armor rating.}
	Armor := PCArmorPV(SC^.PC);

	{Reduce for MOS}
	if MOS > 0 then begin
		if MOS > 4 then MOS := 4;
		Armor := (Armor * (4 - MOS)) div 4;
	end;

	{Reduce for Armor-Piercing attacks. Increase for }
	if Pos(ATT,AA_ArmorDoubling) <> 0 then Armor := Armor * 2
	else if Pos(ATT,AA_ArmorPiercing) <> 0 then Armor := (Armor+1) div 2;

	{Reduce damage for armor.}
	DMG := DMG - Armor;
	if DMG < 1 then DMG := 1;

	SC^.PC^.HP := SC^.PC^.HP - DMG;
	PCStatLine(SC);

	if SC^.PC^.HP > 0 then begin
		gameover := false;

		{There may be status change effects here.}
		E := AAVal(ATT,AA_StatusChange);
		if E <> 0 then begin
			FxRoll := AAVal(ATT,AA_HitRoll);
			if (FxRoll=0) or (RollStep(FxRoll)>RollStep(PCLuckSave(SC^.PC))) then begin
				v := RollStep( AAVal( ATT , AA_Value ) );
				if v < 5 then v := 5;
				AddNAtt( SC^.PC^.SF , NAG_StatusChange , -E , v );
				DCAppendMessage('You are '+LowerCase(NegSFName[E])+'!');
			end;
		end;
	end else begin
		gameover := true;
		Excommunicate(SC,SC^.PC^.M);
	end;

	DamagePC := gameover;
end;

Procedure CritterDeath(SC: ScenarioPtr; C: CritterPtr; KilledByPC: Boolean);
	{A critter has died. Deal with it.}
var
	I: DCItemPtr;
	N: Integer;
begin
	if C = Nil then begin
		DCGameMessage('SHAZBOT - The attemptes killing of a nonexistant critter.');
		Exit;
	end;

	{Critters will only drop random treasure if they are killed}
	{by the PC.}
	if KilledByPC then begin
		if (MonMan[C^.Crit].TType > 0) then begin
			N := 0;
			while (N < MonMan[C^.Crit].TNum) and (Random(100) < MonMan[C^.Crit].TDrop) do begin
				Inc(N);
				I := GenerateItem(SC,MonMan[C^.Crit].TType);
				PlaceDCItem(SC^.gb,SC^.ig,I,C^.M^.X,C^.M^.Y);
			end;
		end;
	end;

	if (C^.Eqp <> Nil) and (Random(100) < CDropEqp) then begin
		{The critter dropped whatever it was carrying.}
		PlaceDCItem(SC^.gb,SC^.ig,C^.Eqp,C^.M^.X,C^.M^.Y);
		{Set the Eqp field to Nil, or else the RemoveCritter procedure}
		{will delete the item. And mess up our map.}
		C^.Eqp := Nil;
	end;

	Excommunicate(SC,C^.M);
	RemoveCritter(C,SC^.CList,SC^.GB);
end;

Function DamageCritter(SC: ScenarioPtr; C: CritterPtr; MOS: Integer; AR: AttackRequest; var DMG: Integer; var Rep: AttackReport): Boolean;
	{Damages a critter. Returns TRUE if the critter has been}
	{destroyed; returns FALSE if it is still functional.}
var
	OriginalDamage,E,N,V,Armor: Integer;
	snuffedit: Boolean;
begin
	{Save the original damage}
	OriginalDamage := DMG;

	{Scale damage for elemental types.}
	{First, determine what element is being invoked.}
	E := AAVal(AR.ATT,AA_Element);
	DMG := ScaleCritterDamage(C,DMG,E);

	{Scale damage for critter slaying attribute.}
	E := AAVal(AR.ATT,AA_Slaying);
	if (E > 0) and (Pos(CTMan[E],MonMan[C^.Crit].CT) > 0) then begin
		if DMG < OriginalDamage then DMG := OriginalDamage;
		DMG := DMG * (2 + Random(3));
	end;

	{Reduce damage for armor, and increase it for condition.}
	if DMG > 0 then begin
		{If a critter is asleep, then it will take double damage}
		{from a successful hit and be woken up if it survives.}
		If NAttValue( C^.SF , NAG_StatusChange, SEF_Sleep ) <> 0 then begin
			DMG := DMG * 2;
			SetNAtt( C^.SF , NAG_StatusChange, SEF_Sleep , 0 );
		end;

		{Calculate Armor rating.}
		Armor := MonMan[C^.Crit].Armor;

		{Reduce for MOS}
		if MOS > 0 then begin
			if MOS > 4 then MOS := 4;
			Armor := (Armor * (4 - MOS)) div 4;
			if TileLOS(SC^.gb^.pov,C^.M^.X,C^.M^.Y) then DCAppendMessage('Critical Hit!');
		end;

		{Reduce for Armor-Piercing}
		if Pos(AR.ATT,AA_ArmorDoubling) <> 0 then Armor := Armor * 2
		else if Pos(AR.ATT,AA_ArmorPiercing) <> 0 then Armor := (Armor+1) div 2;

		DMG := DMG - Armor;
		if DMG < 1 then DMG := 1;
	end;

	C^.HP := C^.HP - DMG;
	if C^.HP > 0 then begin
		{The target is still alive. See what else needs to be done.}
		snuffedit := false;

		{There may be status change effects here.}
		E := AAVal(AR.ATT,AA_StatusChange);
		if E <> 0 then begin
			N := AAVal(AR.ATT,AA_HitRoll);
			if (N=0) or (RollStep(N)>RollStep(MonMan[C^.Crit].mystic)) then begin
				v := RollStep( AAVal( AR.ATT , AA_Value ) );
				if v < 5 then v := 5;
				if SetCritterStatus(C,-E,v) and TileLOS(SC^.gb^.pov,C^.M^.X,C^.M^.Y) then DCAppendMessage(NegSFName[E]+'!');
			end;
		end;
	end else begin
		snuffedit := true;

		{Add the XPV of the critter to the Attack Report's XPV field.}
		rep.XPV := rep.XPV + MonMan[C^.Crit].XPV;

		CritterDeath(SC,C,AR.Attacker = SC^.PC^.M);
	end;
	DamageCritter := SnuffedIt;
end;

Function RollDamage( DC: Integer ): Integer;
	{ Normally, this function just calls RollStep to do the dice }
	{ rolling. However, if the DAMAGECAP option is set, it also }
	{ makes sure that the damage rolled doesn't exceed a certain }
	{ amount. }
var
	DMG: Integer;
begin
	DMG := RollStep( DC );

	{ If DAMAGECAP is on, check to make sure the amount of damage }
	{ rolled doesn't exceed the maximum. }
	if COMBAT_DamageCap then begin
		{ Store the Damage Cap value in DC }
		DC := DC * 2 + 3;
		if DMG > DC then DMG := DC;
	end;

	RollDamage := DMG;
end;

Function DamageTarget(SC: ScenarioPtr; TX,TY,MOS: Integer; var AR: AttackRequest; var DMG: Integer; var Rep: AttackReport): Boolean;
	{Do DMG damage to whatever happens to be sitting at map}
	{location TX,TY.}
	{MOS is the Margin Of Success}
var
	M: ModelPtr;
	exparrot: Boolean;
begin
	exparrot := False;
	if SC^.GB^.Mog[TX,TY] then begin
		{It's a model. Do something appropriate to it.}
		M := FindModelXY(SC^.GB^.MList,TX,TY);
		case M^.Kind of
			MKIND_Critter: exparrot := DamageCritter(SC,LocateCritter(M,SC^.CList),MOS,AR,DMG,Rep);
			MKIND_Character: exparrot := DamagePC(SC,MOS,AR.ATT,DMG);
		end;

	end;
	DamageTarget := exparrot;
end;

Procedure AlertOthers(SC: ScenarioPtr; C: CritterPtr; DMG: Integer);
	{The PC has just attacked critter C. All other critters}
	{of this type now have a chance to target the PC for}
	{retribution.}
var
	CTemp: CritterPtr;
begin
	CTemp := SC^.CList;
	while CTemp <> Nil do begin
		if (CTemp^.M^.gfx = C^.M^.gfx) and (CTemp^.Target = Nil) and (Range(CTemp^.M,C^.M) < 25) then begin
			{This critter is a contemporary of the one}
			{which was attacked.}
			{Check to see whether the shot was noticed.}
			if (CTemp^.AIType <> AIT_Passive) and (RollStep(MonMan[CTemp^.Crit].sense) > RollStep(PCStealth(SC^.PC) - DMG)) then begin
				CTemp^.Target := SC^.PC^.M;
			end;
		end;
		CTemp := CTemp^.next;
	end;
end;

Function RollDefenses(SC: ScenarioPtr; AR: AttackRequest; TX,TY: Integer): Integer;
	{Roll the defenses for whatever is in location TX,TY}
var
	DefRoll,DfSt: Integer;
	C: CritterPtr;
begin
	if SC^.GB^.Mog[TX,TY] then begin
		{the target is a model. Yay! Determine if it's a}
		{critter, the PC, or something else, then look up}
		{its defense value.}
		DfSt := ModelDefenseStep(SC,FindModelXY(SC^.GB^.MList,TX,TY),AR.DF);
		{Do the defense roll. Note that unlike most rolls,}
		{defense rolls have a minimum value.}
		DefRoll := RollStep(DfSt);
		if DefRoll < DfSt then DefRoll := DfSt;

		{While we're here, might as well do something else}
		{altogether. If a critter is attacked, it switches its}
		{TARGET to whatever model attacked it.}
		if FindModelXY(SC^.GB^.MList,TX,TY)^.Kind = MKIND_Critter then begin
			C := LocateCritter(FindModelXY(SC^.GB^.MList,TX,TY),SC^.CList);
			if C^.M <> AR.Attacker then begin
				C^.Target := AR.Attacker;
				if AR.Attacker^.Kind = MKIND_Character then begin
					SC^.PC^.Target := FindModelXY(SC^.GB^.MList,TX,TY);
					AlertOthers(SC,C,AR.Damage);
				end;
			end;
		end;
	end else begin
		{There's no model present, meaning that we're}
		{firing at a map tile. It's not likely to dodge.}
		DefRoll := 0;
	end;

	RollDefenses := DefRoll;
end;

Function DirectFire(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
	{The attack being invoked is a regular, old fashioned,}
	{direct fire attack.}
var
	O: Integer;
	AVis,TVis: Boolean;
	Rep: AttackReport;
	DefRoll,ARoll: Integer;
	MOS,DBonus: Integer;
	TName,msg: string;
	P: Point;
begin
	{Initialize Attack Report}
	rep.XPV := 0;

	{Do some checking for missile attacks.}
	if AR.Range > -1 then begin
		{Determine obscurement. If the target can't be seen,}
		{switch TX,TY to whatever obstacle is in the way.}
		O := CalcObscurement(AR.Attacker,AR.TX,AR.TY,SC^.GB);
		if O = -1 then begin
			P := LocateBlock(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY);
			AR.TX := P.X;
			AR.TY := P.Y;
			O := CalcObscurement(AR.Attacker,AR.TX,AR.TY,SC^.GB);
		end;

		{Calculate range modifier.}
		if AR.Range > 0 then
			O := O + (Range(AR.Attacker,AR.TX,AR.TY) div AR.Range)
		else
			O := O + Range(AR.Attacker,AR.TX,AR.TY);
	end else begin
		{It's a melee attack. No obscurement.}
		O := 0;
	end;

	{Determine the visibility status of the attacker and target.}
	AVis := TileLOS(SC^.GB^.POV,AR.Attacker^.X,AR.Attacker^.Y);
	TVis := TileLOS(SC^.GB^.POV,AR.TX,AR.TY);

	{Initialize values.}
	Rep.Fatal := False;
	Rep.XPV := 0;
	msg := '';

	if SC^.GB^.Mog[AR.TX,AR.TY] then begin
		tname := ModelName(SC,FindModelXY(SC^.GB^.MList,AR.TX,AR.TY));
	end else begin
		tname := TerrName[SC^.GB^.Map[AR.TX,AR.TY].terr];
	end;

	{Announce the attack.}
	if AVis or TVis then begin
		if AVis then msg := ModelName(SC,AR.Attacker)
		else msg := 'Something';

		if (AR.Desc <> '') and (Random(3) = 1) then begin
			if AR.Attacker^.Kind = MKIND_Character then msg := 'You '+AR.Desc+' '
			else msg := msg + ' ' + AR.Desc + ' ';
		end else begin
			if AR.Attacker^.Kind = MKIND_Character then msg := 'You attack '
			else msg := msg + ' attacks ';
		end;

		if TVis then
			msg := msg + tname
		else
			msg := msg + 'something';
	end;

	{Determine the defense roll of the target.}
	DefRoll := RollDefenses(SC,AR,AR.TX,AR.TY);

	{Determine the attack roll of the attacker.}
	ARoll := RollStep(AR.HitRoll) - O;

	{Add punctuation to our message string, then print.}
	if Length(msg) > 0 then begin
		if Random(8) = 5 then msg := msg + '... '
		else if ARoll > 50 then msg := msg + '!!! '
		else if ARoll > 25 then msg := msg + '! '
		else if ARoll > 5 then msg := msg + '. '
		else begin
			if Random(5) = 1 then msg := msg + '? '
			else msg := msg + ', sort of... ';
		end;
	end;

	if ARoll > DefRoll then begin
		{The attack hit! Do whatever needs to be done...}
		{Determine Margin of Success}
		if DefRoll > 0 then
			MOS := ARoll div DefRoll - 1
		else MOS := ARoll div 10;
		{There's a maximum value for MOS, based on magnitude of the roll.}
		if AROLL < 15 then MOS := 0
		else if MOS > ((AROLL - 10) div 5) then MOS := ((ARoll - 10) div 5);

		{Determine Damage Bonus}
		DBonus := Random(MOS+1);
		MOS := MOS - DBonus;
		if MOS > 4 then begin
			DBonus := DBonus + MOS - 4;
			MOS := 4;
		end;

		Rep.ItHit := True;
		Rep.Damage := RollDamage(AR.Damage + (DBonus*3));
		if Length(msg) > 0 then msg := msg + 'The attack hit!';
	end else begin
		{The attack missed! Again, do whatever needs to be done...}
		Rep.ItHit := False;
		if (Random(3) = 2) and TVis then
			msg := msg + TName + ' dodged the attack.'
		else if Length(msg) > 0 then
			msg := msg + 'The attack missed.'
	end;

	if Length(msg) > 0 then begin
		DCGameMessage(msg);
		msg := '';
	end;

	if TVis or AVis then
		DisplayShot(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY,AR.C,Rep.ItHit);

	{Damage the target now, after the shot has been displayed.}
	if Rep.ItHit then begin
		Rep.Fatal := DamageTarget(SC,AR.TX,AR.TY,MOS,AR,Rep.Damage,Rep);
		if TVis and (Rep.Damage > 0) then begin
			Str(Rep.Damage,msg);
			msg := msg + ' damage!';
		end else if TVis and (Rep.Damage < 0) then begin
			Str(Abs(Rep.Damage),msg);
			msg := msg + ' HP restored!';
		end else if TVis and (Rep.Damage = 0) then begin
			msg := msg + ' No damage!';
		end;
	end;

	if Rep.Fatal and TVis then msg := msg + ' ' + tname + ' died!';
	if Length(msg)>0 then DCAppendMessage(msg);

	DirectFire := Rep;
end;

Function LineAttack(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
	{The attack being processed is a line attack. It keeps going,}
	{affecting every model it touches, until it runs out of range}
	{or until it hits a wall.}
var
	t: Integer;
	rep: AttackReport;
	ARoll,DRoll: Integer;	{Attack Roll/Defense Roll}
	Dmg: Integer;		{Damage done.}
	P: Point;
	TName: String;		{The target's name. Useful to store, in case it dies.}
	F: Boolean;		{Fatality counter}
begin
	{Begin by making sure the Range is an appropriate value.}
	if AR.Range < 2 then AR.Range := 2;

	{Initialize values.}
	rep.ItHit := False;
	rep.Fatal := False;
	rep.Damage := 0;
	rep.XPV := 0;

	{Do the initial message here, if appropriate}
	if TileLOS(SC^.GB^.POV,AR.Attacker^.X,AR.Attacker^.Y) then begin
		{Print message saying what's going on.}
		if AR.Attacker^.Kind = MKIND_Character then
			DCGameMessage('You ' + AR.Desc+'.')
		else
			DCGameMessage(ModelName(SC,AR.Attacker) + ' ' + AR.Desc+'.');
	end;

	for t := 1 to AR.Range do begin
		{Calculate the current target square.}
		P := SolveLine(AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY,T);

		if ModelPresent(SC^.gb^.mog,p.x,p.y) then begin
			{Determine the defense roll of the target.}
			DRoll := RollDefenses(SC,AR,P.X,P.Y);

			{Determine the attack roll of the attacker.}
			ARoll := RollStep(AR.HitRoll);

			{Determine the target's name. Modify for PC.}
			tname := ModelName(SC,FindModelXY(SC^.GB^.MList,p.X,p.Y));
			if tname = 'you' then tname := 'You';

			if ARoll > DRoll then begin
				{Hit!}
				Rep.ItHit := True;
				Dmg := RollDamage(AR.Damage);

				MapSplat(SC^.gb,'*',AR.C,p.X,p.Y,False);

			end else if ARoll > (DRoll div 2) then begin
				{Partial hit! Half damage!}
				Rep.ItHit := True;
				Dmg := RollDamage((AR.Damage+1) div 2);

				MapSplat(SC^.gb,'+',AR.C,p.X,p.Y,False);

			end else begin
				{Complete miss!}
				Dmg := 0;

				MapSplat(SC^.gb,'-',AR.C,p.X,p.Y,False);
			end;

			if Dmg > 0 then begin
				{Line Attacks never score critical hits.}
				f := DamageTarget(SC,p.X,p.Y,0,AR,Dmg,Rep);
				rep.damage := rep.damage + dmg;

				if f then rep.fatal := true;
				if TileLOS(SC^.GB^.POV,p.X,p.Y) then begin
					if f then DCAppendMessage(TName + ' died!')
					else if tname = 'You' then DCAppendMessage('You are hit!')
					else if DMG > 0 then DCAppendMessage(TName + ' is hit!')
					else if DMG < 0 then DCAppendMessage(TName + ' is healed!');
				end;
			end;

		end else begin
			{There's no model here. Just do the gfx.}
			MapSplat(SC^.gb,'+',AR.C,p.X,p.Y,False);
		end;

		{If visible, do an animation delay.}
		if TileLOS(SC^.GB^.POV,p.X,p.Y) then Delay(FrameDelay div 2);

		{If there's a wall here, break the loop.}
		if TerrPass[GetTerr(SC^.gb,p.x,p.y)] < 1 then break;
	end;

	{Clean up the display.}
	for t := 1 to AR.Range do begin
		{Calculate the current target square.}
		P := SolveLine(AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY,T);
		DisplayTile(SC^.gb,p.x,p.y);
	end;

	LineAttack := rep;
end;

Function BlastAttack(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
	{This attack is, like, a big explosion or something.}
var
	Rep: AttackReport;
	BRad: Integer;	{Blast Radius}
	X,Y: Integer;
	O,Dmg: Integer;
	F,Vis: Boolean;
	ARoll,DRoll: Integer;
	TName: String;
	P: Point;
begin
	{Initialize values.}
	rep.ItHit := False;
	rep.Fatal := False;
	rep.Damage := 0;
	rep.XPV := 0;
	BRad := AAVal(AR.Att,AA_BlastAttack);
	if BRad < 0 then BRad := 0;
	Vis := False;

	{Check to see if the shot hit the desired spot}
	if (AR.Range <> 0) and (RollStep(AR.HitRoll) > (Range(AR.Attacker,AR.TX,AR.TY) div AR.Range + BlastBaseTarget)) then begin
		{roll for deviation}
		{We'll use X for the total range right now.}
		X := Range(AR.Attacker,AR.TX,AR.TY) div 2;
		if X < 2 then X := 2;
		AR.TX := AR.TX + Random(X) - Random(X);
		AR.TY := AR.TY + Random(X) - Random(X);
	end;

	{Check to make sure our grenade isn't trying to bounce through a wall.}
	if CalcObscurement(AR.Attacker,AR.TX,AR.TY,SC^.gb) = -1 then begin
		P := LocateStop(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY);
		AR.TX := P.X;
		AR.TY := P.Y;
	end;

	{Do the initial message here, if appropriate}
	if TileLOS(SC^.GB^.POV,AR.Attacker^.X,AR.Attacker^.Y) then begin
		{Print message saying what's going on.}
		if AR.Attacker^.Kind = MKIND_Character then
			DCGameMessage('You ' + AR.Desc+'.')
		else
			DCGameMessage(ModelName(SC,AR.Attacker) + AR.Desc+'.');
	end;

	{Display the path of the projectile, if appropriate.}
	if TileLOS(SC^.gb^.pov,AR.Attacker^.X,AR.Attacker^.Y) or TileLOS(SC^.gb^.pov,AR.TX,AR.TY) then begin
		DisplayShot(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY,AR.C,True);
	end;

	for X := (AR.TX - BRad) to (AR.TX + BRad) do begin
		for Y := (AR.TY - BRad) to (AR.TY + BRad) do begin
			O := CalcObscurement(X,Y,AR.TX,AR.TY,SC^.gb);
			if (O > -1) and (O < AR.Damage) then begin

				if TileLOS(SC^.gb^.pov,X,Y) then begin
					{This square will be affected by the blast.}
					MapSplat(SC^.gb,'*',AR.C,X,Y,True);
					Vis := True;
				end;

				if ModelPresent(SC^.gb^.mog,X,Y) then begin
					{Determine the defense roll of the target.}
					DRoll := RollDefenses(SC,AR,X,Y);
					{Determine the attack roll of the attacker.}
					ARoll := RollStep(AR.HitRoll);
					{Determine the target's name. Modify for PC.}
					tname := ModelName(SC,FindModelXY(SC^.GB^.MList,X,Y));
					if tname = 'you' then tname := 'You';

					if ARoll > DRoll then begin
						{Hit!}
						Rep.ItHit := True;
						Dmg := RollDamage(AR.Damage - O);

					end else if ARoll > (DRoll div 2) then begin
						{Partial hit! Half damage!}
						Rep.ItHit := True;
						Dmg := RollDamage(AR.Damage+1-O) div 2;

					end;

					if Dmg > 0 then begin
						{Blast Attacks never score critical hits.}
						f := DamageTarget(SC,X,Y,0,AR,Dmg,Rep);
						rep.damage := rep.damage + dmg;

						if f then rep.fatal := true;
						if TileLOS(SC^.GB^.POV,X,Y) then begin
							if f then DCAppendMessage(TName + ' died!')
							else if tname = 'You' then DCAppendMessage('You are hit!')
							else if DMG > 0 then DCAppendMessage(TName + ' is hit!')
							else if DMG < 0 then DCAppendMessage(TName + ' is healed!');
						end;
					end;
				end;
			end;
		end;
	end;

	if Vis then begin
		Delay(FrameDelay);
		{Restore the display.}
		for X := (AR.TX - BRad) to (AR.TX + BRad) do begin
			for Y := (AR.TY - BRad) to (AR.TY + BRad) do begin
				DisplayTile(SC^.gb,X,Y);
			end;
		end;
	end;

	BlastAttack := Rep;
end;

Function SmokeAttack(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
	{This attack will just cause lots of smoke.}
var
	Rep: AttackReport;
	SKind,BRad,Dur: Integer;	{Smoke Kind, Blast Radius, Duration}
	X,Y: Integer;
	P: Point;
begin
	{Initialize values.}
	rep.ItHit := True;
	rep.Fatal := False;
	rep.Damage := 0;
	rep.XPV := 0;

	SKind := AAVal(AR.Att,AA_SmokeAttack);
	BRad := AAVal(AR.Att,AA_Value);
	Dur := AAVal(AR.Att,AA_Duration);
	if Dur < 1 then Dur := 1;


	{Check to see if the shot hit the desired spot}
	if (AR.Range <> 0) and (RollStep(AR.HitRoll) > (Range(AR.Attacker,AR.TX,AR.TY) div AR.Range + BlastBaseTarget)) then begin
		{roll for deviation}
		{We'll use X for the total range right now.}
		X := Range(AR.Attacker,AR.TX,AR.TY) div 2;
		if X < 2 then X := 2;
		AR.TX := AR.TX + Random(X) - Random(X);
		AR.TY := AR.TY + Random(X) - Random(X);
		Rep.ItHit := False;
	end;

	{Check to make sure our grenade isn't trying to bounce through a wall.}
	if CalcObscurement(AR.Attacker,AR.TX,AR.TY,SC^.gb) = -1 then begin
		P := LocateStop(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY);
		AR.TX := P.X;
		AR.TY := P.Y;
	end;

	{Do the initial message here, if appropriate}
	if TileLOS(SC^.GB^.POV,AR.Attacker^.X,AR.Attacker^.Y) then begin
		{Print message saying what's going on.}
		if AR.Attacker^.Kind = MKIND_Character then
			DCGameMessage('You ' + AR.Desc+'.')
		else
			DCGameMessage(ModelName(SC,AR.Attacker) + AR.Desc+'.');
	end;

	{Display the path of the projectile, if appropriate.}
	if TileLOS(SC^.gb^.pov,AR.Attacker^.X,AR.Attacker^.Y) or TileLOS(SC^.gb^.pov,AR.TX,AR.TY) then begin
		DisplayShot(SC^.gb,AR.Attacker^.X,AR.Attacker^.Y,AR.TX,AR.TY,AR.C,True);
	end;

	{Go through every point in the blast radius. If appropriate, add}
	{a cloud to each one.}
	for X := (AR.TX - BRad) to (AR.TX + BRad) do begin
		for Y := (AR.TY - BRad) to (AR.TY + BRad) do begin
			if (CalcObscurement(X,Y,AR.TX,AR.TY,SC^.gb) > -1) and (TerrPass[GetTerr(SC^.gb,X,Y)] > 0) then begin
				AddCloud( SC^.Fog , SC^.gb , SKind , X , Y , SC^.ComTime + (Dur * 12) + RollStep(6) );
			end;
		end;
	end;

	{Return the attack report, for what it's worth.}
	SmokeAttack := Rep;
end;


Function ProcessAttack(SC: ScenarioPtr; AR: AttackRequest): AttackReport;
	{We have a filled-out AttackRequest structure. Process it.}
var
	Rep: AttackReport;
begin
	if Pos(AA_LineAttack,AR.ATT)>0 then Rep := LineAttack(SC,AR)
	else if Pos(AA_BlastAttack,AR.ATT)>0 then Rep := BlastAttack(SC,AR)
	else if Pos(AA_SmokeAttack,AR.ATT)>0 then Rep := SmokeAttack(SC,AR)
	else Rep := DirectFire(SC,AR);

	if (AR.Attacker^.Kind = MKIND_Character) and (Rep.XPV > 0) then DoleExperience(SC,Rep.XPV);

	ProcessAttack := Rep;
end;

Procedure RevealTrap(SC: ScenarioPtr; TX,TY: Integer);
	{Reveal the trap at location X,Y so that the player will}
	{be able to see it.}
begin
	SC^.gb^.map[TX,TY].trap := Abs(SC^.gb^.map[TX,TY].trap);
	DisplayTile(SC^.gb,TX,TY);
end;

Procedure TheTrapStuffIsHere(SC: ScenarioPtr; TX,TY: Integer);
	{Do the actual causing of damage trap stuff now.}
var
	M: ModelPtr;
	D: Integer;
	DS: String;
	AR: AttackRequest;
	rep: AttackReport;
begin
	{Do the trap animation here.}
	if TileLOS(SC^.gb^.pov,TX,TY) then begin
		Case Abs(SC^.gb^.map[TX,TY].trap) of
			1: PikaPikaOuch(SC^.gb,TX,TY);
			2: DakkaDakka(SC^.gb,TX,TY);
			3: LaserCut(SC^.gb,TX,TY);
		end;
	end;

	AR.Att := '';
	AR.Attacker := Nil;

	M := FindModelXY(SC^.gb^.mlist,TX,TY);

	if M <> Nil then begin
		{Do the damage.}
		if TrapMan[Abs(SC^.gb^.map[TX,TY].trap)].DMG > 0 then begin
			D := RollStep(TrapMan[Abs(SC^.gb^.map[TX,TY].trap)].DMG);

			DamageTarget(SC,TX,TY,4,AR,D,rep);

			if TileLOS(SC^.gb^.pov,TX,TY) then begin
				Str(D,DS);
				DCAppendMessage(' ' + DS + ' damage!');
			end;
		end else begin
			{ This is apparently a non-damaging trap. }
			case TrapMan[Abs(SC^.gb^.map[TX,TY].trap)].DMG of
				0:	if M = SC^.PC^.M then SetTrigger( SC , 'ALARM' );
			end;
		end;
	end;
end;

Procedure SpringTrap(SC: ScenarioPtr; TX,TY: Integer);
	{Spring the trap at location TX,TY, damaging creatures if}
	{there are any present.}
var
	M: ModelPtr;
	T: Integer;
	TName: String;
begin
	{Error check- make sure we have a trap to spring!}
	T := Abs(SC^.gb^.map[TX,TY].trap);
	if T = 0 then exit;

	{Find out who sprung it.}
	M := FindModelXY(SC^.gb^.mlist,TX,TY);
	if M <> Nil then begin
		TName := ModelName(SC,M);
	end;

	{What happens next depends upon whether or not the PC}
	{is watching.}
	if TileLOS(SC^.gb^.pov,TX,TY) then begin
		{The PC can see this. Better tell her what's going on.}
		DCGameMessage('Trap!');

		if M <> Nil then begin
			{Explain exactly what the trap is doing.}
			if M^.Kind = MKIND_Critter then
				DCAppendMessage(TName+' is '+TrapMan[T].Desc+'!')
			else if M^.Kind = MKIND_Character then
				DCAppendMessage('You are '+TrapMan[T].Desc+'!');

			{Do damage to target, and report on it.}
			TheTrapStuffIsHere(SC,TX,TY);
		end;

		{If it's the character in the trap, pause after the message.}
		if (M <> Nil) and (M^.Kind = MKIND_Character) and (SC^.PC^.HP > 0) then GamePause;

		{Since this trap is within LOS, it's now revealed.}
		RevealTrap(SC,TX,TY);
	end else if M <> Nil then begin
		{A trap has been sprung, but the PC can't see it.}
		{Just damage the creature involved.}
		TheTrapStuffIsHere(SC,TX,TY);
	end;
end;

end.
