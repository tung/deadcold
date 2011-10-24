unit charts;
	{What does this unit do? Well, you probably know that}
	{any pen-&-paper RPG worth its salt comes with pages and}
	{pages and pages of charts that the GM can use to roll}
	{up encounters, rewards, and whatnots.}

	{Okay, maybe most good modern RPGs have done away with}
	{the oodles of hideous charts that were the norm all}
	{throughout the 80s... but this is a computer game, darnit,}
	{and we need charts to supplement the CPU's inherent lack}
	{of imagination.}

	{So, that's what this unit is. Random generators for all}
	{kinds of stuff. The appendicies of the 1e DMG, if you will.}
	{And if you understand that reference, no more need be said.}

interface

uses texmodel,texmaps,critters,dcitems,gamebook,rpgdice,dcchars,rpgtext;

Const
	MaxMonsters = 1500;	{The maximum number of monsters that can appear on the map at once.}
				{On a P2-165 laptop, lag becomes noticeable around C = 800.}

	{Our wandering monster chart is structured as follows:}
	{ The first value is the creature number.}
	{ The second value is the # Appearing die size.}
	NumWCT = 25;	{Number of Wandering Critter Types.}
	LowWChart = 0;	{ Lowest Wandering Monster Chart }
	NumWChart = 5;	{ Number of Wandering Monster Charts. }
	WanderChart: Array [LowWChart..NumWChart,1..NumWCT,1..2] of Integer = (
	(	(4,4),(4,8),(11,2),(8,1),(3,1),	{ Signature Chart -         }
		(4,6),(16,1),(11,1),(8,2),(3,1),{   Module "B": Memorials   }
		(4,6),(16,1),(10,1),(8,2),(15,4), { Many vacuum critters &  }
		(4,8),(16,1),(10,3),(8,2),(15,5), { non-breathers here.     }
		(4,10),(16,1),(18,1),(8,3),(15,6)	),

	(	(2,4),(2,4),(4,4),(6,3),(2,3),	{ This is chart 1, and also }
		(2,4),(2,4),(4,4),(6,4),(2,3),	{ the signature chart for }
		(2,4),(2,4),(4,4),(6,4),(10,1),	{ Module "C" - Visitor Center }
		(2,4),(8,1),(4,4),(6,4),(2,3),	{   A lot of easy monsters. }
		(2,6),(4,4),(2,5),(2,4),(15,3)	),

	(	(2,4),(2,4),(4,4),(6,5),(8,1),
		(2,4),(2,4),(4,4),(6,4),(8,1),
		(2,4),(2,8),(4,4),(6,4),(10,1),
		(2,4),(8,1),(4,4),(6,4),(11,1),
		(2,6),(4,4),(4,8),(16,1),(15,3)	),

	(	(2,8),(3,1),(5,1),(9,1),(12,1),
		(2,8),(4,6),(6,8),(9,3),(14,1),
		(2,8),(4,8),(6,10),(10,4),(12,1),
		(2,10),(4,10),(8,3),(10,3),(15,8),
		(19,1),(18,1),(8,3),(11,6),(2,16)	),

	(	(2,12),(4,20),(9,5),(12,5),(3,1),
		(20,1),(5,1),(9,5),(12,5),(3,2),
		(16,3),(6,20),(9,5),(12,3),(3,2),
		(3,1),(8,8),(10,5),(14,1),(2,16),
		(18,4),(13,1),(10,5),(14,1),(2,16)	),

	(	(20,1),(18,8),(9,5),(12,5),(3,3),
		(19,4),(5,4),(20,1),(12,5),(3,3),
		(16,3),(6,20),(19,4),(12,3),(3,3),
		(3,1),(8,8),(10,5),(14,1),(17,1),
		(3,3),(13,1),(10,6),(14,1),(17,1)	)



	);

	{TType stands for Treasure Type.}
	NumTType = 24;
	NumTChance = 25;	{Number of entries per random chart.}

	TType_SecurityArea = 1;
	TType_StorageRoom = 2;
	TType_SpaceGear = 3;
	TType_BasicWeapons = 4;
	TType_RobotWeapons = 5;
	TType_TechnoItems = 6;
	TType_Crypt = 7;

	TType_AllMedicene = 9;
	TType_AllFood = 9;
	TType_AllAmmo = 10;
	TType_BasicGuns = 11;
	TType_BasicWeps = 12;
	TType_CivilianClothes = 13;
	TType_C5mm = 14;
	TType_C8mm = 15;
	TType_C12mm = 16;
	TType_C25mm = 17;
	TType_CGrn = 18;
	TType_UC5mm = 19;
	TType_UC8mm = 20;
	TType_UC12mm = 21;
	TType_AdvGuns = 22;
	TType_AdvWeps = 23;
	TType_AdvClothes = 24;

	TTChart: Array [1..NumTType,1..NumTChance,1..3] of Integer = (
		{SECURITY ROOM TREASURE}
	(	(IKIND_Ammo,1,30),(IKIND_Ammo,2,20),(TTYPE_C12mm,-1,1),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),
		(TTYPE_UC5mm,-1,0),(TTYPE_C8mm,-1,0),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),
		(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),
		(TTYPE_BasicGuns,-1,0),(TTYPE_CGrn,-1,0),(TTYPE_CGrn,-1,0),(TTYPE_CGrn,-1,0),(TTYPE_CGrn,-1,0),
		(TTYPE_CGrn,-1,0),(TTYPE_AdvGuns,-1,0),(TTYPE_BasicGuns,-1,0),(TTYPE_AdvWeps,-1,0),(TTYPE_BasicWeps,-1,0)),

		{STORAGE AREA TREASURE CHART}
	(	(TType_AllFood,-1,1),(IKIND_Food,2,20),(IKIND_Food,3,10),(IKIND_Food,4,10),(TType_AllFood,-1,1),
		(TType_AllFood,-1,1),(IKIND_Food,7,5),(IKIND_Food,35,1),(IKIND_Food,8,4),(IKIND_Food,34,1),
		(TType_AllMedicene,-1,1),(TTYPE_AllFood,-1,5),(IKIND_Food,7,4),(TTYPE_SpaceGear,-1,7),(TType_AllFood,-1,1),
		(TType_AllMedicene,-1,23),(TType_AllFood,-1,1),(TType_AllFood,-1,1),(IKIND_Armor,1,1),(IKIND_Armor,1,1),
		(TTYPE_CivilianClothes,-1,1),(TTYPE_CivilianClothes,-1,1),(TType_SpaceGear,-1,6),(TType_AllAmmo,-1,0),(TType_AllFood,-1,0)),

		{GENERAL SPACE LIVING GEAR - dropped by polyps and other random treasure monsters}
	(	(TTYPE_AllFood,-1,0),(TTYPE_AllMedicene,-1,0),(TTYPE_AllMedicene,-1,0),(TTYPE_BasicWeps,-1,0),(TTYPE_BasicWeapons,-1,0),
		(IKIND_Food,7,1),(IKIND_Food,8,1),(TTYPE_TechnoItems,-1,1),(TTYPE_AllFood,-1,1),(TTYPE_AllFood,-1,1),
		(IKIND_Electronics,1,0),(TTYPE_CivilianClothes,-1,1),(TTYPE_CivilianClothes,-1,1),(IKIND_Armor,2,1),(IKIND_Glove,1,1),
		(TTYPE_CivilianClothes,-1,1),(TTYPE_CivilianClothes,-1,1),(IKIND_Ammo,1,20),(IKIND_Grenade,12,8),(TTYPE_AllMedicene,-1,0),
		(TType_AllAmmo,-1,0),(TType_AllAmmo,-1,0),(TType_AllFood,-1,0),(TType_AllFood,-1,0),(TType_AllMedicene,-1,0)),

		{BASIC WEAPONS - carried by zombies and other critters}
	(	(IKIND_Gun,1,10),(IKIND_Gun,2,24),(IKIND_Gun,3,20),(IKIND_Gun,4,8),(IKIND_Gun,5,0),
		(IKIND_Gun,6,30),(IKIND_Gun,1,8),(IKIND_Gun,4,0),(IKIND_Gun,2,10),(IKIND_Gun,9,7),
		(IKIND_Gun,3,0),(IKIND_Gun,1,8),(IKIND_Gun,1,0),(IKIND_Gun,3,5),(IKIND_Wep,15,1),
		(IKIND_Wep,2,0),(IKIND_Wep,3,0),(IKIND_Wep,4,0),(IKIND_Wep,6,0),(IKIND_Wep,8,0),
		(TTYPE_BasicGuns,-1,0),(TTYPE_BasicWeps,-1,0),(TTYPE_BasicWeps,-1,0),(TTYPE_BasicWeps,-1,0),(TType_BasicGuns,-1,0)),

		{ROBOT WEAPONS}
	(	(IKIND_Gun,2,10),(IKIND_Gun,2,20),(IKIND_Gun,3,20),(IKIND_Gun,3,8),(IKIND_Gun,4,0),
		(IKIND_Gun,2,10),(IKIND_Gun,2,20),(IKIND_Gun,3,20),(IKIND_Gun,3,8),(TTYPE_BasicGuns,-1,0),
		(IKIND_Gun,2,10),(IKIND_Gun,2,20),(IKIND_Gun,3,20),(IKIND_Gun,3,8),(TTYPE_BasicGuns,-1,2),
		(IKIND_Gun,2,10),(IKIND_Gun,2,20),(IKIND_Gun,3,20),(IKIND_Gun,3,8),(TTYPE_BasicGuns,-1,0),
		(IKIND_Gun,2,10),(IKIND_Gun,12,10),(IKIND_Gun,3,20),(IKIND_Gun,11,8),(IKIND_Gun,7,10)),

		{TECHNOLOGICAL ITEMS - usually dropped by slain robots}
	(	(IKIND_Wep,8,1),(IKIND_Wep,15,1),(IKIND_Wep,8,1),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3),
		(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3),
		(TTYPE_AllAmmo,-1,0),(TTYPE_AllAmmo,-1,0),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3),
		(TTYPE_AllAmmo,-1,0),(IKIND_Ammo,5,2),(IKIND_Ammo,5,2),(IKIND_Ammo,5,10),(IKIND_Ammo,5,3),
		(TTYPE_BasicGuns,-1,6),(TType_AllAmmo,-1,2),(TType_AllAmmo,-1,2),(IKIND_Ammo,5,3),(IKIND_Ammo,5,3)),

		{CRYPT TREASURES}
	(	(IKIND_Cap,4,1),(IKIND_Armor,5,1),(IKIND_Shoe,5,1),(IKIND_KeyItem,2,1),(IKIND_KeyItem,3,1),
		(IKIND_Wep,9,1),(IKIND_KeyItem,4,1),(IKIND_KeyItem,3,1),(IKIND_KeyItem,4,1),(IKIND_KeyItem,5,1),
		(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_AdvClothes,-1,0),
		(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),(TTYPE_CivilianClothes,-1,0),
		(TTYPE_BasicGuns,-1,0),(TTYPE_BasicWeps,-1,0),(TTYPE_AdvGuns,-1,0),(TTYPE_AdvWeps,-1,0),(TTYPE_AdvWeps,-1,0) ),

		{ALL MEDICENE}
	(	(IKIND_Food,24,5),(IKIND_Food,25,5),(IKIND_Food,26,5),(IKIND_Food,27,5),(IKIND_Food,30,10),
		(IKIND_Food,24,10),(IKIND_Food,25,5),(IKIND_Food,26,1),(IKIND_Food,27,5),(IKIND_Food,30,10),
		(IKIND_Food,24,1),(IKIND_Food,25,5),(IKIND_Food,26,1),(IKIND_Food,27,1),(IKIND_Food,30,10),
		(IKIND_Food,24,1),(IKIND_Food,39,5),(IKIND_Food,38,5),(IKIND_Food,37,5),(IKIND_Food,36,5),
		(IKIND_Food,33,5),(IKIND_Food,32,5),(IKIND_Food,31,5),(IKIND_Food,28,1),(IKIND_Food,29,10)),

		{ALL FOOD}
	(	(IKIND_Food,1,6),(IKIND_Food,2,20),(IKIND_Food,3,10),(IKIND_Food,4,10),(IKIND_Food,5,10),
		(IKIND_Food,6,8),(IKIND_Food,7,5),(IKIND_Food,7,3),(IKIND_Food,8,4),(IKIND_Food,8,5),
		(IKIND_Food,16,4),(IKIND_Food,24,15),(IKIND_Food,7,4),(IKIND_Food,7,4),(IKIND_Food,34,3),
		(IKIND_Food,23,8),(IKIND_Food,22,8),(IKIND_Food,21,5),(IKIND_Food,15,1),(IKIND_Food,14,1),
		(IKIND_Food,9,1),(IKIND_Food,10,1),(IKIND_Food,11,1),(IKIND_Food,12,1),(IKIND_Food,13,1)),

		{ALL AMMO}
	(	(IKIND_Ammo,1,50),(IKIND_Ammo,2,30),(IKIND_Ammo,3,20),(IKIND_Ammo,4,10),(IKIND_Ammo,5,3),
		(IKIND_Ammo,1,40),(IKIND_Ammo,2,25),(IKIND_Ammo,103,10),(TTYPE_C25mm,-1,0),(IKIND_Ammo,6,3),
		(IKIND_Ammo,1,30),(IKIND_Ammo,2,20),(IKIND_Ammo,3,20),(TTYPE_C25mm,-1,0),(IKIND_Ammo,5,3),
		(TTYPE_C5mm,-1,0),(TTYPE_C8mm,-1,0),(TTYPE_C12mm,-1,0),(TTYPE_UC5mm,-1,0),(IKIND_Ammo,6,3),
		(TTYPE_C5mm,-1,0),(TTYPE_C8mm,-1,0),(TTYPE_C12mm,-1,0),(TTYPE_UC8mm,-1,0),(TTYPE_CGrn,-1,0)),

		{BASIC GUNS}
	(	(IKIND_Gun,1,10),(IKIND_Gun,2,10),(IKIND_Gun,3,10),(IKIND_Gun,4,7),(IKIND_Gun,5,3),
		(IKIND_Gun,6,10),(IKIND_Gun,7,10),(IKIND_Gun,8,10),(IKIND_Gun,9,10),(IKIND_Gun,10,10),
		(IKIND_Gun,1,0),(IKIND_Gun,9,10),(IKIND_Gun,2,10),(IKIND_Gun,4,6),(IKIND_Gun,1,9),
		(IKIND_Gun,1,0),(IKIND_Gun,9,10),(IKIND_Gun,3,10),(IKIND_Gun,5,5),(IKIND_Gun,9,3),
		(IKIND_Gun,11,10),(IKIND_Gun,12,10),(IKIND_Gun,13,8),(IKIND_Gun,14,8),(TTYPE_AdvGuns,-1,-1)	),

		{BASIC WEAPONS}
	(	(IKIND_Wep,1,0),(IKIND_Wep,2,0),(IKIND_Wep,3,0),(IKIND_Wep,4,0),(IKIND_Wep,1,1),
		(IKIND_Wep,6,1),(IKIND_Wep,13,1),(IKIND_Wep,8,1),(IKIND_Wep,1,1),(IKIND_Wep,6,1),
		(IKIND_Wep,8,1),(IKIND_Wep,9,1),(IKIND_Wep,14,1),(IKIND_Wep,3,1),(IKIND_Wep,4,1),
		(IKIND_Wep,1,1),(IKIND_Wep,15,1),(IKIND_Wep,3,1),(IKIND_Wep,4,1),(IKIND_Wep,6,1),
		(IKIND_Wep,6,1),(IKIND_Wep,1,1),(IKIND_Wep,8,1),(IKIND_Wep,3,1),(TTYPE_AdvWeps,-1,-1)	),

		{CIVILIAN CLOTHING}
	(	(IKIND_Armor,1,1),(IKIND_Armor,1,1),(IKIND_Armor,1,1),(IKIND_Armor,1,1),(IKIND_Armor,1,1),
		(IKIND_Armor,2,1),(IKIND_Armor,4,1),(IKIND_Armor,2,1),(IKIND_Shoe,2,1),(IKIND_Cap,1,1),
		(IKIND_Armor,6,1),(IKIND_Armor,6,1),(IKIND_Armor,6,1),(IKIND_Armor,6,1),(IKIND_Armor,1,1),
		(IKIND_Cap,1,1),(IKIND_Cap,2,1),(IKIND_Glove,1,1),(IKIND_Glove,1,1),(IKIND_Shoe,1,1),
		(IKIND_Shoe,2,1),(IKIND_Shoe,3,1),(IKIND_Shoe,4,1),(TTYPE_AdvClothes,-1,-1),(TTYPE_AdvClothes,-1,-1)	),

		{COMMON 5mm AMMUNITION}
	(	(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1001,25),
		(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1101,25),(IKIND_Ammo,1001,25),
		(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1,25),(IKIND_Ammo,1201,25),(IKIND_Ammo,1001,25),
		(IKIND_Ammo,301,25),(IKIND_Ammo,301,25),(IKIND_Ammo,301,25),(IKIND_Ammo,301,25),(IKIND_Ammo,301,25),
		(IKIND_Ammo,601,25),(IKIND_Ammo,901,25),(IKIND_Ammo,801,25),(IKIND_Ammo,801,25),(TTYPE_UC5mm,-1,0)	),

		{COMMON 8mm AMMUNITION}
	(	(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,1102,17),(IKIND_Ammo,1002,17),
		(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,1102,17),(IKIND_Ammo,1002,17),
		(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,2,17),(IKIND_Ammo,1202,17),(IKIND_Ammo,1002,17),
		(IKIND_Ammo,902,17),(IKIND_Ammo,302,17),(IKIND_Ammo,302,17),(IKIND_Ammo,802,17),(IKIND_Ammo,602,17),
		(IKIND_Ammo,802,17),(IKIND_Ammo,802,17),(IKIND_Ammo,302,17),(IKIND_Ammo,802,17),(TTYPE_UC8mm,-1,0)	),

		{COMMON 12mm AMMUNITION}
	(	(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,1003,15),
		(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,1003,15),
		(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,1203,15),
		(IKIND_Ammo,3,15),(IKIND_Ammo,103,15),(IKIND_Ammo,1403,15),(IKIND_Ammo,603,15),(IKIND_Ammo,903,15),
		(IKIND_Ammo,303,15),(IKIND_Ammo,603,15),(IKIND_Ammo,903,15),(TTYPE_UC12mm,-1,0),(TTYPE_UC12mm,-1,0)	),

		{COMMON 25mm AMMUNITION}
	(	(IKIND_Ammo,4,30),(IKIND_Ammo,104,20),(IKIND_Ammo,304,10),(IKIND_Ammo,104,10),(IKIND_Ammo,1004,10),
		(IKIND_Ammo,4,20),(IKIND_Ammo,104,20),(IKIND_Ammo,604,10),(IKIND_Ammo,104,10),(IKIND_Ammo,1104,10),
		(IKIND_Ammo,4,20),(IKIND_Ammo,104,10),(IKIND_Ammo,404,10),(IKIND_Ammo,1504,10),(IKIND_Ammo,1204,10),
		(IKIND_Ammo,4,10),(IKIND_Ammo,104,10),(IKIND_Ammo,704,10),(IKIND_Ammo,4,10),(IKIND_Ammo,1204,10),
		(IKIND_Ammo,4,10),(IKIND_Ammo,1404,50),(IKIND_Ammo,904,10),(IKIND_Ammo,4,10),(IKIND_Ammo,1204,10)	),

		{COMMON GRENADES}
	(	(IKIND_Grenade,1,9),(IKIND_Grenade,2,5),(IKIND_Grenade,3,2),(IKIND_Grenade,3,1),(IKIND_Grenade,12,3),
		(IKIND_Grenade,1,5),(IKIND_Grenade,2,3),(IKIND_Grenade,4,2),(IKIND_Grenade,4,1),(IKIND_Grenade,12,9),
		(IKIND_Grenade,1,3),(IKIND_Grenade,2,3),(IKIND_Grenade,5,2),(IKIND_Grenade,5,1),(IKIND_Grenade,12,10),
		(IKIND_Grenade,1,3),(IKIND_Grenade,2,3),(IKIND_Grenade,6,3),(IKIND_Grenade,6,3),(IKIND_Grenade,11,3),
		(IKIND_Grenade,1,3),(IKIND_Grenade,2,3),(IKIND_Grenade,1,3),(IKIND_Grenade,7,3),(IKIND_Grenade,9,1)	),

		{UNCOMMON 5mm AMMUNITION}
	(	(IKIND_Ammo,201,20),(IKIND_Ammo,201,20),(IKIND_Ammo,401,20),(IKIND_Ammo,801,20),(IKIND_Ammo,701,20),
		(IKIND_Ammo,201,20),(IKIND_Ammo,201,20),(IKIND_Ammo,401,20),(IKIND_Ammo,801,20),(IKIND_Ammo,701,20),
		(IKIND_Ammo,201,20),(IKIND_Ammo,201,20),(IKIND_Ammo,401,20),(IKIND_Ammo,801,20),(IKIND_Ammo,301,20),
		(IKIND_Ammo,201,20),(IKIND_Ammo,1201,20),(IKIND_Ammo,401,20),(IKIND_Ammo,801,20),(IKIND_Ammo,301,20),
		(IKIND_Ammo,201,20),(IKIND_Ammo,501,20),(IKIND_Ammo,401,20),(IKIND_Ammo,1501,20),(IKIND_Ammo,301,20)	),

		{UNCOMMON 8mm AMMUNITION}
	(	(IKIND_Ammo,202,12),(IKIND_Ammo,402,12),(IKIND_Ammo,402,12),(IKIND_Ammo,802,12),(IKIND_Ammo,702,12),
		(IKIND_Ammo,202,12),(IKIND_Ammo,402,12),(IKIND_Ammo,402,12),(IKIND_Ammo,802,12),(IKIND_Ammo,702,12),
		(IKIND_Ammo,202,12),(IKIND_Ammo,402,12),(IKIND_Ammo,402,12),(IKIND_Ammo,802,12),(IKIND_Ammo,702,12),
		(IKIND_Ammo,1202,12),(IKIND_Ammo,402,12),(IKIND_Ammo,502,12),(IKIND_Ammo,802,12),(IKIND_Ammo,302,12),
		(IKIND_Ammo,1202,12),(IKIND_Ammo,1202,12),(IKIND_Ammo,502,12),(IKIND_Ammo,802,12),(IKIND_Ammo,302,12)	),

		{UNCOMMON 12mm AMMUNITION}
	(	(IKIND_Ammo,403,12),(IKIND_Ammo,503,12),(IKIND_Ammo,303,12),(IKIND_Ammo,303,12),(IKIND_Ammo,703,12),
		(IKIND_Ammo,403,12),(IKIND_Ammo,503,12),(IKIND_Ammo,303,12),(IKIND_Ammo,303,12),(IKIND_Ammo,703,12),
		(IKIND_Ammo,1203,12),(IKIND_Ammo,503,12),(IKIND_Ammo,403,12),(IKIND_Ammo,103,12),(IKIND_Ammo,703,12),
		(IKIND_Ammo,1203,12),(IKIND_Ammo,503,12),(IKIND_Ammo,403,12),(IKIND_Ammo,103,12),(IKIND_Ammo,703,12),
		(IKIND_Ammo,1203,12),(IKIND_Ammo,503,12),(IKIND_Ammo,303,12),(IKIND_Ammo,1503,12),(IKIND_Ammo,703,12)	),

		{ ADVANCED GUNS }
	(	(IKIND_Gun,7,5),(IKIND_Gun,8,20),(IKIND_Gun,10,20),(IKIND_Gun,13,8),(IKIND_Gun,15,10),
		(IKIND_Gun,7,5),(IKIND_Gun,8,20),(IKIND_Gun,10,20),(IKIND_Gun,13,8),(IKIND_Gun,15,10),
		(IKIND_Gun,7,5),(IKIND_Gun,8,20),(IKIND_Gun,10,20),(IKIND_Gun,13,8),(IKIND_Gun,15,10),
		(IKIND_Gun,7,5),(IKIND_Gun,8,20),(IKIND_Gun,10,20),(IKIND_Gun,13,8),(IKIND_Gun,15,10),
		(IKIND_Gun,7,5),(IKIND_Gun,8,20),(IKIND_Gun,10,20),(IKIND_Gun,13,8),(IKIND_Gun,15,10) ),

		{ ADVANCED WEAPONS }
	(	(IKIND_Wep,11,1),(IKIND_Wep,12,1),(IKIND_Wep,7,1),(IKIND_Wep,9,1),(IKIND_Wep,10,1),
		(IKIND_Wep,11,1),(IKIND_Wep,12,1),(IKIND_Wep,7,1),(IKIND_Wep,9,1),(IKIND_Wep,10,1),
		(IKIND_Wep,11,1),(IKIND_Wep,12,1),(IKIND_Wep,7,1),(IKIND_Wep,9,1),(IKIND_Wep,10,1),
		(IKIND_Wep,11,1),(IKIND_Wep,12,1),(IKIND_Wep,7,1),(IKIND_Wep,9,1),(IKIND_Wep,10,1),
		(IKIND_Grenade,9,3),(IKIND_Wep,12,1),(IKIND_Wep,7,1),(IKIND_Wep,9,1),(IKIND_Wep,10,1) ),

		{ ADVANCED CLOTHING }
	(	(IKIND_Armor,3,1),(IKIND_Armor,8,1),(IKIND_Armor,9,1),(IKIND_Armor,10,1),(IKIND_Armor,10,1),
		(IKIND_Glove,2,1),(IKIND_Armor,3,1),(IKIND_Armor,3,1),(IKIND_Armor,3,1),(IKIND_Armor,11,1),
		(IKIND_Glove,2,1),(IKIND_Glove,2,1),(IKIND_Glove,3,1),(IKIND_Shoe,1,1),(IKIND_Shoe,5,1),
		(IKIND_Cap,1,1),(IKIND_Cap,3,1),(IKIND_Cap,3,1),(IKIND_Cap,3,1),(IKIND_Cap,6,1),
		(IKIND_Glove,2,1),(IKIND_Armor,3,1),(IKIND_Cap,7,1),(IKIND_Shoe,6,1),(IKIND_Glove,4,1) )

	);

