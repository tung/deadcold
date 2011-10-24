unit dcchars;
	{This unit contains major character stuff for DeadCold.}
	{This includes the character generator, and functions}
	{to derive stuff like skill ratings, etc.}

interface

uses crt,rpgmenus,texmodel,texmaps,statusfx,critters,spells,dcitems,plotbase;

const
	NumJobs = 10;
	JobName: array [1..NumJobs] of string = (
		'Marine','Astral Seer','Navigator','Hacker','Demon Hunter',
		'Explorer','Samurai','Bounty Hunter','Star Pirate','Zeomancer'
	);
	JobHitDie: array [1..NumJobs] of byte = (
		9,3,6,5,4, 6,8,4,7,3
	);
	JobMojoDie: array [1..NumJobs] of byte = (
		1,6,4,2,8, 3,4,3,2,6
	);
	JobSchool: array [1..NumJobs] of byte = (
		0,SCHOOL_Astral,SCHOOL_Navigator,0,SCHOOL_DemonHunter,
		0,SCHOOL_Samurai,0,0,SCHOOL_Zeomancy
	);
	JobDesc: array [1..NumJobs] of pchar = (
		'A well trained killing machine. The Marine doesn''t have many noncombat skills, but generally doesn''t need them.',
		'The mind of an Astral Seer is naturally tuned to the vibration frequency of reality itself. They are powerful psykers, acting as advisors on spiritual matters and as the keepers of ancient traditions.',
		'Only special individuals with psychic awareness are able to guide spacecraft through transreal space. The Navigator has psi powers, plus a number of other skills which are needed in the depths of space.',
		'A computer security expert, and career criminal. Hackers are experts at finding things which other people wish would stay hidden.',
		'Member of an ancient order, sworn to eternal secrecy, the demon hunter protects this reality from those who would destroy it.',
		'Travelling the fringes of human space, searching for new worlds, the explorer leads a solitary existence. A wide variety of skills are needed for this job.',
		'An anacronistic figure, well schooled in the martial arts and mystic secrets of ancient Terra. Samurai scorn the use of guns, but none are their equal in close combat.',
		'Part lawman, part assassin, Bounty Hunters are paid to track down and eliminate other human beings. They are experts at sniping enemies from a distance.',
		'Cruising the spaceways, smuggling contraband or seeking ripe targets, pirates are the bane of interstellar trade. They are skilled combatants who rely more on speed and guile than on brute force.',
		'Trained in both math and mysticism, Zeomancers pursue their arcane craft with modern science. Study has freed their order from ancient superstition, allowing them greater control of natural forces than ever thought possible.'
	);
	JobStat: array [1..NumJobs,1..8] of byte =(
		(11,11, 1, 1, 1, 1, 1, 1),	{Marine}
		( 1, 1, 1, 1, 1,11,11, 1),	{Astroseer}
		( 7, 7,10,10, 8,15,12, 7),	{Navigator}
		( 1, 1, 1, 1,11, 1, 1,11),	{Hacker}
		(13,14,13,14,13,14,14,13),	{Demon Hunter}
		( 1, 1, 1, 1, 1, 1, 1, 1),	{Explorer}
		(16, 1, 5,15, 1, 1,12, 5),	{Samurai}
		( 1, 1,15,12, 5,15, 5, 9),	{Bounty Hunter}
		( 1, 1,11,11, 1, 1, 1, 1),	{Pirate}
		( 1, 1, 1, 1,11, 1,11, 1)	{Zeomancer}
	);
	StatName: array [1..8] of string = (
		'Strength','Endurance','Speed','Dexterity',
		'Technical','Awareness','Willpower','Luck');
	StatAbbrev: array [1..8] of string = (
		'St','En','Sp','Dx','Tc','Aw','Wp','Lk'
	);

	{Define the index numbers associated with each character stat.}
	STAT_Strength = 1;
	STAT_Toughness = 2;
	STAT_Speed = 3;
	STAT_Dexterity = 4;
	STAT_Technical = 5;
	STAT_Perception = 6;
	STAT_Willpower = 7;
	STAT_Luck = 8;

	NumSkill = 15;	{The number of PC skills.}
	JobSkill: array [1..NumJobs,1..NumSkill] of shortint = (
	( 0, 0, 0, 0, 2, 2,-3, 0,-4,-2, 0, 0, 0, 0, 0),	{Marine}
	( 4, 2, 2, 0, 1,-2, 0, 1,-3, 2, 0, 0, 2, 5, 0),	{Astral Seer}
	( 0, 1, 1, 0, 0, 2,-1, 1,-3, 1, 0, 1, 1, 1, 0),	{Navigator}
	( 0, 5, 0, 0, 2, 1, 3, 2, 2,-1, 0, 2, 0, 6, 0),	{Hacker}
	( 1, 3, 9, 0, 1, 1,-1, 0,-1, 1, 3, 0, 2, 1, 0),	{Demon Hunter}
	( 1, 1, 1, 1, 2, 2,-1, 1,-1, 1, 0, 2, 0, 4, 0),	{Explorer}
	(-2, 0, 2, 0, 2,-3,-2, 0,-3, 1, 0, 0,-1, 0, 0),	{Samurai}
	( 0, 0, 0, 1, 2, 2,-2, 0,-4, 0, 0, 0, 0, 0, 0),	{Bounty Hunter}
	( 1, 0,-1,-1, 2, 2,-2, 0,-4,-1, 0,-1, 0, 0, 0),	{Pirate}
	( 2, 1, 2, 0,-3,-2, 1, 2,-2, 2, 1, 1, 2, 3, 0)	{Zeomancer}
	);
	SKILL_DodgeAttack = 1;
	SKILL_LuckSave = 2;
	SKILL_MysticDefense = 3;
	SKILL_VisionRange = 4;
	SKILL_MeleeAttack = 5;
	SKILL_MissileAttack = 6;
	SKILL_Stealth = 7;
	SKILL_Detection = 8;
	SKILL_DisarmTrap = 9;
	SKILL_PsiSkill = 10;
	SKILL_PsiForce = 11;
	SKILL_Technical = 12;
	SKILL_LearnSpell = 13;
	SKILL_Identify = 14;
	SkillAdv: array [1..NumJobs,1..NumSkill] of shortint = (
	(-5,-5,-5, 0, 3, 3,-5,-6,-9, 1, 0, 0, 0,-5, 0),	{Marine}
	(-5,-5,-5,-9, 1, 1, 1,-5,-7, 3, 1, 0, 3,-5, 0),	{Astral Seer}
	(-5,-5,-5,-9, 2, 3, 1,-4,-5, 2,-4, 0,-2,-5, 0),	{Navigator}
	(-5, 1,-5, 0, 2, 2, 2, 1, 1, 1, 0, 2, 0,-5, 0),	{Hacker}
	(-5,-5, 3, 0, 3, 3, 1,-5,-7, 2, 2, 0, 2,-5, 0),	{Demon Hunter}
	(-5,-5,-5,-6, 2, 2, 1,-4,-4, 2, 0, 1, 0, 1, 0),	{Explorer}
	(-5,-5,-5, 0, 4, 1,-4,-5,-6, 2,-5, 0,-2,-5, 0),	{Samurai}
	( 1,-5,-5,-5, 1, 3, 2,-5,-6, 1, 0, 0, 0,-5, 0),	{Bounty Hunter}
	(-5,-5,-5, 0, 3, 3,-5,-6,-7, 1, 0, 0, 0,-5, 0),	{Pirate}
	(-5,-5, 1, 0, 1, 1, 1,-4,-5, 3, 1, 1, 3,-5, 0)	{Zeomancer}
	);


	{Derived Statistic Constants}
	BaseHP = 6;

	{define the KIND field for a character model.}
	MKIND_Character = 1;

	NumEquipSlots = 6;
	ES_MissileWeapon = IKIND_Gun;
	ES_MeleeWeapon = IKIND_Wep;
	ES_Head = IKIND_Cap;
	ES_Body = IKIND_Armor;
	ES_Hand = IKIND_Glove;
	ES_Foot = IKIND_Shoe;
	EquipSlotName: Array [1..NumEquipSlots] of String = (
		'Missile Weapon:','Melee Weapon:  ','Head:          ',
		'Body:          ','Hands:         ','Feet:          '
	);

