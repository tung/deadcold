unit dcplay;

interface

uses crt,rpgdice,rpgtext,rpgmenus,texmodel,texmaps,randmaps,statusfx,dcchars,randchar,critters,gamebook,pcaction,cbrain,charts,plotline,dccombat,dcitems;

Procedure StartGame;
Procedure RestoreGame;


implementation

uses dos,plotbase;

Function HelpScreen( SC: ScenarioPtr ): Boolean;
	{Just print a list of keys.}
var
	RPM: RPGMenuPtr;
	T: Integer;
begin
	DCGameMessage('Help - Here are the implemented command keys.');

	RPM := CreateRPGMenu(LightGray,Green,LightGreen,20,7,40,19);
	RPM^.dx1 := 45;
	RPM^.dy1 := 10;
	RPM^.dx2 := 65;
	RPM^.dy2 := 15;
	RPM^.dborcolor := LightGray;
	RPM^.dtexcolor := LightBlue;

	for t := 1 to NumGKeys do begin
		AddRPGMenuItem(RPM,KMap[t].Key+': '+KMap[t].Name,t,KMap[t].Desc);
	end;

	SelectMenu(RPM,RPMNormal);
	DisposeRPGMenu( RPM );
	PCRecenter(SC);

	HelpScreen := False;
end;

Function PCCanAct(PC: DCCharPtr): Boolean;
	{Return TRUE if the PC is capable of acting}
	{right now, FALSE if it is for any reason incapacitated.}
var
	it: Boolean;
begin
	it := true;
	if NAttValue(PC^.SF,NAG_StatusChange,SEF_Paralysis) <> 0 then it := false
	else if NAttValue(PC^.SF,NAG_StatusChange,SEF_Sleep) <> 0 then it := false;
	PCCanAct := it;
end;

Procedure DoPCAction( SC: ScenarioPtr );
	{Input a command from the PC, and do it.}
var
	Act: Boolean;
	A: Char;
	D: Integer;
