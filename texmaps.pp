unit texmaps;
	{This will handle all of the map stuff for a RL game.}

	{This is the ASCII version of this unit.}

	{ *** GFX UNIT *** }

Interface

uses CRT,rpgdice,rpgtext,texmodel;

Const
	POVSize = 50;
	NumTerr = 50;

	{Constants for specific terrain types.}
	{CONVENTION: ClosedTerr = OpenTerr + 1}
	OpenDoor = 7;
	ClosedDoor = 8;
	OpenServicePanel = 11;
	ClosedServicePanel = 12;
	HiddenServicePanel = 13;
	Crawlspace = 9;
	SecureWall = 16;
	Chair = 14;
	MarbleColumn = 17;
	PilotsChair = 21;
	TransitLeft = 32;
	TransitRight = 33;
	TransitUp = 35;
	TransitDown = 34;
	ForceField = 43;
	ForceFieldGenerator = 44;
	CryoCapsule = 45;

	TerrName: Array [1..NumTerr] of string = (
		'Vacuum','Floor','Wall','Shrubbery','Grate',
		'Inner Workings','Door','Door','CrawlSpace','Blood Stain',
		'Service Panel','Service Panel','Wall','Chair','Carpet',
		'Wall','Marble Column','Scarab','Bed','Space Ship',
		'Pilot''s Chair','Command Console','View Port','Space Ship','Space Ship',
		'Space Ship','Thruster','Space Ship','Floor','Transitway',
		'Transitway','Transitway Door','Transitway Door','Transitway Door','Transitway Door',
		'Transitway Shaft','Table','Toilet','Altar','Marble Floor',
		'Headstone','Grass','Force Field','Force Field Generator','Cryogenic Casket',
		'Thruster','Space Ship','Space Ship','Space Ship','Space Ship'
	);
	TerrChar: Array [1..NumTerr] of char = (
		' ','.','#','#','%',
		'#',':','+','=','.',
		':','#','#','-','.',
		'#','I','i','_','#',
		'-','[',')',']','=',
		'|','>','-','.','[',
		']','<','>','V','A',
		'*','0','-','~','.',
		'+','.','*','^','=',
		'A','|','/','!','\'
	);
	TerrColor: Array [1..NumTerr] of byte = (
		Black,Blue,White,Green,DarkGray,
		LightGray,Cyan,Cyan,Magenta,Red,
		Yellow,LightCyan,White,Yellow,LightBlue,
		White,White,Blue,Yellow,Green,
		White,Red,Yellow,Green,Green,
		Green,LightGreen,Green,Cyan,White,
		White,Cyan,Cyan,Red,Red,
		White,White,LightGray,White,LightGray,
		White, Green, Yellow, DarkGray, Blue,
		Yellow,Yellow,Yellow,Yellow,Yellow
	);

	{This array tells how easily you can see through the terrain in question.}
	{A negative value means the terrain completely blocks LOS.}
	TerrObscurement: Array [1..NumTerr] of integer = (
		0,0,-1,5,0,
		-1,1,-1,1,0,
		1,-1,-1,1,0,
		-1,1,1,1,-1,
		1,-1,-1,-1,-1,
		-1,1,-1,0,-1,
		-1,0,0,0,0,
		-1,2,1,2,0,
		2,0,-1,0,2,
		-1,-1,-1,-1,-1
	);

	{This array tells how easily you may walk through the terrain.}
	{It is a percent chance of making it through unhindered.}
	{CONVENTION: A negative number here indicates terrain which cannot be overwritten in the random map generator.}
	TerrPass: Array [1..NumTerr] of integer = (
		-1,100,0,30,100,
		0,100,-1,85,100,
		75,-1,-1,55,100,
		-1,-1,-1,45,-1,
		85,-1,-1,-1,-1,
		-1,-1,-1,100,-1,
		-1,100,100,100,100,
		-1,15,50,-1,100,
		-1,100,-1,100,95,
		-1,-1,-1,-1,-1
	);

	{These constants tell the system how to display traps.}
	TrapGfx = '^';
	TrapColor = LightRed;

	{This array holds the vector information for movement. The 9 directions}
	{correspond to the keys on the numeric keypad.}
	VecDir: Array [1..9,1..2] of Integer = (
	(-1, 1),( 0, 1),( 1, 1),
	(-1, 0),( 0, 0),( 1, 0),
	(-1,-1),( 0,-1),( 1,-1)
	);