Procedure AttemptToIdentify( SC: ScenarioPtr; I: DCItemPtr );
Function GenerateItem(SC: ScenarioPtr; TT: Integer): DCItemPtr;
Procedure WanderingCritters(SC: ScenarioPtr);



implementation

Function IDTarget( I: DCItemPtr ): Integer;
	{ Examine item I and return the difficulcy number needed to identify it. }
var
	it: Integer;
begin
	case I^.ikind of
		IKIND_Gun,IKIND_Wep: it := 12;
		IKIND_Cap,IKIND_Armor,IKIND_Glove,IKIND_Shoe: it := 9;
		IKIND_Food:	begin
					{ Pills are notoriously difficult to ID. }
					if CFood[i^.icode].fk = 2 then it := 16
					else it := 5;
				end;
		IKIND_Ammo,IKIND_Grenade: it := 7;
	else it := 10
	end;

	IDTarget := it;
end;

Procedure AttemptToIdentify( SC: ScenarioPtr; I: DCItemPtr );
	{ The PC will try to figure out what this item is. }
begin
	if SC^.PC <> Nil then begin
		{ The PC must make a tech skill roll against the item's }
		{ difficulcy number, as calculated above. }
		I^.ID := RollStep( PCIDSkill( SC^.PC ) ) >= IDTarget( I );
	end else I^.ID := False;
end;

Function GenerateItem(SC: ScenarioPtr; TT: Integer): DCItemPtr;
	{Generate a random item from chart TT.}
	{ The ScenarioPtr is used for the PC's tech skill, to see if items }
	{ start out identified or not. }
var
	i: DCItemPtr;
	r: Integer;
begin
	{Decide which chart entry will be generated.}
	R := Random(NumTChance)+1;

	{If the ICode listed in -1, jump instead to a different}
	{item list, as indicated by the IKind field. Normally}
	{item lists can only access item lists which occur after}
	{them in the series; a check will be performed here to make}
	{sure the procedure can't get stuck in an infinite loop.}
	if (TTChart[TT,R,2] = -1) and (TTChart[TT,R,1] > TT) then begin
		i := GenerateItem( SC , TTChart[TT,R,1] );

	end else if TTChart[TT,R,2] <> -1 then begin
		{Allocate the item.}
		i := NewDCItem;

		if I <> Nil then begin
			I^.ikind := TTChart[TT,R,1];
			I^.icode := TTChart[TT,R,2];
			if TTChart[TT,R,3] = 0 then i^.charge := 0
			else i^.charge := Random(TTChart[TT,R,3]) + 1;
		end;

	end else begin
		{There's apparently an error in our random chart,}
		{with one treasure list trying to access an earlier}
		{one or somesuch. Let's make sure the error is noticed.}
		{Drop 999 bananas.}
		i := NewDCItem;

		if I = Nil then begin
			I^.ikind := IKIND_Food;
			I^.icode := 6;
			i^.charge := 999;
		end;
	end;

	{ Finally, see whether or not the item is identified by the PC. }
	AttemptToIdentify( SC , I );

	GenerateItem := i;
end;

Procedure WanderingCritters(SC: ScenarioPtr);
	{Add some random monsters to the map, if appropriate.}
	Function GoodSpot(X,Y: Integer): Boolean;
		{Check spot X,Y and see if this is a good place to}
		{stick a new monster. A good spot is a space, not}
		{in the player's LOS, with no other monster currently}
		{standing in it.}
	var
		it: Boolean;
	begin
		if TerrPass[sc^.gb^.map[X,Y].terr] < 1 then it := False
		else if TileLOS(SC^.gb^.pov,X,Y) then it := False
		else if SC^.gb^.mog[X,Y] then it := False
		else it := True;
		GoodSpot := it;
	end;
var
	Gen,Chart,E,N,T,X0,Y0,X,Y,tries: Integer;
	C: CritterPtr;
begin
	{Decide how many random generations we're gonna perform.}
	N := NumberOfCritters(SC^.CList);
	if N >= MaxMonsters then Exit;
	if NumberOfCritters(SC^.CList) < (MaxMonsters div 2) then Gen := CHART_NumGenerations + Random( CHART_NumGenerations )
	else Gen := Random( CHART_NumGenerations )+1;

	While Gen > 0 do begin
		Dec(Gen);

		{Check to see if there is any room for more monsters.}
		{The more monsters we have, the less likely we are to add more.}
		if NumberOfCritters(SC^.CList) < (Random(MaxMonsters div 2)+(MaxMonsters div 2)+1) then begin
			{Roll on the random monster chart.}
			{ First decide what chart to use. Either pick a chart }
			{ based on PC level, or use the "signature chart" for }
			{ the currrent location. }
			if Random( 3 ) <> 1 then begin
				{ Pick chart based on level. }
				Chart := (Random(SC^.PC^.Lvl) div 3) + 1;
			end else begin
				{ The Signature Charts start at 1 and go down. }
				Chart := 2 - SC^.Loc_Number;
			end;

			{ Range check the selected chart... }
			if Chart > NumWChart then Chart := NumWChart
			else if Chart < LowWChart then Chart := LowWChart;

			{ Roll the Entry and Number. }
			E := Random(NumWCT)+1;
			N := Random(WanderChart[Chart,E,2]) + 1;

			{Decide upon a nice place to put our critters.}
			{Select an origin spot - the generated critters will be centered here.}
			X0 := Random(XMax)+1;
			Y0 := Random(YMax)+1;

			{We're gonna give up if we can't find an appropriate}
			{tile after 10,000 tries.}
			tries := 0;
			while (TerrPass[sc^.gb^.map[X0,Y0].terr] < 1) and (tries < 10000) do begin
				Inc(X0);
				Inc(tries);
				if X0 > XMax then begin
					Inc(Y0);
					X0 := 1;
				end;
				if Y0 > YMax then Y0 := 1;
			end;

			for t := 1 to N do begin
				{Starting position for the swarm is the origin determined earlier.}
				X := X0;
				Y := Y0;

				{Check to see if this is an appropriate spot.}
				tries := 0;
				while (tries < 10) and not GoodSpot(X,Y) do begin
					Inc(tries);
					X := X + Random(3) - Random(3);
					if X < 1 then X := 1
					else if X > XMax then X := XMax;
					Y := Y + Random(3) - Random(3);
					if Y < 1 then Y := 1
					else if Y > YMax then Y := YMax;
				end;

				{If we have a good spot, render the monster.}
				{Otherwise, just forget it.}
				if GoodSpot(X,Y) then begin
					C := AddCritter(SC^.CList,SC^.gb,WanderChart[Chart,E,1],X,Y);

					{Check to see whether the monster is equipped with a weapon.}
					if (C <> Nil) and (MonMan[C^.Crit].EType > 0) and (Random(100) < MonMan[C^.Crit].EChance) then begin
						C^.Eqp := GenerateItem(SC,MonMan[C^.Crit].EType);
					end;
				end;
			end;
		end;
	end;
end;


end.
