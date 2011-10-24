unit backpack;
	{This unit handles the PC's Inventory UI.}

Interface

uses crt,rpgtext,rpgmenus,texmodel,texmaps,gamebook,dcitems,dcchars,zapspell,libram;

Const
	EqpWin_X1 = 1;
	EqpWin_Y1 = 4;
	EqpWin_X2 = 50;
	EqpWin_Y2 = 11;

	DscWin_X1 = 52;
	DscWin_Y1 = 4;
	DscWin_X2 = 79;
	DscWin_Y2 = 15;
	DscColor = LightGreen;

	InvWin_X1 = 1;
	InvWin_Y1 = 11;
	InvWin_X2 = 50;
	InvWin_Y2 = 24;

	PCSWin_X1 = 51;
	PCSWin_Y1 = 16;
	PCSWin_X2 = 80;
	PCSWin_Y2 = 20;

	{MenuKey Constants}
	BMK_SwitchKey = '/';
	BMK_SwitchCode = -2;
	BMK_DropKey = 'd';
	BMK_DropCode = -3;


Procedure HandyMap( SC: ScenarioPtr );
Procedure Inventory(SC: ScenarioPtr; StartWithInv: Boolean);
Function PromptItem(SC: ScenarioPtr; IK: Integer): DCItemPtr;


Implementation

Const
	InvRPM: RPGMenuPtr = Nil;
	EqpRPM: RPGMenuPtr = Nil;


Procedure HandyMap( SC: ScenarioPtr );
	{ The PC is about to use his HANDYMAP automatic mapping system. }
const
	HMOX = 23;
	HMOY = 4;
var
	X,Y,XX,YY: Integer;
	Rev: Integer;		{ # of revealed tiles. }
	C: Char;
begin
	{ Start by doing the HANDYMAP case display. }
	Window( HMOX , HMOY , HMOX + 35 , HMOY + 20 );
	ClrScr;
	Window( 1 , 1 , 80 , 25 );
	LovelyBox( Red , HMOX , HMOY , HMOX + 35 , HMOY + 20 );
	LovelyBox( LightGray , HMOX+1 , HMOY+2 , HMOX + 34 , HMOY + 19 );
	TextColor( LightRed );
	TextBackground( Black );
	GotoXY( HMOX + 1 , HMOY + 1 );
	Write( 'X     HANDYMAP v3.14' );

	{ Next, go through the map in 16 x 16 blocks. }
	For X := 1 to ( XMax div 8 ) do begin
		for Y := 1 to ( YMax div 16 ) do begin
			Rev := 0;
			C := ' ';

			for XX := ( X * 8 - 7 ) to ( X * 8 ) do begin
				for YY := ( Y * 16 - 15 ) to ( Y * 16 ) do begin
					{ If this tile has been seen by the PC, increment }
					{ the visible counter. }
					if SC^.GB^.Map[XX,YY].Visible then begin
						Inc( Rev );

						{ If this tile contains a special tile, }
						{ store it here. }
						Case SC^.GB^.Map[XX,YY].Terr of
							TransitLeft:	C := '<';
							TransitRight:	C := '>';
							TransitUp:	C := '^';
							TransitDown:	C := 'v';
							PilotsChair:	C := 'S';
							ForceField:	C := 'F';
							ForceFieldGenerator: C := 'g';
						end;
					end;
				end;
			end;

			{ Set colors - if this is the map block containing the }
			{ pilot, reverse the colors. }
			if ( SC^.PC^.M^.X > ((X-1)*8) ) and ( SC^.PC^.M^.X <= (X*8) ) and ( SC^.PC^.M^.Y > ((Y-1)*16) ) and ( SC^.PC^.M^.Y <= (Y*16) ) then begin
				TextColor( Black );
				TextBackground( LightGreen );
			end else begin
				TextColor( Green );
				TextBackground( Black );
			end;

			{ Print the decided-upon character. }
			GotoXY( X + 1 + HMOX , Y + 2 + HMOY );
			if C <> ' ' then Write( C )
			else if Rev > 75 then Write( '#' )
			else if Rev > 50 then Write( '=' )
			else if Rev > 25 then Write( '-' )
			else if Rev > 0 then Write( '.' )
			else Write( ' ' );
		end;
	end;

	{ Wait for a keypress. }
	RPGKey;
end;

Procedure CreateEqpMenu(SC: ScenarioPtr);
	{Create the equipment menu, and store it in EqpRPM}
var
	t: Integer;
	m: String;
begin
	{Initialize the menu.}
	if EqpRPM <> Nil then DisposeRPGMenu(EqpRPM);
	EqpRPM := CreateRPGMenu(Black,Green,LightGreen,EqpWin_X1,EqpWin_Y1,EqpWin_X2,EqpWin_Y2);

	EqpRPM^.DBorColor := White;
	EqpRPM^.DTexColor := DscColor;
	EqpRPM^.dx1 := DscWin_X1;
	EqpRPM^.dy1 := DscWin_Y1;
	EqpRPM^.dx2 := DscWin_X2;
	EqpRPM^.dy2 := DscWin_Y2;

	{Add the MenuKeys.}
	AddRPGMenuKey(EqpRPM,BMK_SwitchKey,BMK_SwitchCode);

	{Add one MenuItem for each Equipment Slot.}
	for t := 1 to NumEquipSlots do begin
		m := EquipSlotName[t];
		if SC^.PC^.Eqp[t] <> Nil then begin
			m := m + ' ' + ItemNameLong(SC^.PC^.Eqp[t]);
		end;
		AddRPGMenuItem(EqpRPM,m,t,ItemDesc(SC^.PC^.Eqp[t]));
	end;	
end;

Procedure CreateInvMenu(SC: ScenarioPtr);
	{Create the inventory menu, and store it in InvRPM}
var
	i: DCItemPtr;
	t: Integer;
begin
	{Initialize the menu.}
	if InvRPM <> Nil then DisposeRPGMenu(InvRPM);
	InvRPM := CreateRPGMenu(Black,Green,LightGreen,InvWin_X1,InvWin_Y1,InvWin_X2,InvWin_Y2);

	InvRPM^.DBorColor := White;
	InvRPM^.DTexColor := DscColor;
	InvRPM^.dx1 := DscWin_X1;
	InvRPM^.dy1 := DscWin_Y1;
	InvRPM^.dx2 := DscWin_X2;
	InvRPM^.dy2 := DscWin_Y2;

	{Add the MenuKeys.}
	AddRPGMenuKey(InvRPM,BMK_SwitchKey,BMK_SwitchCode);
	AddRPGMenuKey(InvRPM,BMK_DropKey,BMK_DropCode);

	{Add a MenuItem for each object in the player's inventory.}
	i := SC^.PC^.Inv;
	t := 1;
	while i <> Nil do begin
		AddRPGMenuItem(InvRPM,ItemNameLong(i),t,ItemDesc(I));
		i := i^.Next;
		Inc(t);
	end;

	{Sort the menu alphabetically.}
	RPMSortAlpha(InvRPM);
end;

Procedure DisplayPCStats(SC: ScenarioPtr);
	{Do a quick display of several of the PC's stats.}
const
	c1 = 2;
	c2 = 6;
	c3 = 12;
	c4 = 16;
	c5 = 22;
	c6 = 26;
begin
	Window(PCSWin_X1+1,PCSWin_Y1+1,PCSWin_X2-1,PCSWin_Y2-1);
	ClrScr;
	TextColor(Blue);
	GotoXY(C1,1);
	Write('H2H');
	GotoXY(C3,1);
	Write('Dmg');
	GotoXY(C1,2);
	Write('Gun');
	GotoXY(C3,2);
	Write('Dmg');
	GotoXY(C5,2);
	Write('Rng');
	GotoXY(C1,3);
	Write('Armor');

	TextColor(LightBlue);
	GotoXY(C2,1);
	Write(PCMeleeSkill(SC^.pc));
	GotoXY(C4,1);
	Write(PCMeleeDamage(SC^.pc));
	GotoXY(C2,2);
	Write(PCMissileSkill(SC^.pc));
	GotoXY(C4,2);
	Write(PCMissileDamage(SC^.PC));
	GotoXY(C6,2);
	Write(PCMissileRange(SC^.PC));
	GotoXY(C1+7,3);
	Write(PCArmorPV(SC^.PC));

	Window(1,1,80,25);
end;

Procedure TheDisplay(SC: ScenarioPtr);
	{This procedure sets up the BackPack display.}
var
	t: Integer;
begin
	Window(EqpWin_X1,EqpWin_Y1,PCSWin_X2,InvWin_Y2);
	ClrScr;
	Window(1,1,80,25);
	LovelyBox(LightGray,EqpWin_X1,EqpWin_Y1,InvWin_X2,InvWin_Y2);
	TextColor(Green);
	GotoXY(EqpWin_X1+2,EqpWin_Y2);
	for t := 1 to (EqpWin_X2 - EqpWin_X1 - 3) do
		write('=');

	LovelyBox(DarkGray,PCSWin_X1,PCSWin_Y1,PCSWin_X2,PCSWin_Y2);
	DisplayPCStats(SC);
	TextColor(DarkGray);
	GotoXY(PCSWin_X1,PCSWin_Y2+1);
	write('/ - Mode  d - Drop');
	GotoXY(PCSWin_X1,PCSWin_Y2+2);
	write('[SPACE] - Default Item Action');
	GotoXY(PCSWin_X1,PCSWin_Y2+3);
	write('[ESC] - Exit');
end;

Procedure RefreshBackPack(SC: ScenarioPtr);
	{Something has changed in the inventory/equipment lists.}
	{update the menus and the screen display to deal with this.}
var
	N,S: Integer;
begin
	{Error check- exit immediately if EqpRPM or InvRPM are NIL.}
	if (EqpRPM = Nil) or (InvRPM = Nil) then Exit;

	{Save the SelectItem number so that we can restore it later.}
	S := EqpRPM^.SelectItem;

	{Create the Equipment menu}
	CreateEqpMenu(SC);

	EqpRPM^.SelectItem := S;

	{Save the number of items and selected item of the Inv menu.}
	N := InvRPM^.NumItem;
	S := InvRPM^.SelectItem;

	{Create the Inventory menu}
	CreateInvMenu(SC);

	if InvRPM^.NumItem = N then InvRPM^.SelectItem := S;

	{Display both menus}
	DisplayMenu(EqpRPM);
	DisplayMenu(InvRPM);

	{ Display PC stats. }
	PCStatLine( SC );
end;

Function SelectItem(SC: ScenarioPtr; IK: Integer): DCItemPtr;
	{Create a menu, then query the user for an item which}
	{corresponds to the kind IK. Return Nil if either no}
	{such items are present in the inventory, or if the user}
	{cancels item selection.}
var
	RPM: RPGMenuPtr;	{Our menu.}
	i: DCItemPtr;
	t: Integer;
begin
	{Create the menu. It's gonna use the InvWindow.}
	RPM := CreateRPGMenu(Black,Green,LightGreen,InvWin_X1,InvWin_Y1,InvWin_X2,InvWin_Y2);
	RPM^.DBorColor := White;
	RPM^.DTexColor := DscColor;
	RPM^.dx1 := DscWin_X1;
	RPM^.dy1 := DscWin_Y1;
	RPM^.dx2 := DscWin_X2;
	RPM^.dy2 := DscWin_Y2;

	{Add one menu item for each appropriate item in the Inventory.}
	i := SC^.PC^.Inv;
	t := 1;
	while i <> Nil do begin
		if I^.IKind = IK then
			AddRPGMenuItem(RPM,ItemNameLong(i),t,ItemDesc(I));
		i := i^.Next;
		Inc(t);
	end;

	{Error check- make sure there are items present in the list!!!}
	if RPM^.FirstItem = Nil then begin
		DisposeRPGMenu(RPM);
		Exit(Nil);
	end;

	{Sort the menu alphabetically.}
	RPMSortAlpha(RPM);

	{Next, select the item.}
	t := SelectMenu(RPM,RPMNormal);
	if t = -1 then i := Nil
	else i := LocateItem(SC^.PC^.Inv,t);

	{Dispose of the menu.}
	DisposeRPGMenu(RPM);

	{Show the complete inventory list again.}
	DisplayMenu(InvRPM);

	SelectItem := i;
end;

Procedure UnEquipItem(SC: ScenarioPtr; Slot: Integer);
	{UnEquip the item in slot Slot in the PC's equipment list.}
var
	I: DCItemPtr;
begin
	I := SC^.PC^.Eqp[Slot];
	if I <> Nil then begin
		SC^.PC^.Eqp[Slot] := Nil;
		MergeDCItem(SC^.PC^.Inv,I);
		RefreshBackPack(SC);
		DisplayPCStats(SC);
	end;
end;

Procedure EquipItem(SC: ScenarioPtr; I: DCItemPtr);
	{Delink this item from the main Inventory list, then stick}
	{it in the appropriate equipment slot. If there's already}
	{an item there, unequip it.}
begin
	if ( I^.ikind > 0 ) and ( I^.ikind <= NumEquipSlots ) then begin
		{If something is already equipped, get rid of it.}
		if SC^.PC^.Eqp[I^.ikind] <> Nil then UnEquipItem(SC,I^.ikind);

		{Delink the item we're equipping from the Inventory.}
		DelinkDCItem(SC^.PC^.Inv,I);

		{Link it to the correct inventory slot.}
		SC^.PC^.Eqp[I^.ikind] := I;
		RefreshBackPack(SC);
		DisplayPCStats(SC);
	end;
end;

Procedure ChangeItem(SC: ScenarioPtr; Slot: Integer);
	{Change the item that's currently equipped in equipment}
	{slot Slot. If there are other items that could go there,}
	{select one of them for use. If not, just unequip the item.}
var
	I: DCItemPtr;
begin
	{UnEquip the item in the slot.}
	if SC^.PC^.Eqp[Slot] <> Nil then UnEquipItem(SC,Slot);

	{Select a new item, of appropriate type, from the menu.}
	I := SelectItem(SC,Slot);

	{Equip it. Any item currently in this slot will be sent to}
	{the Inventory.}
	if I <> Nil then EquipItem(SC,I);

	RefreshBackPack(SC);
	DisplayPCStats(SC);
end;

Procedure LoadAmmo(SC: ScenarioPtr; I: DCItemPtr);
	{Load ammunition item I into the currently equipped gun.}
	{Fill the gun to its full capacity, or as full as it can}
	{get given the current number of cartridges in inventory.}
	{If the gun is currently loaded with a different ammo type,}
	{unload that ammo. If the selected ammo won't fit in the}
	{current gun, choose a different gun from the inventory.}
var
	cal,spec: Integer;
	gun,ul: DCItemPtr;
	N: Integer;
	ID: Boolean;
begin
	{Determine the Caliber and Special Type of the ammo.}
	cal := I^.ICode mod 100;
	spec := I^.ICode div 100;
	ID := I^.ID;

	gun := SC^.PC^.Eqp[ES_MissileWeapon];

	if (gun = Nil) or (CGuns[gun^.icode].Caliber <> Cal) then begin
		{The gun currently equipped is either inappropriate}
		{or doesn't exist. Either way, we need to choose a new gun.}
		gun := SelectItem(SC,IKIND_Gun);
	end;

	if (gun = Nil) or (CGuns[gun^.icode].Caliber <> Cal) or (gun^.charge = -1) then exit;

	{We have a gun to load. Let's get to it!}

	{If the gun is currently loaded with a different sort of}
	{ammunition, unload it.}
	if (gun^.state <> spec) and (gun^.charge > 0) then begin
		if (Cal <> CAL_Energy) and (Cal <> CAL_Napalm) then begin
			UL := NewDCItem;
			UL^.IKind := IKIND_Ammo;
			UL^.ICode := (Abs(gun^.state) * 100) + Cal;
			UL^.charge := gun^.charge;
			gun^.charge := 0;
			if gun^.state < 0 then UL^.ID := False;
			MergeDCItem(SC^.PC^.Inv,UL);
		end else begin
			gun^.charge := 0;
			gun^.state := 0;
		end;
	end;

	{Figure out how many rounds are needed to fill the gun.}
	if (CGuns[gun^.icode].Caliber = CAL_Energy) or (CGuns[gun^.icode].Caliber = CAL_Napalm) then
		N := 1
	else
		N := CGuns[gun^.icode].magazine - gun^.Charge;

	if N > 0 then begin
		{Consume the ammo, add it to the magazine.}
		DCGameMessage('You load '+ItemNameShort(gun)+'.');

		N := ConsumeDCItem(SC^.PC^.Inv,I,N);
		if CGuns[gun^.icode].Caliber = CAL_Energy then begin
			{Energy guns can store a large number of shots,}
			{depending upon how many E-Cells are loaded}
			{into them.}
			gun^.charge := gun^.charge + CGuns[gun^.icode].magazine;

			if ID then gun^.state := spec
			else gun^.state := -spec;

			{If the weapon is overloaded, well that's bad...}
			if (gun^.charge > (600 div CGuns[gun^.icode].DMG)) then begin
				DCAppendMessage(' Weapon is overcharged!');
				gun^.charge := 0;
				gun^.state := 0;
			end;
		end else if CGuns[gun^.icode].Caliber = CAL_Napalm then begin
			{One cannister reloads the weapon to full capacity.}
			gun^.charge := CGuns[gun^.icode].magazine;
			if Random(10) = 7 then DCAppendMessage(' Ready to cook.');
			if ID then gun^.state := spec
			else gun^.state := -spec;
		end else
			{In this, the default case, the gun gains}
			{as many shots as bullets you put into it.}
			gun^.charge := gun^.charge + N;
			if ID then gun^.state := spec
			else gun^.state := -spec;
	end;
	RefreshBackPack(SC);
end;

Procedure DropItem(SC: ScenarioPtr; I: DCItemPtr);
	{The player wants to drop an item.}
begin
	DelinkDCItem(SC^.PC^.Inv,I);
	PlaceDCItem(SC^.gb,SC^.ig,I,SC^.PC^.M^.X,SC^.PC^.M^.Y);
	RefreshBackPack(SC);
end;

Procedure EatFood(SC: ScenarioPtr; I: DCItemPtr);
	{Eat the food. Go for it.}
begin
	{Error check- make sure we have actual food.}
	if I^.ikind <> IKIND_Food then exit;

	if ( SC^.PC^.Carbs + CFood[I^.icode].carbs ) < 102 then begin
		SC^.PC^.Carbs := SC^.PC^.Carbs + CFood[I^.icode].carbs;
		if SC^.PC^.Carbs > 100 then SC^.PC^.Carbs := 100;

		{ Display a different message depending upon whether the }
		{ food item being eaten is a pill or not. }
		if CFood[I^.icode].fk = 2 then begin
			DCGameMessage('You take the '+CFood[I^.icode].Name+'.');
		end else begin
			DCGameMessage('You eat the '+CFood[I^.icode].Name+'.');
		end;

		if CFood[I^.icode].fx <> Nil then begin
			ProcessSpell(SC,CFood[I^.icode].fx);
		end;

		{ Just in case this hasn't been identified yet, ID it now. }
		I^.ID := True;

		ConsumeDCItem(SC^.PC^.Inv,I,1);
	end else begin
		{ The PC is too full to eat. Print a message depending upon }
		{ whether the food item is a pill or something else. }
		if CFood[I^.icode].fk = 2 then begin
			DCGameMessage('You''re too full to take the '+CFood[I^.icode].Name+' now.');
		end else begin
			DCGameMessage('You''re too full to eat the '+CFood[I^.icode].Name+' now.');
		end;
	end;
	RefreshBackPack(SC);
end;

Procedure BPReadBook(SC: ScenarioPtr; I: DCItemPtr);
	{The PC wants to read book I. Call the procedure to do so,}
	{and restore the display afterwards.}
begin
	ReadBook(SC,I^.icode);
	TheDisplay(SC);
	RefreshBackPack(SC);
end;

Procedure BPElectronics(SC: ScenarioPtr; I: DCItemPtr);
	{The PC wants to use item I. Call the procedure to do so,}
	{and restore the display afterwards.}
begin
	HandyMap( SC );
	TheDisplay(SC);
	RefreshBackPack(SC);
end;

Function EqpMenu(SC: ScenarioPtr): Boolean;
	{This procedure will do all the stuff needed for the}
	{Equipment menu. Return TRUE if the player should remain}
	{in the inventory screen, FALSE otherwise.}
var
	n: Integer;
	it: Boolean;
begin
	repeat
		n := SelectMenu(EqpRPM,RPMNoCleanup);
		DisplayMenu(EqpRPM);

		if N > 0 then ChangeItem(SC,N);

	until (n = -1) or (n = BMK_SwitchCode);
	if n = BMK_SwitchCode then it := True
	else it := False;
	EqpMenu := it;
end;

Function InvMenu(SC: ScenarioPtr): Boolean;
	{This procedure will do all the stuff needed for the}
	{Inventory menu. Return TRUE to keep doing inventory,}
	{FALSE otherwise.}
var
	n: Integer;
	it: Boolean;
	I: DCItemPtr;
begin
	{Error Check- if there's nothing present in the inventory,}
	{boot the player back out to the Equipment menu.}
	if InvRPM^.FirstItem = Nil then Exit(True);

	repeat
		n := SelectMenu(InvRPM,RPMNoCleanup);
		DisplayMenu(InvRPM);

		if N > -1 then begin
			{An actual item was selected. Do something}
			{with it.}
			I := LocateItem(SC^.PC^.Inv,N);

			{Check to see if this is an equippable item.}
			if I^.ikind > 0 then begin
				EquipItem(SC,I);
			end else if I^.ikind = IKIND_Ammo then begin
				LoadAmmo(SC,I);
			end else if I^.ikind = IKIND_Food then begin
				EatFood(SC,I);
			end else if I^.ikind = IKIND_Book then begin
				BPReadBook(SC,I);
			end else if I^.ikind = IKIND_Electronics then begin
				BPElectronics(SC,I);
			end;
		end else if N = BMK_DropCode then begin
			I := LocateItem(SC^.PC^.Inv,RPMLocateByPosition(InvRPM,InvRPM^.selectitem)^.value);
			DropItem(SC,I);
		end;

		{Check to make sure there are items left in the inventory.}
		if InvRPM^.FirstItem = Nil then n := -1;
	until (n = -1) or (n = BMK_SwitchCode);
	if n = BMK_SwitchCode then it := True
	else it := False;
	InvMenu := it;
end;

Procedure Inventory(SC: ScenarioPtr; StartWithInv: Boolean);
	{This procedure opens up the PC's inventory display,}
	{and allows all the standard RPG options, such as}
	{equipping items, dropping items, etc.}
var
	LC: Boolean;
begin
	{Set up the display.}
	TheDisplay(SC);

	{Initialize misc values.}
	LC := True;

	{Create the Equipment menu}
	CreateEqpMenu(SC);

	{Create the Inventory menu}
	CreateInvMenu(SC);

	{Display both menus}
	DisplayMenu(EqpRPM);
	DisplayMenu(InvRPM);

	{Begin loop here.}
	While LC do begin
		{Query the active menu.}
		if StartWithInv then
			LC := InvMenu(SC)
		else
			LC := EqpMenu(SC);

		{Switch to the other menu}
		StartWithInv := not StartWithInv;
	end;

	{Release the two menus that we created.}
	DisposeRPGMenu(EqpRPM);
	DisposeRPGMenu(InvRPM);

	{Restore the display.}
	Window(EqpWin_X1,EqpWin_Y1,PCSWin_X2,InvWin_Y2);
	ClrScr;
	Window(1,1,80,25);
end;

Function PromptItem(SC: ScenarioPtr; IK: Integer): DCItemPtr;
	{Create a menu, then query the user for an item which}
	{corresponds to the kind IK. Return Nil if either no}
	{such items are present in the inventory, or if the user}
	{cancels item selection. Retore map display afterwards.}
var
	RPM: RPGMenuPtr;	{Our menu.}
	i: DCItemPtr;
	t: Integer;
begin
	{Create the menu. It's gonna use the InvWindow.}
	RPM := CreateRPGMenu(LightGray,Green,LightGreen,16,7,65,21);

	{Add one menu item for each appropriate item in the Inventory.}
	i := SC^.PC^.Inv;
	t := 1;
	while i <> Nil do begin
		if I^.IKind = IK then
			AddRPGMenuItem(RPM,ItemNameLong(i),t,Nil);
		i := i^.Next;
		Inc(t);
	end;

	{Error check- make sure there are items present in the list!!!}
	if RPM^.FirstItem = Nil then Exit(Nil);

	{Sort the menu alphabetically.}
	RPMSortAlpha(RPM);

	{Next, select the item.}
	t := SelectMenu(RPM,RPMNormal);
	if t = -1 then i := Nil
	else i := LocateItem(SC^.PC^.Inv,t);

	{Dispose of the menu.}
	DisposeRPGMenu(RPM);

	{Restore the map display.}
	DisplayMap(SC^.gb);

	PromptItem := i;
end;


End.
