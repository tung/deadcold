unit critters;
	{This unit defines the creature stuff for DeadCold. It doesn't}
	{deal with creature behavior; just some primitive creature handling}
	{routines.}

interface

uses crt,rpgtext,rpgdice,texmodel,texmaps,dcitems,statusfx,spells,plotbase;

Type
	CDesc = Record
		Name: String;
		CT: String;
		IntroText: PChar;
		Gfx: Char;
		Color: Byte;
		MaxHP,Armor,DefStep,Mystic: Integer;
		AIType: Byte;
		Sense,Speed: Integer;	{Sensory range and action speed}
		HitRoll,Damage,Range: Integer;
		AtAt: String;		{Attack Attributes.}
		ADesc: String;		{Attack description.}
		TType,TDrop,TNum: Integer;	{Treasure type, and chance of dropping loot.}
		EType,EChance: Integer;	{Equipment type, and chance of having it.}
		XPV: Integer;	{Experience Value}
	end;

Const
	MaxCrit = 24;

	NumCT = 8;
	CT_Alive = 'Al';
	CT_Undead = 'Ud';
	CT_Mech = 'Mk';
	CT_Flying = 'Fl';
	CT_Etheral = 'Et';
	CT_Bug = 'Bg';
	CT_Cold = 'Ec';
	CT_Hot = 'Eh';
	CTMan: Array [1..NumCT] of string = (
		CT_Alive, CT_Undead, CT_Mech, CT_Flying, CT_Etheral,
		CT_Bug, CT_Cold, CT_Hot
	);

	{ The Extended Critter Types describe various critters, }
	{ but they don't contribute to special attacks/defenses. }
	XCT_Breeder = 'Br';

	{The numbers in the following array represent resistance to}
	{elemental attacks. 0 is average; -5 is extreme vunerability}
	{and 5 is element absorbtion. 4 is complete immunity.}
	CTResist: Array [1..NumCT,0..NumElem] of SmallInt = (
		( 0, 0, 0, 0, 0, 0),
		( 0,-1, 1, 0, 0,-5),
		( 0, 0, 0,-2, 0, 1),
		( 0, 0,-1,-2, 0, 0),
		( 4, 0, 0, 0, 3,-2),
		( 0, 0,-1, 0,-2, 0),
		( 1,-5, 5, 0, 0, 0),
		( 1, 5,-5, 0, 0, 0)
	);

	CTAvoid: Array [1..NumCT,1..NumNegSF] of Boolean = (
		{   Par  Sleep    Psn             Attribute Draining                          }
		(  True,  True,  True, False, False, False, False, False, False, False, False),
		(  True, False, False, False, False, False, False, False, False, False, False),
		(  True, False, False, False, False, False, False, False, False, False, False),
		(  True,  True,  True, False, False, False, False, False, False, False, False),
		(  True,  True,  True, False, False, False, False, False, False, False, False),
		(  True,  True,  True, False, False, False, False, False, False, False, False),
		(  True,  True,  True, False, False, False, False, False, False, False, False),
		(  True,  True,  True, False, False, False, False, False, False, False, False)
	);

	AIT_PCHunter = 1;	{PCHunter will pursue PC if in range.}
	AIT_Passive = 2;	{Passive will move randomly and never attack.}
	AIT_Chaos = 3;		{Chaos will move randomly and attack whatever it encounters.}
	AIT_Guardian = 4;	{Creature will guard a room, attacking nearby targets.}
	AIT_Slime = 5;		{Creature can't walk, but attacks any models that pass within range.}
	AIT_HalfHunter = 6;	{Half of the time, acts as PCHunter. Half of the time, acts as Chaos.}

	MonMan: Array [1..MaxCrit] of CDesc = (
		(	Name: 'Maintenance Bot';
			CT: CT_Mech;
			IntroText: Nil;
			Gfx: 'R'; Color: LightGray;
			MaxHP: 25; Armor: 15; DefStep: 1; Mystic: 2;
			AIType: AIT_Passive; Sense: 10; Speed: 5;
			HitRoll: 2; Damage: 13; Range: -1;
			AtAt: '';
			ADesc: 'rams';
			TType: 6; TDrop: 15; TNum: 2;
			EType: 5; EChance: 15;
			XPV: 15
		),
		(	Name: 'Mutant Rat';
			CT: CT_Alive;
			IntroText: 'You see a rat of enormous size, probably escaped from one of the station''s science labs. It doesn''t look too friendly.';
			Gfx: 'r'; Color: Brown;
			MaxHP: 3; Armor: 0; DefStep: 4; Mystic: 1;
			AIType: AIT_PCHunter; Sense: 6; Speed: 8;
			HitRoll: 10; Damage: 2; Range: -1;
			AtAt: '';
			ADesc: 'charges';
			TType: 0; TDrop: 0; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 5
		),
		(	Name: 'Corpse';
			CT: CT_Undead;
			IntroText: 'Finally, another person! Relief from finding someone turns to horror as you realize that the being standing there is no longer alive. The corpse stares at you through unliving eyes. It begins to walk towards you...';
			Gfx: '@'; Color: Yellow;
			MaxHP: 200; Armor: 2; DefStep: 5; Mystic: 12;
			AIType: AIT_PCHunter; Sense: 3; Speed: 5;
			HitRoll: 12; Damage: 12; Range: -1;
			AtAt: '';
			ADesc: 'claws';
			TType: 3; TDrop: 5; TNum: 1;
			EType: 4; EChance: 20;
			XPV: 45
		),
		(	Name: 'Vacuum Worm';
			CT: CT_Alive + CT_Bug;
			IntroText: 'There''s a vacuum worm inside the station! These parasites live on spacecraft hulls throughout the galaxy, but defense screens usually keep them on the outside.';
			Gfx: 'w'; Color: Magenta;
			MaxHP: 10; Armor: 0; DefStep: 1; Mystic: 1;
			AIType: AIT_HalfHunter; Sense: 2; Speed: 6;
			HitRoll: 8; Damage: 3; Range: -1;
			AtAt: '';
			ADesc: 'lunges at';
			TType: 6; TDrop: 1; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 4
		),
		(	Name: 'Sentry Drone';
			CT: CT_Mech;
			IntroText: Nil;
			Gfx: 'R'; Color: LightGray;
			MaxHP: 20; Armor: 15; DefStep: 3; Mystic: 2;
			AIType: AIT_Guardian; Sense: 9; Speed: 4;
			HitRoll: 6; Damage: 5; Range: 3;
			AtAt: '';
			ADesc: 'fires at';
			TType: 6; TDrop: 10; TNum: 1;
			EType: 5; EChance: 100;
			XPV: 15
		),

	{ CRITTERS 6 - 10 }
		(	Name: 'Locust';
			CT: CT_Alive + CT_Flying + CT_Bug;
			IntroText: 'You see some kind of flying insect, about the size of a large cat. No idea what it is or how it got here, but it may have something to do with the emergency that has affected the station.';
			Gfx: 'i'; Color: LightGreen;
			MaxHP: 1; Armor: 3; DefStep: 4; Mystic: 5;
			AIType: AIT_PCHunter; Sense: 6; Speed: 8;
			HitRoll: 11; Damage: 1; Range: 2;
			AtAt: AA_ElemAcid;
			ADesc: 'spits bile at';
			TType: 0; TDrop: 0; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 3
		),
		(	Name: 'Maximillian';
			CT: CT_Mech + CT_Flying;
			IntroText: Nil;
			Gfx: 'R'; Color: Red;
			MaxHP: 300; Armor: 75; DefStep: 17; Mystic: 15;
			AIType: AIT_Guardian; Sense: 8; Speed: 9;
			HitRoll: 21; Damage: 23; Range: 8;
			AtAt: '';
			ADesc: 'fires Laser Cannon at';
			TType: 6; TDrop: 10; TNum: 5;
			EType: 0; EChance: 0;
			XPV: 150
		),
		(	Name: 'Polyp';
			CT: CT_Alive;
			IntroText: 'Oozing across the floor, you see a shapeless blob of a creature. Items which it has injested are visible beneath its pale orange skin. You hope that it isn''t interested in eating you as well...';
			Gfx: 'P'; Color: LightRed;
			MaxHP: 20; Armor: 5; DefStep: 2; Mystic: 1;
			AIType: AIT_HalfHunter; Sense: 4; Speed: 5;
			HitRoll: 9; Damage: 7; Range: -1;
			AtAt: '';
			ADesc: 'touches';
			TType: 3; TDrop: 25; TNum: 3;
			EType: 0; EChance: 0;
			XPV: 10
		),
		(	Name: 'Red Gore';
			CT: CT_Alive;
			IntroText: 'Standing before you is a hideous column of diseased flesh. It seems to be immobile, but the acid being excreted from its pores is eating its way through the station''s hull.';
			Gfx: 'X'; Color: Red;
			MaxHP: 35; Armor: 5; DefStep: 1; Mystic: 4;
			AIType: AIT_Slime; Sense: 6; Speed: 9;
			HitRoll: 10; Damage: 9; Range: -1;
			AtAt: AA_ElemAcid;
			ADesc: 'touches';
			TType: 3; TDrop: 2; TNum: 5;
			EType: 0; EChance: 0;
			XPV: 10
		),
		(	Name: 'Scarab';
			CT: CT_Undead + CT_Flying + CT_Bug;
			IntroText: 'You see a large black beetle, like the scarabs sometimes used to decorate tombs. This one appears to be alive.';
			Gfx: 'i'; Color: Blue;
			MaxHP: 5; Armor: 4; DefStep: 6; Mystic: 6;
			AIType: AIT_Guardian; Sense: 4; Speed: 7;
			HitRoll: 12; Damage: 3; Range: -1;
			AtAt: AA_ArmorPiercing+AA_StatusPar+AA_HitRoll+'02';
			ADesc: 'bites';
			TType: 0; TDrop: 0; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 7
		),

	{ CRITTERS 11 - 15 }
		(	Name: 'Mycozoan Spore';
			CT: CT_Alive + CT_Flying;
			IntroText: 'Mycozoan spores drift through the void, feeding on vacuum worms and organic debris. There''s one inside the station.';
			Gfx: '`'; Color: Brown;
			MaxHP: 2; Armor: 7; DefStep: 1; Mystic: 1;
			AIType: AIT_Chaos; Sense: 2; Speed: 3;
			HitRoll: 11; Damage: 2; Range: -1;
			AtAt: AA_StatusPsn+AA_Value+'02'+AA_Duration+'06'+AA_HitRoll+'13';
			ADesc: 'gropes';
			TType: 7; TDrop: 1; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 5
		),
		(	Name: 'Mutant Rabbit';
			CT: CT_Alive;
			IntroText: 'You spot a hideously twisted rabbit, as large as a man and covered in oozing sores. It probably escaped from the same place as all those rats.';
			Gfx: 'r'; Color: White;
			MaxHP: 15; Armor: 3; DefStep: 5; Mystic: 1;
			AIType: AIT_PCHunter; Sense: 8; Speed: 9;
			HitRoll: 14; Damage: 7; Range: -1;
			AtAt: '';
			ADesc: 'charges';
			TType: 2; TDrop: 2; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 15
		),
		(	Name: 'Stench of Death';
			CT: CT_Etheral;
			IntroText: Nil;
			Gfx: '*'; Color: DarkGray;
			MaxHP: 10; Armor: 0; DefStep: 3; Mystic: 10;
			AIType: AIT_HalfHunter; Sense: 5; Speed: 6;
			HitRoll: 9; Damage: 4; Range: -1;
			AtAt: AA_StatusPsn + AA_Value + '03' + AA_HitRoll + '06' + AA_Duration + '02';
			ADesc: 'touches';
			TType: 0; TDrop: 0; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 20
		),
		(	Name: 'Gelatenous Mass';
			CT: CT_Alive + CT_Bug;
			IntroText: Nil;
			Gfx: ','; Color: LightBlue;
			MaxHP: 22; Armor: 10; DefStep: 3; Mystic: 3;
			AIType: AIT_Slime; Sense: 1; Speed: 2;
			HitRoll: 9; Damage: 3; Range: -1;
			AtAt: '';
			ADesc: 'touches';
			TType: 3; TDrop: 30; TNum: 2;
			EType: 1; EChance: 70;
			XPV: 4
		),
		(	Name: 'Spike Mushroom';
			CT: CT_Alive;
			IntroText: 'There is a giant mushroom growing from a pile of debris on the floor. It is covered in spikes; better not get too close.';
			Gfx: 'm'; Color: Brown;
			MaxHP: 5; Armor: 0; DefStep: 2; Mystic: 3;
			AIType: AIT_Slime; Sense: 2; Speed: 4;
			HitRoll: 9; Damage: 2; Range: 5;
			AtAt: AA_StatusSleep + AA_HitRoll + '04';
			ADesc: 'fires spines at';
			TType: 3; TDrop: 15; TNum: 3;
			EType: 0; EChance: 0;
			XPV: 6
		),

	{ CRITTERS 16 - 20 }
		(	Name: 'Corpse Eater';
			CT: CT_Alive;
			IntroText: 'You see a long, bloated centipede chewing on what looks like the remains of one of the station''s crew members.';
			Gfx: 'C'; Color: Green;
			MaxHP: 25; Armor: 7; DefStep: 6; Mystic: 6;
			AIType: AIT_Passive; Sense: 8; Speed: 6;
			HitRoll: 12; Damage: 7; Range: -1;
			AtAt: AA_StatusPar+AA_HitRoll+'05';
			ADesc: 'bites';
			TType: 2; TDrop: 1; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 17
		),
		(	Name: 'Buzzsaw Bot';
			CT: CT_Mech;
			IntroText: 'That robot is acting strangely...';
			Gfx: 'R'; Color: LightGray;
			MaxHP: 10; Armor: 15; DefStep: 3; Mystic: 2;
			AIType: AIT_HalfHunter; Sense: 2; Speed: 10;
			HitRoll: 5; Damage: 17; Range: -1;
			AtAt: '';
			ADesc: 'saws';
			TType: 6; TDrop: 5; TNum: 1;
			EType: 5; EChance: 2;
			XPV: 21
		),
		(	Name: 'Parasite';
			CT: CT_Alive;
			IntroText: Nil;
			Gfx: 'w'; Color: Yellow;
			MaxHP: 20; Armor: 3; DefStep: 5; Mystic: 14;
			AIType: AIT_HalfHunter; Sense: 2; Speed: 4;
			HitRoll: 16; Damage: 6; Range: -1;
			AtAt: AA_StatusPsn + AA_Value + '01' + AA_HitRoll + '03' + AA_Duration + '10';
			ADesc: 'lunges at';
			TType: 6; TDrop: 1; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 14
		),
		(	Name: 'Creeping Guts';
			CT: CT_Alive;
			IntroText: Nil;
			Gfx: 'X'; Color: Red;
			MaxHP: 35; Armor: 5; DefStep: 1; Mystic: 4;
			AIType: AIT_PCHunter; Sense: 6; Speed: 3;
			HitRoll: 10; Damage: 9; Range: -1;
			AtAt: '';
			ADesc: 'touches';
			TType: 3; TDrop: 2; TNum: 5;
			EType: 0; EChance: 0;
			XPV: 30
		),
		(	Name: 'Mannikin';
			CT: CT_Undead + CT_Mech;
			IntroText: 'You hear the scraping of gristle against steel. Before you stands a wretched creature, the tattered remains of its humanity held together only by wire and nails.';
			Gfx: '@'; Color: Cyan;
			MaxHP: 200; Armor: 10; DefStep: 7; Mystic: 10;
			AIType: AIT_PCHunter; Sense: 7; Speed: 6;
			HitRoll: 15; Damage: 10; Range: -1;
			AtAt: '';
			ADesc: 'claws';
			TType: 3; TDrop: 3; TNum: 1;
			EType: 4; EChance: 35;
			XPV: 55
		),


	{ CRITTERS 21 - 25 }
		(	Name: 'KillBot';
			CT: CT_Mech;
			IntroText: 'It''s a vintage Mk.XI KillBot! Ever since the new Mk.XIII was introduced, they''ve been selling off the older models as bargain security units. It may be obsolete, but it''s probably still deadly.';
			Gfx: 'R'; Color: White;
			MaxHP: 60; Armor: 15; DefStep: 5; Mystic: 17;
			AIType: AIT_Guardian; Sense: 4; Speed: 5;
			HitRoll: 7; Damage: 8; Range: 5;
			AtAt: '';
			ADesc: 'fires at';
			TType: 6; TDrop: 15; TNum: 2;
			EType: 5; EChance: 100;
			XPV: 35
		),
		(	Name: 'Sentinel';
			CT: CT_Mech;
			IntroText: Nil;
			Gfx: 'R'; Color: White;
			MaxHP: 120; Armor: 30; DefStep: 8; Mystic: 8;
			AIType: AIT_Passive; Sense: 4; Speed: 6;
			HitRoll: 11; Damage: 12; Range: 5;
			AtAt: '';
			ADesc: 'fires at';
			TType: 6; TDrop: 45; TNum: 3;
			EType: 5; EChance: 30;
			XPV: 35
		),
		(	Name: 'Dust Jelly';
			CT: CT_Alive + CT_Cold + XCT_Breeder;
			IntroText: Nil;
			Gfx: 'j'; Color: LightCyan;
			MaxHP: 2; Armor: 0; DefStep: 3; Mystic: 3;
			AIType: AIT_HalfHunter; Sense: 3; Speed: 6;
			HitRoll: 10; Damage: 1; Range: -1;
			AtAt: '';
			ADesc: 'lunges at';
			TType: 6; TDrop: 1; TNum: 1;
			EType: 0; EChance: 0;
			XPV: 5;
		),
		(	Name: 'Thorny Rhizome';
			CT: CT_Alive + XCT_Breeder;
			IntroText: '.';
			Gfx: 'm'; Color: LightGray;
			MaxHP: 5; Armor: 0; DefStep: 2; Mystic: 3;
			AIType: AIT_Slime; Sense: 1; Speed: 2;
			HitRoll: 23; Damage: 2; Range: -1;
			AtAt: '';
			ADesc: 'whips';
			TType: 3; TDrop: 2; TNum: 3;
			EType: 0; EChance: 0;
			XPV: 6
		)



	);

	{Define the model KIND field for critters.}
	MKIND_Critter = 2;

Type
	critter = Record
		crit: Integer;		{Defines what kind of a creature we're dealing with.}
		HP: Integer;		{Current hit points.}
		AIType: Byte;		{Current mood.}
		Spotted: Boolean;	{Whether or not this critter has been seen by the PC.}

		TX,TY: Integer;		{Temporary X and Y values.}

		Eqp: DCItemPtr;		{Critter equipment.}
		SF: NAttPtr;	{Critter status.}

		Target: ModelPtr;	{This is the model the critter is gunning for.}
		M: ModelPtr;		{The critter's model.}
		Next: ^Critter;		{So we can do a linked list.}
	end;
	critterptr = ^critter;

Function LastCritter(CP: CritterPtr): CritterPtr;
Function AddCritter(var CList: CritterPtr; gb: GameBoardPtr; crit,X,Y: Integer): CritterPtr;
Procedure DisposeCritterList(CP: CritterPtr);
Procedure RemoveCritter(CP: CritterPtr; var CList: CritterPtr; gb: GameBoardPtr);
Function LocateCritter(MP: ModelPtr; CList: CritterPtr): CritterPtr;
Function NumberOfCritters(C: CritterPtr): Integer;
Function ScaleCritterDamage(C: CritterPtr; DMG,E: Integer): Integer;
Function SetCritterStatus(C: CritterPtr; S: Integer; V: LongInt): Boolean;
Procedure WriteCritterList(C: CritterPtr; var F: Text);
Function ReadCritterList(var F: Text; gb: GameBoardPtr; SFV: Integer ): CritterPtr;

implementation

Function LastCritter(CP: CritterPtr): CritterPtr;
	{Locate the last critter in the list.}
begin
	{To prevent errors, first solve the trivial case.}
	if CP = Nil then Exit(Nil);

	while CP^.next <> Nil do begin
		CP := CP^.next
	end;
	LastCritter := CP;
end;

Function AddCritter(var CList: CritterPtr; gb: GameBoardPtr; C,X,Y: Integer): CritterPtr;
	{Add a new creature, of type CRIT, to the critter list.}
	{Allocate a model for the critter, and place it on the map at position}
	{X,Y.}
var
	it: CritterPtr;
	C2: Byte;
begin
	{Allocate memory for IT}
	New(it);
	if it = Nil then Exit(Nil);

	{Initialize all of ITs fields}
	it^.crit := c;
	it^.next := Nil;
	it^.AIType := MonMan[c].AIType;
	it^.Target := Nil;
	it^.Spotted := False;
	it^.Eqp := Nil;
	it^.SF := Nil;

	{Calculate a HitPoint value for the monster. This should be}
	{within +-20% of the normal maximum.}
	it^.HP := MonMan[c].MaxHP * (100 + RollStep(7) - Random(20)) div 100;
	if it^.HP < 1 then it^.HP := 1;

	{Generate a model for IT}
	if MonMan[c].color = Yellow then C2 := White
	else C2 := Yellow;
	it^.m := GAddModel(gb,MonMan[c].gfx,MonMan[c].color,C2,False,X,Y,MKIND_Critter);

	{If adding a model failed, we're in real trouble. Get rid}
	{of the critter altogether.}
	if it^.m = Nil then begin
		Dispose(it);
		Exit(Nil);
	end;

	{Locate a good position to attach IT to.}
	if CList = Nil then begin
		{the list is currently empty. Attach it as the first model.}
		CList := it;
		end
	else begin
		{The list has stuff in it. Attach IT to the end.}
		LastCritter(CList)^.next := it;
	end;

	{Return the address of the new critter, just in case}
	{the calling procedure wants to mess around with it.}
	AddCritter := it;
end;

Procedure DisposeCritterList(CP: CritterPtr);
	{Given a linked list of monsters starting at CP, dispose of all of them}
	{and free the system resources. The models associated with these}
	{creatures will have to be disposed of somewhere else, since this}
	{procedure ain't doing that.}
var
	CPtemp: CritterPtr;
begin
	while CP <> Nil do begin
		CPtemp := CP^.Next;

		{If the critter is holding an item, get rid of it.}
		if CP^.Eqp <> Nil then DisposeItemList(CP^.Eqp);
		if CP^.SF <> Nil then DisposeNAtt(CP^.SF);

		Dispose(CP);
		CP := CPtemp;
	end;
end;


Procedure ZonkCritter(C: CritterPtr; gb: GameBoardPtr);
	{Delete the critter record at C, along with its associated model.}
begin
	{Get rid of the model}
	GRemoveModel(C^.m,gb);

	{If the critter is holding an item, get rid of it.}
	if C^.Eqp <> Nil then DisposeItemList(C^.Eqp);
	if C^.SF <> Nil then DisposeNAtt(C^.SF);

	{Get rid of the critter record}
	Dispose(C);
end;

Procedure RemoveCritter(CP: CritterPtr; var CList: CritterPtr; gb: GameBoardPtr);
	{Remove critter C from the critter list, also disposing of its}
	{associated model, and updating screen display if needed.}
var
	a,b: CritterPtr; {Counters. A is first in line, B comes right after it.}
begin
	B := CList;
	A := Nil;

	while (B <> CP) and (B <> Nil) do begin
		A := B;
		B := B^.next;
	end;

	if B = Nil then begin
		{Major FUBAR. The critter we were trying to remove can't}
		{be found in the list.}
		writeln('ERROR- RemoveCritter asked to remove a critter that dont exist.');
		readkey;
		end
	else if A = Nil then begin
		{There's no critter before the one we want to remove,}
		{i.e. it's the first one in the list.}
		CList := B^.Next;
		ZonkCritter(B,gb);

		end
	else begin
		{We found the critter we want to delete and have a critter}
		{standing before it in line. Go to work.}
		A^.next := B^.next;
		ZonkCritter(B,gb);
	end;

end;

Function LocateCritter(MP: ModelPtr; CList: CritterPtr): CritterPtr;
	{Search through the critters list and return a pointer to the}
	{critter whose model is at MP. Return Nil if no such critter can}
	{be found.}
var
	temp: CritterPtr;
begin
	{Initialize Temp}
	temp := Nil;

	{Loop through all of the models, looking for the right one.}
	While CList <> Nil do begin
		if CList^.m = MP then
			temp := CList;
		CList := CList^.next;
	end;

	{Return Temp}
	LocateCritter := temp;
end;

Function NumberOfCritters(C: CritterPtr): Integer;
	{Scan through the list of critters and tell us how many}
	{there are.}
var
	N: Integer;
begin
	N := 0;
	while C <> Nil do begin
		C := C^.Next;
		Inc(N);
	end;
	NumberOfCritters := N;
end;

Function ScaleCritterDamage(C: CritterPtr; DMG,E: Integer): Integer;
	{Scale the damage being done based on the critter's resistances.}
var
	T,M: Integer;
begin
	{First determine the critter's succeptability to this attack}
	{type. See what kind of a critter this is.}
	M := 0;
	for t := 1 to NumCT do begin
		if Pos(CTMan[T],MonMan[C^.Crit].CT) > 0 then begin
			M := M + CTResist[T,E];
		end;
	end;

	if M < 0 then begin
		DMG := (DMG * (2 + Abs(M))) div 2;
	end else if M > 0 then begin
		if M < 4 then
			DMG := (DMG * (4 - M)) div 4
		else if M > 9 then
			DMG := -DMG
		else DMG := 0;
	end;
	ScaleCritterDamage := DMG;
end;

Function SetCritterStatus(C: CritterPtr; S: Integer; V: LongInt): Boolean;
	{Attempt to give status S to critter C. Return TRUE if the}
	{critter now has this status, FALSE if it failed.}
var
	it: Boolean;
	T: Integer;
begin
	{Check the critter's type string, to see if it gets an immunity}
	{to this status change.}
	it := true;
	for t := 1 to NumCT do begin
		if Pos(CTMan[T],MonMan[C^.Crit].CT) > 0 then begin
			it := it and CTAvoid[T,Abs(S)];
		end;
	end;

	if it then begin
		AddNAtt(C^.SF,NAG_StatusChange,S,V);
	end;

	SetCritterStatus := it;
end;

Procedure WriteCritterList(C: CritterPtr; var F: Text);
	{Write the list of critters C to file F.}
begin
	{First, do an informative message that may help in debugging.}
	writeln(F,'*** The Critters List ***');

	while C <> Nil do begin
		writeln(F,C^.crit);

		{Record the position of the critter.}
		writeln(F,C^.M^.X);
		writeln(F,C^.M^.Y);

		writeln(F,C^.HP);
		writeln(F,C^.AIType);

		WriteItemList(C^.Eqp,F);
		WriteNAtt(C^.SF,F);

		{Record whether or not the critter has been spotted.}
		if C^.Spotted then writeln(F,'T')
		else writeln(F,'F');

		{Record the whereabouts of the critter's target, if any.}
		if C^.Target = Nil then begin
			writeln(F,-1);
			writeln(F,-1);
		end else begin
			writeln(F,C^.Target^.X);
			writeln(F,C^.Target^.Y);
		end;

		C := C^.Next;
	end;

	{Send a -1 to indicate the end of the critter list.}
	writeln(F,-1);
end;

Function ReadCritterList(var F: Text; gb: GameBoardPtr; SFV: Integer ): CritterPtr;
	{Load a bunch of critters from file F and stick them onto}
	{the Game Board. Return a pointer to the new list.}
var
	CList,C: CritterPtr;
	S: String;
	N,X,Y: Integer;
begin
	CList := Nil;

	{Get rid of the info line.}
	readln(F,S);

	repeat
		readln(F,N);

		if N <> -1 then begin
			readln(F,X);
			readln(F,Y);

			{Allocate memory for the critter now.}
			C := AddCritter(CList,gb,N,X,Y);

			readln(F,C^.HP);
			readln(F,C^.AIType);

			C^.Eqp := ReadItemList(F);

			if SFV < 1003 then begin
				C^.SF := Nil;
				ReadObsoleteSFX(F);
			end else begin
				C^.SF := ReadNAtt( F );
			end;


			{Determine whether or not the critter has been spotted.}
			readln(F,S);
			{Record whether or not the critter has been spotted.}
			if S = 'T' then C^.Spotted := True
			else C^.Spotted := False;

			readln(F,C^.TX);
			readln(F,C^.TY);
		end;
	until N = -1;

	{Assign all the correct targets for all our critters.}
	C := CList;
	while C <> Nil do begin
		C^.Target := FindModelXY(gb^.mlist,C^.TX,C^.TY);
		C := C^.Next;
	end;

	ReadCritterList := CList;
end;

end.
