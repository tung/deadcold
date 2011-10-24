unit plotline;
	{This unit handles storyline development in our RL.}
	{Specifically, it handles the scripting language which}
	{will be used to control everything.}

	{ See plotref.txt for info on the scripting language used. }

interface

uses plotbase,rpgtext,dcitems,critters,gamebook,texutil,randmaps,texmodel,texmaps,dcchars,dccombat;

const
	NumCPL = 25;
	PLConstant: Array [1..NumCPL] of String = (
	{ Attempting to ">" the cryogenic capsule. }
	'EN45 <ifYN CRYO1 else GotoLEAVECRYO print CRYO3 print CRYO4 print CRYO5>',
	'gotoLEAVECRYO <print CRYO2>',
	'msgCRYO1 <Do you want to lie down in the cryonic casket?>',
	'msgCRYO2 <You leave the casket, unwilling at this point to turn yourself into a meat popsicle.>',
	'msgCRYO3 <You lie down in the casket and close the lid...>',
	'msgCRYO4 <...>',
	'msgCRYO5 <Nothing happens. You get back out.>',

	{When the CORPSE is first seen, it attacks the PC.}
	'NC3 <Alert @>',

	{Transitway door handler.}
	'EN32 <ifkey 1 else GotoSorryNoPasscard GoLeft>',
	'EN33 <ifkey 1 else GotoSorryNoPasscard GoRight>',
	'GOTOSORRYNOPASSCARD <print SorryMsg>',
	'MSGSORRYMSG <Unregistered personnel may not use the transit system. Access Denied.>',

	{ Pilots chair handler. }
	'EN21 <print PilotChair>',
	'MSGPILOTCHAIR <Your ship''s computer has stopped working. None of the systems will respond to your commands.>',

	{ Toilet Humor. }
	'EN38 <if= V1 2 else GotoTH2 V= 1 3 print ToiletHumor1>',
	'GotoTH2 <print ToiletHumor2>',
	'msgToiletHumor1 <You use the toilet. You feel better.>',
	'msgToiletHumor2 <You already did that. You don''t have to any more.>',

	{ When the alarm goes off, notify all robots and zombies. }
	'ALARM <Alert R Alert @>',

	{ Reliquary door plaques }
	'MS3 <Print Reliquary1>',
	'MS4 <Print Reliquary2>',
	'MS5 <Print Reliquary3>',
	'msgRELIQUARY1 <A plaque on the door reads "IN HOC SALUS".>',
	'msgRELIQUARY2 <A plaque on the door reads "MEMENTO MORI".>',
	'msgRELIQUARY3 <A plaque on the door reads "TO THE FATHERS".>'


	);

Procedure HandleTriggers(SC: ScenarioPtr);



implementation