begin
	{Initialize values}
	Act := False;
	a := '&';
	PCStatLine( SC );

	{Check to make sure the PC is capable of acting right now.}
	{If paralyzed or asleep, no action is possible.}
	if PCCanAct(SC^.PC) then begin

		{Check to see whether or not the PC is currently doing}
		{a continual action. If so, do that.}
		if SC^.PC^.RepCount > 0 then begin
			{Decrement the repeat counter.}
			Dec(SC^.PC^.RepCount);

			{Call the Repeat Handler.}
			Act := PCProcessRepeat(SC);
		end else begin
			Repeat
				a := RPGKey;
				if a = KMap[1].Key then Act := PCMove(SC,1)
				else if a = KMap[2].Key then Act := PCMove(SC,2)
				else if a = KMap[3].Key then Act := PCMove(SC,3)
				else if a = KMap[4].Key then Act := PCMove(SC,4)
				else if a = KMap[5].Key then Act := PCMove(SC,5)
				else if a = KMap[6].Key then Act := PCMove(SC,6)
				else if a = KMap[7].Key then Act := PCMove(SC,7)
				else if a = KMap[8].Key then Act := PCMove(SC,8)
				else if a = KMap[9].Key then Act := PCMove(SC,9)
				else if a = KMap[10].Key then Act := PCOpenDoor(SC)

				else if a = KMap[11].Key then Act := PCCloseDoor(SC)
				else if a = KMap[12].Key then Act := PCRecenter(SC)
				else if a = KMap[13].Key then Act := PCShooting(SC,true)
				else if a = KMap[14].Key then Act := PCTosser(SC)
				else if a = KMap[15].Key then Act := PCInvScreen(SC,true)

				else if a = KMap[16].Key then Act := PCInvScreen(SC,false)
				else if a = KMap[17].Key then Act := PCPickUp(SC)
				else if a = KMap[18].Key then Act := PCDisarmTrap(SC)
				else if a = KMap[19].Key then Act := PCSearch(SC)
				else if a = KMap[20].Key then Act := PCUsePsi(SC,True)

				else if a = KMap[21].Key then Act := PCUsePsi(SC,False)
				else if a = KMap[22].Key then Act := PCCheckXP(SC)
				else if a = KMap[23].Key then Act := PCLookAround(SC)
				else if a = KMap[24].Key then Act := PCEnter(SC)
				else if a = KMap[25].Key then Act := PCRepeat(SC)

				else if a = KMap[26].Key then begin
					{ It's quitting time. }
					Act := True;
					DCGameMessage( 'Save the game first? (Y/N)' );
					if YesNo then SaveGame( SC );
				end
				else if a = KMap[27].Key then Act := HelpScreen( SC )
				else if a = KMap[28].Key then begin
					Act := False;
					DCGameMessage('Saving game...');
					SaveGame(SC);
					DCAppendMessage('Done.');
				end
				else if a = KMap[29].Key then Act := PCInfoScreen( SC )
				else if a = KMap[30].Key then Act := PCHandyMap( SC )
				else if a = '!' then begin
					DCGameMessage('Cheat Code Alpha!');
					DoleExperience(SC,100);
				end
				else if a = '@' then begin
					DCGameMessage('Cheat Code Beta!');
					gotoxy(1,25);
					TextColor(Yellow);
					write(NumberOfCritters(SC^.CList));
					CritterDeath(SC,SC^.CList,True);
				end;

			until Act or not PCCanAct(SC^.PC);
			SC^.PC^.LastCmd := A;
		end;
	end else DCGameMessage( 'Can''t move!' );

	{Check for poisoning here.}
	if (NAttValue( SC^.PC^.SF , NAG_StatusChange , SEF_Poison ) > 0 ) and ( SC^.PC^.HP > 0 ) then begin
		{Make a Luck roll to avoid the effect of poison.}
		D := ( 60 - RollStep(PCLuckSave(SC^.PC)) ) div 10;
		if D > 0 then begin
			SC^.PC^.HP := SC^.PC^.HP - D;
			DCGameMessage('Poison!');
			if SC^.PC^.HP < 1 then DCAppendMessage('You have died!');
			PCStatLine(SC);
		end;

	{ Check for regeneration here - is cancelled by poison. }
	end else if (NAttValue( SC^.PC^.SF , NAG_StatusChange , SEF_Regeneration ) > 0 ) and ( SC^.PC^.HP < SC^.PC^.HPMax ) then begin
		SC^.PC^.HP := SC^.PC^.HP + 1 + Random( 3 );
		if SC^.PC^.HP > SC^.PC^.HPMax then SC^.PC^.HP := SC^.PC^.HPMax;
	end;
end;


Procedure PlayScene( SC: ScenarioPtr );
	{ This procedure holds the actual game loop. }
	{ Note that at the end of this procedure, the scenario is }
	{ deallocated. }
var
	t: Integer;
	Cr: CritterPtr;
	FName: String;
	F: Text;
begin
	ClrScr;

	UpdatePOV(SC^.gb^.pov,SC^.gb);
	ApplyPOV(SC^.gb^.pov,SC^.gb);
	DisplayMap(SC^.gb);

	PCStatLine(SC);
	SC^.PC^.LastCmd := ' ';

	DCGameMessage('Welcome to the game.');

	repeat
		Inc(SC^.ComTime);

		{ Set time triggers here. }
		if ( SC^.Comtime mod 720 ) = 0 then begin
			SetTrigger( SC , 'HOUR' );
		end else if ( SC^.Comtime mod 120 ) = 0 then begin
			SetTrigger( SC , '10MIN' );
		end else if ( SC^.Comtime mod 12 ) = 0 then begin
			SetTrigger( SC , 'MINUTE' );
		end;

		{Update the PC's Status List.}
		UpdateStatusList( SC^.PC^.SF );

		{Check the PCs food status. A check is performed}
		{every 10 minutes.}
		if (SC^.ComTime mod 120) = 81 then begin
			if SC^.PC^.Carbs > -10 then Dec(SC^.PC^.Carbs);
			if SC^.PC^.Carbs < 0 then DCGameMessage('You are starving!')
			else if SC^.PC^.Carbs < 10 then DCGameMessage('You are hungry.');
			PCStatLine(SC);
		end;

		{ Check for PC regeneration. A check is performed every minute. }
		{ The PC does _not_ regenerate while poisoned. Ouch. }
		if ((SC^.ComTime mod 12) = 0) then begin
			{See if the PC gets any HPs back this click...}
			if (SC^.PC^.HP < SC^.PC^.HPMax) and ( NAttValue( SC^.PC^.SF, NAG_StatusChange , SEF_Poison ) = 0 ) then begin
				if NumberOfActions(SC^.Comtime div 12,PCRegeneration(SC^.PC)) > 0 then begin
					SC^.PC^.HP := SC^.PC^.HP + NumberOfActions(SC^.Comtime div 12,PCRegeneration(SC^.PC));

					{If the PC is starving and injured, perminant damage to health may result.}
					if (SC^.PC^.Carbs < 0) and (Random(Abs(SC^.PC^.Carbs)) > Random(SC^.PC^.Stat[8])) and (SC^.PC^.HPMax > 10) then begin
						Dec(SC^.PC^.HPMax);
						DCGameMessage('You feel seriously ill.');
					end;

					if SC^.PC^.HP > SC^.PC^.HPMax then SC^.PC^.HP := SC^.PC^.HPMax;
					PCStatLine(SC);
				end;
			end;

			{Check for PC MP restoration.}
			if (SC^.PC^.MP < SC^.PC^.MPMax) then begin
				SC^.PC^.MP := SC^.PC^.MP + NumberOfActions(SC^.Comtime div 12,PCRestoration(SC^.PC));
				if SC^.PC^.MP > SC^.PC^.MPMax then SC^.PC^.MP := SC^.PC^.MPMax;
				PCStatLine(SC);
			end;
		end;

		{Check for random monsters every 5 minutes.}
		if (SC^.ComTime mod PLAY_MonsterTime) = 0 then WanderingCritters(SC);

		{ Check for spontaneous identification of items every hour. }
		if (SC^.ComTime mod 720) = 553 then ScanUnknownInv(SC);


		{If the player gets an action this second, use it.}
		for t := 1 to NumberOfActions(SC^.ComTime,PCMoveSpeed(SC^.PC)) do begin
			DoPCAction( SC );

			{ If QUIT was the command, or if the PC is dead, }
			{ break this loop. }
			if (SC^.PC^.LastCmd = KMap[26].Key) or (SC^.PC^.HP <= 0) then break;

			HandleTriggers(SC);

			SC^.gb^.pov.range := PCVisionRange(SC^.PC);
		end;

		{ If a QUIT request wan't recieved, handle clouds and critters. }
		if SC^.PC^.LastCmd <> KMap[26].Key then begin
			{Cloud handling. Happens every 4 seconds.}
			if ((SC^.Comtime mod 4) = 1) then BrownianMotion(SC);

			{Critter handling}
			Cr := SC^.CList;
			while Cr <> Nil do begin
				{Save the position of the next critter,}
				{since the critter we're processing might}
				{accidentally kill itself during its move.}
				SC^.CA2 := Cr^.Next;
				for t := 1 to NumberOfActions(SC^.ComTime,MonMan[Cr^.Crit].Speed) do begin
					CritterAction(SC,Cr);
					if Cr = Nil then break;
				end;
				Cr := SC^.CA2;
				if SC^.PC^.HP < 1 then Cr := Nil;
			end;
		end;
	until (SC^.PC^.LastCmd = KMap[26].Key) or (SC^.PC^.HP < 1);

	if SC^.PC^.HP < 1 then begin
		DCGameMessage('Game Over.');
		GamePause;

		FName := FSearch( SC^.PC^.Name + '.txt' , 'savegame\' );
		if ( FName <> '' ) and PLAY_DangerOn then begin
			Assign(F,FName);
			Erase(F);
		end;
	end;

	DisposeScenario(SC);
end;

Procedure StartGame;
	{ Begin a new game. Generate a character, make a level, etc. }
	{ Pass all info on to the PLAYSCENE procedure above. If character }
	{ creation is cancelled, or for some reason isn't successful, }
	{ exit this procedure without calling PLAYSCENE. }
var
	SC: ScenarioPtr;
begin
	SC := NewScenario;
	ResetLogon;

	SC^.PC := RollNewChar;
	if SC^.PC = Nil then begin
		DisposeScenario(SC);
		Exit;
	end;

	SC^.Loc_Number := 1;

	GotoLevel( SC , 1 , PilotsChair );

	SaveGame( SC );
	PlayScene( SC );
end;

Procedure RestoreGame;
	{ Load a saved game file from the SAVEGAME directory. }
	{ If this action is cancelled, return to the main menu. }
	{ If there are no files to load, call the STARTGAME procedure. }
	{ Otherwise, pass the scenario data on to PLAYSCENE. }
var
	RPM: RPGMenuPtr;
	FName: String;
	SC: ScenarioPtr;
begin
	{ Create the menu. }
	RPM := CreateRPGMenu( LightBlue , Green , LightGreen , 20 , 8 , 60 , 23 );
	BuildFileMenu( RPM , 'SAVEGAME\*.txt' );

	if RPM^.numitem < 1 then begin
		{ No save game files were found. Jump to STARTGAME, }
		{ after deallocating the empty menu... }
		DisposeRPGMenu( RPM );
		StartGame;

	end else begin
		{ Select a file, then dispose of the menu. }
		RPMSortAlpha( RPM );
		FName := SelectFile( RPM );
		DisposeRPGMenu( RPM );

		{ If selection was cancelled, just fall back out to the }
		{ main menu. Otherwise, load the file and pass the }
		{ scenario to PLAYSCENE. }
		if FName <> '' then begin
			SC := LoadGame( 'savegame\' + FName );
			PlayScene( SC );
		end;
	end;
end;

end.