Type
	Point = Record
		x,y: Integer;
	end;

	FrameOfReference = Record
		los: Array [-POVSize..POVSize,-POVSize..POVSize] of boolean;	{Each block in the array is set to True if visible from center, false otherwise.}
		LeftX,TopY: Integer;	{The top,left corner of the screen display.}
		M: ModelPtr;		{The model to which the POV belongs.}
		range: byte;		{Range of visual perception.}
		sense: byte;		{The sensor rating of the FoR.}
	end;

	tile = Record
		terr: byte;		{The terrain of the tile.}
		visible: boolean;	{Has the tile been spotted yet?}
		trap: ShortInt;		{Is there a trap here? 0 = No trap; + = Trap visible}
		special: ShortInt;	{Is there something special here? This unit doesn't check the value of this field at all.}
	end;

	OverImage = Record	{This is an image overlaid on the map.}
		gfx: Char;	{Useful primarily for items.}
		color: Byte;
	end;

	GameBoard = Record
		map: Array [1..XMax,1..YMax] of Tile; {The terrain in each map square.}
		mog: ModelGrid;	{The modelgrid for the map.}
		itm: Array [1..XMax,1..YMax] of OverImage;
		mlist: ModelPtr; {The list of models that are present on the map.}
		POV: FrameOfReference;
	end;
	GameBoardPtr = ^GameBoard;

	WalkReport = Record
		go: Boolean;	{Did the walker actually move anywhere?}
		m: ModelPtr;	{Did the walker contact another model?}
		trap: SmallInt;	{Did the walker step on a trap?}
	end;


Function SolveLine(X1,Y1,X2,Y2,N: Integer): Point;
Function NewBoard: gameboardptr;
Procedure DisposeBoard(gb: gameboardptr);

Function OnTheMap(X,Y: Integer): Boolean;
Function OnTheScreen(gb: GameBoardPtr; X,Y: Integer): Boolean;
Function GetTerr(gb: GameBoardPtr; X,Y: Integer): Integer;
Function TileLOS(var pov: FrameOfReference; X,Y: Integer): Boolean;
Procedure DisplayTile(gb: GameBoardPtr; X,Y: Integer);
Procedure HighlightTile(gb: GameBoardPtr; X,Y: Integer);
Procedure ClearMapArea;
Procedure DisplayMap(gb: gameboardptr);
Procedure RecenterPOV(gb: GameBoardPtr);
Procedure UpdatePOV(var pov: FrameOfReference; gb: GameBoardPtr);
Procedure ApplyPOV(var pov: FrameOfReference; gb: GameBoardPtr);

Function MoveModel(M: ModelPtr; gb: GameBoardPtr; X,Y: Integer): WalkReport;
Function GAddModel(gb: GameBoardPtr; gfx: char; AC,BC: byte; cohab: boolean; X,Y,Kind: Integer): ModelPtr;
Procedure GRemoveModel(m: ModelPtr; gb: GameBoardPtr);
Procedure SetOverImage(gb: GameBoardPtr; X,Y: Integer; gfx: char; color: byte);
Procedure ClearOverImage(gb: GameBoardPtr; X,Y: Integer);

Function CalcObscurement(X1,Y1,X2,Y2: Integer; gb: GameBoardPtr): Integer;
Function CalcObscurement(M: ModelPtr; X,Y: Integer; gb: GameBoardPtr): Integer;
Function CalcObscurement(M1,M2: ModelPtr; gb: GameBoardPtr): Integer;

Procedure MapSplat(gb: GameBoardPtr; gfx: char; color: byte; X,Y: Integer; NoLOS: Boolean);

Function Range(M1,M2: ModelPtr): Integer;
Function Range(M: ModelPtr; X,Y: Integer): Integer;

Function LocateBlock(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer): Point;
Function LocateStop(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer): Point;

Procedure WriteGameBoard(gb: GameBoardPtr; var F: Text);
Function ReadGameBoard(var F: Text): GameBoardPtr;


implementation

Const
	MapDisplayWidth = 80;	{Map Display Width}
	MapDisplayHeight = 21;	{Map Display Height}
	MOX = 1;	{Map Origin X}
	MOY = 4;	{Map Origin Y}

Function SolveLine(X1,Y1,X2,Y2,N: Integer): Point;
	{Find the N'th point along a line starting at X1,Y1 and ending}
	{at X2,Y2. Return its location.}
var
	tmp: point;
	VX1,VY1,VX,VY: Integer;
	Rise,Run: Integer; {Rise and Run}
begin
	{ERROR CHECK- Solve the trivial case.}
	if (X1=X2) and (Y1=Y2) then begin
		tmp.x := X1;
		tmp.y := Y1;
		Exit(tmp);
	end;

	{For line determinations, we'll use a virtual grid where each game}
	{tile is a square 10 units across. Calculations are done from the}
	{center of each square.}
	VX1 := X1*10 + 5;
	VY1 := Y1*10 + 5;

	{Do the slope calculations.}
	Rise := Y2 - Y1;
	Run := X2 - X1;

	if Abs(X2 - X1)> Abs(Y2 - Y1) then begin
		{The X direction is longer than the Y axis.}
		{Therefore, we can infer X pretty easily, then}
		{solve the equation for Y.}
		{Determine our X value.}
		if Run > 0 then VX := (n*10) + VX1
		else VX := VX1 - n*10;

		VY := n*10*Rise div Abs(Run) + VY1;

		end
	else begin
		{The Y axis is longer.}
		if Rise > 0 then VY := (n*10) + VY1
		else VY := VY1 - n*10;

		VX := (n*10*Run div Abs(Rise)) + VX1;

	end;

	{Error check- DIV doesn't deal with negative numbers as I would}
	{want it to. I'd always like a positive remainder- so, let's modify}
	{the values.}
	if VX<0 then VX := VX - 10;
	if VY<0 then VY := VY - 10;

	tmp.x := VX div 10;
	tmp.y := VY div 10;
	SolveLine := tmp;
end;

Function NewBoard: gameboardptr;
	{Initialize a new GameBoard array.}
var
	gb: gameboardptr;
	x,y: integer;     {Counters for initialization of the tiles}
begin
	{Allocate memory for the map}
	New(gb);

	{Loop through every tile on the map and initialize it.}
	for x := 1 to XMax do begin
		for y := 1 to YMax do begin
			gb^.map[x,y].terr := 1;	{Set terrain to 1. No reason.}
			gb^.map[x,y].visible := false;
			gb^.map[X,Y].trap := 0;
			gb^.map[X,Y].special := 0;
			gb^.mog[x,y] := false;	{There's no model standing here now...}
			gb^.itm[x,y].gfx := ' ';
			gb^.itm[x,y].color := white;
		end;
	end;

	gb^.mlist := Nil;

	{Initialize the POV elements.}
	GB^.pov.TopY := 1;
	GB^.pov.LeftX := 1;
	GB^.pov.sense := 5;
	gb^.POV.M := Nil;

	NewBoard := gb;
end;

Procedure DisposeBoard(gb: gameboardptr);
	{Deallocate the game board and all associated stuff}
begin
	{Dispose of the models list.}
	DisposeModelList(gb^.mlist);

	{Dispose of the actual map.}
	Dispose(gb);
end;

Function OnTheMap(X,Y: Integer): Boolean;
	{Check the set of coordinates given, and decide whether or not}
	{the point lies within the defined map.}
var
	it: Boolean;
begin
	if (X>=1) and (X<=XMax) and (Y>=1) and (Y<=YMax) then
		it := True
	else
		it := False;

	OnTheMap := it;
end;

Function ScreenX(gb: GameBoardPtr; X: Integer): Integer;
	{This function will return the screen coordinate of map column X.}
var
	DX: Integer; {Delta X... the distance from the column to the UL corner.}
begin
	DX := X - gb^.POV.LeftX;
	ScreenX := DX + MOX;
end;

Function ScreenY(gb: GameBoardPtr; Y: Integer): Integer;
	{This function will return the screen coordinate of map column X.}
var
	DY: Integer;	{Delta Y... see above.}
begin
	DY := Y - gb^.POV.TopY;

	ScreenY := DY + MOY;
end;

Function OnTheScreen(gb: GameBoardPtr; X,Y: Integer): Boolean;
	{This function will tell whether or not map location X,Y}
	{is currently within screen boundaries. This doesn't}
	{necessarily mean that it's visible, just that it's present.}
var
	it: Boolean;
begin
	{Error Check- Make sure the POV is initialized.}
	if gb^.POV.M = Nil then Exit(False);

	if (X >= gb^.POV.LeftX) and (X < (gb^.POV.LeftX + MapDisplayWidth)) and (Y >= gb^.POV.TopY) and (Y < (gb^.POV.TopY + MapDisplayHeight)) then
		it := true
	else
		it := false;
	OnTheScreen := it;
end;

Function GetTerr(gb: GameBoardPtr; X,Y: Integer): Integer;
	{Check location X,Y and return the terrain type found there.}
	{If the point lies outside of the boundaries, return a one.}
var
	t: Integer;
begin
	{Check to make sure that the point lies within the boundaries}
	{of the map.}
	if OnTheMap(X,Y) then
		t := gb^.map[x,y].terr
	else
		t := 1;

	GetTerr := t;
end;

Procedure SetVisible(gb: GameBoardPtr; X,Y: Integer);
	{Set the visibility flag to true on tile X,Y on the gameboard.}
begin
	{Check to make sure that the point lies within the boundaries}
	{of the map.}
	if OnTheMap(X,Y) then
		gb^.map[X,Y].visible := true;
end;

Function TileVisible(gb: GameBoardPtr; X,Y: Integer): Boolean;
	{Check the VISIBLE field of the tile in question, and}
	{return its value.}
var
	it: Boolean;
begin
	if OnTheMap(X,Y) then
		it := gb^.Map[X,Y].visible
	else
		it := false;
	TileVisible := it;
end;

Function TileLOS(var pov: FrameOfReference; X,Y: Integer): Boolean;
	{Check to see whether location X,Y is visible to the frame of reference POV.}
var
	px,py: Integer;		{The coordinates of X and Y relative to the POV origin.}
	temp: Boolean;
begin
	{Error Check- if the POV isn't initialized, no LoS possible.}
	if pov.M = Nil then Exit(False);

	{Calculate PX and PY.}
	px := X - pov.M^.x;
	py := Y - pov.M^.y;

	{Check to make sure that PX and PY are within range.}
	if (px >= -POVSize) and (px <= POVSize) and (py >= -POVSize) and (py<= POVSize) then
		temp := pov.los[px,py]
	else
		temp := false;

	TileLOS := temp;
end;

Procedure RenderTile(gb: GameBoardPtr; Norm: Boolean; X,Y: Integer);
	{This procedure actually does the work for DisplayTile.}
	{Set Norm to FALSE to print the tile in reversed color.}
var
	T: Integer;	{Terrain.}
	M: ModelPtr;	{Model.}
begin
	{Error Check- Make sure that the tile in question is}
	{actually on the screen.}
	if OnTheScreen(gb,X,Y) then begin
		{Goto the correct screen location.}
		GotoXY(ScreenX(gb,X),ScreenY(gb,Y));

		{If there's a model here, display that.}
		if ModelPresent(gb^.mog,X,Y) and TileLOS(gb^.pov,X,Y) then begin
			{There's a model. Show it.}
			m := FindModelXY(gb^.mlist,X,Y);
			if M <> Nil then begin
				if Norm then begin
					TextColor(m^.color);
					TextBackground(Black);
				end else begin
					TextBackground(m^.color);
					if m^.color = white then TextColor(LightCyan)
					else TextColor(White);
				end;
				Write(m^.gfx);
			end;
		end else if TileLOS(gb^.pov,X,Y) and (gb^.itm[X,Y].gfx <> ' ') then begin
			{There's an OverImage. Show it.}
			if Norm then begin
				TextColor(gb^.itm[X,Y].color);
				TextBackground(Black);
			end else begin
				TextBackground(gb^.itm[X,Y].color);
				if gb^.itm[X,Y].color = white then TextColor(LightCyan)
				else TextColor(White);
			end;
			Write(gb^.itm[X,Y].gfx);
		end else if TileVisible(gb,X,Y) and (gb^.map[X,Y].trap > 0) then begin
			if Norm then begin
				TextColor(TrapColor);
				TextBackground(Black);
			end else begin
				TextBackground(TrapColor);
				if TrapColor = white then TextColor(LightCyan)
				else TextColor(White);
			end;
			Write(TrapGfx);
		end else if TileVisible(gb,X,Y) then begin
			{There's no model. Show the terrain.}
			t := GetTerr(gb,X,Y);
			if Norm then begin
				TextColor(TerrColor[t]);
				TextBackground(Black);
			end else begin
				TextBackground(TerrColor[t]);
				if TerrColor[t] = white then TextColor(LightCyan)
				else TextColor(White);
			end;
			Write(TerrChar[t]);
		end else begin
			{This tile has not yet been revealed. Print a space.}
			if not Norm then TextBackground(White);
			Write(' ');
		end;
	end;
	if not Norm then TextBackground(Black);
end;

Procedure DisplayTile(gb: GameBoardPtr; X,Y: Integer);
	{Move the cursor to the correct location, then print the tile.}
begin
	RenderTile(gb,True,X,Y)
end;

Procedure HighlightTile(gb: GameBoardPtr; X,Y: Integer);
	{Move the cursor to the correct location, then print the tile.}
begin
	RenderTile(gb,False,X,Y)
end;

Procedure ClearMapArea;
	{Clear the map area. Pretty straight forward.}
begin
	{Set the clip area for this operation.}
	Window(MOX,MOY,MOX + MapDisplayWidth - 1,MOY + MapDisplayHeight - 1);

	{Clear the current display area.}
	ClrScr;

	{Restore the original window.}
	Window(1,1,80,25);
end;

Procedure DisplayMap(gb: gameboardptr);
	{Display the map. Duh. This procedure will perform a}
	{complete refresh of the screen display.}
var
	X,Y:	Integer;	{For cycling through all the elements of the map.}
begin
	ClearMapArea;

	{Loop through every tile currently on the screen.}
	{Display it if visible, don't display it otherwise.}
	for y := gb^.POV.TopY to (gb^.POV.TopY + MapDisplayHeight - 1) do begin
		for X := gb^.POV.LeftX to (gb^.POV.LeftX + MapDisplayWidth - 1) do begin
			if TileVisible(gb,X,Y) then DisplayTile(gb,X,Y);
		end;
	end;
end;

Function CantSeeThrough(pov: FrameOfReference; terr: Integer): Boolean;
	{Check the terrain in question and see whether or not the}
	{observer can see through/over this type.}
var
	it: Boolean;
begin
	{Error check- if POV is empty, can't see anything.}
	if pov.m = Nil then Exit(False);

	if TerrObscurement[Terr] = -1 then it := true
	else it := false;

	CantSeeThrough := it;
end;

Procedure RecenterPOV(gb: GameBoardPtr);
	{The model for the POV is getting close to the edge of}
	{the screen display. Recenter it.}
begin
	gb^.POV.LeftX := gb^.POV.M^.X - (MapDisplayWidth div 2);
	gb^.POV.TopY := gb^.POV.M^.Y - (MapDisplayHeight div 2);

	if gb^.POV.LeftX < 1 then
		gb^.POV.LeftX := 1
	else if gb^.POV.LeftX > (XMax - MapDisplayWidth) then
		gb^.POV.LeftX := XMax - MapDisplayWidth + 1;

	if gb^.POV.TopY < 1 then
		gb^.POV.TopY := 1
	else if gb^.POV.TopY > (YMax - MapDisplayHeight) then
		gb^.POV.TopY := YMax - MapDisplayHeight + 1;

end;

Procedure CheckPOV(gb: GameBoardPtr);
	{Check to see whether or not the POV is getting close to}
	{the edge of the screen. If it is, recenter it.}
var
	RC: Boolean;
	SX,SY: Integer;
begin
	{Check to see whether or not the screen needs to be recentered.}
	RC := False;

	{Calculate the current screen coordinates of the POV.}
	SX := gb^.POV.M^.X - gb^.POV.LeftX + 1;
	SY := gb^.POV.M^.Y - gb^.POV.TopY + 1;

	{The screen will be recentered if X or Y are within 3 squares}
	{of the edge of the display area, and that said edge is not}
	{the edge of the map.}
	if (SX <= 3) and (gb^.POV.LeftX > 1) then
		RC := True
	else if (SX >= (MapDisplayWidth - 3)) and (gb^.POV.LeftX < (XMax - MapDisplayWidth + 1)) then
		RC := True;

	if (SY <= 3) and (gb^.POV.TopY > 1) then
		RC := True
	else if (SY >= (MapDisplayHeight - 3)) and (gb^.POV.TopY < (YMax - MapDisplayHeight + 1)) then
		RC := True;

	if RC then begin
		RecenterPOV(gb);
		DisplayMap(gb);
	end;
end;

Procedure UpdatePOV(var pov: FrameOfReference; gb: GameBoardPtr);
	{Given the frame of reference POV, decide what can and what}
	{cannot actually be seen.}
const
	UPV_True = 1;
	UPV_False = -1;
	UPV_Maybe = 0;
var
	temp: Array [-POVSize..POVSize,-POVSize..POVSize] of integer;
	x,y: Integer;

	Procedure CheckLine(XT,YT: Integer);
	var
		t,terr: Integer;	{A counter, and a terrain type.}
		Wall: Boolean;	{Have we hit a wall yet?}
		p: Point;
		O: Integer;	{The obscurement count.}
	begin
		{Check every point on the line from the origin to XT,YT,}
		{recording the results in the Temp array.}

		{The obscurement count starts out with a value of 1.}
		O := 1;

		{The variable WALL represents a boundary that cannot be seen through.}
		Wall := false;

		for t := 1 to pov.range do begin
			{Locate the next point on the line.}
			p := SolveLine(0,0,XT,YT,t);

			{Determine the terrain of this tile.}
			terr := GetTerr(gb,pov.M^.x + p.x,pov.M^.y + p.y);

			{Update the Obscurement count.}
			O := O + TerrObscurement[Terr];

			{Models also cause obscurement.}
			if ModelPresent(gb^.mog,p.x,p.y) then Inc(O);

			{If we have already encountered a wall, mark this square as UPV_False}
			if Wall then temp[p.x,p.y] := UPV_False;

			Case temp[p.x,p.y] of
				UPV_False: Break; {This LoS is blocked. No use searching any further.}
				UPV_Maybe: begin  {We will mark this one as true, but check for a wall later.}
					temp[p.x,p.y] := UPV_True;
					end;
				{If we got a UPV_True, we just skip merrily along without doing anything.}
			end;

			{If this current square is a wall,}
			{or if we have too much obscurement to see,}
			{set Wall to true.}
			if CantSeeThrough(pov,terr) or (O > PoV.Sense) then Wall := True;
		end;
	end;

	Procedure FillOutCardinals( D: Integer );
		{ Travel along direction D. If the tile is set to UPV_True, }
		{ then set the two adjacent tiles to UPV_True as well. }
	var
		t: Integer;
	begin
		for t := 1 to POVSize do begin
			if temp[ 0 + VecDir[D,1]*T , 0 + VecDir[D,2]*t ] = UPV_True then begin
				temp[ 0 + VecDir[D,1]*T + VecDir[D,2] , 0 + VecDir[D,2]*t + VecDir[D,1] ] := UPV_True;
				temp[ 0 + VecDir[D,1]*T - VecDir[D,2] , 0 + VecDir[D,2]*t - VecDir[D,1] ] := UPV_True;
			end;
		end;
	end;

begin
	{Error Check- make sure there's a model attached.}
	if pov.M = Nil then Exit;

	{Error Check- make sure that the range is a legal value.}
	if pov.range > POVsize then pov.range := POVsize
	else if pov.range < 2 then pov.range := 2;

	{Make sure we're in a good display area.}
	CheckPOV(gb);

	{Set every square in the temp array to Maybe.}
	for x := -POVSize to POVSize do
		for y := -POVSize to POVSize do
			temp[x,y] := UPV_Maybe;

	{Set the origin to True.}
	temp[0,0] := UPV_True;

	{Check the 4 cardinal directions}
	CheckLine(0,pov.range);
	CheckLine(0,-pov.range);
	CheckLine(pov.range,0);
	CheckLine(-pov.range,0);

	{Check the 4 diagonal directions}
	CheckLine(pov.range,pov.range);
	CheckLine(pov.range,-pov.range);
	CheckLine(-pov.range,pov.range);
	CheckLine(-pov.range,-pov.range);

	For X := -pov.range + 1 to -1 do begin
		Checkline(X,-pov.range);
		CheckLine(X,pov.range);
	end;

	For X := pov.range -1 downto 1 do begin
		Checkline(X,-pov.range);
		CheckLine(X,pov.range);
	end;


	For Y := -pov.range + 1 to -1 do begin
		Checkline(pov.range,Y);
		CheckLine(-pov.range,Y);
	end;

	For Y := pov.range - 1 downto 1 do begin
		CheckLine(pov.range,Y);
		CheckLine(-pov.range,Y);
	end;

	FillOutCardinals( 8 );
	FillOutCardinals( 6 );
	FillOutCardinals( 2 );
	FillOutCardinals( 4 );

	{Copy the results from temp to the actual LOS array.}
	for x := -POVSize to POVSize do
		for y := -POVSize to POVSize do
			if temp[x,y] = UPV_True then
				pov.los[x,y] := true
			else
				pov.los[x,y] := false;

end;

Procedure ApplyPOV(var pov: FrameOfReference; gb: GameBoardPtr);
	{Given the frame of reference POV, copy visibilty settings to}
	{the game board and update the screen display.}
var
	x,y: Integer;
begin
	{Error check- abort if the POV has no model.}
	if pov.M = Nil then Exit;

	{Loop through all of the elements in the LoS matrix.}
	For x := -pov.range to pov.range do begin
		for y := -pov.range to pov.range do begin
			if pov.los[x,y] then begin
				if Not TileVisible(gb,x+pov.M^.x,y+pov.M^.y) then begin
					{Set the visible flag on the map.}
					SetVisible(gb,(x + pov.M^.x),(y + pov.M^.y));

					{This square can be seen.}
					DisplayTile(gb,x + pov.M^.x, y + pov.M^.y);
				end else if ModelPresent(gb^.mog,X + pov.M^.X,Y + pov.M^.Y) or (gb^.itm[X + pov.M^.X,Y + pov.M^.Y].gfx <> ' ') then begin
					{There's a model or item here. Display it.}
					DisplayTile(gb,x + pov.M^.x, y + pov.M^.y);

				end;
			end;
		end;
	end;
end;

Function MoveModel(M: ModelPtr; gb: GameBoardPtr; X,Y: Integer): WalkReport;
	{Move model M from its current location to X,Y. Update the}
	{display if necessary.}
	{THIS PROCEDURE CHECKS FOR:      }
	{  - Map boundaries              }
	{  - Model in target square      }
	{  - Terrain Passability         }
var
	X1,Y1: Integer;
	it: WalkReport;
begin
	{Save the initial position of the model.}
	X1 := M^.X;
	Y1 := M^.Y;

	{Initialize values.}
	it.go := False;
	it.m := Nil;
	it.trap := 0;

	{Check the destination to make sure the move can take place.}
	if OnTheMap(X,Y) then begin
		{The target square is on the map. Continue on.}
		if ModelPresent(gb^.mog,X,Y) then begin
			{There's a model in the target square. Check}
			{to see if it can cohabitate or not.}
			it.m := FindModelXY(gb^.mlist,X,Y);
			it.go := it.m^.Cohab;
		end else begin
			it.go := true;
		end;

		{Check the target square for terrain concerns.}
		if it.go then begin
			if (Random(100) + 1) > TerrPass[GetTerr(gb,X,Y)] then begin
				it.go := False;
			end;
		end;
	end else begin
		{The target square is off the side of the map.}
		it.go := false;
	end;

	if it.go then begin
		{There's no reason why the move can't take place.}
		{Let's do it! Move the model.}
		SetModelLoc(M,gb^.mlist,gb^.mog,X,Y);

		{If this model is the player's model, update the POV.}
		if gb^.pov.M = M then begin
			UpdatePOV(gb^.pov,gb);
			ApplyPOV(gb^.pov,gb);
		end;

		{Update the display}
		if TileVisible(gb,X1,Y1) then
			DisplayTile(gb,X1,Y1);
		if TileLOS(gb^.pov,X,Y) then
			DisplayTile(gb,X,Y);

		{Mention if there's a trap in this square.}
		it.trap := Abs(gb^.map[X,Y].trap);
	end;
	MoveModel := it;
end;

Function GAddModel(gb: GameBoardPtr; gfx: char; AC,BC: byte; cohab: boolean; X,Y,Kind: Integer): ModelPtr;
	{Add a model to the game board and update the graphics.}
	{That's what the 'G' stands for.}
var
	it: ModelPtr;
begin
	{Actually add the model to the list. This is the easy part.}

	it := AddModel(gb^.MList,gb^.MoG,gfx,AC,BC,cohab,X,Y,Kind);

	{Update the display, if within LoS.}
	if TileLOS(gb^.pov,X,Y) then
		DisplayTile(gb,X,Y);

	{Return a pointer to the model we've added.}
	GAddModel := it;
end;

Procedure GRemoveModel(m: ModelPtr; gb: GameBoardPtr);
	{As above. Remove a model from the list, then update the display.}
var
	X,Y: Integer;
begin
	{Save the location of the model.}
	X := M^.X;
	Y := M^.Y;

	{Check- this might be the model that the PoV is attached to!}
	if gb^.POV.M = M then
		{Set the POV's model to Nil.}
		gb^.POV.M := Nil;

	{Remove the model.}
	RemoveModel(m,gb^.mlist,gb^.mog);

	{Refresh the display!}
	DisplayTile(gb,X,Y);
end;

Procedure SetOverImage(gb: GameBoardPtr; X,Y: Integer; gfx: char; color: byte);
	{Add an image to the map. Display it if it's currently}
	{visible.}
begin
	if OnTheMap(X,Y) then begin
		gb^.itm[X,Y].gfx := gfx;
		gb^.itm[X,Y].color := color;
		if TileLOS(gb^.pov,X,Y) then DisplayTile(gb,X,Y);
	end;
end;

Procedure ClearOverImage(gb: GameBoardPtr; X,Y: Integer);
	{Dispose of the OverImage at X,Y.}
begin
	if OnTheMap(X,Y) then begin
		gb^.itm[X,Y].gfx := ' ';
		if TileLOS(gb^.pov,X,Y) then DisplayTile(gb,X,Y);
	end;
end;

Function CalcObscurement(X1,Y1,X2,Y2: Integer; gb: GameBoardPtr): Integer;
	{Check the space between X1,Y1 and X2,Y2. Calculate the total}
	{obscurement value of the terrain there. Return 0 for a}
	{clear LOS, a positive number for an obscured LOS, and -1}
	{for a completely blocked LOS.}
var
	N: Integer;		{The number of points on the line.}
	t,terr: Integer;	{A counter, and a terrain type.}
	Wall: Boolean;	{Have we hit a wall yet?}
	p: Point;
	O: Integer;	{The obscurement count.}
	MO: Integer;	{Obscurement caused by an intervening model.}
begin
	if Abs(X2 - X1) > Abs(Y2 - Y1) then
		N := Abs(X2-X1)
	else
		N := Abs(Y2-Y1);

	{The obscurement count starts out with a value of 0.}
	O := 0;

	{The variable WALL represents a boundary that cannot be seen through.}
	Wall := false;

	for t := 1 to N do begin
		{Locate the next point on the line.}
		p := SolveLine(X1,Y1,X2,Y2,t);

		{Determine the terrain of this tile.}
		terr := GetTerr(gb,p.X,p.Y);

		{Update the Obscurement count.}
		O := O + TerrObscurement[Terr];

		{Increase O for models in the way.}
		if ModelPresent(gb^.mog,p.X,p.Y) then begin
			MO := FindModelXY(gb^.mlist,p.X,p.Y)^.Obs;
			O := O + MO;
		end else MO := 0;

		{If this current square is a wall,}
		{or if there is a perfectly blocking model in the square,}
		{set Wall to true.}
		if CantSeeThrough(gb^.pov,terr) or (MO = -1) then Wall := True;
	end;

	{If there's a wall in the way, Obscurement := -1}
	if Wall then
		O := -1;

	CalcObscurement := O;
end;

Function CalcObscurement(M: ModelPtr; X,Y: Integer; gb: GameBoardPtr): Integer;
	{Check the space between M and X,Y. Calculate the total}
	{obscurement value of the terrain there. Return 0 for a}
	{clear LOS, a positive number for an obscured LOS, and -1}
	{for a completely blocked LOS.}
begin
	CalcObscurement := CalcObscurement(M^.X,M^.Y,X,Y,gb);
end;

Function CalcObscurement(M1,M2: ModelPtr; gb: GameBoardPtr): Integer;
	{Check the space between M1 and M2. Calculate the total}
	{obscurement value of the terrain there. Return 0 for a}
	{clear LOS, a positive number for an obscured LOS, and -1}
	{for a completely blocked LOS.}
begin
	CalcObscurement := CalcObscurement(M1^.X,M1^.Y,M2^.X,M2^.Y,gb);
end;

Procedure MapSplat(gb: GameBoardPtr; gfx: char; color: byte; X,Y: Integer; NoLOS: Boolean);
	{Display a spurious character at location X,Y. Useful for shots,}
	{explosions, and other stuff.}
	{Set NoLOS to TRUE if you want the image printed regardless}
	{of whether the PC can see it or not.}
begin
	{Check to make sure the location lies within map bounds.}
	if OnTheMap(X,Y) then begin

		{Check to make sure that the location is visible.}
		if (NoLOS or TileLOS(gb^.pov,X,Y)) and OnTheScreen(gb,X,Y) then begin
			{Go to the appropriate screen coordinates.}
			GotoXY(ScreenX(gb,X),ScreenY(gb,Y));

			TextColor(color);
			TextBackground(Black);

			Write(gfx);
		end;
	end;
end;

Function Range(M1,M2: ModelPtr): Integer;
	{Calculate the range between M1 and M2.}
begin
	{Pythagorean theorem.}
	Range := Round(Sqrt(Sqr(M2^.X - M1^.X) + Sqr(M2^.Y - M1^.Y)));
end;

Function Range(M: ModelPtr; X,Y: Integer): Integer;
	{Calculate the range between the model and the point.}
begin
	{Pythagorean theorem.}
	Range := Round(Sqrt(Sqr(M^.X - X) + Sqr(M^.Y - Y)));
end;

Function LocateBlock(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer): Point;
	{The Line of Sight from X1,Y1 to X2,Y2 is blocked. Locate}
	{the point at which this happens. Keep going until either}
	{a wall or the edge of the map is found.}
var
	N: Integer;
	Wall: Boolean;
	P: Point;
begin
	N := 1;
	Wall := False;
	while not Wall do begin
		p := SolveLine(X1,Y1,X2,Y2,n);
		Inc(n);
		if (p.x=1) or (p.x=XMax) or (p.y=1) or (p.y=YMax) then Wall := True
		else if CantSeeThrough(gb^.pov,GetTerr(gb,p.X,p.Y)) then Wall := True
		else if ModelPresent(gb^.mog,p.X,p.Y) and (FindModelXY(gb^.mlist,p.X,p.Y)^.Obs = -1) then Wall := True;
	end;
	LocateBlock := p;
end;

Function LocateStop(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer): Point;
	{The Line of Sight from X1,Y1 to X2,Y2 is blocked. Locate}
	{the point just before this happens. Keep going until either}
	{a wall or the edge of the map is found.}
var
	N: Integer;
	Wall: Boolean;
	P,P0: Point;
begin
	N := 1;
	Wall := False;
	P0.X := X1;
	P0.Y := Y1;
	while not Wall do begin
		p := SolveLine(X1,Y1,X2,Y2,n);
		Inc(n);
		if (p.x=1) or (p.x=XMax) or (p.y=1) or (p.y=YMax) then Wall := True
		else if CantSeeThrough(gb^.pov,GetTerr(gb,p.X,p.Y)) then Wall := True
		else if ModelPresent(gb^.mog,p.X,p.Y) and (FindModelXY(gb^.mlist,p.X,p.Y)^.Obs = -1) then Wall := True
		else p0 := p;
	end;
	LocateStop := p0;
end;

Procedure NextPoint(var P: Point);
	{We're stepping through the map. Increment the tile}
	{by one. If the edge of the map is reached, start on}
	{the other side.}
begin
	Inc(p.x);
	if p.x > XMax then begin
		Inc(p.y);
		p.x := 1;
	end;
end;


Procedure WriteGameBoard(gb: GameBoardPtr; var F: Text);
	{Write all of the important info in GB to the file F.}
	{Not everything in gb will be copied- the model list,}
	{for instance, won't be. I'm assuming that new models}
	{will be generated for everything that needs one when the}
	{saved game is loaded.}
var
	P: Point;
	T,C,X,Y: Longint;
	Vis: Boolean;
begin
	{First, a descriptive message.}
	writeln(F,'*** DeadCold GameBoard Record ***');

	{Output the terrain of the map, compressed using}
	{run length encoding.}
	T := gb^.map[1,1].terr;
	C := 0;
	P.X := 1;
	P.Y := 1;
	while P.Y <= YMax do begin
		if gb^.map[P.X,P.Y].terr = t then begin
			Inc(C);
		end else begin
			writeln(F,C);
			writeln(F,T);
			T := gb^.map[P.X,P.Y].terr;
			C := 1;
		end;
		NextPoint(P);
	end;
	{Output the last terrain stretch}
	writeln(F,C);
	writeln(F,T);

	writeln(F,'***');

	{write the traps.}
	for X := 1 to XMax do begin
		for Y := 1 to YMax do begin
			if gb^.map[X,Y].Trap <> 0 then begin
				writeln(F,X);
				writeln(F,Y);
				writeln(F,gb^.map[X,Y].Trap);
			end;
		end;
	end;
	{write the sentinel.}
	writeln(F,0);

	{write the specials.}
	for X := 1 to XMax do begin
		for Y := 1 to YMax do begin
			if gb^.map[X,Y].Special <> 0 then begin
				writeln(F,X);
				writeln(F,Y);
				writeln(F,gb^.map[X,Y].Special);
			end;
		end;
	end;
	{write the sentinel.}
	writeln(F,0);

	{Output the Visibility of the map, again using run}
	{length encoding. Since there are only two possible}
	{values, just flop between them.}
	Vis := False;
	C := 0;
	P.X := 1;
	P.Y := 1;
	while P.Y <= YMax do begin
		if gb^.map[P.X,P.Y].visible = Vis then begin
			Inc(C);
		end else begin
			writeln(F,C);
			Vis := not Vis;
			C := 1;
		end;
		NextPoint(P);
	end;
	{Output the last terrain stretch}
	writeln(F,C);

end;

Function ReadGameBoard(var F: Text): GameBoardPtr;
	{We're reading the gameboard from disk.}
var
	gb: GameBoardPtr;
	P: Point;
	C,T,X,Y: Longint;
	A: String;
	Vis: Boolean;
begin
	gb := NewBoard;

	{First, get rid of the descriptive message.}
	readln(F,A);

	P.X := 1;
	P.Y := 1;
	while P.Y <= YMax do begin
		readln(F,C);	{Read Count}
		readln(F,T);	{Read Terrain}

		{Fill the map with this terrain up to Count.}
		for X := 1 to C do begin
			gb^.map[P.X,P.Y].terr := t;
			NextPoint(P);
		end;
	end;

	{Read the second descriptive label.}
	readln(F,A);

	{Read the traps.}
	Repeat
		readln(F,X);
		if X <> 0 then begin
			readln(F,Y);
			readln(F,gb^.map[X,Y].trap);
		end;
	until X = 0;

	{Read the specials.}
	Repeat
		readln(F,X);
		if X <> 0 then begin
			readln(F,Y);
			readln(F,gb^.map[X,Y].special);
		end;
	until X = 0;

	{Read the visibility data.}
	Vis := False;
	P.X := 1;
	P.Y := 1;
	while P.Y <= YMax do begin
		readln(F,C);	{Read Count}

		{Fill the map with this terrain up to Count.}
		for X := 1 to C do begin
			gb^.map[P.X,P.Y].visible := Vis;
			NextPoint(P);
		end;

		Vis := not Vis;
	end;

	ReadGameBoard := gb;
end;

finalization
	ClrScr;

end.
