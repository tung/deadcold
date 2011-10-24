unit RPGText;
	{ This started out as just the text handling unit, but I might }
	{ as well admit that it has grown into an all-encompassing game }
	{ environment unit. It handles text output, keyboard input, text }
	{ storage, configuration file support, and probably a few other }
	{ things I've forgotten. And it's still under a thousand lines }
	{ long, so it isn't really even worth splitting it up. }

interface

uses crt,strings,dos,texutil;

Type
	GKeyDesc = Record
		key,dkey: Char; {The KEY and DEFAULT KEY}
		name: String;	{The name of the command.}
		desc: PChar;	{A description of the command, for help}
	end;

	{ This record describes a computer text message. }
	TexDesc = Record
		title: String;
		msg: PChar;
		clearance,XPV: Integer;
		used: Boolean;
	end;

const
	NumTex = 29;
	Texman: Array [1..NumTex] of TexDesc = (
		(	title: '06/18/64 WARNING - SIDNEY JAMES WARNER';
			msg: 'Dr.S J Warner is wanted for questioning. CentSec has implicated him in the recent deaths of Twomas Draklor, Ed Patres and Moira Chak. Warner is a trained psycap and is thought to be carrying a weapon.';
			clearance: 1; XPV: 15;	),
		(	title: '04/12/64 MORGAN, DESCARTES, and THANATOS users';
			msg: 'DeadCold Central Server and Navcomp has been accessed by an intrusive alias. Please consult online documentation for more information.';
			clearance: 7; XPV: 1;	),
		(	title: '07/05/64 !!!ABANDON SHIP!!! CS N.Balordo';
			msg: 'Shut down Majordomo but outsider in core now. Nt much time. Pods may be corrupt. Get out. In secure room "K" deck- send res%#$ dhds v=4200 v2=16 v4=89711';
			clearance: 30; XPV: 25;	),
		(	title: '05/25/64 Software Upgrade Delayed';
			msg: 'The software upgrade which has been scheduled for the past few weeks has not yet been performed. There have been problems uninstalling the Sirius Intuition Interface from the Win2636 kernel.';
			clearance: 2; XPV: 2;	),
		(	title: '05/30/64 Software Upgrade Completed';
			msg: 'The scheduled upgrade to the station''s kernel OS has been finished. Please familiarize yourself with the new operating procedures.';
			clearance: 4; XPV: 2;	),

		(	title: '05/31/64 Software Patch to be Installed';
			msg: 'We apologize for the station-wide computer problems that users have been reporting today. CompSec is working on the problem. Thank you%443=2';
			clearance: 5; XPV: 3;	),
		(	title: '06/11/64 Shuttle Launch Schedule';
			msg: 'Ships to Denoles leave on Thursday, Saturday, and Tuesday at 15:00. Ships to Mascan leave on Wednesday, Friday, and Monday at the same time.';
			clearance: 0; XPV: 1;	),
		(	title: '05/07/64 Shuttle Launch Schedule';
			msg: 'Ships to Denoles leave on Thursday, Saturday, and Tuesday at 15:00. Ships to Mascan leave on Wednesday, Friday, and Monday at the same time.';
			clearance: 8; XPV: 1;	),
		(	title: '06/05/64 Alien Burial Chamber on Display';
			msg: '[AGUER] The Taltuo Collection will be on display at the museum on Deck "D" today. These items have been sent to DeadCold for catalogueing and analysis.';
			clearance: 0; XPV: 1;	),
		(	title: '06/07/64 No More Bugs!';
			msg: '[NBALO] This is Nick at CS 2 conf -> all bugs from OS upg have been fixed. Gentlemen, to your workstations! haha';
			clearance: 10; XPV: 2;	),

		(	title: '06/08/64 Delta Patch Being Shipped';
			msg: 'Due to recent computer failures, station management has ordered the costly "Delta Upgrade" package. It should arrive by freight transport in a week or two.';
			clearance: 14; XPV: 2;	),
		(	title: '06/10/64 ALERT - Meningitis Outbreak';
			msg: 'There have been several apparent cases of viral meningitis among crew members. Residents and visitors to the station are advised to have all water sources tested before use.';
			clearance: 0; XPV: 1;	),
		(	title: '05/17/64 Welcome to our visitors from Sendai! [AGUER]';
			msg: 'We would like to extend our hospitality to the Sendai Gravesite Society, and issue our hope that they have an interesting and educational visit.';
			clearance: 0; XPV: 1;	),
		(	title: '07/06/64 Sorry for the Inconvenience';
			msg: '[MD] We would like to apologize for several news bulletins recently made which were in error. There is no emergency on our station. Please report to security if you have any further concerns.';
			clearance: 20; XPV: 30;	),
		(	title: '05/33/64 Ferryman Destroyed in Transit';
			msg: '[TDRAK] While en route to DeadCold the shuttle craft "Ferryman" met with an accident and was lost in space. As it was an automated shuttle, no lives were lost. The 262 deceased on board are not expected to be recovered.';
			clearance: 0; XPV: 2;	),

		(	title: 'ANDROS GUERO';
			msg: 'Disrythmia: Atazine 15mg. Risk factor heart disease- reccomend more exercise.';
			clearance: 1; XPV: 1;	),
		(	title: 'TWOMAS DRAKLOR';
			msg: 'Deceased. Massive head trauma possibly caused by gunshot. Legs mutilated after time of death. Forensics report pending.';
			clearance: 7; XPV: 5;	),
		(	title: 'EDWARD PATRES';
			msg: 'Deceased. Blunt trauma over majority of body. Two incisions in lower abdomen. Forensics report pending.';
			clearance: 3; XPV: 5;	),
		(	title: 'MOIRA CHAK';
			msg: 'Deceased. Multiple stab wounds to body plus significant damage to head and face. Forensics report pending.';
			clearance: 5; XPV: 5;	),
		(	title: 'NICHOLAS BALORDO';
			msg: 'Hypertension: Nerve Relaxants 15mg. Stress: Counseling reccomended.';
			clearance: 1; XPV: 1;	),

		(	title: 'SIDNEY JAMES WARNER';
			msg: 'Arthritis in 85% of bone mass: Solenol pain medicene 8mg, Anti-inflammatory tablets 16mg. Cybernetic replacement may be only option.';
			clearance: 10; XPV: 15;	),
		(	title: 'DAEYOUNG PARK';
			msg: 'Ulcer, acid reflux. Stomach condition aggrevated by not following diet.';
			clearance: 1; XPV: 1;	),
		(	title: '[NBALO:>MD] Primary Generator Failed';
			msg: 'The primary power generator has gone down; switching emergency power to cryogenics & ordering an evacuation.';
			clearance: 0; XPV: 5;	),
		(	title: '[TDRAK:>NBALO] Security Upgrade';
			msg: 'Find out why our defense lasers targeted "FERRYMAN" as a hostile craft. We can''t afford for this kind of accident to happen again.';
			Clearance: 5; XPV: 150;	),
		(	title: '[DPARK:>CTOMS] Re:TS involved in AI?';
			msg: 'With regards to your recent inquiries, I do not believe that this is a case where it is nessecary to presuppose the existance of spirit (or even consciousness) to find the results of the "Ventrue" experiments useful.';
			Clearance: 1; XPV: 10;	),

		(	title: '[MCHAK:>SWARN] DK17 Discrepency';
			msg: 'RE. the missing sample of DK17, it doesn''t appear to have been transferred to our lab. Hades wouldn''t turn over sensor reports for A-Mod so I''m afraid I can''t be of any more help. Ask Twomas.';
			Clearance: 3;	XPV: 15;	),
		(	title: '[SWARN:>TDRAK] Sensor Logs "A" Module';
			msg: 'I need access to the sensor logs from JnIII to JnX. Hades claims security protocol, can''t you circumvent him?';
			Clearance: 7; XPV: 10;		),
		(	title: '06/05/64 Taltuo Artefacts now on display';
			msg: 'Several of the treasures recovered from the Taltuo burial site are now on display in the main hall.';
			Clearance: 0; XPV: 0;		),
		(	title: '06/17/64 Museum Closed due to Infestation';
			msg: 'A recent shipment of ancient scrolls was infested with Algolian Dust-Jellies. The museum will remain in quarantine until this problem has been dealt with.';
			Clearance: 0; XPV: 0;		)
	);


	DebugCode: Integer = 0;

	DCBulletColor = Green;
	DCTextColor = LightGreen;
	DCTextBox_X1 = 1;
	DCTextBox_Y1 = 1;
	DCTextBox_X2 = 80;
	DCTextBox_Y2 = 3;

	{This is the location of the more message for GamePause.}
	MORE_X = DCTextBox_X2 - 5;
	MORE_Y = DCTextBox_Y2;
	MORE_Color = LightBlue;
	MORE_Msg = '(more)';

	{ ================================= }
	{ ***  CONFIGURATION CONSTANTS  *** }
	{ ================================= }
	{ This is the speed used for animations. }
	FrameDelay: Word = 200;
	CHART_MaxMonsters: Integer = 1500;	{The maximum number of monsters that can appear on the map at once.}
						{On a P2-165 laptop, lag becomes noticeable around C = 800.}
	CHART_NumGenerations: Integer = 10;	{ Controls rate of monster propogation. }
	PLAY_MonsterTime: Integer = 90;		{ Controls the speed of monster propogation. }

	COMBAT_DamageCap: Boolean = False;	{ If DAMAGECAP is true, damage rolls have an upper limit. }

	PLAY_DangerOn: Boolean = True;		{ Controls whether save files get deleted at character death. }

	CfgName = 'deadcold.cfg';

	NumGKeys = 30;
	KMap: Array [1..NumGKeys] of GKeyDesc = (
		(	dkey: '1';
			name: 'SouthWest';
			desc: 'Movement key.';),
		(	dkey: '2';
			name: 'South';
			desc: 'Movement key.';),
		(	dkey: '3';
			name: 'SouthEast';
			desc: 'Movement key.';),
		(	dkey: '4';
			name: 'West';
			desc: 'Movement key.';),
		(	dkey: '5';
			name: 'Wait';
			desc: 'Movement key.';),
		(	dkey: '6';
			name: 'East';
			desc: 'Movement key.';),
		(	dkey: '7';
			name: 'NorthWest';
			desc: 'Movement key.';),
		(	dkey: '8';
			name: 'North';
			desc: 'Movement key.';),
		(	dkey: '9';
			name: 'NorthEast';
			desc: 'Movement key.';),
		(	dkey: 'o';
			name: 'OpenDoor';
			desc: 'Open a door or service panel adjacent to the PC.';),

		(	dkey: 'c';
			name: 'CloseDoor';
			desc: 'Close a door or service panel adjacent to the PC.';),
		(	dkey: 'R';
			name: 'Recenter';
			desc: 'Recenter the display on the PC''s current position.';),
		(	dkey: 'a';
			name: 'Targeting';
			desc: 'Fire the PC''s missile weapon.';),
		(	dkey: 't';
			name: 'ThrowGrenade';
			desc: 'Throw a grenade.';),
		(	dkey: 'i';
			name: 'Inventory';
			desc: 'Access items in the PC''s backpack.';),

		(	dkey: 'e';
			name: 'Equipment';
			desc: 'Access items which the PC has equipped.';),
		(	dkey: ',';
			name: 'PickUp';
			desc: 'Pick up an item off the floor.';),
		(	dkey: 'D';
			name: 'DisarmTrap';
			desc: 'Attempt to disarm a trap.';),
		(	dkey: 's';
			name: 'Search';
			desc: 'Search for secret doors and traps.';),
		(	dkey: 'z';
			name: 'InvokePsi';
			desc: 'Invoke one of the PC''s psychic powers.';),

		(	dkey: 'Z';
			name: 'QuickPsi';
			desc: 'Invoke one of the PC''s psychic powers using quick key.';),
		(	dkey: 'x';
			name: 'CheckXP';
			desc: 'Display the PC''s level and experience.';),
		(	dkey: '/';
			name: 'Look';
			desc: 'Identify characters on the screen.';),
		(	dkey: '>';
			name: 'Enter';
			desc: 'Enter transitway, or activate terrain.';),
		(	dkey: '.';
			name: 'Repeat';
			desc: 'Perform the same command repeditively.';),


		(	dkey: 'Q';
			name: 'QuitGame';
			desc: 'Stop playing and go do something productive.';),
		(	dkey: '?';
			name: 'Help';
			desc: 'Display all these helpful messages.';),
		(	dkey: 'X';
			name: 'SaveGame';
			desc: 'Write all game data to disk.';),
		(	dkey: 'C';
			name: 'CharInfo';
			desc: 'Provide some detailed information about your character.';),
		(	dkey: 'M';
			name: 'HandyMap';
			desc: 'Provides a rough map of the areas you have explored already.')

	);

Function RPGKey: Char;
Function DirKey: Integer;
Procedure GamePause;
Function YesNo: Boolean;
procedure Delineate(msg: pchar; width: longint; offset: Byte );
Procedure LovelyBox(EdgeColor,X1,Y1,X2,Y2: byte);
Procedure GameMessage(msg: pchar; X1,Y1,X2,Y2,tcolor,ecolor: byte);
Procedure DCNewMessage;
Procedure DCGameMessageC(msg: pchar; lf: boolean);
Procedure DCGameMessage(msg: string);
Procedure DCAppendMessage(msg: string);
Procedure DCPointMessage(msg: string);

Procedure ResetLogon;
Procedure SaveLogon( var F: Text );
Procedure LoadLogon( var F: Text );


implementation

const
	GM_X: byte = 1;	{Game Message Cursor Pos.}
	GM_Y: byte = 1;
	StartMem: LongInt = 0;

Function RPGKey: Char;
	{Read a keypress from the keyboard. Convert it into a form}
	{that my other procedures would be willing to call useful.}
var
	rk,getit: Char;
begin
	RK := ReadKey;

	Case RK of
		#0: begin	{We have a two-part special key.}
			{Obtain the scan code.}
			getit := Readkey;
			case getit of
				#72: RK := KMap[8].key; {Up Cursor Key}
				#80: RK := KMap[2].key; {Down Cursor Key}
				#75: RK := KMap[4].key; {Left Cursor Key}
				#77: RK := KMap[6].key; {Right Cursor Key}
			end;
		end;

		{Convert the Backspace character to ESCape.}
		#8: RK := #27;	{Backspace => ESC}

		{Normally, SPACE is the selection button, but ENTER should}
		{work as well. Therefore, convert all enter codes to spaces.}
		#10: RK := ' ';
		#13: RK := ' ';
	end;

	RPGKey := RK;
end;

Function DirKey: Integer;
	{ This procedure will input a single keypress, then return }
	{ whatever direction was indicated. }
	{ If the key pressed does not correspond to a direction, }
	{ or if there were any other errors, return 0. }
var
	K: Char;	{ Keypress }
	D: Integer;	{ Direction }
begin
	{ Input a keypress. }
	K := RPGkey;

	if K = KMap[1].key then D := 1
	else if K = KMap[2].key then D := 2
	else if K = KMap[3].key then D := 3
	else if K = KMap[4].key then D := 4
	else if K = KMap[5].key then D := 5
	else if K = KMap[6].key then D := 6
	else if K = KMap[7].key then D := 7
	else if K = KMap[8].key then D := 8
	else if K = KMap[9].key then D := 9
	else D := 0;

	DirKey := D;
end;

Procedure GamePause;
	{Pause the game until the player hits space.}
var
	a: Char;
begin
	GotoXY(MORE_X,MORE_Y);
	TextColor(MORE_color);
	write(MORE_msg);
	repeat
		a := RPGKey;
	until (a = ' ') or (a = #27);
	GotoXY(MORE_X,MORE_Y);
	TextColor(Black);
	write(MORE_msg);
end;

Function YesNo: Boolean;
	{Get a Y/N answer from the player. Return TRUE for Y,}
	{FALSE for N.}
var
	a: Char;
begin
	repeat
		a := Upcase(RPGKey);
	until (a = 'Y') or (a = 'N');

	yesno := a = 'Y';
end;

procedure Delineate(msg: pchar; width: longint; offset: Byte );
	{This is the breaking-into-lines section of the prettyprinter.}
	{Take a null-terminated string, MSG, and break it into}
	{sections of width characters or less.}
	{The offset parameter, if more than one, indicates the column}
	{that text display starts at.}

	{PRE-CONDITIONS: The CRT display is set up exactly as you want it with}
	{  regards to window, text color, cursor placement, and so on.}
var
	linestart: pchar; {the start of the current line}
	linebreak: pchar; {the point at which the line will be broken}
	THEline: pchar;   {a single screen line that has to be printed}
	aa: pchar;        {a counter, of the house of Cromwell.}
	t: integer;       {word counter, named t for c64 programmers}

begin
	{Error check- in the case of a Nil, exit without a word.}
	if msg = Nil then exit;

	{The start of the first line is the start of the message. duh.}
	linestart := msg;
	Aa := Nil;

	repeat
		{start the counter at the start of the line}
		linebreak := linestart;

		{reset the word counter to 0}
		t := 0;

		{move up through the whitespace until you find a line}
		{too long to print, or the end of the file.}
		repeat
			{increment the word counter}
			inc(t);

			{locate the next space. If there is no next}
			{space, move the counter to the end of the string.}
			aa := StrScan(linebreak,' ');
			if aa = Nil then
				aa := StrEnd(msg);

			{if there's enough room for this to fit on a}
			{line, it becomes linebreak.}
			{Also, if this is the first word, print it}
			{anyways. This should, in theory, deal with}
			{words too long to fit on a single line.}
			if ((aa-linestart+offset-1) <= width) or (t = 1) then
				linebreak := aa + 1;


		until ((aa-linestart+offset)>width) or (linebreak = StrEnd(msg)+1);

		{locate and extract THEline}
		THELine := StrAlloc(linebreak - linestart + 1);
		StrLCopy(THEline,linestart,(linebreak-linestart)-1);

		{Check to see whether or not the cursor is where it's}
		{supposed to be.}
		if whereX <> Offset then writeln;
		write(THEline);

		Dispose(THEline);

		linestart := linebreak;

		offset := 1;
	until (linestart = StrEnd(msg)+1);

end;

Procedure LovelyBox(EdgeColor,X1,Y1,X2,Y2: byte);
	{Draw a lovely box!}
var
	t: integer;		{a counter, of the house of CBM.}

begin
	{Set the color for the box.}
	TextColor(EdgeColor);

	{Print the four corners.}
	GotoXY(X1,Y1);
	write('+');
	GotoXY(X2,Y1);
	write('+');
	GotoXY(X1,Y2);
	write('+');
	GotoXY(X2,Y2);
	write('+');

	{Print the two horizontal edges.}
	for t := x1+1 to x2-1 do begin
		GotoXY(t,y1);
		write('-');
		GotoXY(t,y2);
		write('-');
	end;

	{Print the two vertical edges.}
	for t := y1+1 to y2-1 do begin
		GotoXY(x1,t);
		write('|');
		GotoXY(x2,t);
		write('|');
	end;

end;

Procedure GameMessage(msg: pchar; X1,Y1,X2,Y2,tcolor,ecolor: byte);
	{Take a null-terminated text string, MSG, and prettyprint}
	{it within the box defined by X1,Y1 - X2,Y2. }

	{BUGS: No checking done on dimensions of box.}
begin
	{Set the background color to black.}
	TextBackground(Black);

	{Print the border}
	if ecolor <> black then
		LovelyBox(ecolor,X1,Y1,X2,Y2);

	{Set the window to the desired print area, and clear everything.}
	Window(x1+1,y1+1,x2-1,y2-1);
	ClrScr;

	{call the Delineate procedure to prettyprint it.}
	TextColor(tcolor);
	Delineate(msg, x2 - x1 - 1,1);

	{restore the window to its original, full dimensions.}
	window(1,1,80,25);

end;

Procedure DCNewMessage;
	{Start a new line in the DCMessage area.}
begin
	{Set the window.}
	Window(DCTextBox_X1,DCTextBox_y1,DCTextBox_x2,DCTextBox_y2);

	GotoXY(GM_X,GM_Y);
	if GM_X <> 1 then writeln;
	TextColor(DCBulletColor);
	write('> ');

	GM_X := WhereX;		{Reset the Cursor Pos.}
	GM_Y := WhereY;

	Window(1,1,80,25);
end;

Procedure DCGameMessageC(msg: pchar; lf: boolean);
	{Print a standard text message for the game GearHead.}
begin
	{Set the background color to black.}
	TextBackground(Black);

	{If needed, go to the next line.}
	if lf then DCNewMessage;

	{Set the text color.}
	TextColor(DCTextColor);

	{Set the window to the desired print area, and move to the right pos.}
	Window(DCTextBox_X1,DCTextBox_y1,DCTextBox_x2,DCTextBox_y2);
	GotoXY(GM_X,GM_Y);

	{call the Delineate procedure to prettyprint it.}
	Delineate(msg,DCTextBox_X2 - DCTextBox_X1 + 1,GM_X);

	{Save the current cursor position.}
	GM_X := WhereX;
	GM_Y := WhereY;

	{restore the window to its original, full dimensions.}
	window(1,1,80,25);
end;

Procedure DCGameMessage(msg: string);
	{As above, but prints a pascal string as a GameMessage.}
var
	pmsg: pchar;	{The holder for the PChar string.}
begin
	{Allocate memory for it.}
	pmsg := StrAlloc(Length(msg)+1);

	{Do the conversion.}
	StrPCopy(pmsg,msg);

	{Send the PChar string to the above procedure.}
	DCGameMessageC(pmsg,true);

	{Dispose of the string.}
	Dispose(pmsg);
end;

Procedure DCAppendMessage(msg: string);
	{As above, but appends this string to the last one.}
var
	pmsg: pchar;	{The holder for the PChar string.}
begin
	{Allocate memory for it.}
	pmsg := StrAlloc(Length(msg)+2);

	{Do the conversion.}
	StrPCopy(pmsg,' ' + msg);

	{Send the PChar string to the above procedure.}
	DCGameMessageC(pmsg,false);

	{Dispose of the string.}
	Dispose(pmsg);
end;

Procedure DCPointMessage(msg: string);
	{Display a message without affecting GM_X,GM_Y.}
var
	width: Integer;
begin
	{Set the background color to black.}
	TextBackground(Black);
	TextColor(DCTextColor);

	{Set the window to the desired print area, and move to the right pos.}
	Window(DCTextBox_X1,DCTextBox_y1,DCTextBox_x2,DCTextBox_y2);
	GotoXY(GM_X,GM_Y);

	ClrEOL;

	width := DCTextBox_X2 - DCTextBox_X1 - GM_X;
	if width < 1 then exit;

	{Write out as much of the message as will fit on the line.}
	write(Copy(msg,1,width));

	{restore the window to its original, full dimensions.}
	window(1,1,80,25);
end;

Procedure SetKeyMap;
	{Set up the key map for this game.}
var
	t: Integer;
	S,cmd,C: String;
	F: Text;
begin
	{Set the default keys for all commands.}
	for t := 1 to NumGKeys do begin
		KMap[t].key := KMap[t].dkey;
	end;

	{See whether or not there's a configuration file.}
	S := FSearch(CfgName,'.');
	if S <> '' then begin
		writeln('Loading config file...');
		Assign(F,S);
		Reset(F);

		while not Eof(F) do begin
			ReadLn(F,S);
			cmd := ExtractWord(S);
			if (cmd <> '') then begin
				{Check to see if CMD is one of the standard keys.}
				cmd := UpCase(cmd);
				for t := 1 to NumGKeys do begin
					if UpCase(KMap[t].Name) = cmd then begin
						C := ExtractWord(S);
						if Length(C) <> 1 then begin
							writeln('Error reading cfg file - '+cmd+' bad key.');
						end else begin
							KMap[t].Key := C[1];
						end;
					end;
				end;

				{ Check to see if CMD is the animation speed throttle. }
				if cmd = 'ANIMSPEED' then begin
					T := ExtractValue( S );
					if T < 0 then T := 0;
					FrameDelay := T;
				end else if cmd = 'NUMMONSTERS' then begin
					T := ExtractValue( S );
					if T < 100 then T := 100;
					CHART_MaxMonsters := T;
				end else if cmd = 'SWARMRATE' then begin
					T := ExtractValue( S );
					if T < 2 then T := 2;
					CHART_NumGenerations := T;
				end else if cmd = 'MONSTERTIME' then begin
					T := ExtractValue( S );
					if T < 10 then T := 10;
					PLAY_MonsterTime := T;
				end else if cmd = 'SAFEMODE' then begin
					PLAY_DangerOn := False;
				end else if cmd = 'DAMAGECAP' then begin
					COMBAT_DamageCap := True;
				end;
			end;
		end;

		Close(F);
	end else begin
		writeln('Standard configuration.');
	end;
end;

Procedure ResetLogon;
	{ Set the USED field of each TEX entry to FALSE. }
var
	T: Integer;
begin
	for t := 1 to NumTex do TexMan[T].used := False;
end;

Procedure SaveLogon( var F: Text );
	{ Write the index number of every TEX the player has accessed to }
	{ disk, followed by a -1 sentinel. }
var
	T: Integer;
begin
	for t := 1 to NumTex do begin
		if TexMan[T].used then writeln( F , T );
	end;
	writeln( F , '-1' );
end;

Procedure LoadLogon( var F: Text );
	{ Load the player's logon data from disk. Basically, this is }
	{ just a list of read messages. }
var
	N: Integer;
begin
	ResetLogon;
	repeat
		readln( F , N );
		if ( N > 0 ) and ( N <= NumTex ) then TexMan[N].used := True;
	until N < 1;
end;



initialization
	StartMem := MemAvail;
	CursorOff; {LINUX ALERT}
	ClrScr;
	SetKeyMap;

finalization
	NormVideo;
	CursorOn;
	ClrScr;
	writeln('Start Mem: ',StartMem);
	writeln('Currently: ',MemAvail);
	writeln('If the above two numbers are different, I''ve done something bad.');
end.
