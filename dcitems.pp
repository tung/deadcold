unit DCItems;
	{This unit handles items. Duh.}
	{It also handles items on the map display. Big problem.}

interface

uses crt,texutil,TexModel,TexMaps,statusfx,spells;

Type
	dcitem = Record
		ikind: Integer;		{Type of item.}
		icode: Integer;		{Specific kind.}
		state: Integer;		{The state of the item.}
		charge: Integer;	{This field tells how many shots/uses a device has left.}
		ID: Boolean;		{Whether or not the item has been identified.}
		next: ^dcitem;
	end;
	dcitemptr = ^dcitem;

	IGrid = Array [1..Xmax,1..YMax] of dcitemptr;
	IGridPtr = ^IGrid;

	MissileDesc = Record		{Data on a missile weapon.}
		name: String;
		caliber: Integer;	{What kind of ammo does it take?}
		magazine: Integer;	{How many shots can it hold?}
		ACC: Integer;		{Weapon Accuracy}
		DMG: Integer;		{Damage Step}
		RNG: Integer;		{Range Band}
		CCM: Integer;		{Close Combat Modifier}
		ATT: String;		{Attack Attributes.}
		Desc: PChar;
	end;

	WeaponDesc = Record		{Data on a melee weapon.}
		name: String;
		Stat: Byte;		{What stat does it use to target?}
		ACC: Integer;		{Weapon Accuracy}
		DMG: Integer;		{Damage Step}
		ATT: String;		{Attack Attributes.}
		Desc: PChar;
	end;

	ArmorDesc = Record		{Data on body armor.}
		name: String;
		PV: Integer;		{Protection Value}
		Sealed: Boolean;	{ Is it atmospherically sealed? }
		Desc: PChar;
	end;

	FoodDesc = Record
		name: String;
		fk: byte;		{Food kind. Rations, Pills, etc}
		carbs: byte;
		fx: SpellDescPtr;
		Desc: PChar;
	end;

	SpecAmmoDesc = Record
		name: String;
		DMG,ACC: SmallInt;	{Damage & Accuracy modifiers}
		ATT: String;		{Attack Attributes. Come before gun attributes, so suprecede them in the event of a conflict.}
		Desc: PChar;
	end;

	GrenadeDesc = Record
		name: String;
		SayGrenade: Boolean;	{ Say "Grenade" in the name? }
		DMG: SmallInt;
		RNG: SmallInt;	{This does not affect the actual range the grenade can be thrown, but does affect its accuracy.}
		ATT: String;
		desc: PChar;
	end;

	MiscDesc = Record
		name: String;
		Desc: PChar;
	end;

