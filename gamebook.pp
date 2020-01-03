unit gamebook;
	{This unit contains a record type which is used for binding}
	{together game information. It also contains some procedures}
	{for correlating the information between different game}
	{structures, such as matching models with individual}
	{critters and so on.}

interface

uses CRT,plotbase,rpgtext,texmodel,texmaps,texfx,texutil,statusfx,dcitems,dcchars,randchar,critters,cwords;

Const
	DF_Physical = 1;
	DF_AvoidTrap = 2;
	DF_Mystic = 3;
	PLT_MapSquare = 'MS';
	PLT_SeeNewCritter = 'NC';
	PLT_EnterCom = 'EN';

	{ This constant is the number of levels- consequently, the size }
	{ of the Frozen Levels array }
	Num_Levels = 8;

Type
	Frozen = Record
		{ This record holds the level descriptions for a }
		{ level that the player has left. }
		{ ANy data not saved here should be deallocated when }
		{ the level changes. }
		gb: GameBoardPtr;
		ig: IGridPtr;
		PL: SAttPtr;
		CList: CritterPtr;
		Comps: MPUPtr;
	end;

	Scenario = Record
		{This record type holds pointers to all associated}
		{data needed for a single level in the game. It also}
		{has pointers to related data, such as the PC's}
		{character structure.}
		ComTime: LongInt;	{How many seconds have passed.}
		Loc_Number: Integer;	{ What level the PC is on. }
		gb: GameBoardPtr;	{the map}
		ig: IGridPtr;		{the stuff on the map}
		PLLocal: SAttPtr;	{Local plot effects.}
		PLGlobal: SAttPtr;	{Global plot effects.}
		PLTrig: SAttPtr;	{Triggers waiting to be processed.}
		CList: CritterPtr;	{the monsters}
		Comps: MPUPtr;		{the computer terminals}
		Fog: CloudPtr;		{Vapors floating around the map}
		CAct,CA2: CritterPtr;	{the active critter, and the next to move.}
		PC: dccharptr;		{the PC}
		NA: NAttPtr;		{ Numeric Attributes }
		Frozen_Levels: Array [1..Num_Levels] of Frozen;
	end;
	ScenarioPtr = ^Scenario;

Function NewScenario: ScenarioPtr;
Procedure DisposeScenario(SC: ScenarioPtr);

{*** MODEL LOOKUP FUNCTIONS ***}
Procedure Excommunicate(SC: ScenarioPtr; M: ModelPtr);
Function ModelDefenseStep(SC: ScenarioPtr; M: ModelPtr; D: Byte): Integer;
Function ModelName(SC: ScenarioPtr; M: ModelPtr): String;
Function TileName(SC: ScenarioPtr; X,Y: Integer): String;

{*** GENERAL IO ROUTINES ***}
Procedure PCStatLine(SC: ScenarioPtr);
Procedure SaveGame(SC: ScenarioPtr);
Function LoadGame( FName: String ): ScenarioPtr;

{*** GAMING ENVIRONMENT ROUTINES ***}
Procedure SetTrigger( SC: ScenarioPtr; Trigger: String );
Procedure SetTrigger( SC: ScenarioPtr; Trigger: String; P1: Integer );
Procedure SetTrigger( SC: ScenarioPtr; Trigger: String; P1, P2: Integer );
Procedure UpdateMonsterMemory(SC: ScenarioPtr; C: CritterPtr);
Function NumberOfActions(CT: LongInt; Spd: Integer): Integer;
Function XPNeeded(lvl: Integer): Cardinal;
Procedure DoleExperience(SC: ScenarioPtr; XPV: Integer);



implementation

Const
	SaveFileVersion = -1010;

Function NewScenario: ScenarioPtr;
	{Create a new scenario structure. Initialize everything to Nil.}
var
	SC: ScenarioPtr;
	T: Integer;
begin
	New(SC);
	SC^.gb := Nil;
	SC^.ig := Nil;
	SC^.PLLocal := Nil;
	SC^.PLGlobal := Nil;
	SC^.PLTrig := Nil;
	SC^.CList := Nil;
	SC^.Comps := Nil;
	SC^.Fog := Nil;
	SC^.CAct := Nil;
	SC^.CA2 := Nil;
	SC^.PC := Nil;
	SC^.ComTime := 0;
	SC^.NA := Nil;
	for t := 1 to Num_Levels do begin
		SC^.Frozen_Levels[t].gb := Nil;
		SC^.Frozen_Levels[t].ig := Nil;
		SC^.Frozen_Levels[t].PL := Nil;
		SC^.Frozen_Levels[t].CList := Nil;
		SC^.Frozen_Levels[t].Comps := Nil;
	end;
	NewScenario := SC;
end;

Procedure DisposeScenario(SC: ScenarioPtr);
	{Free all the resources currently held by this scenario.}
var
	T: Integer;
begin
	if SC^.gb <> Nil then DisposeBoard(SC^.gb);
	DisposeSAtt(SC^.PLLocal);
	DisposeSAtt(SC^.PLGlobal);
	DisposeSAtt(SC^.PLTrig);
	DisposeNAtt(SC^.NA);
	DisposeCritterList(SC^.CList);
	if SC^.ig <> Nil then DisposeIGrid(SC^.ig);
	if SC^.PC <> Nil then DisposePC(SC^.PC);
	DisposeCloud(SC^.Fog);
	DisposeMPU(SC^.Comps);

	{ Get rid of any frozen levels that may be lurking about. }
	for t := 1 to Num_Levels do begin
		if SC^.Frozen_Levels[T].GB <> Nil then DisposeBoard( SC^.Frozen_Levels[T].GB );
		if SC^.Frozen_Levels[T].IG <> Nil then DisposeIGrid( SC^.Frozen_Levels[T].IG );
		if SC^.Frozen_Levels[T].PL <> Nil then DisposeSAtt( SC^.Frozen_Levels[T].PL );
		if SC^.Frozen_Levels[T].CList <> Nil then DisposeCritterList( SC^.Frozen_Levels[T].CList );
		if SC^.Frozen_Levels[T].Comps <> Nil then DisposeMPU( SC^.Frozen_Levels[T].Comps );
	end;

	Dispose(SC);
	SC := Nil;
end;


{*** MODEL LOOKUP FUNCTIONS ***}

Procedure Excommunicate(SC: ScenarioPtr; M: ModelPtr);
	{This isn't a lookup function, but it seemed appropriate}
	{to place it here. Model M and the thing it belongs to are}
	{about to be removed from play. Remove all mention of this}
	{model from game memory.}
var
	CT: CritterPtr;
begin
	{Remove all mention of this model from the Target lists}
	{of various monsters.}
	CT := SC^.CList;
	while CT <> Nil do begin
		if CT^.Target = M then CT^.Target := Nil;
		CT := CT^.Next;
	end;

	{Clear the PC's target.}
	if SC^.PC^.Target = M then SC^.PC^.Target := Nil;

	{Clear the active critter, if this is the active critter.}
	if (SC^.CAct <> Nil) and (SC^.CAct^.M = M) then SC^.CAct := Nil;

	{If the next critter to act is the one who was killed,}
	{move that pointer to the next critter in line.}
	if (SC^.CA2 <> Nil) and (SC^.CA2^.M = M) then begin
		SC^.CA2 := SC^.CA2^.Next;
	end;

end;

Function ModelDefenseStep(SC: ScenarioPtr; M: ModelPtr; D: Byte): Integer;
	{Given a model pointer, determine the Defense Step of the}
	{entity to which it belongs.}
var
	it: Integer;
begin
	it := 1;
	Case M^.Kind of
		MKIND_CRITTER:	begin
			{The model is a critter.}
			{Look up its defense step from the appropriate array.}
				case D of
				DF_Mystic:	it := MonMan[LocateCritter(M,SC^.CList)^.Crit].Mystic;
				DF_AvoidTrap:	it := MonMan[LocateCritter(M,SC^.CList)^.Crit].Sense;
				DF_Physical:	it := MonMan[LocateCritter(M,SC^.CList)^.Crit].DefStep;
				end;
			end;
		MKIND_Character: begin
			{The model is a character.}
				case D of
				DF_Physical:	it := PCDefense(SC^.PC);
				DF_AvoidTrap:	it := PCLuckSave(SC^.PC);
				DF_Mystic:	it := PCMysticDefense(SC^.PC);
				end;
			end;

		else it := 1;
	end;

	{Just as a precaution, make sure that the number doesn't}
	{fall below a certain minimal value.}
	if it < 1 then it := 1;

	{Return the defense value.}
	ModelDefenseStep := it;
end;

Function ModelName(SC: ScenarioPtr; M: ModelPtr): String;
	{Given a model, M, look up its name.}
	{If the model is the PC, return the string "You".}
var
	it: String;
begin
	if M = Nil then
		it := 'Empty Space'
	else if M^.Kind = MKIND_Character then
		it := 'you'
	else if M^.Kind = MKIND_Critter then
		it := MonMan[LocateCritter(M,SC^.CList)^.Crit].Name
	else if M^.Kind = MKIND_Cloud then
		it := CloudMan[LocateCloud(M,SC^.Fog)^.Kind].Name
	else if M^.Kind = MKIND_MPU then
		it := MPUMan[LocateMPU(M,SC^.Comps)^.Kind].Name;

	ModelName := it;
end;

Function TileName(SC: ScenarioPtr; X,Y: Integer): String;
	{Given location X,Y provide a string to describe the contents.}
var
	it: String;
begin
	if not OnTheMap(X,Y) then begin
		it := 'Swirling Pandemonium';
	end else if ModelPresent(SC^.gb^.mog,X,Y) and TileLOS(SC^.gb^.pov,X,Y) then begin
		it := ModelName(SC,FindModelXY(SC^.gb^.mlist,X,Y));
	end else if (SC^.gb^.itm[X,Y].gfx <> ' ') and TileLOS(SC^.gb^.pov,X,Y) then begin
		it := 'an item';
	end else if (SC^.gb^.map[X,Y].trap > 0) and TileLOS(SC^.gb^.pov,X,Y) then begin
		it := 'a trap';
	end else if SC^.gb^.map[X,Y].visible then begin
		it := TerrName[SC^.gb^.map[X,Y].terr];
	end else begin
		it := 'unknown';
	end;
	TileName := it;
end;

{*** GENERAL IO ROUTINES ***}

Function StatusColor(M,C: Integer): Byte;
	{Given a maximum value of M and a current value of C, return the}
	{appropriate status color. The three colors being used are red,}
	{yellow, and green.}
var
	it: Byte;	{What color is IT?}
begin
	if (C < 1) and (M > 0) then
		{If the part is out of hits, and this isn't normal for}
		{said part, color will be grey, implying complete stoppage}
		{of function.}
		it := DarkGray
	else if C < (M div 4) then
		it := Red
	else if C < (M div 2) then
		it := Yellow
	else if C < M then
		it := Green
	else if C = M then
		it := LightGreen
	else
		it := LightCyan;
	StatusColor := It;	
end;

Procedure PCStatLine(SC: ScenarioPtr);
	{Print details about the PC in row 25 of the screen.}
const
	PCSLNumSFX = 3;	{PC Stat Line Number of Status Effects}
	SFXChar: Array[1..PCSLNumSFX] of String[3] = ('Par','Zzz','Psn');
	SFXColor: Array [1..PCSLNumSFX] of byte = (Magenta,White,LightGreen);
	SFXVal: Array [1..PCSLNumSFX] of smallint = ( SEF_Paralysis,SEF_Sleep,SEF_Poison);
var
	T,HP: Integer;
begin
	window(1,25,79,25);
	ClrScr;
	window(1,1,80,25);

	{Print data on status effects.}
	GotoXY(2,25);
	{ First, if player is starving, show that. }
	if SC^.PC^.Carbs < 0 then begin
		TextColor(LightRed);
		write('Sta');
	end else if SC^.PC^.Carbs < 10 then begin
		TextColor(Yellow);
		write('Hgr');
	end;
	for t := 1 to PCSLNumSFX do begin
		if (WhereX < 15) and (NAttValue( SC^.PC^.SF , NAG_StatusChange , SFXVal[T] ) <> 0 ) then begin
			TextColor(SFXColor[t]);
			write(SFXChar[t]);
		end;
	end;

	HP := SC^.PC^.HP;
	if HP<0 then HP := 0
	else if HP>999 then HP := 999;
	TextColor(Green);
	GotoXY(18,25);
	Write('HP:');
	TextColor(StatusColor(SC^.PC^.HPMax,SC^.PC^.HP));
	Write(HP);

	HP := SC^.PC^.MP;
	if HP<0 then HP := 0
	else if HP>999 then HP := 999;
	TextColor(Green);
	GotoXY(25,25);
	Write('MP:');
	TextColor(StatusColor(SC^.PC^.MPMax,SC^.PC^.MP));
	Write(HP);

	For T := 1 to 8 do begin
		TextColor(Green);
		GotoXY(27 + T*6,25);
		write(StatAbbrev[t],':');
		HP := CStat(SC^.PC,t);
		if HP < SC^.PC^.Stat[t] then TextColor(Red)
		else if HP > SC^.PC^.Stat[t] then TextColor(LightBlue)
		else TextColor(LightGreen);
		if HP>99 then HP := 99;
		if HP<10 then write(' ');
		write(HP);
	end;
end;


Procedure SaveGame(SC: ScenarioPtr);
	{This is it. The big one. Save everything to disk...}
var
	F: Text;
	T: Integer;
begin
	{Open the file.}
	Assign(F,'savegame' + DirectorySeparator + SC^.PC^.Name + '.txt');
	{$i-}
	ReWrite(F);
	{$+}
	if IOResult = 0 then
	begin
		{Write the savefile version first of all.}
		writeln(F,SaveFileVersion);

		{Write the current ComTime.}
		writeln(F,SC^.ComTime);

		writeln( F , SC^.Loc_Number );

		{Write the GameBoard}
		WriteGameBoard(SC^.gb,F);

		{Write the PC data.}
		WritePC(SC^.PC,F);

		{Write the Item Grid}
		WriteIGrid(SC^.ig,F);

		{Write the Critters List}
		WriteCritterList(SC^.CList,F);

		{Write the PlotLine Scripts}
		WriteSAtt(SC^.PLLocal,F);
		WriteSAtt(SC^.PLGlobal,F);

		{Write the clouds}
		WriteClouds(SC^.Fog,F);

		{ Write the computers. }
		WriteMPU( SC^.Comps , F );
		SaveLogon( F );

		{ Write the numeric attributes. }
		WriteNAtt( SC^.NA , F );

		{ Write the frozen levels. }
		Writeln( F , '*** FROZEN LEVELS ***' );
		for t := 1 to Num_Levels do begin
			if SC^.Frozen_Levels[t].gb <> Nil then begin
				Writeln( F , T );
				WriteGameBoard( SC^.Frozen_Levels[t].GB , F );
				WriteIGrid( SC^.Frozen_Levels[t].IG , F );
				WriteSAtt( SC^.Frozen_Levels[t].PL , F );
				WriteCritterList( SC^.Frozen_Levels[t].CList , F );
				WriteMPU( SC^.Frozen_Levels[t].Comps , F );
			end;
		end;
		Writeln( F , '-1' );
		{Close the file}
		Close(F);
	end;
end;

Function LoadGame( FName: String ): ScenarioPtr;
	{Load everything from disk and make sure that it's the}
	{same as when it was saved.}
var
	SC: ScenarioPtr;
	F: Text;
	SFV: Integer;	{The save file version.}
	T: Integer;
	S: String;
begin
	SC := NewScenario;

	writeln('Loading...');

	Assign(F,FName);
	Reset(F);
		readln(F,SFV);

		{Save file version must be negative. If it's positive,}
		{that means we're trying to load an earlier version save}
		{file, and we've actually just read the ComTime.}
		if SFV < 0 then begin
			readln(F,SC^.ComTime);
			SFV := Abs(SFV);
		end else begin
			SC^.ComTime := SFV;
			SFV := 0;
		end;

		{ For save files >= 1010, read the location. }
		if SFV >= 1010 then begin
			readln( F , SC^.Loc_Number );
		end else begin
			SC^.Loc_Number := 1;
		end;

		SC^.gb := ReadGameBoard(F);

		SC^.PC := ReadPC(F,SC^.gb,SFV);

		SC^.ig := ReadIGrid(F,SC^.gb);

		SC^.CList := ReadCritterList(F,SC^.gb,SFV);

		SC^.PLLocal := ReadSAtt(F);
		SC^.PLGlobal := ReadSAtt(F);

		{ Add the version-dependant code here. }
		if SFV >= 1000 then SC^.Fog := ReadClouds(F,SC^.gb);
		if SFV >= 1001 then begin
			SC^.Comps := ReadMPU( F , SC^.GB );
			LoadLogon( F );
		end;
		if SFV >= 1002 then begin
			SC^.NA := ReadNAtt( F );
		end;

		{ Read frozen levels starting at 1010. }
		if SFV >= 1010 then begin
			{ Dispose of the header. }
			readln( F , S );
			repeat
				readln( F , T );

				if ( T > 0 ) then begin
					SC^.Frozen_Levels[t].GB := ReadGameBoard( F );
					SC^.Frozen_Levels[t].IG := ReadIGrid( F , SC^.Frozen_Levels[t].GB );
					SC^.Frozen_Levels[t].PL := ReadSAtt( F );
					SC^.Frozen_Levels[t].CList := ReadCritterList( F , SC^.Frozen_Levels[t].GB , SFV );
					SC^.Frozen_Levels[t].Comps := ReadMPU( F , SC^.Frozen_Levels[t].GB );
				end;
			until T < 1;
		end;
	Close(F);

	LoadGame := SC;
end;

{*** GAMING ENVIRONMENT ROUTINES ***}

Procedure SetTrigger( SC: ScenarioPtr; Trigger: String );
	{ Place the requested trigger in the triggers list. }
begin
	{ This is pretty easy. }
	StoreSAtt( SC^.PLTrig , Trigger );
end;

Procedure SetTrigger( SC: ScenarioPtr; Trigger: String; P1: Integer );
	{ Place the requested trigger with parameter P1 in the list. }
begin
	SetTrigger( SC , Trigger + BStr( P1 ) );
end;

Procedure SetTrigger( SC: ScenarioPtr; Trigger: String; P1, P2: Integer );
	{ Place the requested trigger with parameter P1 in the list. }
begin
	SetTrigger( SC , Trigger + BStr( P1 ) + '%' + BStr( P2 ) );
end;

Procedure UpdateMonsterMemory(SC: ScenarioPtr; C: CritterPtr);
	{This monster has apparently just walked into the player's}
	{view. Update the player's Monster Memory, and maybe print}
	{the monster's introductory text.}
begin
	if NAttValue( SC^.NA , NAG_MonsterMemory , C^.Crit ) < 100 then begin
		AddNAtt( SC^.NA , NAG_MonsterMemory , C^.Crit , 1 );
		if NAttValue( SC^.NA , NAG_MonsterMemory , C^.Crit ) = 1 then begin
			SetTrigger( SC , PLT_SeeNewCritter , C^.Crit );
			if (MonMan[C^.Crit].IntroText <> Nil) then begin
				DCGameMessageC(MonMan[C^.Crit].IntroText,True);
				ModelFlash(SC^.gb,C^.M);
				GamePause;
			end;
		end;
	end;
	C^.Spotted := True;
end;

Function NumberOfActions(CT: LongInt; Spd: Integer): Integer;
	{Return the number of actions which a model moving at}
	{speed SPD would be able to perform during this click.}
	{SPD indicates how many actions a model will take during}
	{a 12 click period.}
const
	Chart: Array [0..11,1..12] of byte = (
	(	0,0,0,0,0,0,0,0,0,0,0,0	),	{Speed 0}
	(	1,0,0,0,0,0,0,0,0,0,0,0	),	{Speed 1}
	(	0,0,1,0,0,0,0,0,1,0,0,0	),	{Speed 2}
	(	0,1,0,0,0,1,0,0,0,1,0,0	),	{Speed 3}
	(	1,0,0,1,0,0,1,0,0,1,0,0	),	{Speed 4}
	(	0,1,0,0,1,0,1,0,1,0,0,1	),	{Speed 5}
	(	1,0,1,0,1,0,1,0,1,0,1,0	),	{Speed 6}
	(	1,0,1,0,1,0,1,0,1,1,0,1	),	{Speed 7}
	(	1,1,0,0,1,1,0,1,1,1,1,0	),	{Speed 8}
	(	1,1,0,1,1,1,0,1,1,1,0,1	),	{Speed 9}
	(	1,1,0,1,1,1,1,1,1,1,1,0	),	{Speed 10}
	(	1,1,1,1,0,1,1,1,1,1,1,1	)	{Speed 11}
	);
var
	RT: Integer;	{Relative Time.}
	it: Integer;
begin
	RT := CT mod 12 + 1;
	it := 0;

	{Check for minimum speed}
	if Spd < 1 then Spd := 1

	{If more than 12 actions are to be taken, sort that out first.}
	else if Spd >= 12 then begin
		it := it + Spd div 12;
		Spd := Spd mod 12;
	end;

	{Determine whether or not this is one of the clicks in which}
	{the model gets to take an action.}
	if Chart[Spd,RT] > 0 then Inc(it);

	NumberOfActions := it;
end;

Function XPNeeded(lvl: Integer): Cardinal;
	{Calculate the XP needed to reach level Lvl.}
begin
	XPNeeded := (lvl * lvl * 25) + (lvl * 15);
end;

Procedure LevelUp(SC: ScenarioPtr);
	{The PC has just advanced an experience level. Do whatever}
	{you have to.}
const
	SkChart: Array [0..2,0..2] of byte = (
		( 0, 0, 0),
		( 0, 0, 1),
		( 1, 1, 0)
	);
var
	t,P: Integer;
begin
	DCGameMessage('You have gained a level!');
	GamePause;

	Inc(SC^.PC^.Lvl);

	{Calculate the bonus HitPoints}
	P := JobHitDie[SC^.PC^.Job] + Random(JobHitDie[SC^.PC^.Job]) + PCHPBonus(SC^.PC);
	SC^.PC^.HPMax := SC^.PC^.HPMax + P;
	SC^.PC^.HP := SC^.PC^.HP + P;

	{Calculate the bonus MojoPoints}
	P := JobMojoDie[SC^.PC^.Job] + Random(JobMojoDie[SC^.PC^.Job]) + PCMPBonus(SC^.PC);
	SC^.PC^.MPMax := SC^.PC^.MPMax + P;
	SC^.PC^.MP := SC^.PC^.MP + P;

	{Improve skill ratings}
	for t := 1 to NumSkill do begin
		{If the adv number is > 0, this indicates rate.}
		{if <0, this indicates slow progress.}
		{if =0, this indicates no improvement.}
		if SkillAdv[SC^.PC^.Job,T] > 0 then begin
			P := SkillAdv[SC^.PC^.Job,T];
			if P >= 3 then begin
				{The PC gains more than 1 pt/Level}
				SC^.PC^.Skill[T] := SC^.PC^.Skill[T] + (P div 3);
				P := P mod 3;
			end;
			SC^.PC^.Skill[t] := SC^.PC^.Skill[t] + SkChart[P,SC^.PC^.Lvl mod 3];

			if SC^.PC^.Lvl = 2 then begin
				{A level 2 character gets the level 1 bonuses as well.}
				if SkillAdv[SC^.PC^.Job,T] >= 3 then begin
					{The PC gains more than 1 pt/Level}
					SC^.PC^.Skill[T] := SC^.PC^.Skill[T] + (SkillAdv[SC^.PC^.Job,T] div 3);
				end;
				SC^.PC^.Skill[t] := SC^.PC^.Skill[t] + SkChart[P,1];
			end;
		end else if SkillAdv[SC^.PC^.Job,T] < 0 then begin
			if (SC^.PC^.Lvl mod Abs(SkillAdv[SC^.PC^.Job,T])) = 0 then begin
				Inc(SC^.PC^.Skill[t]);
			end;
		end;
	end;

	{Give spells to whoever qualifies for them.}
	if SC^.PC^.Skill[SKILL_LearnSpell] > 0 then begin
		SelectPCSpells(SC^.PC);
		DisplayMap(SC^.gb);
	end;

end;

Procedure DoleExperience(SC: ScenarioPtr; XPV: Integer);
	{Give XPV experience points to the character.}
	{Check for going up a level.}
begin
	SC^.PC^.XP := SC^.PC^.XP + XPV;
	if SC^.PC^.XP >= XPNeeded(SC^.PC^.Lvl + 1) then begin
		LevelUp(SC);
		PCStatLine(SC);
	end;
end;

end.
