unit mdlogon;
	{When the PC accesses a computer terminal, this procedure}
	{is the one that's called.}

	{md stands for MajorDomo, the chief AI on DeadCold. It does not}
	{mean "Most Dangerous".}

interface

uses crt,cwords,gamebook,rpgtext,rpgmenus,dcchars,rpgdice,texmodel,texmaps,plotbase,statusfx;

Procedure MDSession( SC: ScenarioPtr; M: ModelPtr );


implementation

uses texutil;

const
	{ Station Map }
	NumMapRows = 11;
	StationMap: Array [1..NumMapRows] of String = (
	'   --- A ---',
	'  /    |    \',
	' B     |     H',
	'/      #      \',
	'|      #      |',
	'C    J-I-K    G',
	'|      #      |',
	'\      #      /',
	' D     |     F',
	'  \    |    /',
	'   --- E ---'
	);
	NumNamedLevels = 11;
	LevelLoc: Array[1..NumNamedLevels,1..2] of Byte = (
	(8,1),(2,3),(1,6),(2,9),(8,11),(14,9),(15,6),(14,3),(8,6),(6,6),(10,6)
	);
	LevelName: Array[1..NumNamedLevels] of String = (
		'A - Primary Research Module',
		'B - Monument Construction',
		'C - Visitor Center & Dock',
		'D - Theistic Services',
		'E - Forensic Laboratories',
		'F - Compsec & Life Support',
		'G - Cold Storage Module',
		'H - Processing & Industry',
		'I - Operations Control',
		'J - Deep Orbit Massdriver',
		'K - Navigational Control'
	);


	LevelDesc: Array[1..NumNamedLevels] of PChar = (
	'Deadcold is the galaxy''s foremost leader in the science of necrology. In this module, our scientists work hard to keep our edge.',
	'In this module lasting tributes to those who have passed on are created. Our workshops are equipped to create everything from marble tombs to self-sustaining cryogenic probes.',
	'This module is our visitor''s gateway to DeadCold. There are chapels, lounges, and bereavement counselors to welcome you to our station.',
	'DeadCold is proud to offer funerary rites according to over five hundred different planetary traditions. This module houses our denominational offices and chapels, as well as the DeadCold Cortege Museum.',
	'Our forensic research facilities are the best in the Eastmost Stellar March. Currently we are examining bug corpses obtained from the western Aradar war. Research has developed several new weapons which may prove particularly effective.',
	'This module houses the machinery which keeps our station running. It is also the station''s primary residential area, featuring the majority of the crew quarters.',
	'Located on the opposite side of the station from the visitor center, this module features DeadCold''s other docking bay. This is where our unliving clients first enter the station, and where they are kept until ready for processing.',
	'We are proud to offer a wide range of interrment options. This module holds the tools and machinery needed for embalming, cremation, preservation, excarnation, reprocessing, and harvesting.',
	'At the center of the station ring is DeadCold control center. Most administrative functions have been completely automated, requiring only minimal human supervision.',
	'The station mass driver is powered by a 120Gz gravitic coil. It can be used to place caskets in deep orbit burial, ship materials to nearby planets such as Mascan and Denoles, or to make corrections to the station''s orbit.',
	'This module houses the thrusters and verniers which help keep DeadCold in a stable orbit. It is also sometimes necessary to move the station, as solar flares and meteor storms could seriously damage our solar arrays.'
	);

	UCM_X1 = 5;
	UCM_Y1 = 7;
	UCM_X2 = 53;
	UCM_Y2 = 22;

	MCM_X1 = 55;
	MCM_Y1 = 14;
	MCM_X2 = 77;
	MCM_Y2 = 22;

Procedure ClearUCM;
	{ Cls on the UCM zone described above. }
begin
	Window( UCM_X1 , UCM_Y1 , UCM_X2 , UCM_Y2 );
	ClrScr;
	Window( 1 , 1 , 80 , 25 );
end;

Procedure DoMapDisplay;
	{ This procedure handles the map displayer. }
var
	MM: RPGMenuPtr;	{Map Menu}
	T,N: Integer;
begin
	{ Create the menu. }
	MM := CreateRPGMenu( Blue , Green , LightGreen , UCM_X1 + 19 , UCM_Y1 + 1 , UCM_X2 - 1 , UCM_Y2 - 1 );
	For t := 1 to NumNamedLevels do AddRPGMenuItem( MM , LevelName[ T ] , T );
	AddRPGMenuItem( MM , '  Exit' , -1 );

	{ Display the map itself }
	ClearUCM;
	Window( UCM_X1 , UCM_Y1 , UCM_X2 , UCM_Y2 );
	TextColor( Green );
	for t := 1 to NumMapRows do begin
		GotoXY( 3 , T + 2 );
		write( StationMap[T] );
	end; 
	window( 1 , 1 , 80 , 25 );

	{ Enter the main loop. Keep processing until an Exit is recieved. }
	repeat
		N := SelectMenu( MM , RPMNormal );

		if N <> -1 then begin
			GotoXY( UCM_X1 + LevelLoc[ N , 1 ] + 1 , UCM_Y1 + LevelLoc[ N , 2 ] + 1 );
			TextColor( Yellow );
			write( LevelName[ N ][1] );

			GameMessage( LevelDesc[N] , UCM_X1 + 19 , UCM_Y1 + 1 , UCM_X2 - 1 , UCM_Y2 - 1 , Green , Blue );
			rpgkey;

			GotoXY( UCM_X1 + LevelLoc[ N , 1 ] + 1 , UCM_Y1 + LevelLoc[ N , 2 ] + 1 );
			TextColor( Green );
			write( LevelName[ N ][1] );
		end;
	until N = -1;

	{ Get rid of the menu. }
	DisposeRPGMenu( MM );
end;

Procedure TexBrowser( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer; Cap: String );
	{ This computer apparently has a list of text messages which the }
	{ player might or might not be able to access. }
	procedure PrintCap( msg: String );
	var
		X: Integer;
	begin
		window( UCM_X1 , UCM_Y1 , UCM_X2 , UCM_Y1 + 2 );
		ClrScr;
		LovelyBox( Blue , 3 , 1 , UCM_X2 - UCM_X1 - 2 , 3 );
		TextColor( Green );
		X := ( UCM_X2 - UCM_X1 - Length( msg ) ) div 2;
		if X < 1 then X := 1;
		GotoXY( X , 2 );
		write( msg );
		window( 1 , 1 , 80 , 25 );
	end;
var
	TBM: RPGMenuPtr;
	S: String;
	N: Integer;
begin
	{ Prepare the display. }
	ClearUCM;

	{ Create the menu. The items this menu will have in it are determined }
	{ by the SEC score that the player achieved. }
	TBM := CreateRPGMenu( Black , Green , LightGreen , UCM_X1 , UCM_Y1 + 3 , UCM_X2 , UCM_Y2 );
	S := MP^.Attr;
	while S <> '' do begin
		N := ExtractValue( S );
		if ( N > 0 ) and ( N <= NumTex ) then begin
			{ Only add those messages for which the player }
			{ has obtained clearance. }
			if TexMan[N].clearance <= Sec then AddRPGMenuItem( TBM , TexMan[N].Title , N );
		end;
	end;
	RPMSortAlpha( TBM );

	{ If the player does not have clearance to see any messages at }
	{ all, show a brief message then exit this procedure. }
	if TBM^.NumItem < 1 then begin
		PrintCap( 'NO AVALIABLE MESSAGES' );
		rpgkey;
		DisposeRPGMenu( TBM );
		exit;
	end;

	repeat
		PrintCap( Cap );
		N := SelectMenu( TBM , RPMNormal );

		if N > -1 then begin
			PrintCap( TexMan[N].title );
			GameMessage( TexMan[N].msg , UCM_X1 , UCM_Y1 + 3 , UCM_X2 , UCM_Y2 , Green , Black );
			rpgkey;

			if not TexMan[N].used then begin
				TexMan[N].used := True;
				DoleExperience( SC , TexMan[N].XPV );
			end;
		end;
	until N = -1;

	{ Get rid of the menu. }
	DisposeRPGMenu( TBM );
end;

Procedure DoInfoKiosk( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer );
	{ This computer contains a list of TEX messages. If the player }
	{ has the correct security clearance, let her see them. }
const
	NumLogoRows = 10;
	LogoWidth = 38;
	DCLogo: Array [1..NumLogoRows] of String = (
	'            ..',
	'           .%%.',
	'          .%##%.',
	'         .%%##%%.',
	'        .%#!''''!#%.',
	'       .%#%!..!##%.     ::. .:: :  :::',
	'      .%#%#%##%%##%.    : : :   : ::''',
	'     .%#%#%#%#%#%##%.   : : :   :  .::',
	'    .%#%#%#%#%#%#%##%.  ::'' '':: : :::',
	'     ----------------'
	);
var
	IKM: RPGMenuPtr;
	N: Integer;
begin
	{ Create the menu. }
	IKM := CreateRPGMenu( Black , Green , LightGreen , UCM_X1 , UCM_Y2 - 4 , UCM_X2 , UCM_Y2 );
	AddRPGMenuItem( IKM , 'Public Service Messages' , 2 );
	AddRPGMenuItem( IKM , 'Station Map' , 1 );

	repeat
		{ Set up the display. }
		ClearUCM;
		TextColor( Green );
		for N := 1 to NumLogoRows do begin
			GotoXY( ( UCM_X1 + UCM_X2 - LogoWidth ) div 2 , UCM_Y1 + N );
			write( DCLogo[ N ] );
		end;

		N := SelectMenu( IKM , RPMNoCleanup );

		case N of
			1:	DoMapDisplay;
			2:	TexBrowser( SC , MP , Sec , 'STATION NEWS' );
		end;
	until N = -1;

	{ Freeze the display, and dispose of the menu. }
	DisplayMenu( IKM );
	DisposeRPGMenu( IKM );
end;

Procedure DoCrashedTerminal;
	{ Simulate a crashed & nonfunctioning terminal. }
const
	msg: PChar = 'System Error 255 Main interface unit is offline';
begin
	GameMessage( msg , UCM_X1 + 10 , UCM_Y1 + 5 , UCM_X2 - 10 , UCM_Y2 - 5 , LightRed , LightRed );
end;

Procedure DoMedUnit( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer );
	{ The medical unit is the player character's best friend. It will }
	{ heal all injuries and status conditions instantly... until the }
	{ player crashes it by trying to hack the medical database, that is. }
	Procedure HealAllInjuries;
		{ The medical terminal is going to fix everything that is }
		{ wrong with the PC. }
	var
		SFX,SF2: NAttPtr;	{ For removing status changes. }
	begin
		DCGameMessage( 'Your injuries are treated by the medical unit.');
		SC^.PC^.HP := SC^.PC^.HPMax;
		SFX := SC^.PC^.SF;
		while SFX <> Nil do begin
			SF2 := SFX^.Next;
			if ( SFX^.G = NAG_StatusChange ) and ( SFX^.S < 0 ) then begin
				RemoveNAtt( SC^.PC^.SF , SFX );
			end;
			SFX := SF2;
		end;
		PCStatLine( SC );
	end;
var
	RPM: RPGMenuPtr;
	N: Integer;
begin
	RPM := CreateRPGMenu( Red , Red , LightRed , UCM_X1 + 2 , UCM_Y1 + 2 , UCM_X2 - 2 , UCM_Y2 - 2 );
	AddRPGMenuItem( RPM , 'Treat Injuries' , 1 );
	AddRPGMenuItem( RPM , 'View Records' , 2 );
	AddRPGMenuItem( RPM , 'Standby Mode' , -1 );

	repeat
		N := SelectMenu( RPM , RPMNoCleanup );

		case N of
			1:	HealAllInjuries;
			2:	TexBrowser( SC , MP , Sec , 'MEDICAL RECORDS' );
		end;

	until N = -1;

	DisposeRPGMenu( RPM );
end;

Procedure DoMorgan( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer );
	{ The player is accessing primary server MORGAN. }
	Procedure PowerAllocation;
	var
		PAM: RPGMenuPtr;
		N: Integer;
	begin
		PAM := CreateRPGMenu( DarkGray , Blue , LightBlue , UCM_X1 + 2 , UCM_Y1 + 2 , UCM_X2 - 2 , UCM_Y2 - 2 );
		AddRPGMenuItem( PAM , 'Module "B" Emergency Power: Security' , 0 );
		AddRPGMenuItem( PAM , 'Module "B" Emergency Power: Cryogenics' , 0 );
		AddRPGMenuItem( PAM , 'Module "B" Emergency Power: Infratap' , 0 );
		AddRPGMenuItem( PAM , 'Module "B" Emergency power: Life Support' , 1 );
		AddRPGMenuItem( PAM , 'Module "B" Emergency Power: Network' , 0 );
		N := SelectMenu( PAM , RPMNoCancel );
		DisposeRPGMenu( PAM );
		SetNAtt( SC^.NA , NAG_ScriptVar , 2 , N );
	end;
var
	RPM: RPGMenuPtr;
	N: Integer;
begin
	RPM := CreateRPGMenu( DarkGray , Magenta , LightMagenta , UCM_X1 + 2 , UCM_Y1 + 2 , UCM_X2 - 2 , UCM_Y2 - 2 );
	AddRPGMenuItem( RPM , 'Power Allocation' , 1 );
	AddRPGMenuItem( RPM , 'Mail Core Memory' , 2 );
	AddRPGMenuItem( RPM , 'Log Off' , -1 );

	repeat
		N := SelectMenu( RPM , RPMNoCleanup );

		case N of
			1:	PowerAllocation;
			2:	TexBrowser( SC , MP , Sec , 'MEDICAL RECORDS' );
		end;

	until N = -1;

	DisposeRPGMenu( RPM );
end;

Procedure DoDesCartes( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer );
	{ The player is accessing primary server DESCARTES. }
	Procedure EmergencyStatus;
	var
		RPM: RPGMenuPtr;
		N: Integer;
	begin
		{ Determine current alert status, and create menu accordingly. }
		N := NAttValue( SC^.NA , NAG_ScriptVar , 4 );
		Case N of
			1: RPM := CreateRPGMenu( LightRed , Cyan , Yellow , UCM_X1 + 3 , UCM_Y1 + 3 , UCM_X2 - 3 , UCM_Y2 - 3 );
			0: RPM := CreateRPGMenu( Yellow , Cyan , Yellow , UCM_X1 + 3 , UCM_Y1 + 3 , UCM_X2 - 3 , UCM_Y2 - 3 );
			else RPM := CreateRPGMenu( LightGreen , Cyan , Yellow , UCM_X1 + 3 , UCM_Y1 + 3 , UCM_X2 - 3 , UCM_Y2 - 3 );
		end;

		AddRPGMenuItem( RPM , 'Alert Status: Red' , 2 );
		AddRPGMenuItem( RPM , 'Alert Status: Yellow' , 1 );
		AddRPGMenuItem( RPM , 'Alert Status: Green' , 0 );

		N := SelectMenu( RPM , RPMNormal );
		DisposeRPGMenu( RPM );


		if ( N > -1 ) and ( Sec > 0 ) then begin
			DCGameMessage( 'Alert status changed.' );
			SetNAtt( SC^.NA , NAG_ScriptVar , 4 , N - 1 );

			{ If the alert has been turned off, set the trigger. }
			if N = 0 then begin
				SetTrigger( SC , 'GotoTURNOFFFIELD' );

			{ If, on the other hand, the player set red alert... }
			{ alert all robots. }
			end else if N = 2 then begin
				SetTrigger( SC , 'ALARM' );

			end;

		end else if Sec = 0 then begin
			{ Lock up the terminal, then exit with an alarm. }
			DCGameMessage( 'Denied! Unauthorized use of security systems is prohibited.' );
			MP^.Attr := 'X' + MP^.Attr;
			SetTrigger( SC , 'ALARM' );

		end;
	end;
var
	RPM: RPGMenuPtr;
	N: Integer;
begin
	RPM := CreateRPGMenu( Green , Cyan , Yellow , UCM_X1 + 2 , UCM_Y1 + 2 , UCM_X2 - 2 , UCM_Y2 - 2 );
	AddRPGMenuItem( RPM , 'Emergency Status' , 1 );
	AddRPGMenuItem( RPM , 'Mail Core Memory' , 2 );
	AddRPGMenuItem( RPM , 'Log Off' , -1 );

	repeat
		N := SelectMenu( RPM , RPMNoCleanup );

		case N of
			1:	EmergencyStatus;
			2:	TexBrowser( SC , MP , Sec , 'MEDICAL RECORDS' );
		end;

	until ( N = -1 ) or ( MP^.Attr[1] = 'X' );

	DisposeRPGMenu( RPM );
end;


Procedure DoUserTerminal( SC: ScenarioPtr; MP: MPUPtr; Sec: Integer );
	{ The player wants to use the user terminal. Branch to an appropriate }
	{ procedure. }
begin
	{ If this terminal has locked up, it cannot be used. }
	if MP^.Attr[1] = 'X' then begin
		DoCrashedTerminal;
	end else begin
		case MP^.Kind of
			1:	DoInfoKiosk( SC , MP , Sec );
			2:	DoMedUnit( SC , MP , Sec );
			3:	DoMorgan( SC , MP , Sec );
			4:	DoDescartes( SC , MP , Sec );
		end;
	end;
end;

Procedure AttemptHack( SC: ScenarioPtr; MP: MPUPtr; var Sec: Integer );
	{ The player wants to hack this terminal. Give it a try, and hope }
	{ there are no disasterous results... }
var
	T,N,R: Integer;
begin
	DCGameMessage( 'Attempting to hack ' + MPUMan[ MP^.Kind ].Name + '...' );

	{ Do the animation for hacking. }
	window( MCM_X1 + 1 , MCM_Y1 + 1 , MCM_X2 - 1 , MCM_Y2 - 1 );
	ClrScr;
	TextColor( Blue );
	N := Random(250) + 250;
	for t := 1 to N do write( HexStr( Random( 256 ) , 2 ) + ' ' );
	Delay( FrameDelay );
	N := Random(250) + 250;
	for t := 1 to N do write( HexStr( Random( 256 ) , 2 ) + ' ' );
	Delay( FrameDelay );

	{ Actually figure out if it worked. }
	R := RollStep( PCTechSkill( SC^.PC ) );
	T := Sec + MPUMan[MP^.Kind].SecPass;
	if ( R > MPUMan[MP^.Kind].SecPass ) and ( R > T ) then begin
		DCAppendMessage( ' You did it.' );
		Sec := R - MPUMan[MP^.Kind].SecPass;
	end else begin
		DCAppendMessage( ' You failed.' );
		if R < ( T - 5 ) then begin
			MP^.Attr := 'X' + MP^.Attr;
			if R < ( T - 10 ) then SetTrigger( SC , 'ALARM' );
		end;
	end;
end;

Procedure MDSession( SC: ScenarioPtr; M: ModelPtr );
	{ A computer session has two component windows: The metacontrol }
	{ window, in the lower right of the screen, and the main display }
	{ window in the center. }
var
	MP: MPUPtr;
	MCM: RPGMenuPtr;	{ MetaControl Menu }
	Sec,N: Integer;
begin
	{ Set up the display. }
	ClearMapArea;
	LovelyBox( White , UCM_X1-1 , UCM_Y1 - 1 , UCM_X2 + 1 , UCM_Y2 + 1 );

	{ Find the computer we want. }
	MP := SC^.Comps;
	while ( MP <> Nil ) and ( MP^.M <> M ) do MP := MP^.Next;
	if MP = Nil then Exit;

	{ Tell the player what he's doing. }
	DCGameMessage( 'Using ' + MPUMan[ MP^.Kind ].Name + '.' );


	{ Create MetaControl Menu }
	MCM := CreateRPGMenu( LightGray , Blue , Cyan , MCM_X1 , MCM_Y1 , MCM_X2 , MCM_Y2 );
	AddRPGMenuItem( MCM , 'Access Terminal' , 1 );
	AddRPGMenuItem( MCM , 'Hack Logon System' , 2 );
	AddRPGMenuItem( MCM , 'Disconnect' , -1 );

	{ Initialize Security Clearance. }
	Sec := 0;

	{ Start the main access loop. }
	repeat
		{ Start with the user terminal itself. }
		DisplayMenu( MCM );
		DoUserTerminal( SC , MP , Sec );

		{ Once the user terminal is exited, access metacontrol. }
		repeat
			N := SelectMenu( MCM , RPMNoCleanup );

			{ If the player wants to make a hacking attempt, do that here. }
			if N = 2 then AttemptHack( SC , MP , Sec );
		until N <> 2;
	until N = -1;

	DisposeRPGMenu( MCM );
	DisplayMap( SC^.gb );
end;

initialization
	ResetLogon;

end.
