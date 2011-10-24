unit RandChar;
	{This unit holds the character generator. That's it.}
	{Originally, I had that procedure placed in dcchars,}
	{but it was pretty big, so I decided to make a spinoff}
	{unit just for it.}

interface

uses crt,strings,rpgtext,rpgmenus,rpgdice,dcitems,spells,dcchars;

Procedure SelectPCSpells(PC: DCCharPtr);
Function RandomWorld: String;
Function RollNewChar: dccharptr;


implementation

Const
	JobXFood: Array [0..NumJobs,1..10] of Integer = (
		( 1, 2, 3, 4, 5, 6,22,23, 2, 1),	{generic snack food}
		( 9,10,11,12,13,14,15, 9,10,11),	{Marine}
		( 1,17,18,19,23,21,21,21,21,21),	{Astral Seer}
		( 5, 5, 7, 8,14,17,18,17,18,19),	{Navigator}
		(16, 1, 3, 7, 7, 7, 8,10,12,12),	{Hacker}
		(21,21,21,21,21,21,21,21,21,21),	{Demon Hunter}
		( 1, 4, 6, 7, 8,17,18,17,18,19),	{Explorer}
		( 2,14,15,14,15,14,15,14,15,19),	{Samurai}
		(17,18,17,18,19,21,21,21,21,21),	{Bounty Hunter}
		( 6, 7, 8,17,18,10,11,12,13,19),	{Pirate}
		(23,17,18,19, 6,21,21,21,21,21)		{Zeomancer}
	);

	{ The three indices are chart number, 10 items per chart, }
	{ then ikind/icode/points }
	ItemChart: Array [1..23,1..10,1..3] of Integer = (
			{ Rifles }
		(	( IKIND_Gun , 2 ,  8 ) , ( IKIND_Gun , 2 ,  8 ) ,
			( IKIND_Gun , 2 ,  8 ) , ( IKIND_Gun , 3 , 12 ) ,
			( IKIND_Gun , 3 , 12 ) , ( IKIND_Gun , 3 , 12 ) ,
			( IKIND_Gun , 9 , 11 ) , ( IKIND_Gun , 9 , 11 ) ,
			( IKIND_Gun , 14 , 10 ) , ( IKIND_Gun , 9 , 11 ) ),

			{ Light Pistols }
		(	( IKIND_Gun , 1 , 1 ) , ( IKIND_Gun , 1 , 1 ) ,
			( IKIND_Gun , 1 , 1 ) , ( IKIND_Gun , 4 , 4 ) ,
			( IKIND_Gun , 5 , 6 ) , ( IKIND_Gun , 4 , 4 ) ,
			( IKIND_Gun , 6 , 3 ) , ( IKIND_Gun , 6 , 3 ) ,
			( IKIND_Gun , 1 , 1 ) , ( IKIND_Gun , 4 , 4 ) ),

			{ Assault Weapons }
		(	( IKIND_Gun , 7 , 16 ) , ( IKIND_Gun , 7 , 16 ) ,
			( IKIND_Gun , 8 , 5 ) , ( IKIND_Gun , 8 , 5 ) ,
			( IKIND_Gun , 10 , 15 ) , ( IKIND_Gun , 10 , 15 ) ,
			( IKIND_Gun , 7 , 16 ) , ( IKIND_Gun , 12 , 14  ) ,
			( IKIND_Gun , 5 , 6 ) , ( IKIND_Gun , 8 , 5 ) ),

			{ Light Close Combat Weapons }
		(	( IKIND_Wep , 1 , 1 )  , ( IKIND_Wep , 1 , 1 ),
			( IKIND_Wep , 2 , 1 )  , ( IKIND_Wep , 2 , 1 ),
			( IKIND_Wep , 6 , 2 )  , ( IKIND_Wep , 6 , 2 ),
			( IKIND_Wep , 1 , 1 )  , ( IKIND_Wep , 15 , 1 ),
			( IKIND_Wep , 8 , 3 )  , ( IKIND_Wep , 9 , 7 ) ),

			{ Heavy Close Combat Weapons }
		(	( IKIND_Wep , 8 , 3 )  , ( IKIND_Wep , 8 , 3 ),
			( IKIND_Wep , 3 , 5 )  , ( IKIND_Wep , 4 , 5 ),
			( IKIND_Wep , 3 , 5 )  , ( IKIND_Wep , 4 , 5 ),
			( IKIND_Wep , 3 , 5 )  , ( IKIND_Wep , 4 , 5 ),
			( IKIND_Wep , 3 , 5 )  , ( IKIND_Wep , 4 , 5 ) ),

			{ Grenades }
		(	( IKIND_Grenade , 1 , 2 )  , ( IKIND_Grenade , 1 , 2 ),
			( IKIND_Grenade , 2 , 2 )  , ( IKIND_Grenade , 2 , 2 ),
			( IKIND_Grenade , 5 , 3 )  , ( IKIND_Grenade , 6 , 1 ),
			( IKIND_Grenade , 6 , 1 )  , ( IKIND_Grenade , 7 , 3 ),
			( IKIND_Grenade , 1 , 2 )  , ( IKIND_Grenade , 4 , 3 ) ),

			{ Pills - Medicene }
		(	( IKIND_Food , 24 , 1 )  , ( IKIND_Food , 25 , 1 ),
			( IKIND_Food , 25 , 1 )  , ( IKIND_Food , 26 , 1 ),
			( IKIND_Food , 25 , 1 )  , ( IKIND_Food , 30 , 1 ),
			( IKIND_Food , 25 , 1 )  , ( IKIND_Food , 30 , 1 ),
			( IKIND_Food , 25 , 1 )  , ( IKIND_Food , 30 , 1 ) ),

			{ Pills - Ability Boosters }
		(	( IKIND_Food , 26 , 1 )  , ( IKIND_Food , 27 , 1 ),
			( IKIND_Food , 26 , 1 )  , ( IKIND_Food , 27 , 1 ),
			( IKIND_Food , 37 , 2 )  , ( IKIND_Food , 27 , 1 ),
			( IKIND_Food , 38 , 2 )  , ( IKIND_Food , 36 , 2 ),
			( IKIND_Food , 39 , 2 )  , ( IKIND_Food , 39 , 2 ) ),

			{ Headgear - Spacer }
		(	( IKIND_Cap , 1 , 1 ) , ( IKIND_Cap , 1 , 1 ),
			( IKIND_Cap , 2 , 2 ) , ( IKIND_Cap , 2 , 2 ),
			( IKIND_Cap , 2 , 2 ) , ( IKIND_Cap , 2 , 2 ),
			( IKIND_Cap , 2 , 2 ) , ( IKIND_Cap , 2 , 2 ),
			( IKIND_Cap , 2 , 2 ) , ( IKIND_Cap , 2 , 2 ) ),

			{ Headgear - Fighter }
		(	( IKIND_Cap , 1 , 1 ) , ( IKIND_Cap , 1 , 1 ),
			( IKIND_Cap , 2 , 2 ) , ( IKIND_Cap , 3 , 2 ),
			( IKIND_Cap , 3 , 2 ) , ( IKIND_Cap , 3 , 2 ),
			( IKIND_Cap , 3 , 2 ) , ( IKIND_Cap , 3 , 2 ),
			( IKIND_Cap , 3 , 2 ) , ( IKIND_Cap , 5 , 2 ) ),

			{ Headgear - Samurai }
		(	( IKIND_Cap , 5 , 2 ) , ( IKIND_Cap , 5 , 2 ),
			( IKIND_Cap , 5 , 2 ) , ( IKIND_Cap , 5 , 2 ),
			( IKIND_Cap , 5 , 2 ) , ( IKIND_Cap , 5 , 2 ),
			( IKIND_Cap , 5 , 2 ) , ( IKIND_Cap , 5 , 2 ),
			( IKIND_Cap , 5 , 2 ) , ( IKIND_Cap , 5 , 2 ) ),

			{ Armor - Spacer }
		(	( IKIND_Armor , 2 , 2 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 2 , 2 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 2 , 2 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 2 , 2 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 2 , 2 ) , ( IKIND_Armor , 2 , 2 ) ),

			{ Armor - Soldier }
		(	( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 3 , 4 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 3 , 4 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 3 , 4 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 3 , 4 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 8 , 6 ) ),

			{ Armor - Civilian }
		(	( IKIND_Armor , 1 , 0 ) , ( IKIND_Armor , 1 , 0 ),
			( IKIND_Armor , 1 , 0 ) , ( IKIND_Armor , 10 , 7 ),
			( IKIND_Armor , 1 , 0 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 1 , 0 ) , ( IKIND_Armor , 3 , 4 ),
			( IKIND_Armor , 1 , 0 ) , ( IKIND_Armor , 4 , 0 ) ),

			{ Armor - Samurai / Hunter }
		(	( IKIND_Armor , 5 , 4 ) , ( IKIND_Armor , 7 , 7 ),
			( IKIND_Armor , 5 , 4 ) , ( IKIND_Armor , 7 , 7 ),
			( IKIND_Armor , 5 , 4 ) , ( IKIND_Armor , 7 , 7 ),
			( IKIND_Armor , 5 , 4 ) , ( IKIND_Armor , 7 , 7 ),
			( IKIND_Armor , 5 , 4 ) , ( IKIND_Armor , 8 , 6 ) ),

			{ Armor - Merc }
		(	( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 8 , 6 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 8 , 6 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 8 , 6 ),
			( IKIND_Armor , 3 , 4 ) , ( IKIND_Armor , 8 , 6 ),
			( IKIND_Armor , 7 , 7 ) , ( IKIND_Armor , 8 , 6 ) ),

			{ Armor - Magus }
		(	( IKIND_Armor , 4 , 0 ) , ( IKIND_Armor , 1 , 0 ),
			( IKIND_Armor , 4 , 0 ) , ( IKIND_Armor , 1 , 0 ),
			( IKIND_Armor , 4 , 0 ) , ( IKIND_Armor , 1 , 0 ),
			( IKIND_Armor , 4 , 0 ) , ( IKIND_Armor , 2 , 2 ),
			( IKIND_Armor , 4 , 0 ) , ( IKIND_Armor , 9 , 9 ) ),

			{ Gloves - Spacer }
		(	( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 1 , 1 ),
			( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 1 , 1 ),
			( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 1 , 1 ),
			( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 1 , 1 ),
			( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 1 , 1 ) ),

			{ Gloves - Combat }
		(	( IKIND_Glove , 1 , 1 ) , ( IKIND_Glove , 2 , 2 ),
			( IKIND_Glove , 2 , 2 ) , ( IKIND_Glove , 2 , 2 ),
			( IKIND_Glove , 2 , 2 ) , ( IKIND_Glove , 2 , 2 ),
			( IKIND_Glove , 2 , 2 ) , ( IKIND_Glove , 2 , 2 ),
			( IKIND_Glove , 2 , 2 ) , ( IKIND_Glove , 3 , 4 ) ),

			{ Shoes - Nice }
		(	( IKIND_Shoe , 2 , 0 ) , ( IKIND_Shoe , 4 , 0 ),
			( IKIND_Shoe , 2 , 0 ) , ( IKIND_Shoe , 4 , 0 ),
			( IKIND_Shoe , 2 , 0 ) , ( IKIND_Shoe , 3 , 1 ),
			( IKIND_Shoe , 2 , 0 ) , ( IKIND_Shoe , 3 , 1 ),
			( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 3 , 1 ) ),

			{ Shoes - Mean }
		(	( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 1 , 1 ),
			( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 1 , 1 ),
			( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 3 , 1 ),
			( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 3 , 1 ),
			( IKIND_Shoe , 1 , 1 ) , ( IKIND_Shoe , 3 , 1 ) ),

			{ *VERY* Heavy Close Combat Weapons }
		(	( IKIND_Wep , 10 , 9 )  , ( IKIND_Wep , 10 , 9 ),
			( IKIND_Wep , 10 , 9 )  , ( IKIND_Wep , 12 , 15 ),
			( IKIND_Wep , 11 , 12 )  , ( IKIND_Wep , 12 , 15 ),
			( IKIND_Wep , 11 , 12 )  , ( IKIND_Wep , 12 , 15 ),
			( IKIND_Wep , 11 , 12 )  , ( IKIND_Wep , 12 , 15 ) ),

			{ Warrior Gear }
		(	( IKIND_Wep , 6 , 2 ) , ( IKIND_Grenade , 1 , 2 ),
			( IKIND_Grenade , 2 , 2 ) , ( IKIND_Food , 39 , 2 ),
			( IKIND_Food , 36 , 2 ), ( IKIND_Food , 38 , 2 ),
			( IKIND_Gun , 4 , 4 ), ( IKIND_Gun , 5 , 6 ),
			( IKIND_Gun , 1 , 1 ), ( IKIND_Grenade , 3 , 3 ) )

	);

	HatsChart: Array [ 1..NumJobs ] of Byte = (
		10 , 9 , 9 , 9 , 11 , 9 , 11 , 10 , 9 , 10
	);
	HatsChance: Array [ 1..NumJobs ] of Byte = (
		50, 3, 15, 25, 75, 100, 60, 80, 45, 2
	);
	ArmorChart: Array [ 1..NumJobs ] of Byte = (
		13, 17, 12, 14, 15, 12, 15, 16, 13, 14
	);
	GloveChart: Array [ 1..NumJobs ] of Byte = (
		19 , 18 , 18 , 18 , 19 , 18 , 19 , 19 , 19 , 18
	);
	GloveChance: Array [ 1..NumJobs ] of Byte = (
		40, 1, 10, 15, 55, 100, 10, 50, 55, 2
	);
	ShoeChart: Array [ 1..NumJobs ] of Byte = (
		21 , 20 , 20 , 20 , 20 , 21 , 21 , 21 , 21 , 20
	);

	ExtraGear: Array [0..NumJobs,1..10] of Byte = (
	{Default - 50%}	( 6 , 6 , 6 , 6 , 7 , 7 , 7 , 7 , 7 , 8 ),
	{Marine}	( 6 , 6 , 6 , 6 , 6 , 6 , 7 , 8 , 23 , 23 ),
	{Astral Seer}	( 7 , 7 , 7 , 7 , 7 , 7 , 7 , 7 , 8 , 8 ),
	{Navigator}	( 6 , 6 , 6 , 6 , 6 , 7 , 7 , 7 , 8 , 8 ),
	{Hacker}	( 6 , 6 , 7 , 7 , 7 , 7 , 8 , 8 , 8 , 8 ),
	{Demon Hunter}	( 3 , 5 , 6 , 6 , 6 , 6 , 6 , 7 , 7 , 8 ),
	{Explorer}	( 6 , 6 , 6 , 6 , 7 , 7 , 7 , 7 , 7 , 8 ),
	{Samurai}	( 6 , 6 , 6 , 6 , 6 , 7 , 7 , 8 , 8 , 23 ),
	{Bounty Hunter}	( 6 , 6 , 6 , 6 , 6 , 7 , 8 , 8 , 23 , 23 ),
	{Pirate}	( 6 , 6 , 6 , 6 , 7 , 7 , 7 , 23 , 23 , 23 ),
	{Zeomancer}	( 7 , 7 , 7 , 7 , 7 , 7 , 7 , 7 , 7 , 8 )
	);

	SecondaryGear: Array [1..NumJobs,1..10] of Byte = (
	{Marine}	( 2 , 4 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 6 ),
	{Astral Seer}	( 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 5 , 5 ),
	{Navigator}	( 2 , 4 , 4 , 4 , 5 , 5 , 5 , 5 , 5 , 5 ),
	{Hacker}	( 4 , 4 , 4 , 4 , 4 , 4 , 4 , 5 , 5 , 5 ),
	{Demon Hunter}	( 5 , 5 , 5 , 5 , 5 , 5 , 5 , 22 , 22 , 22 ),
	{Explorer}	( 2 , 4 , 4 , 4 , 4 , 4 , 5 , 5 , 6 , 6 ),
	{Samurai}	( 2 , 3 , 4 , 6 , 23 , 6 , 7 , 8 , 23 , 1 ), { Since Samurai start the game with a Katana, their secondary gear isn't nessecarily a second weapon. }
	{Bounty Hunter}	( 1 , 2 , 2 , 2 , 2 , 2 , 4 , 4 , 5 , 6 ),
	{Pirate}	( 2 , 3 , 4 , 4 , 5 , 5 , 5 , 5 , 5 , 22 ),
	{Zeomancer}	( 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 6 )
	);

	PrimaryGear: Array [1..NumJobs,1..10] of Byte = (
	{Marine}	( 1 , 1 , 1 , 1 , 1 , 1 , 1 , 3 , 3 , 3 ),
	{Astral Seer}	( 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 ),
	{Navigator}	( 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 2 , 2 ),
	{Hacker}	( 1 , 1 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 ),
	{Demon Hunter}	( 1 , 1 , 1 , 1 , 1 , 2 , 2 , 2 , 3 , 3 ),
	{Explorer}	( 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 2 , 2 ),
	{Samurai}	( 1 , 1 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 ),
	{Bounty Hunter}	( 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 3 , 3 ),
	{Pirate}	( 1 , 1 , 1 , 1 , 1 , 1 , 2 , 2 , 3 , 3 ),
	{Zeomancer}	( 1 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 )
	);



Procedure SelectPCSpells(PC: DCCharPtr);
	{The PC has just gone up a level. Choose some spells from}
	{the appropriate list.}
Const
	msg: pchar = 'You can learn new psi powers';
	BColor = LightGray;
	IColor = LightMagenta;
	SColor = Magenta;
	MX1 = 16;
	MY1 = 6;
	MX2 = 65;
	MY2 = 18;
	DY1 = 18;
	DY2 = 22;
var
	RPM: RPGMenuPtr;
	CoP,Max,l,t,S: Integer;
begin
	{Set up the screen.}
	GameMessage(msg,MX1,MY1-2,MX2,MY1,SColor,BColor);

	{Determine the PC's spell college. If none, pick one at}
	{random, just for the hey of it.}
	CoP := JobSchool[PC^.Job];
	if CoP = 0 then CoP := Random(NumSchool) + 1;

	{Keep selecting spells for as long as the PC needs to.}
	while PC^.Skill[SKILL_LearnSpell] > 0 do begin
		{Create the spell menu.}
		RPM := CreateRPGMenu(BColor,SColor,IColor,MX1,MY1,MX2,MY2);
		RPM^.DX1 := MX1;
		RPM^.DY1 := DY1;
		RPM^.DX2 := MX2;
		RPM^.DY2 := DY2;

		{Add an item for each unlearned spell in the PC's}
		{school. First, loop through all the spells up to}
		{the PC's competency, which is (lvl + 1) div 2.}
		Max := (PC^.Lvl+1) div 2;
		if Max > NumLevel then Max := NumLevel;
		for l := 1 to Max do begin
			for t := 1 to 5 do begin
				{Does the PC already know this spell?}
				if (SpellCollege[CoP,l,t] <> 0) and (LocateSpellMem(PC^.Spell,SpellCollege[CoP,l,t]) = Nil) then begin
					{Add a menu item for this spell.}
					AddRPGMenuItem(RPM,SpellMan[SpellCollege[CoP,l,t]].Name,SpellCollege[CoP,l,t],SpellMan[SpellCollege[CoP,l,t]].Desc);
				end;
			end;
		end;

		{If the menu is empty, leave immediately.}
		if RPM^.NumItem = 0 then begin
			DisposeRPGMenu( RPM );
			break;
		end;

		{Sort the menu.}
		RPMSortAlpha(RPM);

		{Select a spell from the menu. No canceling allowed!}
		S := SelectMenu(RPM,RPMNoCancel);
		DisposeRPGMenu( RPM );

		{Add the selected spell to the PC's list.}
		AddSpellMem(PC^.Spell,S);

		{Decrement the PC's LearnSpell number.}
		Dec(PC^.Skill[SKILL_LearnSpell]);
	end;

end;

Procedure StashItem( PC: dccharptr; It: DCItemPtr );
	{ The new PC has been given an item. Decide where to stick it, }
	{ and provide whatever accessories it has coming. }
var
	I: DCItemPtr;
begin
	if it^.IKIND = IKIND_Gun then begin
		{The weapon starts out fully loaded.}
		It^.charge := CGuns[ It^.icode ].Magazine;

		{Give the player some ammo for the gun.}
		I := NewDCItem;
		I^.ikind := IKIND_Ammo;
		I^.icode := CGuns[ it^.icode ].caliber;

		{Decide how many bullets to dole out.}
		if CGuns[ it^.icode ].caliber >= CAL_Energy then begin
			{Energy, napalm, and other special ammo weapons}
			{don't get as many reloads.}
			I^.Charge := 3 + Random(6);
		end else if ( it^.icode = 9 ) or ( it^.icode = 14 ) then begin
			{ Ammo for a shotgun. }
			I^.Charge := CGuns[it^.icode].Magazine * 2 + Random(10);
		end else begin
			I^.Charge := CGuns[it^.icode].Magazine;
			if I^.Charge < 10 then I^.Charge := 10;
			I^.Charge := (I^.Charge * 3) + Random(20);
		end;

		MergeDCItem(PC^.inv,I);

		{ For shotguns, include some scatter ammunition. }
		if ( it^.icode = 9 ) or ( it^.icode = 14 ) then begin
			I := NewDCItem;
			I^.ikind := IKIND_Ammo;
			I^.icode := 100 + CGuns[it^.icode].caliber;
			I^.Charge := CGuns[it^.icode].Magazine + Random(10);
			MergeDCItem(PC^.inv,I);
		end;

	end;

	{ If equippable, equip the item. Otherwise, stash it. }
	if ( It^.ikind > 0 ) and ( PC^.Eqp[ It^.ikind ] = Nil ) then begin
		PC^.Eqp[It^.ikind] := It;
	end else begin
		MergeDCItem(PC^.inv,It);
	end;
end;

Procedure PickItemFromChart( PC: DCCharPtr; Chart: Integer; var Pts: Integer );
	{ Select an item from one of the starting equipment charts, }
	{ stash it in the PC's inventory, then decrement PTS by an }
	{ appropriate amount. }
var
	N: Integer;
	I: DCItemPtr;
begin
	{ Decide what item from the chart to generate. }
	N := Random( 10 ) + 1;

	{ Actually create the item record. }
	I := NewDCItem;
	I^.ikind := ItemChart[ Chart , N , 1 ];
	I^.icode := ItemChart[ Chart , N , 2 ];
	Pts := Pts - ItemChart[ Chart , N , 3 ];

	{ Stick the item in the PC's inventory. }
	StashItem( PC , I );
end;

Procedure GiveBasicStuff( PC: DCCharPtr );
	{ All PCs start with a few free items. }
var
	I: DCItemPtr;
begin
	{ 3 Trauma Fixes, 3 Antidotes. }
	I := NewDCItem;
	I^.ikind := IKIND_Food;
	I^.icode := 25;
	I^.charge := 3;
	StashItem( PC , I );

	I := NewDCItem;
	I^.ikind := IKIND_Food;
	I^.icode := 30;
	I^.charge := 3;
	StashItem( PC , I );

end;

Procedure GiveKatana( PC: DCCharPtr );
	{ All Samurai start the game with a Katana. }
var
	I: DCItemPtr;
begin
	I := NewDCItem;
	I^.ikind := IKIND_Wep;
	I^.icode := 5;
	StashItem( PC , I );
end;

Procedure DoleEquipment( PC: DCCharPtr );
	{ Give out starting equipment to the PC based on job and luck. }
var
	Pts: Integer;
	N: Integer;
begin
	{ First, determine how many points the character will get }
	{ for generation. }
	Pts := 25 + Random( PC^.Stat[ STAT_Luck ] );

	{ Generate the needed equipment - primary weapon, clothes, }
	{ and shoes. }

	{ If the character is a Samurai, give him his Katana now. }
	if PC^.Job = 7 then begin
		Pts := Pts - 12;
		GiveKatana( PC );
	end;

	{ All characters get some free stuff. Add that now. }
	GiveBasicStuff( PC );

	{ Primary Weapon - decide which chart to use. }
	N := Random( 10 ) + 1;
	PickItemFromChart( PC , PrimaryGear[ PC^.Job , N ] , Pts );

	{ Clothes and Shoes }
	PickItemFromChart( PC , ArmorChart[ PC^.Job ] , Pts );
	PickItemFromChart( PC , ShoeChart[ PC^.Job ] , Pts );

	{ If there are points left over, give secondary equipment. }
	if Pts > 0 then begin
		N := Random( 10 ) + 1;
		PickItemFromChart( PC , SecondaryGear[ PC^.Job , N ] , Pts );
	end;

	{ Roll to see if this character gets gloves or a hat. }
	if ( Pts > 0 ) and ( Random(100) < HatsChance[ PC^.Job ] ) then PickItemFromChart( PC , HatsChart[ PC^.Job ] , Pts );
	if ( Pts > 0 ) and ( Random(100) < GloveChance[ PC^.Job ] ) then PickItemFromChart( PC , GloveChart[ PC^.Job ] , Pts );

	{ Spend the remaining points on tertiary equipment. }
	while Pts > 0 do begin
		{ Extra equipment has a 50% chance of coming from the }
		{ job-specific chart and a 50% chance of coming from }
		{ the general items chart. }
		if Random( 2 ) = 1 then begin
			N := Random( 10 ) + 1;
			PickItemFromChart( PC , ExtraGear[ PC^.Job , N ] , Pts );
		end else begin
			N := Random( 10 ) + 1;
			PickItemFromChart( PC , ExtraGear[ 0 , N ] , Pts );
		end;
	end;
end;

Function RandomWorld: String;
	{Generate a random name for a planet.}
Const
	NumSyllables = 50;
	SyllableList: Array [1..NumSyllables] of String = (
		'Us','Ur','An','Ai','Pia','Ae','Ga','Nep','It','Er',
		'Jup','Sat','Plu','To','Ven','Ry','Gar','Del','Phi','Esc',
		'Any','Ron','Comp','Vul','Can','Ea','A','E','I','O',
		'U','Y','Cy','Ber','Tron','Nec','Ro','Mun','Da','Mon',
		'Heim','Tal','Larn','Cad','Ia','Tuo','Mas','Bis','Kup','Mor'
	);
	NumDesig = 15;
	DesigList: Array [1..NumDesig] of String = (
		'II','III','IV','V','VI','III','IV','V',
		'Alpha','Beta','Gamma','Delta','Prime','Omega','Neo'
	);

	Function Syl: String;
	begin
		Syl := SyllableList[Random(NumSyllables)+1];
	end;
var
	it: String;
begin
	{A basic name is two syllables stuck together.}
	it := Syl + LowerCase(Syl);

	{Uncommon names may have 3 syllables.}
	if (Random(3) = 1) and (Length(it) < 6) then
		it := it + LowerCase(Syl)
	else if Random(10) = 1 then
		it := it + LowerCase(Syl);

	{Short names may have a second part. This isn't common.}
	if (Length(it) < 8) and (Random(23) = 7) then begin
		it := it + ' ' + Syl;
		if Random(3) <> 1 then it := it + LowerCase(Syl);
	end else if Random(15) > Length(it) then begin
		it := it + ' ' + DesigList[Random(NumDesig)+1];
	end;

	RandomWorld := it;
end;

Function RandomWDesc: String;
	{Return a random world description.}
	{The description has three parts- first, is it a planet,}
	{a moon, or a space station? Secondly, does the world have}
	{a predominant ecosystem or industry? Finally, where in the}
	{galaxy is it located?}
const
	NumFrm = 3;
	NumEco = 8;
	NumFun = 6;
	frm: Array [1..NumFrm] of string = (
		'planet','station','moon'
	);
	fun: Array [1..NumFun] of string = (
		'an agricultural','an industrial','a military',
		'a trade','a holiday','an administrative'
	);
	eco: Array [1..NumEco] of string = (
		'a jungle','an ice','a desert','a barely habitable',
		'a heavily forested','a beautiful and pristene',
		'an oceanic','a barren'
	);
	loc: Array [1..10] of String = (
		'Western','North Western','South Western','Northern',
		'Southern','North Eastern','South Eastern','Eastern',
		'Imperial','Coreward'
	);
var
	it: String;
	F: Integer;
begin
	{First, decide upon the form of the world. 90% will be planets.}
	if Random(10) <> 1 then F := 1
	else F := Random(NumFrm)+1;

	{Next, decide whether or not the world has a predominant}
	{characteristic. 50% of planets don't have one.}
	if (f=1) and (Random(2)=1) then begin
		{no primary characteristic.}
		it := 'a '+Frm[F];
	end else begin
		if (F=2) or (Random(3)=1) then begin
			it := Fun[Random(NumFun)+1]+' '+Frm[F];
		end else begin
			it := Eco[Random(NumEco)+1]+' '+Frm[F];
		end;
	end;

	it := it + ' in the '+loc[Random(10)+1]+' Stellar March';
	RandomWDesc := it;
end;

Function RandomArrival(PC: DCCharPtr): String;
	{Print a story explaining how the character arrived at Dead Cold.}
	{There are three possible paths- the PC could have responded to}
	{the station's defense call, the PC could have happened here by}
	{accident, or the PC could have come here willingly.}
const
	DCall: String=' There could be people in danger. Immediately, you altered course for the station.';
	Pir: String = ' This might be a good oppurtunity to claim some salvage. You altered course to the station.';
	Mys: String = ' Perhaps fate is calling you in this direction. All other plans can wait; you altered course to the station.';
	Harbor: String = ' Navcomp indicated a friendly space station nearby. You altered course for Dead Cold.';
	NumAtt = 3;
	Att: Array [1..NumAtt] of string = ('pirates','the bugs','raiders');
	NumCar = 3;
	Car: Array [1..NumCar] of string = (
		'the body of your mentor. It was his request that interrment be performed here.',
		'a shipment of fresh produce from the Coreward sector.',
		'the fallen from your homeworld, slain when the bugs attacked.'
	);
var
	P: Integer;
	it: String;
begin
	{Decide which of the three paths the PC will take.}
	P := Random(3)+1;
	if P = 1 then begin
		{Distress call}
		it := 'While travelling to '+RandomWorld+', your ship recieved a distress call from space station Dead Cold.';
		if (PC^.Job = 4) or (PC^.Job=9) then begin
			if Random(3)=1 then it := it + Pir
			else it := it + DCall;
		end else if (PC^.Job = 2) or (PC^.Job = 5) then begin
			if Random(3)=1 then it := it + Mys
			else it := it + DCall;
		end else begin
			if Random(20)=7 then it := it + Mys
			else if Random(20) = 13 then it := it + Pir
			else it := it + DCall
		end;
	end else if P = 2 then begin
		{Accidental arrival}
		it := 'While travelling to '+RandomWorld+', your ship ';
		if Random(2)=1 then begin
			{Attacked!}
			it := it + 'was attacked by '+Att[Random(NumAtt)+1]+' and seriously damaged.';
		end else if Random(2)=1 then begin
			{Meteor!}
			it := it + 'was hit by a meteor.';
		end else begin
			{Out of gas!}
			it := it + 'started to leak fuel.';
		end;

		it := it + Harbor;
	end else begin
		{Purposeful arrival}
		it := 'You have come to Dead Cold bearing ' + Car[Random(NumCar)+1];
	end;

	RandomArrival := it;
end;

Procedure IntroStory(PC: DCCharPtr);
	{Create an introductory story for the PC.}
	{Display it in a special message window.}
const
	Or1: String = 'You are from ';
	Or2: String = ', ';
	Or3: String = '.';
	Ar2: PChar = 'Oddly, the station gave no response to your docking request. You pull into an open shuttle bay and prepare to disembark.';
	X1=15;
	Y1=5;
	X2=65;
	Y2=20;
var
	pmsg: PChar;
begin
	{Set up the screen.}
	ClrScr;
	LovelyBox(LightBlue,X1,Y1,X2,Y2);
	Window(X1+1,Y1+1,X2-1,Y2-1);
	TextColor(Green);

	{Generate the PC's origin.}
	PC^.BGOrigin := Or1 + RandomWorld + Or2 + RandomWDesc + Or3;

	{Generate the PC's history.}

	{Generate the PC's reason for arriving at DeadCold.}
	PC^.BGArrival := RandomArrival(PC);

	{Generate an introduction to the station.}


	{Print the information.}
	pmsg := StrAlloc(Length(PC^.BGOrigin)+1);
	StrPCopy(pmsg,PC^.BGOrigin);
	Delineate(pmsg,X2-X1-1,1);
	Dispose(pmsg);
	pmsg := Nil;
	if WhereX <> 1 then writeln;
	writeln;

	pmsg := StrAlloc(Length(PC^.BGArrival)+1);
	StrPCopy(pmsg,PC^.BGArrival);
	Delineate(pmsg,X2-X1-1,1);
	Dispose(pmsg);
	pmsg := Nil;
	if WhereX <> 1 then writeln;
	writeln;
	Delineate(Ar2,X2-X1-1,1);

	ReadKey;

	Window(1,1,80,25);
	ClrScr;
end;

procedure RollGHStats( PC: DCCharPtr; Pts: Integer);
	{ Randomly allocate PTS points to all of the character's }
	{ stats using the same basic method as in my other game, GearHead. }
	{ *** NOTE: IF THE CHAR ALREADY HAD STAT VALUES SET, THESE WILL BE LOST *** }
var
	T: Integer;	{ A loop counter. }
	{ I always name my loop counters T, in honor of the C64. }
begin
	{ Error Check - Is this a character!? }
	if ( PC = Nil ) then Exit;

	{ Set all stat values to minimum. }
	for t := 1 to 8 do begin
		PC^.Stat[T] := 1;
	end;
	Pts := Pts - 8;

	{ Keep processing until we run out of stat points to allocate. }
	while Pts > 0 do begin
		{ T will now point to the stat slot to improve. }
		T := Random( 8 ) + 1;

		{ If the stat selected is under the max value, }
		{ improve it. If it is at or above the max value, }
		{ there's a one in three chance of improving it. }
		if PC^.Stat[T] < 15 then begin
			Inc( PC^.Stat[T] );
			Dec( Pts );

		end else if Random(2) = 1 then begin
			Inc( PC^.Stat[T] );
			Pts := Pts - 2;
		end;
	end;

end;


Function RollNewChar: dccharptr;
	{We're going to generate a new game character from scratch.}
	{Return NIL if the character creation process was cancelled.}
const
	instructions: pchar = 'Select one of the avaliable jobs from the menu. Press ESC to reroll stats, or select Cancel to exit.';
var
	pc: dccharptr;
	opt: rpgmenuptr;	{The menu holding avaliable jobs.}
	t,tt: Integer;		{Loop counters}
	q: boolean;		{Apparently, for this procedure, I've forgotten about useful variable names. It's hot and I'm tired.}
	I: DCItemPtr;
begin
	{Allocate memory for the character.}
	New(pc);

	{Initilize Job to -1}
	pc^.job := -1;

	{Clear the screen}
	ClrScr;

	{Display the stat names}
	TextColor(Cyan);
	for t := 1 to 8 do begin
		GotoXY(12,t*2 + 3);
		Write(StatName[t],':');
	end;

	{Start a loop. We'll stay in the loop until a character is selected.}
	while pc^.job = -1 do begin

		{Give a short message on how to use the character generator}
		GameMessage(instructions,2,1,79,4,Green,LightBlue);

		{Set the text color}
		TextColor(White);

		{Roll the character's stats.}
		RollGHStats( PC , 100 + Random(20) );
		for t := 1 to 8 do begin
			{display the stat onscreen.}
			GotoXY(35,t*2 + 3);
			Write('   ');
			GotoXY(35,t*2 + 3);
			Write(Pc^.stat[t]);
		end;

		{determine which jobs are open to this character, and}
		{add them to our RPGMenu.}

		{First, allocate the menu.}
		opt := CreateRPGMenu(LightBlue,Blue,LightCyan,46,7,65,17);

		{Initialize the description elements.}
		opt^.dx1 := 2;
		opt^.dx2 := 79;
		opt^.dy1 := 20;
		opt^.dy2 := 24;
		opt^.dtexcolor := green;

		for t := 1 to NumJobs do begin
			{Initialize q to true}
			q := true;

			{Check each stat}
			for tt := 1 to 8 do
				if pc^.stat[tt] < JobStat[t,tt] then q := false;

			{If q is still true, this job may be chosen.}
			if q then begin
				AddRPGMenuItem(opt,JobName[t],t,JobDesc[t]);
			end;
		end;

		{Get the jobs in alphabetical order}
		RPMSortAlpha(opt);

		{Add a CANCEL to the list}
		AddRPGMenuItem(opt,'  Cancel',0,Nil);

		{Ask for a selection}
		pc^.job := SelectMenu(opt,RPMNoCleanup);

		pc^.m := Nil;

		{Get rid of the menu.}
		DisposeRPGMenu(opt);
	end;

	{If the player selected cancel, dispose of the PC record.}
	if pc^.job = 0 then begin
		Dispose(pc);
		pc := Nil;
		end
	else begin
		{Copy skill ranks}
		for t := 1 to NumSkill do begin
			pc^.Skill[t] := JobSkill[pc^.job,t];
		end;

		{Set HP, HPMax, and other initial values.}
		pc^.HPMax := pc^.Stat[STAT_Toughness] + JobHitDie[pc^.job] + BaseHP;
		pc^.HP := pc^.HPMax;
		pc^.MPMax := pc^.Stat[STAT_Willpower] div 2 + JobMojoDie[pc^.job] + Random(JobMojoDie[pc^.job]);
		pc^.MP := pc^.MPMax;
		pc^.Target := Nil;
		pc^.Carbs := 50;
		pc^.Lvl := 1;
		pc^.XP := 0;
		pc^.RepCount := 0;

		pc^.inv := Nil;
		for t := 1 to NumEquipSlots do begin
			pc^.eqp[t] := Nil;
		end;
		pc^.SF := Nil;
		pc^.Spell := Nil;

		{Give some basic equipment.}
		DoleEquipment( PC );

		{Add the PC's meals.}
		for t := 1 to 5 do begin
			I := NewDCItem;
			I^.ikind := IKIND_Food;
			I^.icode := JobXFood[pc^.job,Random(10) + 1];
			I^.charge := 1;
			MergeDCItem(pc^.inv,I);
		end;

		{Add the PC's snacks.}
		for t := 1 to Random(5) do begin
			I := NewDCItem;
			I^.ikind := IKIND_Food;

			{Decide upon what kind of food to give, based on job.}
			if Random(3) = 2 then I^.icode := JobXFood[0,Random(10) + 1]
			else I^.icode := JobXFood[pc^.job,Random(10) + 1];

			I^.charge := Random(3)+1;
			MergeDCItem(pc^.inv,I);
		end;

		{ Input a name. }
		GameMessage('NAME: ',2,1,79,4,LightGreen,LightBlue);
		GotoXY( 9 , 2 );
		CursorOn;
		ReadLn( pc^.Name );
		CursorOff;


		if PC^.Name <> '' then begin
			{ Generate an introduction. }
			IntroStory(PC);

			{Add spells, if appropriate.}
			if pc^.Skill[SKILL_LearnSpell] > 0 then SelectPCSpells(PC);
		end else begin
			DisposePC( PC );
			PC := Nil;
		end;
	end;
	RollNewChar := pc;
end;


end.