Function SeekCPlot( Trigger: String ): String;
	{ Try to find an event matching TRIGGER in the constant plotline }
	{ section. Since the global plotlines are an array of strings, }
	{ not a list of SAtts, we can't use the SAtt procedures to }
	{ search through them. }
var
	it,S: String;
	T: Integer;
begin
	{ Initialize IT, and make sure the trigger is all uppercase. }
	Trigger := UpCase( Trigger );
	it := '';

	{ Go through the constant scripts. }
	for t := 1 to NumCPL do begin
		S := PLConstant[ T ];
		S := UpCase( ExtractWord( S ) );

		{ Retrieve the bits from inside the alligator brackets. }
		if S = Trigger then it := RetrieveAString( PLConstant[ T ] );
	end;

	SeekCPlot := it;
end;

Function LocateEvent( SC: ScenarioPtr; Trigger: String ): String;
	{ This function will attempt to find an event matching TRIGGER. }
	{ Order of searching is Local List, then Global List, then }
	{ Constant List. The first event which matches the specified }
	{ trigger is returned. }
var
	it: String;
begin
	it := SAttValue( SC^.PLLocal , Trigger );
	if it = '' then it := SAttValue( SC^.PLGlobal , Trigger );
	if it = '' then it := SeekCPlot( Trigger );
	LocateEvent := it;
end;

Function PlayVal_Leakage( SC: ScenarioPtr ): Integer;
	{ Return a Leakage value for the PC, in the range of 0 to 10. }
	{ A low value indicates that more of the PC's armor is airtight; }
	{ a high value indicates that the PC really ought to invest in }
	{ some scuba gear or something. }
var
	Leak: Integer;
begin
	Leak := 0;

	{ The helmet contributes 5 leakage points, the body 3, the arms and }
	{ legs one each. }
	if ( SC^.PC^.Eqp[ ES_Head ] = Nil ) or ( not CCap[ SC^.PC^.Eqp[ ES_Head ]^.icode ].Sealed ) then begin
		Leak := Leak + 5;
	end;

	if ( SC^.PC^.Eqp[ ES_Body ] = Nil ) or ( not CArmor[ SC^.PC^.Eqp[ ES_Body ]^.icode ].Sealed ) then begin
		Leak := Leak + 3;
	end;

	if ( SC^.PC^.Eqp[ ES_Hand ] = Nil ) or ( not CGlove[ SC^.PC^.Eqp[ ES_Hand ]^.icode ].Sealed ) then begin
		Leak := Leak + 1;
	end;

	if ( SC^.PC^.Eqp[ ES_Foot ] = Nil ) or ( not CShoe[ SC^.PC^.Eqp[ ES_Foot ]^.icode ].Sealed ) then begin
		Leak := Leak + 1;
	end;

	PlayVal_Leakage := Leak;
end;

Function ScriptValue( var Event: String; SC: ScenarioPtr ): LongInt;
	{ Normally, numerical values will be stored as constants. }
	{ Sometimes we may want to do algebra, or use the result of }
	{ scenario variables as the parameters for commands. That's }
	{ what this function is for. }
var
	VCode: Integer;
	SV: LongInt;
	SMsg: String;
begin
	SMsg := ExtractWord( Event );
	SV := 0;

	{ If the first character is one of the value commands, }
	{ process the string as appropriate. }
	if ( UpCase( SMsg[1] ) = 'V' ) then begin
		{ Use the contents of a variable instead of a constant. }
		DeleteFirstChar( SMsg );
		VCode := ExtractValue( SMsg );
		SV := NAttValue( SC^.NA , NAG_ScriptVar , VCode );

	end else if ( UpCase( SMsg[1] ) = 'P' ) then begin
		{ Use one of the Player values instead of a constant. }
		DeleteFirstChar( SMsg );
		if UpCase( SMsg[1] ) = 'L' then begin
			SV := PlayVal_Leakage( SC );
		end;

	end else begin
		{ No command was given, so this must be a constant value. }
		SV := ExtractValue( SMsg );
	end;

	ScriptValue := SV;
end;

Procedure ProcessPrint( var Event: String; SC: ScenarioPtr );
	{ Locate and then print the specified message. }
var
	l: String;
	msg: String;
begin
	{ find out the label of the message to print. }
	L := ExtractWord( Event );

	{ Locate the message from the SCENE variable. }
	msg := LocateEvent( SC , 'MSG' + L );

	{ If such a message exists, print it. }
	if msg <> '' then begin
		DCGameMessage( msg );
		GamePause;
	end;
end;

Procedure ProcessVarEquals( var Event: String; SC: ScenarioPtr );
	{ The script is going to assign a value to one of the scene }
	{ variables. }
var
	idnum: Integer;
	value: LongInt;
begin
	{ Find the variable ID number and the value to assign. }
	idnum := ScriptValue( event , SC );
	value := ScriptValue( event , SC );

	SetNAtt( SC^.NA , NAG_ScriptVar , idnum , value );
end;

Procedure ProcessVarPlus( var Event: String; SC: ScenarioPtr );
	{ The script is going to add a value to one of the scene }
	{ variables. }
var
	idnum: Integer;
	value: LongInt;
begin
	{ Find the variable ID number and the value to assign. }
	idnum := ScriptValue( event , SC );
	value := ScriptValue( event , SC );

	AddNAtt( SC^.NA , NAG_ScriptVar , idnum , value );
end;

Procedure IfSuccess( var Event: String );
	{ An IF call has generated a "TRUE" result. Just get rid of }
	{ any ELSE clause that the event string might still be holding. }
var
	cmd: String;
begin
	{ Extract the next word from the script. }
	cmd := ExtractWord( Event );

	{ If the next word is ELSE, we have to also extract the label. }
	{ If the next word isn't ELSE, better re-assemble the line... }
	if UpCase( cmd ) = 'ELSE' then ExtractWord( Event )
	else Event := cmd + ' ' + Event;
end;

Procedure IfFailure( var Event: String; SC: ScenarioPtr );
	{ An IF call has generated a "FALSE" result. See if there's }
	{ a defined ELSE clause, and try to load the next line. }
var
	cmd: String;
begin
	{ Extract the next word from the script. }
	cmd := ExtractWord( Event );

	if UpCase( cmd ) = 'ELSE' then begin
		{ There's an else clause. Attempt to jump to the }
		{ specified script line. }
		cmd := ExtractWord( Event );
		Event := LocateEvent( SC , CMD );

	end else begin
		{ There's no ELSE clause. Just cease execution of this }
		{ line by setting it to an empty string. }
		Event := '';
	end;
end;

Procedure ProcessIfEqual( var Event: String; SC: ScenarioPtr );
	{ Two values are supplied as the arguments for this procedure. }
	{ If they are equal, that's a success. }
var
	a,b: LongInt;
begin
	{ Determine the two values. }
	A := ScriptValue( Event , SC );
	B := ScriptValue( Event , SC );

	if A = B then IfSuccess( Event )
	else IfFailure( Event , SC );
end;

Procedure ProcessIfGreater( var Event: String; SC: ScenarioPtr );
	{ Two values are supplied as the arguments for this procedure. }
	{ If the first is biggest, that's a success. }
var
	a,b: LongInt;
begin
	{ Determine the two values. }
	A := ScriptValue( Event , SC );
	B := ScriptValue( Event , SC );

	if A > B then IfSuccess( Event )
	else IfFailure( Event , SC );
end;

Procedure ProcessIfKeyItem( var Event: String; SC: ScenarioPtr );
	{Check to see whether or not the PC has a}
	{certain Key Item.}
var
	i: Integer;
begin
	{Extract the item number, and increase C.}
	I := ScriptValue( Event , SC);

	if HasItem(SC^.PC^.inv,IKIND_KeyItem,I) then IfSuccess( Event )
	else IfFailure( Event , SC );
end;

Procedure ProcessIfYesNo( var Event: String; SC: ScenarioPtr );
	{ Two values are supplied as the arguments for this procedure. }
	{ If the first is biggest, that's a success. }
var
	L,msg: String;
begin
	{ find out the label of the prompt to print. }
	L := ExtractWord( Event );

	{ Locate the message from the SCENE variable. }
	msg := LocateEvent( SC , 'MSG' + L );

	{ If such a message exists, print it. }
	if msg <> '' then begin
		DCGameMessage( msg + ' (Y/N)' );
	end else begin
		DCGameMessage( 'Yes or No? (Y/N)' );
	end;

	{ Check for success or failure. }
	if YesNo then IfSuccess( Event )
	else IfFailure( Event , SC );
end;


Procedure ProcessAlertCritters( var Event: String; SC: ScenarioPtr );
	{Alert all critters of the given type to}
	{the PC's presence.}
var
	CType: String;
	CTemp: CritterPtr;
begin
	{ Find out what sort of critter to alert. }
	CType := ExtractWord( Event );

	{ If the parameter was supplied, go on to alert those critters. }
	if CType <> '' then begin
		CTemp := SC^.CList;
		while CTemp <> Nil do begin
			if CTemp^.M^.gfx = CType[1] then CTemp^.Target := SC^.PC^.M;
			CTemp := CTemp^.Next;
		end;
	end;
end;

Procedure ProcessGoLeft( SC: ScenarioPtr );
	{ The PC is taking a transitway counterclockwise around one of }
	{ the station rings. }
var
	NewLevel: Integer;
begin
{ Right now, since only two levels are "stocked", restrict travel. }
{ Comment out actual code. }
{	NewLevel := SC^.Loc_Number + 1;
	if NewLevel > 8 then NewLevel := 1; }

	Case SC^.Loc_number of
		1:	NewLevel := 2;
		2:	NewLevel := 8;
		else NewLevel := 1;
	end;

	GotoLevel( SC , NewLevel , 33 );
	DisplayMap( SC^.GB );
end;

Procedure ProcessGoRight( SC: ScenarioPtr );
	{ The PC is taking a transitway clockwise around one of }
	{ the station rings. }
var
	NewLevel: Integer;
begin
{ See above for comments. }
{	NewLevel := SC^.Loc_Number - 1;
	if NewLevel < 1 then NewLevel := 8;
}
	Case SC^.Loc_number of
		1:	NewLevel := 8;
		8:	NewLevel := 2;
		else NewLevel := 1;
	end;


	GotoLevel( SC , NewLevel , 32 );
	DisplayMap( SC^.GB );
end;

Procedure ProcessChoke( SC: ScenarioPtr );
	{ The PC is suffocating to death! }
const
	ChokeMsg: Array [0..5] of String = (
		'You''re choking!',
		'You can''t breathe!',
		'You''re suffocating!',
		'The air is too thin... you are passing out.',
		'You begin to gasp for breath.',
		'Your lungs scream for air.'
	);
var
	dmg: Integer;
	dead: Boolean;
begin
	{ Start by printing a jovial message to let the PC know what's going on. }
	DCGameMessage( ChokeMsg[ Random( 6 ) ] );
	SC^.PC^.RepCount := 0;

	{ Roll damage, then deal it out. }
	DMG := Random( 5 ) + Random( 5 ) + 2;
	dead := DamagePC( SC , 4 , '' , DMG );

	GamePause;

	if dead then begin
		DCAppendMessage( 'You die...' );
	end;
end;

Procedure ProcessChangeTerr( var Event: String; SC: ScenarioPtr );
	{ Change Terrain1 into Terrain2 all over the map. }
var
	T1,T2,X,Y: LongInt;
begin
	{ Determine the two terrain values. }
	T1 := ScriptValue( Event , SC );
	T2 := ScriptValue( Event , SC );

	{ Actually change the terrain. }
	for X := 1 to XMax do begin
		for Y := 1 to YMax do begin
			if SC^.GB^.Map[X,Y].Terr = T1 then SC^.GB^.Map[X,Y].Terr := T2;
		end;
	end;
end;

Procedure InvokeEvent( Event: String; SC: ScenarioPtr );
	{ Do whatever is requested by game script EVENT. }
var
	cmd: String;
begin
	{ Keep processing the EVENT until we run out of commands. }
	while Event <> '' do begin
		cmd := UpCase( ExtractWord( Event ) );

		if cmd = 'PRINT' then ProcessPrint( Event , SC )
		else if cmd = 'V=' then ProcessVarEquals( Event , SC )
		else if cmd = 'V+' then ProcessVarPlus( Event , SC )
		else if cmd = 'IF=' then ProcessIfEqual( Event , SC )
		else if cmd = 'IFG' then ProcessIfGreater( Event , SC )
		else if cmd = 'IFKEY' then ProcessIfKeyItem( Event , SC )
		else if cmd = 'IFYN' then ProcessIfYesNo( Event , SC )
		else if cmd = 'ALERT' then ProcessAlertCritters( Event , SC )
		else if cmd = 'GOLEFT' then ProcessGoLeft( SC )
		else if cmd = 'GORIGHT' then ProcessGoRight( SC )
		else if cmd = 'CHOKE' then ProcessChoke( SC )
		else if cmd = 'CHANGETERR' then ProcessChangeTerr( Event , SC );


	end;
end;


Procedure HandleTriggers(SC: ScenarioPtr);
	{Handle all of the accumulated triggers.}

	{Here's how the system works. Certain PC actions can cause}
	{special plot events to take place; any time the PC performs}
	{such an action, a "trigger" message is added to the list.}
	{This procedure checks the triggers which have accumulated since}
	{last call and sees if there's a special event attached to any}
	{of them. Triggers without special effects are ignored.}

	{Check all the PArc lists (local, global,}
	{and constant) to see if there's an effect which matches the}
	{trigger. As soon as a match is found, execute the PArc string.}
	{Do this for all of the triggers. Once finished, deallocate the}
	{trigger list.}
var
	TP: SAttPtr;	{ Trigger Pointer }
	E: String;
	StartLevel: Integer;	{ Check to see if the level changed. }
begin
	{ Record the level the PC started on. }
	StartLevel := SC^.Loc_Number;

	TP := SC^.PLTrig;
	while TP <> Nil do begin
		{ If there is a SAtt in the scenario description }
		{ named after this trigger description, it will }
		{ happen now. First, see if such an event exists. }
		E := LocateEvent( SC , TP^.Info );
		if E <> '' then InvokeEvent( E , SC );

		TP := TP^.Next;
	end;

	{ Finally, dispose of the list of triggers. }
	DisposeSAtt( SC^.PLTrig );

	{ If the Start Level and current level aren't the same, need to add }
	{ a "START" trigger. }
	if StartLevel <> SC^.Loc_Number then SetTrigger( SC , 'START' );
end;


end.
