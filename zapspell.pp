unit zapspell;
	{This unit handles two distinct things: Spells and Item}
	{effects.}

interface

uses crt,rpgdice,rpgtext,rpgmenus,texmodel,texmaps,texfx,statusfx,spells,critters,dcchars,gamebook,dccombat,looker,plotbase;

Procedure ProcessSpell(SC: ScenarioPtr; S: SpellDescPtr);
Function CastSpell(SC: ScenarioPtr; UseMenu: Boolean): Boolean;


implementation

Const
	BColor = Blue;
	IColor = LightMagenta;
	SColor = Magenta;
	MX1 = 16;
	MY1 = 5;
	MX2 = 65;
	MY2 = 17;
	DY1 = 17;
	DY2 = 21;


Function ShootAttack(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{This spell shoots something, just like a missile attack.}
var
	TP: Point;
	AR: AttackRequest;
begin
	DCAppendMessage('Select Target: ');
	TP := SelectPoint(SC,True,True,SC^.PC^.Target);

	{Check to make sure a target was selected, and also}
	{the the player isn't trying to shoot himself.}
	if TP.X = -1 then Exit(False);
	if (TP.X = SC^.PC^.M^.X) and (TP.Y = SC^.PC^.M^.Y) then Exit(False);

	AR.HitRoll := S^.P1;
	AR.Damage := S^.Step;
	AR.Range := S^.P2;
	AR.Attacker := SC^.PC^.M;
	AR.Tx := TP.X;
	AR.TY := TP.Y;
	AR.DF := DF_Mystic;
	AR.C := S^.C;
	AR.ATT := S^.Att;
	AR.Desc := S^.cdesc;

	ProcessAttack(SC,AR);

	ShootAttack := True;
end;

Function CloseAttack(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{This spell zaps something, just like a melee attack.}
var
	D,Err: Integer;
	AR: AttackRequest;
begin
	DCAppendMessage('Direction?');

	{Select a direction. Make sure an appropriate direction was chosen.}
	Val(RPGkey,D,Err);
	if (Err <> 0) or (D = 5) then Exit(False);

	AR.HitRoll := S^.P1;
	AR.Damage := S^.Step;
	AR.Range := -1;
	AR.Attacker := SC^.PC^.M;
	AR.Tx := SC^.PC^.M^.X + VecDir[D,1];
	AR.TY := SC^.PC^.M^.Y + VecDir[D,2];
	AR.DF := DF_Mystic;
	AR.C := S^.C;
	AR.ATT := S^.Att;
	AR.Desc := S^.cdesc;

	ProcessAttack(SC,AR);

	CloseAttack := True;
end;

Function Residual(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Add a residual type to the PC's status list.}
begin
	SetNAtt( SC^.PC^.SF , NAG_StatusChange , S^.Step , S^.P1 * 10 );

	{Just in case this is a FarSight type spell, do an update.}
	if S^.Step = SEF_VisionBonus then begin
		SC^.gb^.pov.range := PCVisionRange(SC^.PC);
		UpdatePOV(SC^.gb^.POV,SC^.gb);
		ApplyPOV(SC^.gb^.POV,SC^.gb);
	end;

	{Display message.}
	if S^.Step >= 0 then DCAppendMessage('Done.')
	else DCAppendMessage('You are '+LowerCase(NegSFName[Abs(S^.Step)])+'!');

	Residual := True;
end;

Function Healing(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Restore HP to the PC.}
var
	dhp: integer;	{Delta HP}
	msg: string;
begin
	dhp := SC^.PC^.HP;

	{Restore HP; make sure it doesn't go over HPMax.}
	SC^.PC^.HP := SC^.PC^.HP + RollStep(S^.Step);
	if SC^.PC^.HP > SC^.PC^.HPMax then SC^.PC^.HP := SC^.PC^.HPMax;
	PCStatLine(SC);

	dhp := SC^.PC^.HP - dhp;
	Str(dhp,msg);
	msg := msg + ' hit points restored.';
	DCAppendMessage(msg);

	Healing := True;
end;

Function MagicMap(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Go through every map tile within range. If the tile is}
	{a floor, and the % chance is rolled, reveal that tile.}
var
	X,Y: Integer;
begin
	for X := (SC^.PC^.M^.X-S^.P1) to (SC^.PC^.M^.X+S^.P1) do begin
		for Y := (SC^.PC^.M^.Y-S^.P1) to (SC^.PC^.M^.Y+S^.P1) do begin
			if OnTheMap(X,Y) then begin
				{Only terrain which is within the cutoff range may be sensed.}
				if (TerrPass[GetTerr(SC^.gb,X,Y)]>=S^.P2) and (Random(100)<S^.Step) then begin
					SC^.gb^.map[X,Y].visible := True;
				end;
			end;
		end;
	end;

	DCAppendMessage('You sense distant locations.');
	DisplayMap(SC^.gb);
	MagicMap := True;
end;

Function StatAttack(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Affect every enemy model within range with a given}
	{status change condition.}
var
	itworked: Boolean;
	X,Y: Integer;
	C: CritterPtr;
	V: Integer;
begin
	itworked := false;

	{Determine the accuracy of the attack, also its Value and}
	{Duration. Use defaults if these values can't be found.}
	V := RollStep( AAVal(S^.ATT,AA_Value) );
	if V < 5 then V := 5;

	for X := (SC^.PC^.M^.X-S^.P1) to (SC^.PC^.M^.X+S^.P1) do begin
		for Y := (SC^.PC^.M^.Y-S^.P1) to (SC^.PC^.M^.Y+S^.P1) do begin
			if ModelPresent(SC^.gb^.mog,X,Y) then begin
				C := LocateCritter(FindModelXY(SC^.gb^.mlist,X,Y),SC^.CList);
				if C <> Nil then begin
					if RollStep(S^.P2) > RollStep(MonMan[C^.Crit].Mystic) then begin
						if SetCritterStatus( C , S^.Step , v ) then begin
							MapSplat(SC^.gb,'*',S^.C,X,Y,False);
							itworked := true;
						end;
					end;
				end;
			end;
		end;
	end;

	if itworked then begin
		DCAppendMessage('Done.');
		Delay(FrameDelay);
		DisplayMap(SC^.gb);

		{Give the PC a few points for successfully using}
		{this spell.}
		DoleExperience(SC,Random(3));
	end else DCAppendMessage('Failed!');

	StatAttack := True;
end;

Function CureStatus(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Cure the PC of status S.}
begin
	if NAttValue( SC^.PC^.SF , NAG_StatusChange , S^.Step ) = 0 then begin
		DCAppendMessage('No effect!');
		CureStatus := False;
	end else begin
		SetNAtt( SC^.PC^.SF , NAG_StatusChange , S^.Step , 0 );
		DCAppendMessage('Cured!');

		CureStatus := True;

		PCStatLine( SC );
	end;
end;

Function Teleport(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{Allow the player to teleport, either randomly or}
	{controlledly.}

	Function GoodSpot(X,Y: Integer): Boolean;
		{Check spot X,Y and see if this is a good place to}
		{teleport to.}
	var
		it: Boolean;
	begin
		if TerrPass[sc^.gb^.map[X,Y].terr] < 1 then it := False
		else if SC^.gb^.mog[X,Y] then it := False
		else it := True;
		GoodSpot := it;
	end;

var
	X,Y,D,Tries: Integer;
begin
	{Select destination point.}
	Tries := 0;
	repeat
		D := Random(8)+1;
		if D > 4 then Inc(D);
		X := SC^.PC^.M^.X + VecDir[D,1]*S^.Step + Random(5)-Random(5);
		Y := SC^.PC^.M^.Y + VecDir[D,2]*S^.Step + Random(5)-Random(5);
		Inc(Tries);
	until OnTheMap(X,Y) or (Tries = 5);

	if OnTheMap(X,Y) then begin

		while (tries < 1000) and not GoodSpot(X,Y) do begin
			Inc(Tries);
			X := X + Random(10) - Random(10);
			if X > XMax then X := XMax
			else if X < 1 then X := 1;
			Y := Y + Random(10) - Random(10);
			if Y > YMax then Y := YMax
			else if Y < 1 then Y := 1;
		end;		

		if GoodSpot(X,Y) then begin
			MoveModel(SC^.PC^.M,SC^.gb,X,Y);
			DCAppendMessage('Done.');
		end else DCAppendMessage('Failed.');
	end else begin
		DCAppendMessage('Failed!');
	end;

	Teleport := True;
end;

Function SenseAura(SC: ScenarioPtr; S: SpellDescPtr): Boolean;
	{The PC gets to see every monster currently on screen.}
var
	M: ModelPtr;
	success: Boolean;
begin
	ClearMapArea;
	success := false;

	{Scan through every model in the list, looking for models}
	{to display.}
	M := SC^.gb^.mlist;

	while M <> Nil do begin
		if OnTheScreen(SC^.gb,M^.X,M^.Y) and (M^.Kind = S^.Step) then begin
			MapSplat(SC^.gb,M^.gfx,M^.color,M^.X,M^.Y,True);
			success := true;
		end;
		M := M^.Next;
	end;

	if success then
		DCAppendMessage('Done.')
	else
		DCAppendMessage('Failed.');
	GamePause;

	{Restore the map display.}
	DisplayMap(SC^.gb);
	SenseAura := True;
end;

Procedure ProcessSpell(SC: ScenarioPtr; S: SpellDescPtr);
	{The PC is invoking spell S. This may be through psi}
	{powers or through the use of an item. Whatever the case,}
	{determine the results.}
begin
	Case S^.eff of
		EFF_ShootAttack: ShootAttack(SC,S);
		EFF_CloseAttack: CloseAttack(SC,S);
		EFF_Residual: 	Residual(SC,S);
		EFF_Healing:	Healing(SC,S);
		EFF_MagicMap:	MagicMap(SC,S);
		EFF_StatAttack: StatAttack(SC,S);
		EFF_CureStatus: CureStatus(SC,S);
		EFF_Teleport: Teleport(SC,S);
		EFF_SenseAura: SenseAura(SC,S);
	end;
end;

Procedure SetQuickLink(SC: ScenarioPtr; SCode: Integer);
	{Assign a letter to one of the PC's spells, for quick}
	{casting later.}
const
	instr: PChar = 'Select a letter to represent this spell.';
	qmerr: PChar = 'Invalid character.';
var
	S: SpellMemPtr;
	C: Char;
begin
	{Display instructions}
	GameMessage(instr,MX1,MY2,MX2,MY2+2,IColor,BColor);

	C := RPGKey;

	if (Upcase(C) >= 'A') and (Upcase(C) <= 'Z') then begin
		{Make sure no other spellmem has this key linked.}
		S := SC^.PC^.Spell;
		while S <> Nil do begin
			if S^.mnem = C then S^.mnem := ' ';
			S := S^.Next;
		end;

		S := LocateSpellMem(SC^.PC^.Spell,SCode);
		if S <> Nil then begin
			S^.mnem := C;
		end;
	end else begin
		GameMessage(qmerr,MX1,MY2,MX2,MY2+2,IColor,BColor);
		ReadKey;
	end;
end;

Function ChooseSpell(SC: ScenarioPtr): Integer;
	{Create a menu from the PC's spell list. Query for a spell.}
	{Return whatever spell was chosen, or -1 for Cancel.}
const
	instr: PChar = '[SPACE] to cast, [/] to quickmark';
	QMval = -10;
var
	RPM: RPGMenuPtr;
	S: SpellMemPtr;
	it: Integer;
begin
	DCPointMessage(' which spell?');
	repeat
		{Display instructions}
		GameMessage(instr,MX1,DY2,MX2,DY2+2,IColor,BColor);

		{Create the menu.}
		RPM := CreateRPGMenu(BColor,SColor,IColor,MX1,MY1,MX2,MY2);
		RPM^.DX1 := MX1;
		RPM^.DY1 := DY1;
		RPM^.DX2 := MX2;
		RPM^.DY2 := DY2;

		AddRPGMenuKey(RPM,'/',QMval);
		S := SC^.PC^.Spell;
		while S <> Nil do begin
			if S^.mnem = ' ' then
				AddRPGMenuItem(RPM,SpellMan[S^.code].Name,S^.code,SpellMan[S^.code].Desc)
			else begin
				AddRPGMenuItem(RPM,SpellMan[S^.code].Name + ' ['+S^.mnem+']',S^.code,SpellMan[S^.code].Desc);
				AddRPGMenuKey(RPM,S^.mnem,S^.code);
			end;

			S := S^.Next;
		end;
		RPMSortAlpha(RPM);

		{Make a menu selection.}
		it := SelectMenu(RPM,RPMNoCleanup);

		{Check to see if the PC wants to QuickMark a spell.}
		if it = QMval then begin
			SetQuickLink(SC,RPMLocateByPosition(RPM,RPM^.selectitem)^.value);
		end;

		DisposeRPGMenu(RPM);
	until it <> QMval;

	{Redisplay the map.}
	DisplayMap(SC^.GB);
	DCPointMessage(' ');

	ChooseSpell := it;
end;

Function QuickSpell(SC: ScenarioPtr): Integer;
	{Locate a spell based on its quicklink char.}
var
	A: Char;
	it: Integer;
	S: SpellMemPtr;
begin
	DCPointMessage(' which spell? [a-z/A-Z] code, or [*] for menu');
	A := RPGKey;
	DCPointMessage(' ');

	if A = '*' then
		it := ChooseSpell(SC)
	else if (Upcase(A) >= 'A') and (Upcase(A) <= 'Z') then begin
		it := -1;
		S := SC^.PC^.Spell;
		while S <> Nil do begin
			if S^.mnem = A then it := S^.code;
			S := S^.Next;
		end;
	end else begin
		it := -1;
	end;

	QuickSpell := it;
end;

Function CastSpell(SC: ScenarioPtr; UseMenu: Boolean): Boolean;
	{The PC wants to use a psychic ability. Select one of the}
	{character's powers and then process it.}
var
	S: Integer;	{The spell being cast.}
	M: Integer;	{Avaliable Mojo}
	SD: SpellDesc;
begin
	{Exit immediately if the player has no spells or no mojo.}
	if (SC^.PC^.Spell = Nil) or (SC^.PC^.MP < 1) then Exit(False);

	DCGameMessage('Invoke');

	{Choose a spell}
	if UseMenu then
		S := ChooseSpell(SC)
	else
		S:= QuickSpell(SC);

	{If the menu selection wasn't cancelled...}
	if S <> -1 then begin
		{reduce mojo by appropriate amount.}
		M := SC^.PC^.MP;
		SC^.PC^.MP := SC^.PC^.MP - SpellMan[S].Cost;
		if SC^.PC^.MP < 0 then SC^.PC^.MP := 0;

		if Random(SpellMan[S].Cost) < M then begin
			{Fill in the SpellDesc record with spell data + PC stats}
			SD := SpellMan[S];

			DCAppendMessage(SD.Name+' - ');

			{Alter SD for PC's stats depending upon type of spell.}
			case SpellMan[S].Eff of
				EFF_ShootAttack,EFF_CloseAttack: begin
					SD.Step := SD.Step + PCPsiForce(SC^.PC);
					SD.P1 := SD.P1 + PCPsiSkill(SC^.PC);
					end;
				EFF_Residual: begin
					SD.P2 := SD.P2 + PCPsiForce(SC^.PC);
					end;
				EFF_Healing: begin
					SD.Step := SD.Step + PCPsiForce(SC^.PC);
					end;
				EFF_MagicMap: begin
					SD.Step := SD.Step + PCPSiForce(SC^.PC);
					end;
				EFF_StatAttack: begin
					SD.P2 := SD.P2 + PCPsiSkill(SC^.PC);
					end;
			end;

			{process the spell.}
			ProcessSpell(SC,@SD);

		end else begin
			{Spellcasting failed due to a lack of Mojo.}
			DCAppendMessage('Failed!');

		end;

		PCStatLine(SC);
	end;

	{Return TRUE if a spell was selected, FALSE if Cancel was selected.}
	CastSpell := S <> -1;
end;

end.
