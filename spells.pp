unit spells;
	{This unit holds the definition lists for psi abilities}
	{that the player might have.}

interface

uses crt,statusfx;

Type
	SpellMem = Record	{Spell Memory - spell learned by PC}
		code: Integer;		{Spell #}
		mnem: Char;		{QuickSpell character}
		next: ^SpellMem;
	end;
	SpellMemPtr = ^SpellMem;
	SpellDesc = Record	{Spell Description}
		name: String;
		cdesc: String;		{description when cast}
		eff: Byte;		{Spell effect code}
		step: SmallInt;		{Spell magnitude}
		P1,P2: SmallInt;	{Spell parameters}
		cost: Byte;
		C: Byte;		{Color of the spell}
		ATT: String;		{Spell attributes}
		Desc: PChar;		{ Description for menus. }
	end;
	SpellDescPtr = ^SpellDesc;	{Used for calling procedures.}

Const
	{These constants describe various Attack Attributes.}
	{CONVENTION: Attribute strings are UC Char + LC Char}
	{  Support Parameters are '#' + LC Char}
	AA_LineAttack = 'La';	{Attacks every target along its line of fire.}
	AA_BlastAttack = 'Ba';	{Attacks every model within R of its target point.}
	AA_SmokeAttack = 'Sa';	{Creates smoke. Value is smoke type.}

	AA_ArmorPiercing = 'Ap';	{Armor only counts half}
	AA_ArmorDoubling = 'PU';	{Armor counts double}
	AA_Element = 'El';	{Attack has an associated element.}
		AA_ElemFire = 'El01';
		AA_ElemCold = 'El02';
		AA_ElemLit =  'El03';
		AA_ElemAcid = 'El04';
		AA_ElemHoly = 'El05';
	AA_StatusChange = 'Sc';
		AA_StatusPar = 'Sc01';
		AA_StatusSleep = 'SC02';
		AA_StatusPsn = 'Sc03';
	AA_Slaying = 'Sl';	{Slays specific critter types.}
		AA_SlayAlive = 'Sl01';
		AA_SlayUndead = 'Sl02';
		AA_SlayMech = 'Sl03';


	AA_Value = '#v';
	AA_HitRoll = '#h';
	AA_Duration = '#d';

	EFF_ShootAttack = 0;	{Works like a shooting attack. Magic missile kind of thing.}
		{P1 = ACC, P2 = RNG}
	EFF_CloseAttack = 1;	{Works like a H2H attack. UI is different from above.}
		{P1 = ACC}
	EFF_Residual = 2;	{Add status change to caster}
		{Step = SEF; P1 = Value }
	EFF_Healing = 3;	{Recover HP}
	EFF_MagicMap = 5;	{Reveal areas of the map.}
		{Step = % area; P1 = Range; P2 = TerrPass filter}
	EFF_StatAttack = 6;	{Cause StatusChange in monsters within radius}
		{Step = SEF; P1 = Range; P2 = HitRoll; Value in ATT}
	EFF_CureStatus = 7;	{Cure a certain status condition.}
		{Step = SEF}
	EFF_Teleport = 8;	{Teleport caster.}
		{Step = Range; P1 = Control (0=Random, 1=Select) }
	EFF_SenseAura = 9;	{See location of monsters on screen.}
		{Step = Model kind to detect}

	NumSpell = 25;
	SpellMan: Array [1..NumSpell] of SpellDesc = (
		(	Name: 'Flamwave';
			cdesc: 'call forth a flaming arc';
			eff: EFF_ShootAttack;
			Step: 2; P1: 0; P2: 6; cost: 5;
			C: LightRed; ATT: AA_LineAttack + AA_ElemFire;
			Desc: 'A cone of pyrokinetic flame which burns targets up to 6m away.'	),
		(	Name: 'Force Bolt';
			cdesc: 'project mental energy towards';
			eff: EFF_ShootAttack;
			Step: 5; P1: 1; P2: 6; cost: 3;
			C: White; ATT: '';
			desc: 'A bolt of telekinetic energy which does concussive damage to a target.' ),
		(	Name: 'Implosion';
			cdesc: 'shread';
			eff: EFF_CloseAttack;
			Step: 12; P1: 3; cost: 2;
			C: LightCyan; ATT: '';
			desc: 'Time-space is slightly pinched at the location of the target, resulting in horrible damage to its physical form.'),
		(	Name: 'Alter Perception';
			eff: EFF_Residual;
			Step: SEF_VisionBonus; P1: 5; P2: 10; cost: 4;
			C: Yellow; ATT: '';
			desc: 'Use of this talent allows the character an extended visual range for about ten minutes.'),
		(	Name: 'Heal Wounds';
			eff: EFF_Healing;
			Step: 5; cost: 2;
			C: LightGreen; ATT: '';
			desc: 'Physical injuries may be mended by this talent.'),

		{ 6 - 10 }
		(	Name: 'Remote Viewing';
			eff: EFF_MagicMap;
			Step: 25; P1: 32; P2: 100; cost: 8;
			C: White; ATT: '';
			desc: 'Distant spaces may become known through this talent.'),
		(	Name: 'Armor Up';
			eff: EFF_Residual;
			Step: SEF_ArmorBonus; P1: 5; cost: 3;
			C: Blue; ATT: '';
			desc: 'The armor of the character will be telekinetically strengthened for about a half an hour.'),
		(	Name: 'Power Up';
			eff: EFF_Residual;
			Step: SEF_CCDmgBonus; P1: 10; cost: 2;
			C: Red; ATT: '';
			desc: 'For ten minutes the character''s close combat attacks will do much more damage.'),
		(	Name: 'Regenerate';
			eff: EFF_Residual;
			Step: SEF_Regeneration; P1: 15; cost: 10;
			C: Green; ATT: '';
			desc: 'Psi energy is converted over time into life energy, speeding up the healing process.' ),
		(	Name: 'Speed Up';
			eff: EFF_Residual;
			Step: SEF_SpeedBonus; P1: 10; cost: 6;
			C: Blue; ATT: '';
			desc: 'For ten minutes the character will move faster.'),

		{ 11 - 15 }
		(	Name: 'Obscure Aura';
			eff: EFF_Residual;
			Step: SEF_StealthBonus; P1: 10; cost: 5;
			C: Blue; ATT: '';
			desc: 'It becomes far more difficult for enemies to spot the character. Lasts thirty minutes.' ),
		(	Name: 'Shockwave';
			cdesc: 'call forth a bolt of lightening';
			eff: EFF_ShootAttack;
			Step: 3; P1: 1; P2: 8; cost: 7;
			C: Yellow; ATT: AA_LineAttack + AA_ElemLit;
			desc: 'A bolt of lightening strikes all foes within 8m.'),
		(	Name: 'Guided Fire';
			eff: EFF_Residual;
			Step: SEF_MslBonus; P1: 10; cost: 3;
			C: LightCyan; ATT: '';
			desc: 'All missile attacks are much more likely to hit for one minute.'),
		(	Name: 'Cryoblast';
			cdesc: 'hurl a freezing vortex at';
			eff: EFF_ShootAttack;
			Step: 5; P1: 3; P2: 5; cost: 5;
			C: LightBlue; ATT: AA_ElemCold;
			desc: 'A bolt of negative thermal potential strikes one enemy.' ),
		(	Name: 'Soul Hammer';
			cdesc: 'blast';
			eff: EFF_CloseAttack;
			Step: 15; P1: 0; cost: 3;
			C: LightCyan; ATT: AA_ElemHoly;
			desc: 'One nearby foe is struck with a bolt of pure spiritual energy.' ),

		{ 16 - 20 }
		(	Name: 'Sleep';
			eff: EFF_StatAttack;
			Step: SEF_Sleep; P1: 3; P2: 0; cost: 8;
			C: LightGray; ATT: AA_Value+'05';
			desc: 'All enemies within 3m will likely fall asleep.' ),
		(	Name: 'Knockdown';
			cdesc: 'project mental energy towards';
			eff: EFF_ShootAttack;
			Step: 2; P1: 2; P2: 8; cost: 6;
			C: White; ATT: AA_StatusSleep + AA_HitRoll + '06' + AA_Value + '01';
			desc: 'A wave of psi energy is shot at one foe, possibly overloading its nervous system.' ),
		(	Name: 'Purge';
			cdesc: 'project waves of spiritual energy';
			eff: EFF_ShootAttack;
			Step: 1; P1: 1; P2: 12; cost: 9;
			C: LightCyan; ATT: AA_LineAttack + AA_SlayUndead + AA_ElemHoly;
			desc: 'A column of unleashed spiritual energy blasts every foe within 12m.'	),
		(	Name: 'Cure Poison';
			eff: EFF_CureStatus;
			Step: SEF_Poison; cost: 10;
			C: LightGreen;
			desc: 'The poison status effect may be cured.' ),
		(	Name: 'Theta Bolt';
			cdesc: 'project mental energy towards';
			eff: EFF_ShootAttack;
			Step: 4; P1: 2; P2: 7; cost: 10;
			C: LightBlue; ATT: AA_StatusSleep + AA_HitRoll + '05' + AA_Value + '03';
			desc: 'One enemy is struck by a calculated blast of psi potential. It may prove too much for their feeble senses.' ),

		{ 21 - 25 }
		(	Name: 'Stasis';
			eff: EFF_StatAttack;
			Step: SEF_Paralysis; P1: 1; P2: 0; cost: 12;
			C: LightMagenta; ATT: AA_Value+'02';
			desc: 'All foes adjacent to the character may be frozen in time.' ),
		(	Name: 'Inferno';
			cdesc: 'call forth a firestorm';
			eff: EFF_ShootAttack;
			Step: 8; P1: 0; P2: 5; cost: 12;
			C: LightRed; ATT: AA_BlastAttack + '01' + AA_ElemFire;
			desc: 'This powerful pyrokinetic attack affects all foes within one and a half meters of its detonation point.' ),
		(	Name: 'Warp Gate';
			eff: EFF_Teleport;
			Step: 30; P1: 0; cost: 7;
			C: LightGreen;
			desc: 'The character can make a short jump through transreal space to a nearby random location.' ),
		(	Name: 'Sense Aura';
			eff: EFF_SenseAura;
			{ NOTE - Manually pasting in MKIND_Critter here.}
			Step: 2; cost: 4;
			C: LightGreen;
			desc: 'The character will for a moment sense the presence of all other beings in the vicinity.' ),
		(	Name: 'Etherial Mist';
			cdesc: 'call forth mysterious clouds';
			eff: EFF_ShootAttack;
			Step: 5; P1: -1; P2: 2; cost: 5;
			C: White; ATT: AA_SmokeAttack + '01' + AA_Value + '03' + AA_Duration + '15';
			desc: 'Smoky mists formed from psychic matter can hide the caster and provide cover.' )


	);


	{The following array holds spell advancement lists for}
	{all the different types of spellcaster in the game.}
	NumSchool = 5;
	NumLevel = 12;
	SCHOOL_Astral = 1;
	SCHOOL_Zeomancy = 2;
	SCHOOL_Navigator = 3;
	SCHOOL_Samurai = 4;
	SCHOOL_DemonHunter = 5;
	SpellCollege: Array [1..NumSchool,1..NumLevel,1..5] of Integer = (
		(	(  2,  5,  6, 11,  0),	{Astral Seer}
			(  7, 15, 24,  0,  0),
			( 16, 19,  0,  0,  0),
			( 18, 23,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0)		),

		(	(  1,  3,  4, 24, 25),	{Zeomancer}
			( 23, 13,  0,  0,  0),
			( 14,  9,  0,  0,  0),
			( 12, 20,  0,  0,  0),
			( 19, 21,  0,  0,  0),
			( 22,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0)		),

		(	(  2,  4,  5, 13,  0),	{Navigator}
			(  6,  3,  0,  0,  0),
			( 10, 23,  0,  0,  0),
			( 16, 20,  0,  0,  0),
			( 11, 19,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0)		),

		(	(  0,  0,  0,  0,  0),	{Samurai}
			(  0,  0,  0,  0,  0),
			(  7,  8,  0,  0,  0),
			(  9,  1,  0,  0,  0),
			( 10, 13,  0,  0,  0),
			( 17, 19,  0,  0,  0),
			( 23,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0)		),

		(	( 13, 18,  9,  8, 15),	{Demon Hunter}
			( 19,  6, 23,  0,  0),
			( 10, 22,  0,  0,  0),
			( 17,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0),
			(  0,  0,  0,  0,  0)		)


	);


Function LocateSpellMem(LList: SpellMemPtr; s: Integer): SpellMemPtr;
Function AddSpellMem(var LList: SpellMemPtr; C: Integer): SpellMemPtr;
Procedure DisposeSpellMem(var LList: SpellMemPtr);
Procedure RemoveSpellMem(var LList,LMember: SpellMemPtr);
Function AAVal(AttList,A: String): Integer;
Procedure WriteSpellMem(SL: SpellMemPtr; var F: Text);
Function ReadSpellMem(var F: Text): SpellMemPtr;


implementation

Function LocateSpellMem(LList: SpellMemPtr; s: Integer): SpellMemPtr;
	{Search through list LList looking for SpellMem S.}
	{If found, return the address of that list member.}
	{If not found, return Nil.}
var
	it: SpellMemPtr;
begin
	it := Nil;
	while LList <> Nil do begin
		if LList^.code = s then it := LList;
		LList := LList^.Next;
	end;
	LocateSpellMem := it;
end;

Function LastSpellMem(LList: SpellMemPtr): SpellMemPtr;
	{Search through the linked list, and return the last element.}
	{If LList is empty, return Nil.}
begin
	if LList <> Nil then
		while LList^.Next <> Nil do
			LList := LList^.Next;
	LastSpellMem := LList;
end;

Function AddSpellMem(var LList: SpellMemPtr; C: Integer): SpellMemPtr;
	{Add a new element to the end of LList.}
var
	it: SpellMemPtr;
begin
	{Check first to see if the spell is already known. If so,}
	{do nothing now.}
	it := LocateSpellMem(LList,C);

	if it = Nil then begin
		{Allocate memory for our new element.}
		New(it);
		if it = Nil then exit;

		{Initialize values.}
		it^.code := C;
		it^.mnem := ' ';
		it^.Next := Nil;

		{Attach IT to the list.}
		if LList = Nil then
			LList := it
		else
			LastSpellMem(LList)^.Next := it;
	end;

	{Return a pointer to the new element.}
	AddSpellMem := it;
end;

Procedure DisposeSpellMem(var LList: SpellMemPtr);
	{Dispose of the list, freeing all associated system resources.}
var
	LTemp: SpellMemPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure RemoveSpellMem(var LList,LMember: SpellMemPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: SpellMemPtr;
begin
	{Initialize A and B}
	B := LList;
	A := Nil;

	{Locate LMember in the list. A will thereafter be either Nil,}
	{if LMember if first in the list, or it will be equal to the}
	{element directly preceding LMember.}
	while (B <> LMember) and (B <> Nil) do begin
		A := B;
		B := B^.next;
	end;

	if B = Nil then begin
		{Major FUBAR. The member we were trying to remove can't}
		{be found in the list.}
		writeln('ERROR- RemoveSpellMem asked to remove a link that doesnt exist.');
		end
	else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		LList := B^.Next;
		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;
		Dispose(B);
	end;
end;

Function AAVal(AttList,A: String): Integer;
	{Given attribute list AttList and attribute A, retrieve}
	{the numerical value associated with said attribute.}
	{This value occupies two chars in the string immediately}
	{following the attribute code. Return 0 if no such value}
	{can be found.}
var
	V,C: Integer;
begin
	if Pos(A,AttList)>0 then begin
		Val(Copy(AttList,Pos(A,AttList)+2,2),V,C);
		if C <> 0 then V := 0;
	end else V := 0;
	AAVal := V;
end;

Procedure WriteSpellMem(SL: SpellMemPtr; var F: Text);
	{Save the linked list of spells to the file F.}
begin
	while SL <> Nil do begin
		writeln(F,SL^.code);
		writeln(F,SL^.mnem);
		SL := SL^.Next;
	end;
	writeln(F,-1);
end;

Function ReadSpellMem(var F: Text): SpellMemPtr;
	{Load a list of items saved by the above procedure from}
	{the file F.}
var
	N: Integer;
	SL,S: SpellMemPtr;
begin
	SL := Nil;
	Repeat
		readln(F,N);
		if N <> -1 then begin
			S := AddSpellMem(SL,N);
			readln(F,S^.mnem);
		end;
	until N = -1;
	ReadSpellMem := SL;
end;



end.