Const
	{These constants define the different types of item.}
	{ - positive KINDs can be equipped.}
	{ - negative KINDs can't be equipped.}
	IKIND_Electronics = -6;
	IKIND_Book = -5;
	IKIND_Grenade = -4;
	IKIND_KeyItem = -3;
	IKIND_Ammo = -2;
	IKIND_Food = -1;
	IKIND_Gun = 1;
	IKIND_Wep = 2;
	IKIND_Cap = 3;
	IKIND_Armor = 4;
	IKIND_Glove = 5;
	IKIND_Shoe = 6;


	NumGuns = 15;
	NumCal = 6;
	CAL_5mm = 1;
	CAL_8mm = 2;
	CAL_12mm = 3;
	CAL_25mm = 4;
	CAL_Energy = 5;
	CAL_Napalm = 6;
	CGuns: Array [1..NumGuns] of MissileDesc = (
		(	Name: 'Sidekick Pistol';
			caliber: CAL_5mm; magazine: 12;
			ACC: 2; DMG: 4; RNG: 3; CCM: 0;
			ATT: '';
			Desc: 'A light pistol, favored by merchants and navigators. It is very accurate at short range, but not too powerful.';	),
		(	Name: 'Long Rifle';
			caliber: CAL_5mm; magazine: 30;
			ACC: 1; DMG: 5; RNG: 12; CCM: -1;
			ATT: '';
			Desc: 'This rifle has excellent range and accuracy, but lacks power. It is primarily used for hunting.';	),
		(	Name: 'Assault Rifle';
			caliber: CAL_8mm; magazine: 24;
			ACC: 0; DMG: 8; RNG: 6; CCM: -1;
			ATT: '';
			Desc: 'This is the main combat weapon of the Republic Marine Corps. It is designed for short range firefights.';	),
		(	Name: 'Headhunter Pistol';
			caliber: CAL_8mm; magazine: 10;
			ACC: 0; DMG: 9; RNG: 3; CCM: 0;
			ATT: '';
			Desc: 'A heavy pistol. This is the favorite sidearm of most security forces in the republic.';),
		(	Name: 'Khan Heavy Pistol';
			caliber: CAL_12mm; magazine: 5;
			ACC: -1; DMG: 12; RNG: 3; CCM: 0;
			ATT: '';
			Desc: 'A sidearm capable of taking down a heavily armored target in a single shot. Designed as a backup support weapon for the marines.';),

		(	Name: 'Sonic Pistol';
			caliber: CAL_Energy; magazine: 100;
			ACC: 0; DMG: 5; RNG: 2; CCM: 0;
			ATT: '';
			Desc: 'This weapon fires a concentrated burst of sound.';			),
		(	Name: 'SK-3 Burner';
			caliber: CAL_Napalm; magazine: 20;
			ACC: 1; DMG: 5; RNG: 8; CCM: -2;
			ATT: AA_LineAttack+AA_ElemFire;
			Desc: 'This flamethrower is often used to clear vacuum worms and fungal infestations from the surface of spaceships.';),
		(	Name: 'Flame Pistol';
			caliber: CAL_Napalm; magazine: 50;
			ACC: 2; DMG: 3; RNG: 4; CCM: 0;
			ATT: AA_LineAttack+AA_ElemFire;
			Desc: 'A light flame weapon.';			),
		(	Name: 'Shotgun';
			caliber: CAL_12mm; magazine: 16;
			ACC: 1; DMG: 6; RNG: 5; CCM: -1;
			ATT: '';
			Desc: 'Primitive but effective. Shotguns are durable, can use a wide variety of ammunition types, and cause enough damage to seriously threaten an armored foe.';),
		(	Name: 'IDF Sonic Rifle';
			caliber: CAL_Energy; magazine: 20;
			ACC: 0; DMG: 9; RNG: 5; CCM: -1;
			ATT: '';
			Desc: 'The sound waves produced by this weapon are comprable in effect to a bullet.';),

		(	Name: 'ICE Rifle';
			caliber: CAL_8mm; magazine: 28;
			ACC: 0; DMG: 10; RNG: 6; CCM: -1;
			ATT: AA_ArmorPiercing + AA_ElemCold;
			Desc: 'The bullets for this rifle are kept in a supercooled state. This improves the efficeincy of the magnetic accelerator, and allows the weapon to shatter armor.';),
		(	Name: 'ICE Carbine';
			caliber: CAL_8mm; magazine: 20;
			ACC: 0; DMG: 7; RNG: 4; CCM: 0;
			ATT: AA_ArmorPiercing + AA_ElemCold;
			Desc: 'This is a smaller version of the ICE Rifle. The bullets for this gun are kept in a supercooled state. This improves the efficeincy of the magnetic accelerator.';),
		(	Name: 'Cone Rifle';
			caliber: CAL_25mm; magazine: 9;
			ACC: 0; DMG: 15; RNG: 8; CCM: -3;
			ATT: '';
			Desc: 'A large, shoulder mounted magnetic accelerator which fires heavy 25mm shells.';	),
		(	Name: 'Sawn-Off Shotgun';
			caliber: CAL_12mm; magazine: 16;
			ACC: 1; DMG: 6; RNG: 3; CCM: 1;
			ATT: '';
			Desc: 'Primitive but effective. This shotgun has been modified for close assault.';),
		(	Name: 'Thumper';
			caliber: CAL_25mm; magazine: 20;
			ACC: -1; DMG: 13; RNG: 4; CCM: -1;
			ATT: '';
			Desc: 'A high caliber heavy damage support weapon designed for tunnel fighting.';)
	);


	NumWep = 16;
	CWep: Array [1..NumWep] of WeaponDesc = (
		(	Name: 'Knife';
			Stat: 4;
			ACC: 1; DMG: 1;
			ATT: '';
			Desc: 'Though intended as a tool, a knife can make a passable weapon for self defense.';),
		(	Name: 'Staff';
			Stat: 4;
			ACC: 0; DMG: 2;
			ATT: '';
			Desc: 'An intricately carved wooden staff.';),
		(	Name: 'Cutlass';
			Stat: 4;
			ACC: 1; DMG: 4;
			ATT: '';
			Desc: 'A short sword with a slightly curved blade.';),
		(	Name: 'Boarding Axe';
			Stat: 1;
			ACC: -1; DMG: 4;
			ATT: AA_ArmorPiercing;
			Desc: 'A collapsable plasteel axe intended for use during ship to ship boarding actions.';),
		(	Name: 'Katana';
			Stat: 4;
			ACC: 2; DMG: 8;
			ATT: AA_ElemHoly;
			Desc: 'An old and treasured family heirloom, created by a master weaponsmith in days long ago.';),

		(	Name: 'Survival Knife';
			Stat: 4;
			ACC: 1; DMG: 2;
			ATT: '';
			Desc: 'A large serrated knife.';),
		(	Name: 'Vibro Maul';
			Stat: 1;
			ACC: -1; DMG: 14;
			ATT: AA_StatusPar+AA_HitRoll+'03';
			Desc: 'The head of this baton is surrounded by a disruptive sonic field.';),
		(	Name: 'Steel Pipe';
			Stat: 1;
			ACC: -1; DMG: 3;
			ATT: '';
			Desc: 'It''s just a length of steel pipe, but it might make a decent club if you should need to defend yourself.';),
		(	Name: 'Silver Dagger';
			Stat: 4;
			ACC: 1; DMG: 3;
			ATT: AA_ElemHoly;
			Desc: 'An ornamental dagger, crafted in silver and covered with jewels.';),
		(	Name: 'Arc Mattock';
			Stat: 1;
			ACC: 0; DMG: 6;
			ATT: AA_ElemLit;
			Desc: 'This is a massive hammer with a built in electrical discharger. It''s used by station maintenance for repair work.';),

		(	Name: 'Chainsaw';
			Stat: 1;
			ACC: -2; DMG: 12;
			ATT: '';
			Desc: 'An industrial cutting tool. It can probably be used for cutting other things.'),
		(	Name: 'Chainsword';
			Stat: 4;
			ACC: 0; DMG: 9;
			ATT: '';
			Desc: 'This sword features a serrated microfusion powered cutting chain.'),
		(	Name: 'Ice Pick';
			Stat: 4;
			ACC: 0; DMG: 2;
			ATT: AA_Slaying + '07';	{ Slays cold-based creatures. }
			Desc: 'A metal spike used for crushing ice.' ),
		(	Name: 'Letter Opener';
			Stat: 4;
			ACC: 2; DMG: 1;
			ATT: '';
			Desc: 'A brass knife made for cutting open envelopes.' ),
		(	Name: 'Spanner';
			Stat: 1;
			ACC: 0; DMG: 2;
			ATT: '';
			Desc: 'A steel wrench.';),

		(	Name: 'Taltuo Dire Sword';
			Stat: 4;
			ACC: 0; DMG: 16;
			ATT: AA_ElemHoly;
			Desc: 'This massive blue greatsword of unknown composition was recovered from an ancient grave site on the moon of Taltuo.';)

	);

	NumFood = 39;
	NumFSpell = 12;
	FSpellMan: Array [1..NumFSpell] of SpellDesc = (
		(	eff: EFF_Healing;
			Step: 12;
			C: LightGreen; ATT: ''			),
		(	eff: EFF_Residual;
			Step: SEF_Regeneration; P1: 9;
			C: LightGreen; ATT: ''			),
		(	eff: EFF_Residual;
			Step: SEF_VisionBonus; P1: 6;
			C: Yellow; ATT: ''			),
		(	eff: EFF_Residual;
			Step: SEF_Poison; P1: 5;
			C: Yellow; ATT: ''			),
		(	eff: EFF_CureStatus;
			Step: SEF_Poison;
			C: Yellow; ATT: ''			),

		(	eff: EFF_Residual;
			Step: SEF_Paralysis; P1: 3;
			C: Magenta; ATT: ''			),
		(	eff: EFF_Residual;
			Step: SEF_Sleep; P1: 5;
			C: White; ATT: ''			),
		(	eff: EFF_Residual;
			Step: -6; P1: 36;
			C: White; ATT: ''			),
		{ Effect 9 - Boost Dexterity }
		(	eff: EFF_Residual;
			Step: SEF_BoostBase + 4; P1: 10;
			C: LightGreen; ATT: ''			),
		(	eff: EFF_Residual;
			Step: SEF_SpeedBonus; P1: 7;
			C: LightGreen; ATT: ''			),

		{ Effect 11 - Boost Strength }
		(	eff: EFF_Residual;
			Step: SEF_BoostBase + 1; P1: 25;
			C: LightGreen; ATT: ''			),
		{ Effect 11 - Boost Speed }
		(	eff: EFF_Residual;
			Step: SEF_BoostBase + 3; P1: 9;
			C: LightGreen; ATT: ''			)
	);
	FKName: Array [1..2] of string = (
		'Rations','Pill'
	);
	CFood: Array [1..NumFood] of FoodDesc = (
		(	Name: 'NutriSnax'; fk: 0;
			carbs: 12; fx: Nil;
			Desc: 'A bag of NutriSnax chips. According to the label, this snack is supposed to provide a balanced diet for most humanoid life forms.';),
		(	Name: 'Hard Biscuit'; fk: 0;
			carbs: 5; fx: Nil;
			Desc: 'Often used as survival rations on spaceships. They last forever, provide enough nutrition to keep someone alive, and don''t take up too much space or weight.';),
		(	Name: 'Meat Jerky'; fk: 0;
			carbs: 5; fx: Nil;
			Desc: 'Dessicated meat from some kind of animal, or a synthetic approximation thereof. Often kept as emergency rations since it will remain edible indefinitely.';),
		(	Name: 'Sausage'; fk: 0;
			carbs: 8; fx: Nil;
			Desc: 'A sausage, supposedly created from the meat of some kind of animal.'),
		(	Name: 'Trail Mix'; fk: 0;
			carbs: 10; fx: Nil;
			Desc: 'A mixture of dried fruits, nuts, and other healthy foods in a convenient serving-size packet.'),

		(	Name: 'Banana'; fk: 0;
			carbs: 8; fx: Nil;
			Desc: 'Fresh fruit is a healthy and delicious snack.'),
		(	Name: 'Canned Ravioli'; fk: 0;
			carbs: 22; fx: Nil;
			Desc: 'A self heating can of ravioli.'),
		(	Name: 'Canned Cream Soup'; fk: 0;
			carbs: 19; fx: Nil;
			Desc: 'A self heating can of cream soup.'),
		(	Name: 'Meat and Starchlog'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';),
		(	Name: 'Irish Stew'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),

		(	Name: 'Lentilsoy Steak'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),
		(	Name: 'Cheesy Noodles'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),
		(	Name: 'Lasagne'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),
		(	Name: 'Curry Rice'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),
		(	Name: 'Bokum Rice'; fk: 1;
			carbs: 50; fx: Nil;
			Desc: 'These rations represent the most palatable form of portable nutrition that the modern military has to offer. Expected shelf life is five thousand years.';			),

		(	Name: 'Crunchy Critters'; fk: 0;
			carbs: 15; fx: Nil;
			Desc: 'The bag appears to be full of some kind of arthropod, dipped in batter and deep fried.';			),
		(	Name: 'Tubelunch Roast Chicken'; fk: 0;
			carbs: 35; fx: Nil;
			Desc: 'A complete meal, in tube form. Portable nutrition for today''s space traveller.';),
		(	Name: 'Tubelunch Salisbury Steak'; fk: 0;
			carbs: 35; fx: Nil;
			Desc: 'A complete meal, in tube form. Portable nutrition for today''s space traveller.';			),
		(	Name: 'Tubelunch Yams'; fk: 0;
			carbs: 42; fx: Nil;
			Desc: 'A complete meal, in tube form. Portable nutrition for today''s space traveller. Yams are the best product in the Tubelunch range.';			),
		(	Name: 'Dead Rat'; fk: 0;
			carbs: 10; fx: Nil;
			Desc: 'A dead rodent.';),

		(	Name: 'Meal Wafer'; fk: 0;
			carbs: 30; fx: Nil;
			Desc: 'A light, octagonal wafer which contains all the nutrients required for life in an easily digestable form.';),
		(	Name: 'Apple'; fk: 0;
			carbs: 8; fx: Nil;
			Desc: 'Fresh fruit is a healthy and delicious snack.';			),
		(	Name: 'Orange'; fk: 0;
			carbs: 8; fx: Nil;
			Desc: 'Fresh fruit is a healthy and delicious snack.';			),
		(	Name: 'Dietary Supplement'; fk: 2;
			carbs: 20; fx: Nil;
			Desc: 'This pill contains all the nutrients required for human life.';),
		(	Name: 'Trauma Fix'; fk: 2;
			carbs: 1; fx: @FSpellMan[1];
			Desc: 'This drug is a multiaction stabilizer for physical injury. Use it if you get hurt.';),

		(	Name: 'Speed Heal'; fk: 2;
			carbs: 1; fx: @FSpellMan[2];
			Desc: 'This drug works by boosting a patient''s natural regenerative processes. Use it if you expect to get hurt.';),
		(	Name: 'Retinal Booster'; fk: 2;
			carbs: 1; fx: @FSpellMan[3];
			Desc: 'These pills can increase a person''s field of vision for a short time.';),
		(	Name: 'Placebo'; fk: 2;
			carbs: 3; fx: Nil;
			Desc: 'Sugar pills are often used in double blind scientific research. Placebos look and taste like real medicene, but have no effect upon the body.';),
		(	Name: 'Rat Poison'; fk: 2;
			carbs: 1; fx: @FSpellMan[4];
			Desc: 'A tablet of cyanide. Better be careful with this.';),
		(	Name: 'Antidote'; fk: 2;
			carbs: 1; fx: @FSpellMan[5];
			Desc: 'Broad spectrum antitoxin. This drug is an effective remedy for most injested or injected poisons.';),

		(	Name: 'Muscle Relaxant'; fk: 2;
			carbs: 1; fx: @FSpellMan[6];
			Desc: 'This is a very powerful medication and should only be taken if prescribed by a doctor.';),
		(	Name: 'Tranquilizer'; fk: 2;
			carbs: 1; fx: @FSpellMan[7];
			Desc: 'A useful drug for people suffering from insomnia. May be habit forming.';),
		(	Name: 'Anti-Nauseant'; fk: 2;
			carbs: 1; fx: @FSpellMan[8];
			Desc: 'This medicene helps to prevent the onset of space-sickness. May cause drowsiness. Effects last six hours.';),
		(	Name: 'Spoiled'; fk: 1;
			carbs: 15; fx: @FSpellMan[4];
			Desc: 'A label on the side claims that these rations should remain edible for five thousand solar years. The thriving colony of green slime growing inside argues otherwise.';),
		(	Name: 'Rancid Sandwich'; fk: 0;
			carbs: 10; fx: @FSpellMan[4];
			Desc: 'This sub sandwich has turned black and is starting to grow hair. You probably shouldn''t eat it.';),

		(	Name: 'Combat Spur'; fk: 2;
			carbs: 1; fx: @FSpellMan[9];
			Desc: 'This drug was initially developed for the military''s "Heavy Damage" program. It temporarily boosts a persons motor reflexes and muscle control.';),
		(	Name: 'Zeno Zip'; fk: 2;
			carbs: 1; fx: @FSpellMan[10];
			Desc: 'Using all natural ingredients, this pill is supposed to improve a persons movement speed by up to 50%.';),
		(	Name: 'Onslaught'; fk: 2;
			carbs: 1; fx: @FSpellMan[11];
			Desc: 'This combat drug allows a person to perform greater feats of strength than would otherwise be possible. It is illegal on most worlds.';),
		(	Name: 'React'; fk: 2;
			carbs: 1; fx: @FSpellMan[12];
			Desc: 'This drug temporarily increases the speed of a persons nervous system.';)

	);

	NumCap = 7;
	CCap: Array [1..NumCap] of ArmorDesc = (
		(	Name: 'Field Cap';
			PV: 1; Sealed: False;
			Desc: 'A visored cap with shock resistant gel pads.';),
		(	Name: 'Vac Helmet';
			PV: 1; Sealed: True;
			Desc: 'A fully enclosed helmet with an incorporated air scrubber.';),
		(	Name: 'Combat Helmet';
			PV: 2; Sealed: False;
			Desc: 'A heavy blast helmet.';			),
		(	Name: 'Iron Mask';
			PV: 3; Sealed: False;
			Desc: 'An iron mask bearing a grim visage.';),
		(	Name: 'Ancestral Helm';
			PV: 2; Sealed: False;
			Desc: 'An ancient master crafted war helm.';	),

		(	Name: 'Starvisor Pilot Helm';
			PV: 2; Sealed: True;
			Desc: 'This full featured space helmet features an LCD monitor which can interface with most starship computers, as well as an emergency air supply to guard against cockpit rupture.' ),
		(	Name: 'Pioneer Space Helmet';
			PV: 3; Sealed: True;
			Desc: 'A heavy work helmet designed for prolonged exposure to vacuum and space dust.' )
	);

	NumArmor = 11;
	CArmor: Array [1..NumArmor] of ArmorDesc = (
		(	Name: 'Clothes';
			PV: 1; Sealed: False;
			Desc: 'A shirt and some pants.';			),
		(	Name: 'Vac Suit';
			PV: 2; Sealed: True;
			Desc: 'A light space suit. It can protect its wearer against hard vacuum.';),
		(	Name: 'Flak Jacket';
			PV: 3; Sealed: False;
			Desc: 'A light armored jacket.';			),
		(	Name: 'Robe';
			PV: 1; Sealed: False;
			Desc: 'A long robe.';),
		(	Name: 'Ancestral Armor';
			PV: 3; Sealed: False;
			Desc: 'An ancient set of ornate armor.';),

		(	Name: 'Dress';
			PV: 1; Sealed: False;
			Desc: 'A stylish dress.';			),
		(	Name: 'Acroweave Kimono';
			PV: 5; Sealed: False;
			Desc: 'A stylish garment woven from the latest armor-class polymer fabrics.';),
		(	Name: 'Tact Hardsuit';
			PV: 4; Sealed: True;
			Desc: 'This suit is constructed from a tough mesh fabric, and is covered in rigid armor plates.';),
		(	Name: 'Acroweave Robes';
			PV: 6; Sealed: False;
			Desc: 'Sturdy robes woven from the latest armor-class polymer fabrics.';),
		(	Name: 'Acroweave Suit';
			PV: 4; Sealed: False;
			Desc: 'A stylish garment woven from the latest armor-class polymer fabrics. Suitable for both work and play.';),

		(	Name: 'Pioneer Spacesuit';
			PV: 4;	Sealed: True;
			Desc: 'An industrial heavy space suit. The Pioneer can withstand prolonged exposure to vacuum and micrometeor abrasion.' )
	);

	NumGlove = 4;
	CGlove: Array [1..NumGlove] of ArmorDesc = (
		(	Name: 'Vac Gloves';
			PV: 1; Sealed: True;
			Desc: 'A pair of thick gloves with sealing cuffs. They are designed to protect a person from vacuum exposure.';),
		(	Name: 'Combat Gauntlets';
			PV: 2; Sealed: False;
			Desc: 'A pair of heavy, armored gloves.';),
		(	Name: 'Sanctified Fist';
			PV: 3; Sealed: True;
			Desc: 'An ornate ceremonial gauntlet.';	),
		(	Name: 'Pioneer Space Gloves';
			PV: 2; Sealed: True;
			Desc: 'A pair of thick gloves with sealing cuffs and integrated tool ports.';)
	);

	NumShoe = 6;
	CShoe: Array [1..NumShoe] of ArmorDesc = (
		(	Name: 'Steel-Toed Boots';
			PV: 1; Sealed: False;
			Desc: 'A pair of steel toed work boots.';			),
		(	Name: 'Shoes';
			PV: 0; Sealed: False;
			Desc: 'A nice pair of simuleather shoes.';),
		(	Name: 'Vac Boots';
			PV: 1; Sealed: True;
			Desc: 'A pair of heavy boots with magnetic soles. They are designed to connect to a vacuum suit.';			),
		(	Name: 'Sandals';
			PV: 0; Sealed: False;
			Desc: 'A simple pair of open topped sandals.';			),
		(	Name: 'Dragon Boots';
			PV: 2; Sealed: False;
			Desc: 'Large ornate spiked boots. The kind a rock star would probably want to be buried in.';	),

		(	Name: 'Pioneer Work Boots';
			PV: 2; Sealed: True;
			Desc: 'A pair of magnetic soled space boots. The Pioneer range of vac clothes is favored by most external repair technicians.';)

	);

	{Ammunition is handled differently from the other item types.}
	{The ICode for an ammo item is in two parts. ICode mod 100}
	{gives the caliber of the bullet; this tells what kind of}
	{gun it will fit. ICode div 100 gives the special attribute}
	{of the ammo.}
	AmmoName: Array [1..NumCal] of String = (
		'5mm Bullet','8mm Bullet','12-gauge Shell','25mm Shell',
		'Energy Cell','Fuel Cannister'
	);
	NumSpecAmmo = 15;
	CSpecAmmo: Array [0..NumSpecAmmo] of SpecAmmoDesc = (
		(	name: 'Normal. If you can read this, there must be a bug.';
			DMG: 0; ACC: 0;
			ATT: '';
			Desc: 'Ammunition.'	),
		(	name: 'Scatter';
			DMG: -1; ACC: 1;
			ATT: AA_LineAttack;
			Desc: 'Wide dispersal fragmentation ammunition.'),
		(	name: 'Hollowpoint';
			DMG: 0; ACC: 0;
			ATT: AA_SlayAlive + AA_ArmorDoubling;
			Desc: 'Antipersonnel hollowpoint ammunition.'),
		(	name: 'Slick';
			DMG: 0; ACC: 0;
			ATT: AA_ArmorPiercing;
			Desc: 'Lubricated coating armor piercing ammunition.'),
		(	name: 'SMRT';
			DMG: 0; ACC: 7;
			ATT: '';
			Desc: 'Sensor Module Remote Targeting ammunition.'),
		(	name: 'Tranq Dart';
			DMG: -10; ACC: 0;
			ATT: AA_StatusSleep+AA_Value+'30'+AA_HitRoll+'25';
			Desc: 'Darts containing a powerful sedative.'),

		(	name: 'Tesla';
			DMG: 0; ACC: 0;
			ATT: AA_ElemLit;
			Desc: 'Electrical discharge anti-mech ammunition.'),
		(	name: 'Scour';
			DMG: 3; ACC: 0;
			ATT: AA_ElemAcid + AA_ArmorPiercing;
			Desc: 'Ammunition containing a highly corrosive molecular solvent.'),
		(	name: 'Flechette';
			DMG: -1; ACC: 0;
			ATT: AA_LineAttack;
			Desc: 'Scatter flechette ammunition.'),
		(	name: 'Incendiary';
			DMG: 1; ACC: 0;
			ATT: AA_ElemFire;
			Desc: 'Exo-Phosphorous based incendiary ammunition.'),
		(	name: 'Practice';
			DMG: -3; ACC: 0;
			ATT: AA_ArmorDoubling;
			Desc: 'Cheap bullets made for firing practice. They won''t do much damage against a real target.'),

		(	name: 'Blank';
			DMG: -25; ACC: -5;
			ATT: AA_ArmorDoubling;
			Desc: 'Empty rounds made for ceremonial salutes.'),
		(	name: 'Rubber';
			DMG: -7; ACC: 1;
			ATT: AA_ArmorDoubling + AA_StatusPar + AA_HitRoll + '01';
			Desc: 'Rubber bullets designed for nonlethal crowd control.'),
		(	name: 'Explosive';
			DMG: 0; ACC: 0;
			ATT: AA_BlastAttack + '01';
			Desc: 'High explosive fragmentation shell rounds.' ),
		(	name: 'Cover';
			DMG: 0; ACC: 2;
			ATT: AA_SmokeAttack + '01' + AA_Value + '03' + AA_Duration + '08';
			Desc: 'Metallic smoke generating defensive rounds.' ),
		(	name: 'Ab-Zero';
			DMG: 1; ACC: 0;
			ATT: AA_BlastAttack + '02' + AA_StatusPar + AA_HitRoll + '02' + AA_Value + '03' + AA_ElemCold;
			Desc: 'Thermally implosive flash-freeze ammunition.';	)
	);

	NumKeyItem = 5;
	KCat: Array [1..NumKeyItem] of MiscDesc = (
		(	name: 'Pass Card';
			Desc: 'A station ID card. The name "Andros Guero" is hand written on the back.';),
		(	name: 'Skull';
			Desc: 'The skull bone of a human being.' ),
		(	name: 'Urn';
			desc: 'An ornate funeral urn. There are ashes inside.'	),
		(	name: 'Shroud';
			desc: 'A burial cloth, now relieved of its occupant.' ),
		(	name: 'Cybernetic Heart';
			desc: 'A replacement heart. The rest of the body has apparently long since decayed away.' )
	);

	NumElectronics = 1;
	ElecCat: Array [1..NumElectronics] of MiscDesc = (
		(	name: 'HandyMap Navigation Unit';
			desc: 'A combination sensor pack and PDA which can help keep track of where you''ve been.' )
	);

	NumBook = 1;
	CBook: Array [1..NumBook] of MiscDesc = (
		(	name: 'Diary';
			Desc: 'An old fashioned pen-and-paper diary.';)
	);

	NumGrn = 12;
	CGrn: Array [1..NumGrn] of GrenadeDesc = (
		(	name: 'Frag';
			SayGrenade: True;
			DMG: 9; Rng: 3;
			ATT: AA_BlastAttack + '01';
			Desc: 'Fragmentation grenade. Scatters shrapnel over a wide area.'; ),
		(	name: 'Shatter';
			SayGrenade: True;
			DMG: 16; Rng: 7;
			ATT: AA_ArmorPiercing + AA_BlastAttack + '00';
			Desc: 'Implosive anti-armor grenade.' ),
		(	name: 'Toxin';
			SayGrenade: True;
			DMG: 3; Rng: 2;
			ATT: AA_BlastAttack + '02' + AA_ElemAcid + AA_StatusPsn + AA_HitRoll + '21' + AA_Value + '09';
			Desc: 'Corrosive gas grenade.'; ),
		(	name: 'Choke';
			SayGrenade: True;
			DMG: 6; Rng: 3;
			ATT: AA_BlastAttack + '02' + AA_StatusSleep + AA_HitRoll + '03' + AA_Value + '09';
			Desc: 'Asphyxiating gas grenade.'; ),
		(	name: 'Haywire';
			SayGrenade: True;
			DMG: 8; Rng: 3;
			ATT: AA_BlastAttack + '01' + AA_ArmorPiercing + AA_ElemLit + AA_SlayMech;
			Desc: 'Electromagnetic pulse anti-mech grenade.'; ),

		(	name: 'Smoke';
			SayGrenade: True;
			DMG: 0; Rng: 3;
			ATT: AA_SmokeAttack + '02' + AA_Value + '03' + AA_Duration + '05';
			Desc: 'Smokescreen grenade.';),
		(	name: 'Forcewall';
			SayGrenade: True;
			DMG: 0; Rng: 3;
			ATT: AA_SmokeAttack + '03' + AA_Value + '00' + AA_Duration + '10';
			Desc: 'Force field generating tactical barrier grenade.';),
		(	name: 'Holy Water';
			SayGrenade: False;
			DMG: 4; Rng: 6;
			ATT: AA_BlastAttack + '00' + AA_ArmorPiercing + AA_ElemHoly + AA_SlayUndead;
			Desc: 'Glass decanter full of holy water.'; ),
		(	name: 'Lost Hope';
			SayGrenade: True;
			DMG: 31; Rng: 2;
			ATT: AA_BlastAttack + '12' + AA_ElemFire;
			Desc: 'Heavy matter, tactical nuclear blast grenade. Also known as a Suicide Stick.'; ),
		(	name: 'Thermal';
			SayGrenade: True;
			DMG: 12; Rng: 3;
			ATT: AA_BlastAttack + '02' + AA_ElemFire;
			Desc: 'High yield controlled range thermal grenade.'; ),

		(	name: 'Flask of Acid';
			SayGrenade: False;
			DMG: 9; Rng: 2;
			ATT: AA_BlastAttack + '01' + AA_ElemAcid;
			Desc: 'A beaker of molecular acid.'; ),
		(	name: 'Molotov Cocktail';
			SayGrenade: False;
			DMG: 7; Rng: 2;
			ATT: AA_BlastAttack + '01' + AA_ElemFire;
			Desc: 'A makeshift grenade, apparently constructed by the station residents to fend off some threat.'; )

	);

Function NewDCItem: DCItemPtr;
Function AddDCItem(var LList: DCItemPtr): DCItemPtr;
Procedure DisposeItemList(var LList: DCItemPtr);
Procedure DelinkDCItem(var IList,I: DCItemPtr);
Procedure RemoveItem(var LList,LMember: DCItemPtr);
Function Mergeable(I: DCItemPtr): Boolean;
Procedure MergeDCItem(var IList,I: DCItemPtr);
Function ConsumeDCItem(var IList,I: DCItemPtr; N: Integer): Integer;

Function NewIGrid: IGridPtr;
Procedure DisposeIGrid(var IG: IGridPtr);
Procedure PlaceDCItem(gb: GameBoardPtr; IG: IGridPtr; var I: DCItemPtr; X,Y: Integer);
Procedure RetrieveDCItem(gb: GameBoardPtr; IG: IGridPtr; var I: DCItemPtr; X,Y: Integer);

Function LocateItem(IList: DCItemPtr; N: Integer): DCItemPtr;
Function HasItem(IList: DCItemPtr; K,C: Integer): Boolean;
Function ItemNameShort(i: DCItemPtr): String;
Function ItemNameLong(i: DCItemPtr): String;
Function ItemDesc(i: DCItemPtr): PChar;

Procedure WriteItemList(I: DCItemPtr; var F: Text);
Function ReadItemList(var F: Text): DCItemPtr;
Procedure WriteIGrid(IG: IGridPtr; var F: Text);
Function ReadIGrid(var F: Text; gb: GameBoardPtr): IGridPtr;


implementation


Function LastItem(LList: DCItemPtr): DCItemPtr;
	{Search through the linked list, and return the last element.}
	{If LList is empty, return Nil.}
begin
	if LList <> Nil then
		while LList^.Next <> Nil do
			LList := LList^.Next;
	LastItem := LList;
end;

Function NewDCItem: DCItemPtr;
	{Return the address of a new DCItem record.}
var
	it: DCItemPtr;
begin
	New(it);
	if it = Nil then exit(Nil);

	{Initialize values.}
	it^.Next := Nil;
	it^.Charge := -1;
	it^.State := 0;
	it^.ID := True;

	NewDCItem := it;
end;

Function AddDCItem(var LList: DCItemPtr): DCItemPtr;
	{Add a new element to the end of LList.}
var
	it: DCItemPtr;
begin
	it := NewDCItem;
	if it=Nil then Exit(Nil);

	{Attach IT to the list.}
	if LList = Nil then
		LList := it
	else
		LastItem(LList)^.Next := it;

	{Return a pointer to the new element.}
	AddDCItem := it;
end;

Procedure DisposeItemList(var LList: DCItemPtr);
	{Dispose of the list, freeing all associated system resources.}
var
	LTemp: DCItemPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure DelinkDCItem(var IList,I: DCItemPtr);
	{Take item I and remove it from the list IList.}
var
	a,b: DCItemPtr;
begin
	{Initialize B to the head of the list.}
	B := IList;

	{Initialize A to Nil.}
	A := Nil;

	while (B <> Nil) and (B <> I) do begin
		A := B;
		B := B^.Next;
	end;

	{Now, check to see what's just happened.}
	if B = Nil then begin
		{Oh dear. The item wasn't found.}
		writeln('ERROR- DelinkItem asked to delink an item that doesn''t exist!');
	end else if A = Nil then begin
		{The item that we're delinking is first in the list.}
		IList := B^.Next;
		B^.Next := Nil;
	end else begin
		{The item we want to delink is B; A is right behind it.}
		A^.Next := B^.Next;
		B^.Next := Nil;
	end;

end;

Procedure RemoveItem(var LList,LMember: DCItemPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: DCItemPtr;
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
		writeln('ERROR- RemoveLink asked to remove a link that doesnt exist.');
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

Function Mergeable(I: DCItemPtr): Boolean;
	{Return TRUE if the item is mergeable, FALSE if not.}
var
	it: Boolean;
begin
	if (I^.IKind = IKIND_Food) or (I^.IKind = IKIND_Ammo) or (I^.IKind = IKIND_Grenade) then
		it := true
	else
		it := false;
	Mergeable := it;
end;

Procedure MergeDCItem(var IList,I: DCItemPtr);
	{Add item I, and any siblings it may have, to list IList.}
	{But wait! There's a catch! If the item is a quantity-type}
	{item, and one or more of them are already in the list,}
	{add the new quantity then dispose of I.}
var
	a,b: DCItemPtr;
begin
	{Error check.}
	if I = Nil then Exit;

	{Check to see if our item is Mergeable.}
	if Mergeable(I) and I^.ID then begin
		{Error check- make sure that I is at least 1.}
		if I^.charge = -1 then I^.charge := 1;

		{Look for another item of the same type in the list.}
		a := IList;
		b := Nil;
		while a <> Nil do begin
			if (a^.ikind = i^.ikind) and (a^.icode = i^.icode) then b := a;
			a := a^.next;
		end;
		if b <> Nil then begin
			{Another item of the same type as I has}
			{been found. Merge this item into it.}
			if b^.charge < 1 then b^.charge := 1;
			b^.charge := b^.charge + i^.charge;
			DisposeItemList(I);
		end;
	end;

	if I <> Nil then begin
		if IList = Nil then
			IList := I
		else
			LastItem(IList)^.Next := I;
	end;
end;

Function ConsumeDCItem(var IList,I: DCItemPtr; N: Integer): Integer;
	{The player wants to use N units of item I. If the units}
	{are avaliable, remove them from the Charge field of the}
	{item. If they're not avaliable, consume as many items as}
	{possible. If the Charge field is reduced to 0 by consumption,}
	{delete the item record. Return the actual number of items}
	{used.}
begin
	{error check- make sure we're dealing with a consumable item!}
	if not mergeable(I) then exit(0)
	else if I^.charge < 1 then I^.charge := 1;

	if N > I^.charge then N := I^.charge;

	I^.charge := I^.charge - N;

	if I^.charge < 1 then RemoveItem(IList,I);

	ConsumeDCItem := N;
end;

Function NewIGrid: IGridPtr;
	{Create a new IGrid array, then initialize all its cells to Nil.}
var
	it: IGridPtr;
	X,Y: Integer;
begin
	New(it);
	if it = Nil then Exit(Nil);

	for x := 1 to XMax do
		for y := 1 to YMax do
			it^[x,y] := Nil;

	NewIGrid := it;
end;

Procedure DisposeIGrid(var IG: IGridPtr);
	{Dispose of IG, and all item records stored on it.}
var
	X,Y: Integer;
begin
	if IG <> Nil then begin
		for x := 1 to XMax do
			for y := 1 to YMax do
				if IG^[X,Y] <> Nil then
					DisposeItemList(IG^[X,Y]);
		Dispose(IG);
	end;
end;

Procedure PlaceDCItem(gb: GameBoardPtr; IG: IGridPtr; var I: DCItemPtr; X,Y: Integer);
	{Stick item I on the gameboard at location X,Y.}
	{update the display as needed.}
begin
	{Error check.}
	if I = Nil then exit;

	MergeDCItem(IG^[X,Y],I);
	SetOverImage(gb,X,Y,',',LightBlue);
end;

Procedure RetrieveDCItem(gb: GameBoardPtr; IG: IGridPtr; var I: DCItemPtr; X,Y: Integer);
	{Remove item I from the board. Clear the graphics display}
	{if needed.}
	{BUGS: item I had better well be in the right spot...}
begin
	DelinkDCItem(IG^[X,Y],I);
	if IG^[X,Y] = Nil then ClearOverImage(gb,X,Y);
end;

Function LocateItem(IList: DCItemPtr; N: Integer): DCItemPtr;
	{This function will find the Nth item in list IList.}
	{If N is too big, it will return the last item in the list.}
	{If N is too small, it will return the first.}
var
	t: Integer;
begin
	if N>1 then
		for t := 2 to N do
			if IList <> Nil then
				IList := IList^.Next;

	LocateItem := IList;
end;

Function HasItem(IList: DCItemPtr; K,C: Integer): Boolean;
	{Search through list IList for an item matching Kind}
	{and Code values K and C.}
var
	it: Boolean;
begin
	it := false;
	while IList <> Nil do begin
		if (IList^.ikind = K) and (IList^.icode = C) then it := true;
		IList := IList^.Next;
	end;
	HasItem := it;
end;

Function ItemNameShort(i: DCItemPtr): String;
	{Provide the terse name for the item in question.}
var
	it: String;
begin
	if I^.ID then begin
		Case i^.ikind of
			IKIND_Gun: it := CGuns[i^.icode].Name;
			IKIND_Wep: it := CWep[i^.icode].Name;
			IKIND_Cap: it := CCap[i^.icode].Name;
			IKIND_Armor: it := CArmor[i^.icode].Name;
			IKIND_Glove: it := CGlove[i^.icode].Name;
			IKIND_Shoe: it := CShoe[i^.icode].Name;
			IKIND_Food: begin
					{Food which belongs to one of the special groups gets}
					{a special addition to the start of its name.}
					if CFood[i^.icode].fk <> 0 then
						it := FKName[CFood[i^.icode].fk]+': '+CFood[i^.icode].Name
					else
						it := CFood[i^.icode].Name;
				end;
			IKIND_Ammo: begin
					it := AmmoName[i^.icode mod 100];
					if (i^.icode div 100) <> 0 then begin
						it := it + ' ('+CSpecAmmo[i^.icode div 100].Name+')';
					end;
				end;
			IKIND_KeyItem: it := KCat[i^.icode].name;
			IKIND_Book: it := CBook[i^.icode].name;
			IKIND_Grenade:	begin
					it := CGrn[i^.icode].name;
					if CGrn[i^.icode].SayGrenade then it := it + ' Grenade';
					end;
			IKIND_Electronics: it := ElecCat[i^.icode].name;
			else it := 'kind:' + BStr( i^.ikind ) + '/code:'+ BStr(i^.icode);
		end;

	end else begin
		{ Provide generic names for unidentified items. }
		Case i^.ikind of
			IKIND_Gun: it := '?Gun';
			IKIND_Wep: it := '?Weapon';
			IKIND_Cap: it := '?Hat';
			IKIND_Armor: it := '?Clothing';
			IKIND_Glove: it := '?Gloves';
			IKIND_Shoe: it := '?Shoes';
			IKIND_Food: begin
					{Food which belongs to one of the special groups gets}
					{a special addition to the start of its name.}
					if CFood[i^.icode].fk <> 0 then
						it := '?'+FKName[CFood[i^.icode].fk]
					else
						it := '?Food';
				end;
			IKIND_Ammo: begin
					it := '?'+AmmoName[i^.icode mod 100];
				end;
			IKIND_KeyItem: it := '?Item';
			IKIND_Book: it := '?Book';
			IKIND_Grenade: begin
					if CGrn[i^.icode].SayGrenade then it := '?Grenade'
					else it := '?Item';
					end;
			IKIND_Electronics: it := '?Item';
			else it := '?kind:' + BStr( i^.ikind ) + '/code:'+ BStr(i^.icode);
		end;

	end;

	ItemNameShort := it;
end;

Function ItemNameLong(i: DCItemPtr): String;
	{Provide the verbose item name for the item in question.}
var
	it,S: String;
begin
	it := ItemNameShort(i);

	if Mergeable(I) then begin
		Str(I^.charge,S);
		it := it + ' x ' + S;

	end else if ( I^.IKind = IKIND_Gun ) and I^.ID then begin
		if I^.Charge <> -1 then begin
			Str(I^.charge,S);
			it := it + ' [' + S + ']';
		end else it := it + ' [+]';
		if I^.state > 0 then begin
			it := it + ' ('+CSpecAmmo[i^.state].name+')';
		end else if I^.state < 0 then begin
			it := it + ' (?)';
		end;
	end;

	ItemNameLong := it;
end;

Function ItemDesc(i: DCItemPtr): PChar;
	{Provide the description for the item in question.}
const
	UnID: PChar = 'Unknown item.';
var
	it: PChar;
begin
	{Error check}
	if I = Nil then Exit(Nil)
	else if not I^.ID then Exit( UnID );

	Case i^.ikind of
		IKIND_Gun: it := CGuns[i^.icode].Desc;
		IKIND_Wep: it := CWep[i^.icode].Desc;
		IKIND_Cap: it := CCap[i^.icode].Desc;
		IKIND_Armor: it := CArmor[i^.icode].Desc;
		IKIND_Glove: it := CGlove[i^.icode].Desc;
		IKIND_Shoe: it := CShoe[i^.icode].Desc;
		IKIND_Food: it := CFood[i^.icode].Desc;
		IKIND_Ammo: it := CSpecAmmo[i^.icode div 100].Desc;
		IKIND_KeyItem: it := KCat[i^.icode].Desc;
		IKIND_Book: it := CBook[i^.icode].Desc;
		IKIND_Grenade: it := CGrn[i^.icode].Desc;
		IKIND_Electronics: it := ElecCat[i^.icode].Desc;
		else it := Nil;
	end;
	ItemDesc := it;
end;

Procedure WriteItemList(I: DCItemPtr; var F: Text);
	{Save the linked list of items I to the file F.}
begin
	while I <> Nil do begin
		writeln(F,I^.icode);
		writeln(F,I^.ikind);
		writeln(F,I^.charge);
		writeln(F,I^.state);
		if I^.ID then writeln(F,'T')
		else writeln(F,'F');
		I := I^.Next;
	end;
	writeln(F,-1);
end;

Function ReadItemList(var F: Text): DCItemPtr;
	{Load a list of items saved by the above procedure from}
	{the file F.}
var
	N: Integer;
	I,IList: DCItemPtr;
	C: Char;
begin
	IList := Nil;
	Repeat
		readln(F,N);
		if N <> -1 then begin
			I := AddDCItem(IList);
			I^.icode := N;
			readln(F,I^.ikind);
			readln(F,I^.charge);
			readln(F,I^.state);
			readln(F,C);
			if C = 'T' then I^.ID := True
			else I^.ID := False;
		end;
	until N = -1;
	ReadItemList := IList;
end;

Procedure WriteIGrid(IG: IGridPtr; var F: Text);
	{Save the Item Grid IG to the file F.}
var
	X,Y: Integer;
begin
	{write the specials.}
	for X := 1 to XMax do begin
		for Y := 1 to YMax do begin
			if IG^[X,Y] <> Nil then begin
				writeln(F,X);
				writeln(F,Y);
				WriteItemList(IG^[X,Y],F);
			end;
		end;
	end;
	{write the sentinel.}
	writeln(F,0);
end;

Function ReadIGrid(var F: Text; gb: GameBoardPtr): IGridPtr;
	{Read the Item Grid IG from the file F.}
var
	IG: IGridPtr;
	X,Y: Integer;
begin
	IG := NewIGrid;
	Repeat
		readln(F,X);
		if X <> 0 then begin
			readln(F,Y);
			IG^[X,Y] := ReadItemList(F);
			SetOverImage(gb,X,Y,',',LightBlue);
		end;
	until X = 0;

	ReadIGrid := IG;
end;


end.