type
	dcchar = Record
		{Primary Characteristics. These are saved to disk.}
		Name: String;		{The character's name.}
		BGOrigin: String;	{Character history}
		BGHistory: String;	{Family/Planet status}
		BGArrival: String;	{Character arrival at DeadCold}
		Gender: Byte;		{The character's gender.}
		stat: Array [1..8] of byte;	{The character's stats.}
		skill: Array [1..NumSkill] of Integer;	{The character's skill ranks.}
		Lvl: Integer;		{Experience Level}
		XP: LongInt;		{Experience Points}
		inv: dcitemptr;		{Inventory}
		eqp: Array [1..NumEquipSlots] of dcitemptr; {Equipment}
		SF: NAttPtr;		{The PC's status.}
		Spell: SpellMemPtr;	{The PC's psi powers.}
		job: Integer;			{The character's job.}
		HP,HPMax: Integer;		{Hit Points current and maximum.}
		MP,MPMax: Integer;		{Mojo Points current and maximum.}

		Carbs: Integer;		{Carbohydrate levels. i.e. food.}

		{Runtime Characteristics. These are generated for the character during the game.}
		M: ModelPtr;			{A pointer to the character's model.}
		Target: ModelPtr;		{The most recently attacked enemy.}
		RepCount: Integer;
		LastCmd: Char;
		RepState: Byte;		{Set to 0 when a repeat is first issued; may be altered by other procedures.}
	end;
	dccharptr = ^dcchar;

Procedure DisposePC( PC: DCCharPtr );

Function CStat(PC: DCCharPtr; Stat: Integer): Integer;

Function PCVisionRange(PC: DCCharPtr): Integer;
Function PCDefense(PC: DCCharPtr): Integer;
Function PCLuckSave(PC: DCCharPtr): Integer;
Function PCMysticDefense(PC: DCCharPtr): Integer;
Function PCMeleeSkill(PC: DCCharPtr): Integer;
Function PCMeleeDamage(PC: DCCharPtr): Integer;
Function PCMissileSkill(PC: DCCharPtr): Integer;
Function PCMissileDamage(PC: DCCharPtr): Integer;
Function PCMissileRange(PC: DCCharPtr): Integer;
Function PCThrowSkill(PC: DCCharPtr): Integer;
Function PCThrowRange(PC: DCCharPtr): Integer;
Function PCArmorPV(PC: DCCharPtr): Integer;
Function PCStealth(PC: DCCharPtr): Integer;
Function PCDetection(PC: DCCharPtr): Integer;
Function PCDisarmSkill(PC: DCCharPtr): Integer;
Function PCTechSkill(PC: DCCharPtr): Integer;
Function PCMoveSpeed(PC: DCCharPtr): Integer;
Function PCRegeneration(PC: DCCharPtr): Integer;
Function PCRestoration(PC: DCCharPtr): Integer;
Function PCPsiSkill(PC: DCCharPtr): Integer;
Function PCPsiForce(PC: DCCharPtr): Integer;
Function PCIDSkill(PC: DCCharPtr): Integer;
Function PCHPBonus(PC: DCCharPtr): Integer;
Function PCMPBonus(PC: DCCharPtr): Integer;

Procedure WritePC(PC: DCCharPtr; var F: Text);
Function ReadPC(var F: Text; gb: GameBoardPtr; SFV: Integer): DCCharPtr;



implementation

Function PCStatusValue( SL: NAttPtr; SFX: Integer ): LongInt;
	{ Determine the value of this status effect. }
var
	N: LongInt;
begin
	N := NAttValue( SL , NAG_StatusChange , SFX );
	if N > 0 then begin
		N := ( N + 9 ) div 10;
	end else if N = -1 then begin
		N := 3;
	end;
	PCStatusValue := N;
end;

Procedure DisposePC( PC: DCCharPtr );
	{Dispose of the PC and all attached dynamic structures.}
var
	t: Integer;
begin
	{Error check.}
	if PC = Nil then exit;

	DisposeItemList(PC^.inv);
	for t := 1 to NumEquipSlots do DisposeItemList(PC^.Eqp[t]);
	DisposeNAtt(PC^.SF);
	DisposeSpellMem(PC^.Spell);
	Dispose(PC);
end;

Function CStat(PC: DCCharPtr; Stat: Integer): Integer;
	{Calculate the player's modified stat value.}
var
	it: Integer;
begin
	it := PC^.Stat[Stat];

	{Modify for attribute draining attack.}
	it := it - PCStatusValue( PC^.SF , -(SEF_DrainBase + Stat) );

	{Modify for attribute boost effects.}
	it := it + PCStatusValue( PC^.SF , SEF_BoostBase + Stat );

	{Modify for hunger/starvation.}
	if PC^.Carbs < 0 then begin
		if Stat < 5 then it := it + PC^.Carbs
		else it := it + (PC^.Carbs div 2);
	end;

	if it < 1 then it := 1;
	CStat := it;
end;

Function PCVisionRange(PC: DCCharPtr): Integer;
	{Calculate the PC's vision range, for use in the POV.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Perception) div 2 + PC^.Skill[SKILL_VisionRange] + 1;

	{Adjust for the FarSight ability.}
	it := it + (( PCStatusValue( PC^.SF , SEF_VisionBonus ) + 4 ) div 5 );

	if it < 2 then it := 2;
	PCVisionRange := it;
end;

Function PCDefense(PC: DCCharPtr): Integer;
	{Calculate the PC's defense step, taking into account such}
	{things as stats, skills, and equipment.}
var
	it: Integer;
begin
	{Defense Step := Def Skill + Speed Bonus}
	{              + Dex and Per slight bonuses}
	it := CStat(PC,STAT_Speed) div 3 + PC^.Skill[SKILL_DodgeAttack];
	if CStat(PC,STAT_Luck) > 14 then it := it + (CStat(PC,STAT_Luck) - 12) div 3;
	if CStat(PC,STAT_Dexterity) > 16 then it := it + (CStat(PC,STAT_Dexterity) - 12) div 5;
	if CStat(PC,STAT_Perception) > 19 then it := it + (CStat(PC,STAT_Perception) - 15) div 5;

	{If the player is not wearing shoes, movement over the hard}
	{metal floors of the space station is adversely affected.}
	if PC^.Eqp[ES_Foot] = Nil then it := it - 2;

	if it < 1 then it := 1;
	PCDefense := it;
end;

Function PCLuckSave(PC: DCCharPtr): Integer;
	{Calculate the PC's Luck Save. This is the defense used}
	{against traps, explosions, breath weapons, etc.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Luck) div 3 + PC^.Skill[SKILL_LuckSave];
	if CStat(PC,STAT_Perception) > 14 then it := it + (CStat(PC,STAT_Perception) - 12) div 3;
	if CStat(PC,STAT_Speed) > 16 then it := it + (CStat(PC,STAT_Speed) - 12) div 5;
	PCLuckSave := it;
end;

Function PCMysticDefense(PC: DCCharPtr): Integer;
	{Calculate the PC's Mystic Defense. This is the defense used}
	{against psi powers and certain monster abilities.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Luck) div 3 + PC^.Skill[SKILL_MysticDefense];
	if CStat(PC,STAT_Willpower) > 14 then it := it + (CStat(PC,STAT_Willpower) - 12) div 3;
	PCMysticDefense := it;
end;

Function PCMeleeSkill(PC: DCCharPtr): Integer;
	{Calculate the PC's melee skill step.}
var
	it: Integer;
begin
	it := PC^.Skill[SKILL_MeleeAttack];
	if PC^.EQP[ES_MeleeWeapon] <> Nil then begin
		it := it + CWep[PC^.EQP[ES_MeleeWeapon]^.icode].ACC;
		it := it + CStat(PC,CWep[PC^.EQP[ES_MeleeWeapon]^.icode].stat) div 3;
	end else begin
		it := it + CStat(PC,STAT_Strength) div 3;
	end;

	{Add the CCM of the PC's missile weapon.}
	if PC^.EQP[ES_MissileWeapon] <> Nil then begin
		it := it + CGuns[PC^.EQP[ES_MissileWeapon]^.icode].CCM;
	end;

	it := it + PCStatusValue(PC^.SF,SEF_H2HBonus);

	if it < 1 then it := 1;
	PCMeleeSkill := it;
end;

Function PCMeleeDamage(PC: DCCharPtr): Integer;
	{Calculate the damage of the PC's basic melee attack.}
var
	it: Integer;
begin
	{Calculate base weapon damage.}
	if PC^.EQP[ES_MeleeWeapon] <> Nil then begin
		it := CWep[PC^.EQP[ES_MeleeWeapon]^.icode].DMG;
	end else it := 0;

	{Add Strength bonus.}
	if CStat(PC,STAT_Strength) > 12 then begin
		it := it + CStat(PC,STAT_Strength) - 12;
	end else if it = 0 then begin
		it := 1;
	end;

	{Add a bonus for Status Change effects.}
	it := it + PCStatusValue(PC^.SF,SEF_CCDmgBonus);

	PCMeleeDamage := it;
end;

Function PCMissileSkill(PC: DCCharPtr): Integer;
	{Calculate the PC's melee skill step.}
var
	it: Integer;
begin
	it := PC^.Skill[SKILL_MissileAttack] + CStat(PC,STAT_Dexterity) div 3;
	if PC^.EQP[ES_MissileWeapon] <> Nil then it := it + CGuns[PC^.EQP[ES_MissileWeapon]^.icode].ACC;

	it := it + PCStatusValue(PC^.SF,SEF_MslBonus);

	if it < 1 then it := 1;
	PCMissileSkill := it;
end;

Function PCMissileDamage(PC: DCCharPtr): Integer;
	{Calculate the damage of the PC's basic missile attack.}
var
	it: Integer;
begin
	if PC^.EQP[ES_MissileWeapon] <> Nil then begin
		it := CGuns[PC^.EQP[ES_MissileWeapon]^.icode].DMG;
	end else it := 0;
	PCMissileDamage := it;
end;

Function PCMissileRange(PC: DCCharPtr): Integer;
	{Calculate the range of the PC's basic missile attack.}
var
	it: Integer;
begin
	if PC^.EQP[ES_MissileWeapon] <> Nil then begin
		it := CGuns[PC^.EQP[ES_MissileWeapon]^.icode].RNG;
	end else it := 0;
	PCMissileRange := it;
end;

Function PCThrowSkill(PC: DCCharPtr): Integer;
	{Determine the PC's grenade throwing skill. This is the}
	{average between the PC's Missile and Melee skills.}
var
	it: Integer;
begin
	it := (PC^.Skill[SKILL_MissileAttack] + PC^.Skill[SKILL_MeleeAttack]) div 2;
	it := it + CStat(PC,STAT_Dexterity) div 3;

	{Throwing skill gets the Missile Bonus from spells.}
	it := it + PCStatusValue(PC^.SF,SEF_MslBonus);

	if it < 1 then it := 1;
	PCThrowSkill := it;
end;

Function PCThrowRange(PC: DCCharPtr): Integer;
	{Determine the maximum range at which the PC can throw}
	{a grenade.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Strength) div 2 + 3;
	PCThrowRange := it;
end;

Function PCArmorPV(PC: DCCharPtr): Integer;
	{Add up the protection value of all the bits of armor that}
	{the PC is wearing.}
var
	it: Integer;
begin
	it := 0;
	if (PC^.EQP[ES_Head] <> Nil) and (PC^.EQP[ES_Head]^.ikind = IKIND_Cap) then begin
		it := it + CCap[PC^.EQP[ES_Head]^.icode].PV;
	end;
	if (PC^.EQP[ES_Body] <> Nil) and (PC^.EQP[ES_Body]^.ikind = IKIND_Armor) then begin
		it := it + CArmor[PC^.EQP[ES_Body]^.icode].PV;
	end;
	if (PC^.EQP[ES_Hand] <> Nil) and (PC^.EQP[ES_Hand]^.ikind = IKIND_Glove) then begin
		it := it + CGlove[PC^.EQP[ES_Hand]^.icode].PV;
	end;
	if (PC^.EQP[ES_Foot] <> Nil) and (PC^.EQP[ES_Foot]^.ikind = IKIND_Shoe) then begin
		it := it + CShoe[PC^.EQP[ES_Foot]^.icode].PV;
	end;

	{Add the bonus for mystic armor, i.e. residual spells.}
	it := it + PCStatusValue(PC^.SF,SEF_ArmorBonus);

	PCArmorPV := it;
end;

Function PCStealth(PC: DCCharPtr): Integer;
	{Determine the PC's stealth rating.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Perception) div 3 + PC^.Skill[SKILL_Stealth];
	it := it + CStat(PC,STAT_Luck) div 5 + CStat(PC,STAT_Dexterity) div 9;

	{If the player is not wearing shoes, stealth is improved.}
	if PC^.Eqp[ES_Foot] = Nil then Inc(it);

	{Add a bonus for spells benefiting the PC.}
	it := it + PCStatusValue(PC^.SF,SEF_StealthBonus);

	if it < 1 then it := 1;
	PCStealth := it;
end;

Function PCDetection(PC: DCCharPtr): Integer;
	{Determine the PC's detection rating.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Perception) div 3 + PC^.Skill[SKILL_Detection];
	it := it + CStat(PC,STAT_Luck) div 8;
	PCDetection := it;
end;

Function PCDisarmSkill(PC: DCCharPtr): Integer;
	{Determine the PC's disarm trap rating.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Technical) div 3 + PC^.Skill[SKILL_DisarmTrap];
	if CStat(PC,STAT_Perception) > 16 then it := it + (CStat(PC,STAT_Perception) - 12) div 5;
	if it < 1 then it := 1;
	PCDisarmSkill := it;
end;

Function PCTechSkill(PC: DCCharPtr): Integer;
	{Determine the PC's technology rating.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Technical) div 3 + PC^.Skill[SKILL_Technical];
	if CStat(PC,STAT_Perception) > 16 then it := it + (CStat(PC,STAT_Perception) - 12) div 5;
	if it < 1 then it := 1;
	PCTechSkill := it;
end;

Function PCMoveSpeed(PC: DCCharPtr): Integer;
	{Determine the movement rate of the PC. The number returned}
	{will be the number of actions that the player will get over}
	{the course of 12 clicks.}
var
	it: Integer;
begin
	it := CStat(PC,STAT_Speed) div 3 + 3;
	it := it + PCStatusValue(PC^.SF,SEF_SpeedBonus);

	{If the player is not wearing shoes, movement over the hard}
	{metal floors of the space station is adversely affected.}
	if PC^.Eqp[ES_Foot] = Nil then Dec(it);

	if it < 1 then it := 1;
	PCMoveSpeed := it;
end;

Function PCRegeneration(PC: DCCharPtr): Integer;
	{Determine the speed of the PC's natural healing.}
var
	it: Integer;
begin
	it := PC^.HPMax div 8;
	it := it + PCStatusValue(PC^.SF,SEF_Regeneration);
	if it < 1 then it := 1;

	{Modify for the PC's action.}
	{HP are restored more quickly when the PC is standing still.}
	if PC^.LastCmd = '5' then begin
		it := it + 3;
		if PC^.RepCount > 0 then it := it + 2;
	end;

	PCRegeneration := it;
end;

Function PCRestoration(PC: DCCharPtr): Integer;
	{Determine the speed of the PC's natural mojo renewal.}
var
	it: Integer;
begin
	it := PC^.MPMax div 3;
	it := it + PCStatusValue(PC^.SF,SEF_Restoration);
	if it < 1 then it := 1;

	{Modify for actions.}
	if PC^.LastCmd = '5' then begin
		it := it + 3;
		if PC^.RepCount > 0 then it := it + 2;
	end;

	PCRestoration := it;
end;


Function PCPsiSkill(PC: DCCharPtr): Integer;
	{Calculate the PC's spellcasting skill.}
var
	it: Integer;
begin
	it := PC^.Skill[SKILL_PsiSkill] + CStat(PC,STAT_Willpower) div 3;
	if it < 1 then it := 1;
	PCPsiSkill := it;
end;

Function PCPsiForce(PC: DCCharPtr): Integer;
	{Calculate the PC's spellcasting effect step.}
var
	it: Integer;
begin
	it := PC^.Skill[SKILL_PsiForce];
	if CStat(PC,STAT_Willpower) > 12 then it := it + ( CStat(PC,STAT_Willpower) - 11 ) div 2;
	PCPsiForce := it;
end;

Function PCIDSkill(PC: DCCharPtr): Integer;
	{Calculate the PC's item identification skill.}
var
	it: Integer;
begin
	it := PC^.Skill[SKILL_Identify] + CStat(PC,STAT_Technical) div 3;
	if it < 1 then it := 1;
	PCIDSkill := it;
end;


Function PCHPBonus(PC: DCCharPtr): Integer;
	{Calculate the level-up HP bonus of the character. This is}
	{based on true Toughness, not the modified score.}
var
	it: Integer;
begin
	it := (PC^.Stat[STAT_Toughness] - 11) div 2;
	if it < -1 then it := -1;
	PCHPBonus := it;
end;

Function PCMPBonus(PC: DCCharPtr): Integer;
	{Calculate the level-up MP bonus of the character. This is}
	{based on true Willpower, not the modified score.}
var
	it: Integer;
begin
	it := (PC^.Stat[STAT_Willpower] - 11) div 2;
	if it < -1 then it := -1;
	PCMPBonus := it;
end;


Procedure WritePC(PC: DCCharPtr; var F: Text);
	{F is an open text file. Write all the data for the given PC}
	{to that file.}
var
	T: Integer;
begin
	{Write an identifier, to make debugging and savefile cheating}
	{so much easier.}
	writeln(F,'*** DCChar Block ***');

	{General Data block}
	writeln(F,PC^.M^.X);
	writeln(F,PC^.M^.Y);
	writeln(F,PC^.Name);
	writeln(F,PC^.Gender);
	writeln(F,PC^.Job);
	writeln(F,PC^.HP);
	writeln(F,PC^.HPMax);
	writeln(F,PC^.MP);
	writeln(F,PC^.MPMax);
	writeln(F,PC^.Carbs);
	writeln(F,PC^.Lvl);
	writeln(F,PC^.XP);

	{Stats block}
	for t := 1 to 8 do writeln(F,PC^.Stat[t]);

	{Skills block}
	for t := 1 to NumSkill do writeln(F,PC^.Skill[t]);

	{Equipment Slots block}
	for t := 1 to NumEquipSlots do WriteItemList(PC^.Eqp[t],F);

	{Inventory block}
	WriteItemList(PC^.Inv,F);

	{Status block}
	WriteNAtt(PC^.SF,F);

	{Spells block}
	WriteSpellMem(PC^.Spell,F);
end;

Function ReadPC(var F: Text; gb: GameBoardPtr; SFV: Integer): DCCharPtr;
	{F is an open text file. Read in all the data needed for}
	{a character, as written to the file by the above procedure.}
	{Also, initialize the model for the PC.}
var
	PC: DCCharPtr;
	T: Integer;
	A: String;
	X,Y: Integer;
begin
	{Allocate memory for the character to be loaded.}
	New(PC);
	if PC = Nil then Exit(Nil);
	PC^.Target := Nil;

	{Read in the identification line.}
	ReadLn(F,A);

	{General Data block}
	readln(F,X);
	readln(F,Y);
	readln(F,PC^.Name);
	readln(F,PC^.Gender);
	readln(F,PC^.Job);
	readln(F,PC^.HP);
	readln(F,PC^.HPMax);
	readln(F,PC^.MP);
	readln(F,PC^.MPMax);
	readln(F,PC^.Carbs);
	readln(F,PC^.Lvl);
	readln(F,PC^.XP);

	{Stats block}
	for t := 1 to 8 do readln(F,PC^.Stat[t]);

	{Skills block}
	for t := 1 to NumSkill do readln(F,PC^.Skill[t]);

	{Monster Memory block - applies only to obsolete save files. }
	if SFV < 1003 then begin
		for t := 1 to 20 do readln(F,A);
	end;

	{Equipment Slots block}
	for t := 1 to NumEquipSlots do PC^.Eqp[t] := ReadItemList(F);

	{Inventory block}
	PC^.Inv := ReadItemList(F);

	{Status block}
	if SFV < 1003 then begin
		PC^.SF := Nil;
		ReadObsoleteSFX(F);
	end else begin
		PC^.SF := ReadNAtt( F );
	end;

	{Spells block}
	PC^.Spell := ReadSpellMem(F);

	{Now, finally, we have all the info we need for the PC.}
	{Let's initialize some values so that things can start working.}
	PC^.RepCount := 0;
	PC^.LastCmd := '&';

	{Add the model here, then set the POV data.}
	PC^.M := AddModel(gb^.mlist,gb^.mog,'@',lightgreen,white,False,X,Y,MKIND_Character);

	gb^.pov.m := PC^.M;
	gb^.pov.range := PCVisionRange(PC);
	UpdatePOV(gb^.pov,gb);

	ReadPC := PC;
end;



end.
