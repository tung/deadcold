unit RandMaps;

interface

uses crt,RPGDice,TexModel,TexMaps,plotbase,dcitems,critters,GameBook,charts,cwords,dcchars,texutil;

Const
	SceneSize = 12;

Type
	Room = Record	{This is the description for one room.}
		Style: Integer;
		X,Y,W,H: Integer;	{X,Y,Width,Height}
		Floor,Wall: Integer;	{What terr type should be used for the floor and the wall.}
		Next: ^Room;
	end;
	RoomPtr = ^Room;
	RStyle = Record	{This describes a type of room}
		Name: String;
		Floor,Wall: Integer;
		SP: Byte;	{% of halls which should be service tunnels}
		WC,WR,HC,HR: Byte;	{Constants for determining size.}
	end;
	Scenery = Array [1..SceneSize,1..SceneSize] of byte;
	SceneryPtr = ^Scenery;

Const
	EmptyTerrain = 6;

	{Direction 1 corresponds to 3 O'Clock; 2 is 6 O'Clock, 3 is 9 O'Clock, and 4 is 12 O'Clock.}
	{This ordering should make Right/Left rotations easier.}
	AngDir: Array [0..5,1..2] of Integer = (
		(0,-1),(1,0),(0,1),(-1,0),(0,-1),(1,0)
	);
	RNormStyle = 1;
	REngineWorks = 2;

	NumStyle = 21;
	{And now, our interior decoration manual.}
	IntDec: Array [1..NumStyle] of RStyle = (
		(	Name: 'Normal Room';
			Floor: 2; Wall: 3; SP: 15;
			WC: 5; WR: 20; HC: 5; HR: 12	),
		(	Name: 'Engine Works';
			Floor: 5; Wall: 6; SP: 100;
			WC: 5; WR: 5; HC: 5; HR: 5	),
		(	Name: 'Lounge';
			Floor: 15; Wall: 3; SP: 20;
			WC: 12; WR: 12; HC: 7; HR: 10	),
		(	Name: 'Security Center';
			Floor: 2; Wall: 3; SP: 0;
			WC: 8; WR: 12; HC: 5; HR: 10	),
		(	Name: 'Storage Room';
			Floor: 5; Wall: 3; SP: 25;
			WC: 20; WR: 10; HC: 10; HR: 10	),

		(	Name: 'Obstructed room';
			Floor: 2; Wall: 3; SP: 45;
			WC: 5; WR: 20; HC: 5; HR: 20	),
		(	Name: 'Shuttle Bay';
			Floor: 2; Wall: 3; SP: 30;
			WC: 20; WR: 12; HC: 20; HR: 12	),
		(	Name: 'Transitway Left';
			Floor: 2; Wall: 3; SP: 5;
			WC: 9; WR: 1; HC: 6; HR: 3	),
		(	Name: 'Transitway Right';
			Floor: 2; Wall: 3; SP: 5;
			WC: 9; WR: 1; HC: 6; HR: 3	),
		(	Name: 'Residential Block';
			Floor: 2; Wall: 3; SP: 10;
			WC: 17; WR: 18; HC: 15; HR: 3	),

		(	Name: 'Andros Guero Quarters';
			Floor: 2; Wall: 3; SP: 10;
			WC: 17; WR: 18; HC: 15; HR: 3	),
		(	Name: 'Chapel';
			Floor: 40; Wall: 3; SP: 2;
			WC: 12; WR: 7; HC: 12; HR: 12	),
		(	Name: 'Reliquary';
			Floor: 2; Wall: 3; SP: 0;
			WC: 12; WR: 18; HC: 12; HR: 12	),
		(	Name: 'Medical Center';
			Floor: 15; Wall: 3; SP: 25;
			WC: 16; WR: 16; HC: 8; HR: 5	),
		(	Name: 'Gravesite';
			Floor: 40; Wall: 3; SP: 3;
			WC: 15; WR: 32; HC: 8; HR: 25	),

		(	Name: 'Computer Control Center';
			Floor: 5; Wall: 6; SP: 100;
			WC: 5; WR: 5; HC: 5; HR: 5	),
		(	Name: 'Cryogenics Lab';
			Floor: 5; Wall: 3; SP: 70;
			WC: 12; WR: 8; HC: 15; HR: 20	),
		(	Name: 'Transitway Down';
			Floor: 2; Wall: 3; SP: 5;
			WC: 9; WR: 1; HC: 6; HR: 3	),
		(	Name: 'Transitway Up';
			Floor: 2; Wall: 3; SP: 5;
			WC: 9; WR: 1; HC: 6; HR: 3	),
		(	Name: 'Museum';
			Floor: 15; Wall: 3; SP: 2;
			WC: 21; WR: 5; HC: 19; HR: 3	),

		(	Name: 'DesCartes Control Center';
			Floor: 5; Wall: 6; SP: 100;
			WC: 10; WR: 5; HC: 10; HR: 5	)

	);

	RocketShip: Scenery = (
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		( 27,25,25,25,25,24, 0, 0, 0, 0, 0, 0	),
		(  0, 0,20,20,20,20, 8,24,28, 0, 0, 0	),
		(  0,27,26,29,29,26,29,20,25,25,20, 0	),
		(  0,27,20,29,29, 8,29,29,29,21,22,23	),
		(  0,27,26,29,29,26,29,20,25,25,20, 0	),
		(  0, 0,20,20,20,20, 8,24,28, 0, 0, 0	),
		( 27,25,25,25,25,24, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	)	);

	TransitChassis: Scenery = (
		( 36,36,36, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		( 30, 0,31, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	)
	);

	Apartment: Scenery = (
		( 16,16,16, 8,16,16,16, 0, 0, 0, 0, 0	),
		( 16,15,15,15,15,15,16, 0, 0, 0, 0, 0	),
		( 16,15,15,15,14,15,16, 0, 0, 0, 0, 0	),
		( 16,15,15,14,37,14,16, 0, 0, 0, 0, 0	),
		( 16,15,15,15,14,15,16, 0, 0, 0, 0, 0	),
		( 16,16,16,15,15,15,16, 0, 0, 0, 0, 0	),
		( 16,38, 8,15,15,19,16, 0, 0, 0, 0, 0	),
		( 16,16,16,16,16,16,16, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	)
	);

	Capsule: Scenery = (
		( 48,49,50, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		( 47,45,47, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		( 46,12,46, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	),
		(  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	)
	);


	Level_Contents: Array [0..Num_Levels] of string = (
		'8 9',
		' 7 10 14  8 12  9 11  5',
		' 4  8 15  9 12 15 16 17',
		' 8  9 18',
		' 8  5  9',
		' 8  9',
		' 4  8  4  9',
		' 8  9 19',
		'12  8 20 10 13  9 12 21'
	);


Procedure RectFill(gb: GameBoardPtr; X1,Y1,X2,Y2,terr: integer);
Procedure RoomFill(gb: GameBoardPtr; X1,Y1,X2,Y2,W,F: integer);
Function AddRoom(var LList: RoomPtr): RoomPtr;
Procedure RandomLevel(SC: ScenarioPtr; R: RoomPtr);
Procedure GenerateCurrentLevel( SC: ScenarioPtr );
Procedure GotoLevel( SC: ScenarioPtr; N, Entry_Terrain: Integer );


implementation

Const
	ItsAFloor: Boolean = False;
	NormHall = 1;
	ServTunnel = 2;
	HallStyle: Byte = NormHall;
	WallStyle: Integer = 3;
	StorageRoomItem = 20;	{% chance of item in each pile.}
	StorageRoomMaxRolls = 3;  {Max # of items to be generated per pile.}
	StorageRoomRobot = 8;	{% chance of a robot, if no item.}
	SecurityCellItem = 88;	{% chance of a stockpile in a security cell.}
	SecurityCellNum = 4;	{Max number of items per cell.}
	SecurityCellZombie = 35; {% chance of a zombie, if no stockpile.}
	CryptItem = 25;		{% chance of a stockpile in a crypt tile.}
	CryptNum = 3;		{Max number of items per cell.}
	CryptCritter = 70;	{% chance of a zombie, if no stockpile.}

Procedure RectFill(gb: GameBoardPtr; X1,Y1,X2,Y2,terr: integer);
	{Fill the given rectangular area with terrain type terr}
var
	x,y:	Integer;
begin
	for x := x1 to x2 do
		for y := y1 to y2 do
			gb^.map[x,y].terr := terr;
end;

Procedure RoomFill(gb: GameBoardPtr; X1,Y1,X2,Y2,W,F: integer);
	{Create a room, with wall type W and floor type F.}
var
	x,y:	Integer;
begin
	for x := x1 to x2 do
		for y := y1 to y2 do begin
			if (X=X1) or (X=X2) or (Y=Y1) or (Y=Y2) then
				gb^.map[x,y].terr := W
			else
				gb^.map[X,Y].terr := F;
		end;
end;

Procedure AddScenery(gb: GameBoardPtr; X0,Y0: Integer; Scene: SceneryPtr; Reveal: Boolean);
	{Add the scenery to the map}
var
	X,Y: Integer;
begin
	for X := 1 to SceneSize do begin
		for Y := 1 to SceneSize do begin
			if OnTheMap(X+X0-1,Y+Y0-1) then begin
				{Apparently, I made a boo-boo when defining things, so now}
				{Scenery data is stored with its coordinates as Y,X instead of X,Y.}
				if (Scene^[Y,X] <> 0) then begin
					gb^.map[X+X0-1,Y+Y0-1].terr := Scene^[Y,X];
					if reveal then gb^.map[X+X0-1,Y+Y0-1].visible := true;
				end;
			end;
		end;
	end;
end;


Function LastRoom(LList: RoomPtr): RoomPtr;
	{Search through the linked list, and return the last element.}
	{If LList is empty, return Nil.}
begin
	if LList <> Nil then
		while LList^.Next <> Nil do
			LList := LList^.Next;
	LastRoom := LList;
end;

Function AddRoom(var LList: RoomPtr): RoomPtr;
	{Add a new element to the end of LList.}
var
	it: RoomPtr;
begin
	{Allocate memory for our new element.}
	New(it);
	if it = Nil then exit;

	{Initialize values.}
	it^.Next := Nil;
	it^.Style := 0;
	it^.X := -1;
	it^.Y := -1;
	it^.Floor := 2;
	it^.Wall := 3;

	{Attach IT to the list.}
	if LList = Nil then
		LList := it
	else
		LastRoom(LList)^.Next := it;

	{Return a pointer to the new element.}
	AddRoom := it;
end;

Procedure DisposeRoomList(var LList: RoomPtr);
	{Dispose of the list, freeing all associated system resources.}
var
	LTemp: RoomPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Function NextRoom(RList,R: RoomPtr): RoomPtr;
	{Return the address of the next room in the list.}
	{If we're already looking at the last room, loop around}
	{to the first one again.}
var
	it: RoomPtr;
begin
	it := R^.Next;
	if it = Nil then it := RList;
	NextRoom := it;
end;

Procedure InitRoom(R: RoomPtr);
	{Given room R, whose Style field has been filled out,}
	{set appropriate values for each of the other fields.}
begin
	R^.W := IntDec[R^.Style].WC + Random(IntDec[R^.Style].WR);
	R^.H := IntDec[R^.Style].HC + Random(IntDec[R^.Style].HR);
	R^.Wall := IntDec[R^.Style].Wall;
	R^.Floor := IntDec[R^.Style].Floor;

	{Special check- make sure that a lounge area will look pretty!}
	if (R^.Style = 3) or (R^.Style = 12) then begin
		if not Odd(R^.H) then Inc(R^.H);
		if not Odd(R^.W) then Inc(R^.W);
	end;
end;

Function NewRoom(var RList: RoomPtr): RoomPtr;
	{Add a random new room to the list.}
var
	R: RoomPtr;
begin
	R := AddRoom(RList);

	{Decide upon the style of this room. For now,}
	{just pick one at random.}
	R^.Style := Random(6)+1;

	InitRoom(R);

	NewRoom := R;
end;

Function AreaClear(GB: GameBoardPtr; X1,Y1,W,H: Integer): Boolean;
	{Search the area defined by X,Y,W and H on the game map.}
	{Return True if the area consists of blank terrain.}
	{Return False if there's anything else there.}
var
	it: Boolean;
	X,Y,X2,Y2: Integer;
begin
	{Initialize variables.}
	it := true;
	X2 := X1 + W - 1;
	Y2 := Y1 + H - 1;

	for X := X1 to X2 do begin
		for Y := Y1 to Y2 do begin
			if gb^.map[X,Y].terr <> EmptyTerrain then it := False;
		end;
	end;

	AreaClear := it;
end;

Function IsASpace(gb: GameBoardPtr; X,Y: Integer): Boolean;
	{Check the space indicated. Return True if it is passable}
	{terrain, False otherwise.}
var
	it: Boolean;
begin
	if not OnTheMap( X , Y ) then Exit( TRUE );

	if (HallStyle <> ServTunnel) and (gb^.map[X,Y].terr = Crawlspace) then it := false
	else if (TerrPass[gb^.map[X,Y].terr] > 0) then it := true
	else if (gb^.map[X,Y].terr = ClosedDoor) or (gb^.map[X,Y].terr = ClosedServicePanel) or (gb^.map[X,Y].terr = HiddenServicePanel) then it := true
	else it := false;
	IsASpace := it;
end;

Function IsAWall(gb: GameBoardPtr; X,Y: Integer): Boolean;
	{Check the space indicated. Return True if it is a plain}
	{wall, False otherwise.}
var
	it: Boolean;
begin
	if TerrPass[gb^.map[X,Y].terr] = 0 then it := true
	else it := false;
	IsAWall := it;
end;


Function PathClear(gb: GameBoardPtr; X,Y,D,L: Integer): Integer;
	{Check the path indicated by the details given. In particular,}
	{check to see whether or not this path will intersect with}
	{a room or corridor in a bad way.}
var
	t,r: Integer;
begin
	r := 1;
	for t := 1 to L do begin
		if IsAWall(gb,X,Y) then begin
			if IsASpace(gb,X+AngDir[D+1,1],Y+AngDir[D+1,2]) then begin
				r := 1;
				break;
			end;
			if IsASpace(gb,X+AngDir[D-1,1],Y+AngDir[D-1,2]) then begin
				r := -1;
				break;
			end;
		end;
		X := X + AngDir[D,1];
		Y := Y + AngDir[D,2];
	end;
	PathClear := t * r;
end;

Procedure PlotWall(gb: GameBoardPtr; X,Y: Integer);
	{Draw a wall in the current wall style. The rule is as}
	{follows: If intersecting empty terrain or default wall}
	{type, draw the wall as normal. If intersecting a crawlspace}
	{then set down a HiddenServicePanel instead of a wall.}
	{If intersecting any other kind of space, don't do anything.}
begin
	if IsAWall(gb,X,Y) then gb^.map[X,Y].terr := WallStyle
	else if gb^.map[X,Y].terr = Crawlspace then gb^.map[X,Y].terr := HiddenServicePanel;
end;

Procedure PlotDoor(gb: GameBoardPtr; X,Y: Integer);
	{Plot a door at location X,Y. Select one of the possible}
	{door types randomly. It may be open or closed, or even}
	{a hidden service panel.}
begin
	{There's a very small chance that instead of a regular door,}
	{we'll plot a service panel instead.}
	if Random(100) = 23 then begin
		{Plot service panel.}
		if Random(5) = 1 then begin
			if Random(3) = 1 then begin
				gb^.map[x,y].terr := OpenServicePanel;
			end else begin
				gb^.map[x,y].terr := ClosedServicePanel;
			end;
		end else begin
			gb^.map[x,y].terr := HiddenServicePanel;
		end;
	end else begin
		{Plot door.}
		if Random(3) = 1 then begin
			{Open door.}
			gb^.map[x,y].terr := OpenDoor;
		end else begin
			{Closed door.}
			gb^.map[x,y].terr := ClosedDoor;
		end;
	end;
end;

Procedure RenderCorner(gb: GameBoardPtr; X,Y: Integer);
	{Render a corner, in the current wall style.}
var
	XX,YY: Integer;
begin
	if HallStyle = ServTunnel then exit;

	{Make sure that our center point is within bounds.}
	if X<2 then X := 2
	else if X>=XMax then X := XMax - 1;
	if Y<2 then Y := 2
	else if Y>=YMax then Y := YMax - 1;

	{Do the rendering. Just replace all walls in the vicinity}
	{with the wall style currently selected.}
	for XX := X-1 to X+1 do
		for YY := Y-1 to Y+1 do
			PlotWall(gb,XX,YY);
end;

Procedure RenderCorridorSection(gb: GameBoardPtr; X,Y,D: Integer);
	{Render a single block of corridor.}
begin
	{Plot the floor, if appropriate.}
	if HallStyle = NormHall then begin
		if (TerrPass[gb^.map[X,Y].terr] = 0) or (gb^.map[X,Y].terr = Crawlspace) then begin
			{If we have a wall or a crawlspace, draw a corridor through it.}
			if ItsAFloor and (Random(2) = 1) then
				PlotDoor(gb,X,Y)
			else begin
				if (TerrPass[gb^.map[X+AngDir[D,1],Y+AngDir[D,2]].terr] > 0) and (Random(2) = 1) then
					PlotDoor(gb,X,Y)
				else
					gb^.map[X,Y].terr := 2;
			end;
			ItsAFloor := False;
		end else if (TerrPass[gb^.map[X,Y].terr] < 0) then begin
			ItsAFloor := False;
		end else begin
			ItsAFloor := True;
		end;
	end else if HallStyle = ServTunnel then begin
		{Here are the rules. If the current square is a}
		{standard wall, change it to a HiddenServicePanel.}
		{If it's empty terrain, draw a crawlspace.}
		if gb^.map[X,Y].terr = EmptyTerrain then begin
			gb^.map[X,Y].terr := Crawlspace;
		end else if (TerrPass[gb^.map[X,Y].terr] = 0) then begin
			gb^.map[X,Y].terr := HiddenServicePanel;
		end;
	end;

	if HallStyle <> ServTunnel then begin
		{Service tunnels don't get walls surrounding them.}
		PlotWall(gb,X + AngDir[D+1,1],Y + AngDir[D+1,2]);
		PlotWall(gb,X + AngDir[D-1,1],Y + AngDir[D-1,2]);
	end;
end;

Procedure RenderCorridor(gb: GameBoardPtr; X1,Y1,D,L: Integer);
	{Draw a corridor onto the map, starting at X,Y and}
	{proceeding L units in direction D.}
var
	X,Y,T: Integer;
begin
	X := X1;
	Y := Y1;
	ItsAFloor := False;

	for t := 1 to L do begin
		RenderCorridorSection(gb,X,Y,D);
		X := X + AngDir[D,1];
		Y := Y + AngDir[D,2];
	end;

	{Finish off the corner of the hall.}
	RenderCorner(gb,X - AngDir[D,1],Y - AngDir[D,2]);
end;

Procedure RenderWTunnel(gb: GameBoardPtr; X,Y,D: Integer);
	{Start rendering a worm tunnel. Yay!}
	{This tunnel has no preset length or destination.}
	{It keeps going until either it runs out of map or it}
	{intersects a room/corridor.}
var
	KeepGoing: Boolean;
	t: Integer;
{WTunnel Procedures Block}
	procedure ChangeDirection;
	begin
		D := D + Random(2) - Random(2);
		if D < 1 then D := 4
		else if D > 4 then D := 1;
		RenderCorner(gb,X,Y);
	end;

begin
	KeepGoing := True;

	{Because WTunnels will be set up on room walls, initialize}
	{this value to True.}
	ItsAFloor := True;

	{Check- if this is not a good place to start doing a WTunnel,}
	{exit without rendering anything.}
	if (X = 1) or (X = XMax) or (Y = 1) or (Y = YMax) then begin
		KeepGoing := False;
	end else if IsASpace(gb,X,y) or IsASpace(gb,X+AngDir[D+1,1],Y+AngDir[D+1,2]) or IsASpace(gb,X+AngDir[D-1,1],Y+AngDir[D-1,2]) then begin
		KeepGoing := False;
	end;

	t := 0;
	While KeepGoing do begin
		Inc(t);
		if IsASpace(gb,X,y) or IsASpace(gb,X+AngDir[D+1,1],Y+AngDir[D+1,2]) or IsASpace(gb,X+AngDir[D-1,1],Y+AngDir[D-1,2]) then begin
			KeepGoing := False;
		end else if Random(1000) = 0 then begin
			KeepGoing := False;
		end;

		RenderCorridorSection(gb,X,Y,D);

		{Maybe change direction now.}
		{First, check for the edge of the map.}
		if (X+AngDir[D,1]=1) or (X+AngDir[D,1]=XMax) or (Y+AngDir[D,2]=1) or (Y+AngDir[D,2]=YMax) then begin
			ChangeDirection;
		end else if (Random(33) = 12) and (t > 1) then begin
			ChangeDirection;
		end;

		{Move to the next square.}
		X := X + AngDir[D,1];
		Y := Y + AngDir[D,2];

		{Check for the edge of the map}
		if (X = 1) or (X = XMax) or (Y = 1) or (Y = YMax) then begin
			KeepGoing := False;
		end;
	end;
	RenderCorner(gb,X,Y);

end;

Procedure AddWTunnels(gb: GameBoardPtr; R: RoomPtr; N: Integer);
	{Attempt to add dN wormtunnels to room R.}
var
	T,D,X,Y: Integer;
begin
	For t := 1 to Dice(N) do begin
		{Determine the starting direction of this tunnel.}
		{This will decide what wall it's starting in.}
		D := Random(4) + 1;
		X := R^.X;
		Y := R^.Y;

		if D = 1 then begin
			Y := Y + Random(R^.H - 2) + 1;
			X := X + R^.W - 1;
		end else if D = 3 then begin
			Y := Y + Random(R^.H - 2) + 1;
		end else if D = 2 then begin
			X := X + Random(R^.W - 2) + 1;
			Y := Y + R^.H - 1;
		end else begin
			X := X + Random(R^.W - 2) + 1;
		end;

		{Determine the style of the tunnel.}
		if (Random(100)+1) <= IntDec[R^.Style].SP then
			HallStyle := ServTunnel
		else
			HallStyle := NormHall;

		RenderWTunnel(gb,X,Y,D);
	end;
end;

Procedure ConnectRoom(gb: GameBoardPtr; R1,R2: RoomPtr);
	{Connect R1 to R2 by means of a hallway.}
var
	X1,Y1,X2,Y2: Integer;
	T,DH,DV: Integer;
begin
	{Before we start on the connection tunnels, let's add some}
	{random tunnels to the room.}
	AddWTunnels(gb,R1,4);

	{Select the origin points of the corridor in both rooms.}
	X1 := Random(R1^.W - 2) + R1^.X + 1;
	Y1 := Random(R1^.H - 2) + R1^.Y + 1;
	X2 := Random(R2^.W - 2) + R2^.X + 1;
	Y2 := Random(R2^.H - 2) + R2^.Y + 1;

	IF x2>x1 then DH := 1
	else DH := 3;

	T := 0;
	while (Abs(PathClear(gb,X1,Y1,DH,Abs(X2-X1)+1)) <> (Abs(X2-X1)+1)) and (T < 30) do begin
		Y1 := Random(R1^.H - 2) + R1^.Y + 1;
		Inc(t);
	end;

	if Y2 > Y1 then DV := 2
	else DV := 4;

	t := 0;
	while (Abs(PathClear(gb,X2,Y1,DV,Abs(Y2-Y1)+1)) <> (Abs(Y2-Y1)+1)) and (T < 30) do begin
		X2 := Random(R2^.W - 2) + R2^.X + 1;
		Inc(t);
	end;

	{These halls, which connect the key rooms, are more likely}
	{to be service tunnels than they are to be normal hallways.}
	if (R1^.Style = REngineWorks) or (R2^.Style = REngineWorks) then
		HallStyle := ServTunnel
	else if (Random(100)+1) > IntDec[R1^.Style].SP then
		HallStyle := NormHall
	else
		HallStyle := ServTunnel;


	{Horizontal Tunnel}
	RenderCorridor(gb,X1,Y1,DH,Abs(X2-X1)+1);

	{Vertical Tunnel}
	RenderCorridor(gb,X2,Y1,DV,Abs(Y2-Y1)+1);

end;

Procedure PlaceItemCache( SC: ScenarioPtr; X , Y: Integer );
	{ Place a number of random, highly valuable items in this spot. }
const
	{ This array tells what treasure type chart to use. }
	TTL: Array [0..9] of byte = (
		TType_AllMedicene,TType_AllMedicene,TType_AllAmmo,TType_AllAmmo,TType_AllAmmo,
		TType_BasicGuns,TType_BasicWeps,TType_TechnoItems,TType_SpaceGear,TType_StorageRoom
	);
var
	N,T: Integer;
	I: DCItemPtr;
begin
	{ Determine how many items to generate. }
	N := Random(10) + 1;

	{ Place N items. }
	for T := 1 to N do begin
		I := GenerateItem(SC,TTL[Random(10)]);
		PlaceDCItem(SC^.gb,SC^.ig,I,X,Y);
	end;
end;

Procedure DetailLounge(SC: ScenarioPtr; R: RoomPtr);
	{Add details needed for a lounge area.}
var
	NX,NY,T: Integer;
begin
	{Determine how many chairs to add, horiz and vert.}
	NX := (R^.W - 3) div 2;
	NY := (R^.H - 3) div 2;

	for t := 1 to NX do begin
		SC^.gb^.map[R^.X+t*2,R^.Y+2].terr := chair;
		SC^.gb^.map[R^.X+t*2,R^.Y+2*NY].terr := chair;
	end;
	for t := 1 to NY do begin
		SC^.gb^.map[R^.X+2,R^.Y+t*2].terr := chair;
		SC^.gb^.map[R^.X+2*NX,R^.Y+t*2].terr := chair;
	end;
end;

Procedure DetailSecArea(SC: ScenarioPtr; R: RoomPtr);
	{Draw in the details appropriate for the security area.}
const
	SecTrap: Array [1..10] of byte = (3,2,2,2,2,2,2,3,3,3);
{*** DetailSecArea Procedures Block ***}
	Procedure SecCell(X,Y,D: Integer);
		{Draw a 3 x 3 security cell at location X,Y.}
	var
		N,T: Integer;
		I: DCItemPtr;
	begin
		RoomFill(SC^.gb,X,Y,X+2,Y+2,SecureWall,R^.Floor);
		{Add a door... with alarm.}
		SC^.gb^.map[X+1+D,Y+1].terr := ClosedDoor;
		SC^.gb^.map[X+1+D*2,Y+1].trap := -4;

		if (Random(100)+1) <= SecurityCellItem then begin
			{Add an item...}
			N := Random( SecurityCellNum ) + 1;
			for t := 1 to N do begin
				I := GenerateItem(SC,TType_SecurityArea);
				PlaceDCItem(SC^.gb,SC^.ig,I,X+1,Y+1);
			end;

			{... then add a trap}
			if Random(100) <> 74 then SC^.gb^.map[X+1,Y+1].trap := -SecTrap[Random(10)+1];

		end else if (Random(100)+1) <= SecurityCellZombie then begin
			AddCritter(SC^.CList,SC^.gb,3,X+1,Y+1);

		end else if Random(3) <> 1 then begin
			{Just add a trap.}
			SC^.gb^.map[X+1,Y+1].trap := -SecTrap[Random(10)+1];
		end;
	end;
var
	t,n,x,y: Integer;
begin

	if R^.W >= 11 then begin
		{Add two lines of security cells}
		for t := 1 to ((R^.H - 4) div 3) do begin
			SecCell(R^.X+2,R^.Y-1+t*3,1);
			SecCell(R^.X+R^.W-5,R^.Y-1+t*3,-1);
		end;
	end else if R^.W >= 8 then begin
		{Add one line of security cells}
		for t := 1 to ((R^.H - 4) div 3) do begin
			SecCell(R^.X+2,R^.Y-1+t*3,1);
		end;
	end;

	{Add security robots.}
	if Random(2) = 1 then AddCritter(SC^.CList,SC^.gb,5,R^.X+1,R^.Y+1);
	if Random(2) = 1 then AddCritter(SC^.CList,SC^.gb,5,R^.X+1,R^.Y+R^.H-2);
	if Random(2) = 1 then AddCritter(SC^.CList,SC^.gb,5,R^.X+R^.W-2,R^.Y+1);
	if Random(2) = 1 then AddCritter(SC^.CList,SC^.gb,5,R^.X+R^.W-2,R^.Y+R^.H-2);
	X := R^.X + ( R^.W div 2 );
	Y := R^.Y + ( R^.H div 2 );
	if IsASpace( SC^.GB , X , Y ) and ( Random( 10 ) = 1 ) then begin
		AddCritter(SC^.CList,SC^.gb,21,X,Y);
	end;

	{ Add some alarms and/or traps. }
	N := Random( 10 );
	for t := 1 to N do begin
		X := Random( R^.W - 2 ) + R^.X + 1;
		Y := Random( R^.H - 2 ) + R^.Y + 1;
		if IsASpace( SC^.GB , X , Y ) and ( SC^.GB^.map[X,Y].Trap = 0 ) then begin
			if Random( 10 ) = 1 then SC^.GB^.Map[X,Y].trap := -2
			else SC^.GB^.Map[X,Y].trap := -4;
		end;
	end;
end;

Procedure DetailStorage(SC: ScenarioPtr; R: RoomPtr);
	{Draw in the details appropriate for the storage room.}
const
	Robo: Array [1..10] of integer = (1,1,1,1,5, 1,1,1,1,5);
var
	X,Y,N: Integer;
	I: DCItemPtr;
begin
	{Loop through each avaliable storage pile position. For}
	{each one, add a pile of goods, a robot of some type, or}
	{nothing at all.}
	for X := 1 to ((R^.W-5) div 2) do begin
		for Y := 1 to ((R^.H-5) div 2) do begin
			if (Random(100)+1) <= StorageRoomItem then begin
				{We are going to stick one (or more) items on the floor at this position.}
				N := 1;
				repeat
					Inc(N);
					I := GenerateItem(SC,TType_StorageRoom);
					PlaceDCItem(SC^.gb,SC^.ig,I,R^.X+(X*2)+1,R^.Y+(Y*2)+1);
				until ((Random(100)+1) > StorageRoomItem) or (N >= StorageRoomMaxRolls);
			end else if (Random(100)+1) <= StorageRoomRobot then begin
				{There's no item here... so, we're gonna add a robot instead.}
				AddCritter(SC^.CList,SC^.gb,Robo[Random(10)+1],R^.X+(X*2)+1,R^.Y+(Y*2)+1);
			end;
		end;
	end;

end;

Procedure DetailBigBox(SC: ScenarioPtr; R: RoomPtr);
	{Why such a strange name? Because that's all this room}
	{is- a regular room with a huge box-shaped obstacle in}
	{the middle.}
var
	N,T,D,X,Y: Integer;
begin
	if Random(3) = 1 then begin
		{Hollow box.}
		if Random(99) = 23 then
			RoomFill(SC^.gb,R^.X+2,R^.Y+2,R^.X+R^.W-3,R^.Y+R^.H-3,SecureWall,4)
		else
			RoomFill(SC^.gb,R^.X+2,R^.Y+2,R^.X+R^.W-3,R^.Y+R^.H-3,SecureWall,5);

		{Add some entry points, maybe.}
		N := RollStep(2) - 1;
		for t := 1 to N do begin
			D := Random(4) + 1;
			X := R^.X+2;
			Y := R^.Y+2;

			if D = 1 then begin
				Y := Y + Random(R^.H - 6) + 1;
				X := X + R^.W - 5;
			end else if D = 3 then begin
				Y := Y + Random(R^.H - 6) + 1;
			end else if D = 2 then begin
				X := X + Random(R^.W - 6) + 1;
				Y := Y + R^.H - 5;
			end else begin
				X := X + Random(R^.W - 6) + 1;
			end;
			SC^.gb^.map[X,Y].terr := HiddenServicePanel;
		end;
	end else begin
		{Filled box.}
		RoomFill(SC^.gb,R^.X+2,R^.Y+2,R^.X+R^.W-3,R^.Y+R^.H-3,SecureWall,R^.Wall);
	end;
end;

Procedure DetailShuttleBay(SC: ScenarioPtr; R: RoomPtr);
	{Draw the spaceship for the shuttle bay.}
var
	T: Integer;
	MP: MPUPtr;
	I: DCItemPtr;
begin
	AddScenery(SC^.gb,R^.X+5,R^.Y+5,@RocketShip,True);

	{Add the plot arcs and the triggers for the message to be}
	{printed when the PC first exits the spaceship.}
	{7,3 7,9 8,3 8,9}
	SC^.gb^.map[R^.X+11,R^.Y+ 7].special := 1;
	SC^.gb^.map[R^.X+11,R^.Y+13].special := 1;
	SC^.gb^.map[R^.X+12,R^.Y+ 7].special := 1;
	SC^.gb^.map[R^.X+12,R^.Y+13].special := 1;
	for t := R^.X to (R^.X + R^.W - 1) do begin
		SC^.gb^.map[T,R^.Y].special := 2;
		SC^.gb^.map[T,R^.Y + R^.H - 1].special := 2;
	end;
	for t := R^.Y to (R^.Y + R^.H - 1) do begin
		SC^.gb^.map[R^.X,T].special := 2;
		SC^.gb^.map[R^.X + R^.W - 1,T].special := 2;
	end;

	{ Add the entry messages. }
	SetSAtt( SC^.PLLocal , 'MS1 <if= V1 0 V= 1 1 print ExitShipMsg>');
	SetSAtt( SC^.PLLocal , 'msgEXITSHIPMSG <You step out into the shuttle bay. There are no maintenance crews, no security teams, to greet your arrival. The only noise is the distant hum of the ventilators.>');
	SetSAtt( SC^.PLLocal , 'MS2 <if= V1 1 V= 1 2 print ExitHangarMsg>');
	SetSAtt( SC^.PLLocal , 'msgEXITHANGARMSG <The design of this level is characteristic of many old space stations. New modules were simply welded on as needed, resulting in a confusing and unplanned mass of tunnels. Finding your way may be difficult.>');

	{ Add the maintenance robot. }
	AddCritter(SC^.CList,SC^.gb,1,R^.X+1,R^.Y+1);

	{ Add a handymap. }
	I := NewDCItem;
	I^.IKind := IKIND_Electronics;
	I^.ICode := 1;
	PlaceDCItem(SC^.gb,SC^.ig,I, R^.X+8 , R^.Y+10);


	MP := AddMPU( SC^.Comps , SC^.GB , 1 , R^.X + R^.W - 3 , R^.Y + R^.H - 3 );
	MP^.Attr := '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15';
end;

Procedure DetailTransitway(SC: ScenarioPtr; R: RoomPtr; Door: Integer );
	{Draw a left-leading transit tube.}
begin
	AddScenery(SC^.gb,R^.X+3,R^.Y+2,@TransitChassis,False);
	SC^.GB^.Map[ R^.X + 4 , R^.Y + 3 ].terr := Door;
end;

Procedure DetailResidence(SC: ScenarioPtr; R: RoomPtr);
	{Draw some living quarters.}
var
	N,T: Integer;
begin
	{ Do a big internal box. }
	RoomFill( SC^.gb , R^.X + 2 , R^.Y + 2 , R^.X + R^.W - 3 , R^.Y + R^.H - 3 , 16 , 6 );

	{Figure out how many apartments we have space to add.}
	N := (R^.W - 5) div 6;

	for t := 0 to ( N-1 ) do begin
		AddScenery( SC^.gb , R^.X+2+T*6 , R^.Y+2 , @Apartment , False );
	end;
end;

Procedure DetailAGQ(SC: ScenarioPtr; R: RoomPtr);
	{Detail Andros Guero's quarters. This is where the PC}
	{can find Andros's security pass and also his diary.}
var
	N: Integer;
	I: DCItemPtr;
begin
	{Start by detailing this area as you would any residence.}
	DetailResidence(SC,R);

	{Next, detail Andros's place. Put blood stains on the floor,}
	{and add the needed items.}
	N := Random((R^.W - 5) div 6);

	{Add the security card.}
	I := NewDCItem;
	I^.IKind := IKIND_KeyItem;
	I^.ICode := 1;
	PlaceDCItem(SC^.gb,SC^.ig,I, R^.X+5+N*6 , R^.Y+7);

	{Add the diary.}
	I := NewDCItem;
	I^.IKind := IKIND_Book;
	I^.ICode := 1;
	PlaceDCItem(SC^.gb,SC^.ig,I, R^.X+5+N*6 , R^.Y+8);

	{Add some blood stains.}
	SC^.gb^.map[R^.X+5+N*6 , R^.Y+7].terr := 10;
	SC^.gb^.map[R^.X+5+N*6 , R^.Y+8].terr := 10;
	SC^.gb^.map[R^.X+6+N*6 , R^.Y+7].terr := 10;
	SC^.gb^.map[R^.X+4+N*6 , R^.Y+6].terr := 10;
end;

Procedure DetailChapel(SC: ScenarioPtr; R: RoomPtr);
	{Draw in the details for the chapel type room.}
var
	t,X,CX: Integer;
	I: DCItemPtr;
begin
	{Determine the midpoint of the chapel.}
	CX := R^.X + (( R^.W + 1 ) div 2) - 1;

	{Draw the columns and pews.}
	for t := 1 to ((R^.H - 3) div 2) do begin
		SC^.gb^.map[R^.X+2,R^.Y+t*2].terr := MarbleColumn;
		SC^.gb^.map[R^.X+R^.W-3,R^.Y+t*2].terr := MarbleColumn;

		if t = 1 then begin
			{Do the altar & Holy Water.}
			SC^.gb^.map[CX,R^.Y+1+t*2].terr := 39;
			I := NewDCItem;
			I^.IKind := IKIND_Grenade;
			I^.ICode := 8;
			I^.charge := 1 + Random(3);
			PlaceDCItem(SC^.gb,SC^.ig,I, CX , R^.Y+2+t*2 );


			SC^.gb^.map[CX-1,R^.Y+1+t*2].terr := 18;

			if (R^.W mod 2) = 0 then begin
				SC^.gb^.map[CX+1,R^.Y+1+t*2].terr := 39;
				I := NewDCItem;
				I^.IKind := IKIND_Grenade;
				I^.ICode := 8;
				I^.charge := 1 + Random(3);
				PlaceDCItem(SC^.gb,SC^.ig,I, CX+1 , R^.Y+2+t*2 );

				SC^.gb^.map[CX+2,R^.Y+1+t*2].terr := 18;
			end else begin
				SC^.gb^.map[CX+1,R^.Y+1+t*2].terr := 18;
				I := NewDCItem;
				I^.IKind := IKIND_Grenade;
				I^.ICode := 8;
				I^.charge := 1 + Random(3);
				PlaceDCItem(SC^.gb,SC^.ig,I, CX , R^.Y+2+t*2 );
			end;

		end else if t < ((R^.H - 3) div 2) then begin
			{Do the pews.}
			for X := 4 to (R^.W - 5) do begin
				SC^.gb^.map[R^.X+X,R^.Y+1+t*2].terr := chair;
			end;
		end;
	end;
end;

Procedure RenderReliquary( SC: ScenarioPtr; X1,Y1,X2,Y2: Integer );
	{ Actually draw on the map a reliquary chamber. It's kind of }
	{ like a Moria treasure room. }
const
	CryptCrit: Array [1..10] of byte = (
		3,3,3,3,3, 20,22,22,16,16
	);
var
	X,Y,N,T: Integer;
	I: DCItemPtr;
begin
	{ Create the basic structure. }
	RoomFill(SC^.gb,X1,Y1,X2,Y2,SecureWall,40);

	{ Scan through the interior tiles alternating walls and floors. }
	for X := ( X1+1 ) to ( X2-1 ) do begin
		for Y := ( Y1+1 ) to ( Y2-1 ) do begin
			if Odd( X + Y ) then begin
				{ Add a wall here. }
				SC^.GB^.Map[X,Y].terr := SecureWall;
			end else begin
				{ Add a pile of treasure or a monster here. }
				if Random(100) < CryptItem then begin
					{Add an item...}
					N := Random( CryptNum ) + 1;
					for t := 1 to N do begin
						I := GenerateItem(SC,TType_Crypt);
						PlaceDCItem(SC^.gb,SC^.ig,I,X,Y);
					end;
				end else if Random(100) < CryptCritter then begin
					{...or a monster.}
					AddCritter(SC^.CList,SC^.gb,CryptCrit[Random(10)+1],X,Y);
				end else if Random( 100 ) = 23 then begin
					{ On a very rare chance, there'll be a big item cache here. }
					PlaceItemCache( SC , X , Y );
				end;
			end;
		end;
	end;

	{ Add the doors and traps. }
	N := Random(3) + 3;
	if Random(2) = 1 then begin
		{ Vertical Orientation - Place the doors. }
		X := ( X1 + X2 ) div 2;
		SC^.GB^.Map[X,Y1].terr := ClosedDoor;
		SC^.GB^.Map[X,Y2].terr := ClosedDoor;
		SC^.GB^.Map[X,Y1].special := N;
		SC^.GB^.Map[X,Y2].special := N;

		{ Inside the door is the super-nasty Plasma Barrier trap. }
		SC^.GB^.Map[X,Y1+1].terr := 40;
		SC^.GB^.Map[X,Y2-1].terr := 40;
		SC^.GB^.Map[X,Y1+1].trap := -5;
		SC^.GB^.Map[X,Y2-1].trap := -5;

		{ Outside the door is an alarm. }
		SC^.GB^.Map[X,Y1-1].trap := -4;
		SC^.GB^.Map[X,Y2+1].trap := -4;
	end else begin
		{ Horizontal Orientation }
		Y := ( Y1 + Y2 ) div 2;
		SC^.GB^.Map[X1,Y].terr := ClosedDoor;
		SC^.GB^.Map[X2,Y].terr := ClosedDoor;
		SC^.GB^.Map[X1,Y].special := N;
		SC^.GB^.Map[X2,Y].special := N;

		{ Inside the door is the super-nasty Plasma Barrier trap. }
		SC^.GB^.Map[X1+1,Y].terr := 40;
		SC^.GB^.Map[X2-1,Y].terr := 40;
		SC^.GB^.Map[X1+1,Y].trap := -5;
		SC^.GB^.Map[X2-1,Y].trap := -5;

		{ Outside the door is an alarm. }
		SC^.GB^.Map[X1-1,Y].trap := -4;
		SC^.GB^.Map[X2+1,Y].trap := -4;
	end;

	{ Add some alarms and/or traps. }
	N := Random( 30 );
	for t := 1 to N do begin
		X := Random( X2 - X1 + 2 ) + X1 - 1;
		Y := Random( Y2 - Y1 + 2 ) + Y1 - 1;
		if IsASpace( SC^.GB , X , Y ) and ( SC^.GB^.map[X,Y].Trap = 0 ) then begin
			SC^.GB^.Map[X,Y].trap := -4;
		end;
	end;
end;

Procedure DetailReliquary(SC: ScenarioPtr; R: RoomPtr);
	{ Provide the details for a reliquary type room. }
begin
	RenderReliquary( SC, R^.X+2 , R^.Y + 2 , R^.X + R^.W - 3 , R^.Y + R^.H - 3 );
end;

Procedure DetailMedCenter(SC: ScenarioPtr; R: RoomPtr);
	{ Provide the details for the medical center- some beds and }
	{ a medical unit. }
var
	MP: MPUPtr;
	X,Y: Integer;
begin
	{ Add some beds. }
	For X := ( R^.X + 4 ) to ( R^.X + R^.W - 5 ) do begin
		For Y := ( R^.Y + 2 ) to ( R^.Y + R^.H - 3 ) do begin
			if Odd( X ) and Odd( Y ) and ( Random(3) <> 1 ) then begin
				SC^.GB^.Map[X,Y].terr := 19;
			end;
		end;
	end;

	{ Add the computer. }
	X := Random( 4 );
	if X = 0 then begin
		MP := AddMPU( SC^.Comps , SC^.GB , 2 , R^.X + R^.W - 3 , R^.Y + R^.H - 3 );
	end else if X = 1 then begin
		MP := AddMPU( SC^.Comps , SC^.GB , 2 , R^.X + R^.W - 3 , R^.Y + 2 );
	end else if X = 2 then begin
		MP := AddMPU( SC^.Comps , SC^.GB , 2 , R^.X +2 , R^.Y + R^.H - 3 );
	end else begin
		MP := AddMPU( SC^.Comps , SC^.GB , 2 , R^.X + 2 , R^.Y + 2 );
	end;
	MP^.Attr := '16 17 18 19 20 21 22';
end;

Procedure DetailGravesite(SC: ScenarioPtr; R: RoomPtr);
	{ Fill in the details for one of DeadCold's memorial gounds. }
var
	X,Y: Integer;
begin
	{ Fill the interior of the room with grass. }
	RectFill( SC^.GB , R^.X+2 , R^.Y + 2 , R^.X + R^.W - 3 , R^.Y + R^.H - 3 , 42);

	{ Add tombstones and shubbery. }
	For X := R^.X+3 to R^.X + R^.W - 4 do begin
		For Y := R^.Y+3 to R^.Y + R^.H - 4 do begin
			if Odd( X ) and Odd( Y ) and ( Random( 3 ) = 1 ) then begin
				SC^.GB^.Map[X,Y].terr := 41;
			end else if Random( 5 ) = 2 then begin
				SC^.GB^.Map[X,Y].terr := 4;
			end;
		end;
	end;

	{ If the room is big enough, add a reliquary. }
	if ( R^.W > 24 + Random( 10 ) ) and ( R^.H > 16 + Random( 10 ) ) then begin
		X := R^.X + 2 + Random( R^.W - 20 );
		Y := R^.Y + 2 + Random( R^.H - 12 );

		RenderReliquary( SC, X , Y , X + 15 , Y + 7 );
	end;
end;

Procedure DetailControlCenter( SC: ScenarioPtr; R: RoomPtr );
	{ Fill out the life support control center. From here, the }
	{ player can re-activate life support for this level. }
var
	MP: MPUPtr;
begin
	{ Start by actually adding the life support breakdown plot scripts. }
	SetSAtt( SC^.PLLocal , 'START <ifG PL 0 if= V2 0 print 1>' );
	SetSAtt( SC^.PLLocal , 'MSG1 <The air on this level doesn''t smell fresh...>' );

	{ If the life support is off, if the player leakage is greater than 0, }
	{ add the leakage score to variable 3. If V3 > 500, the PC will begin }
	{ to choke. }
	SetSAtt( SC^.PLLocal , 'HOUR <if= V2 0 ifG PL 0 ifG V3 100 else GotoLEAK Choke>' );
	SetSAtt( SC^.PLLocal , '10MIN <if= V2 0 ifG PL 0 ifG V3 500 else GotoLEAK Choke>' );
	SetSAtt( SC^.PLLocal , 'MINUTE <if= V2 0 ifG PL 0 ifG V3 2500 else GOTOLeak Choke>' );
	SetSAtt( SC^.PLLocal , 'GotoLEAK <V+ 3 PL>' );

	{ Add MORGAN to the room. }
	MP := AddMPU( SC^.Comps , SC^.GB , 3 , R^.X + ( R^.W div 2 ) , R^.Y + ( R^.H div 2 ) );
	MP^.Attr := '23 24 25 26 27';
end;

Procedure DetailCryoLab( SC: ScenarioPtr; R: RoomPtr );
	{ Fill out the criogenics lab. From here, the player may be }
	{ able to escape the station in a cryogenics pod. }
var
	T: Integer;
begin
	{ Add the cryogenic space probe capsules. }
	for T := 1 to (( R^.H - 4 ) div 5 ) do begin
		AddScenery( SC^.gb , R^.X+3 , R^.Y+2 + T*5 , @Capsule , False );
	end;
end;

Procedure DetailMuseum( SC: ScenarioPtr; R: RoomPtr );
	{ Draw the stuff for the museum, including the sealed-off }
	{ display chamber. }
	Function Randoor: Integer;
	begin
		if Random( 3 ) = 1 then Randoor := OpenDoor
		else RanDoor := ClosedDoor;
	end;
var
	X,Y: Integer;
	I: DCItemPtr;
	MP: MPUPtr;
begin
	{ The museum has been infested by Algon Dust-Jellies, so a }
	{ force field has been erected around it. To deactivate the }
	{ field, the player will have to hack DesCartes. }

	MP := AddMPU( SC^.Comps , SC^.GB , 1 , R^.X + 2 , R^.Y + 2 );
	MP^.Attr := '28 29';

	{ Draw the field box, then the interior chamber. }
	RoomFill( SC^.GB , R^.X+5 , R^.Y+5 , R^.X+R^.W-6 , R^.Y+R^.H-6 , ForceField , 15 );
	RoomFill( SC^.GB , R^.X+6 , R^.Y+6 , R^.X+R^.W-7 , R^.Y+R^.H-7 , SecureWall , 15 );

	{ Add some doors. }
	{ Left Wall }
	SC^.GB^.Map[ R^.X+6 , R^.Y+7 ].terr := RanDoor;
	SC^.GB^.Map[ R^.X+6 , R^.Y+R^.H-8 ].terr := RanDoor;
	{ Right Wall }
	SC^.GB^.Map[ R^.X+R^.W-7 , R^.Y+7 ].terr := RanDoor;
	SC^.GB^.Map[ R^.X+R^.W-7 , R^.Y+R^.H-8 ].terr := RanDoor;
	{ Top Wall }
	SC^.GB^.Map[ R^.X+7 , R^.Y+6 ].terr := RanDoor;
	SC^.GB^.Map[ R^.X+R^.W-8 , R^.Y+6 ].terr := RanDoor;
	{ Bottom Wall }
	SC^.GB^.Map[ R^.X+7 , R^.Y+R^.H-7 ].terr := RanDoor;
	SC^.GB^.Map[ R^.X+R^.W-8 , R^.Y+R^.H-7 ].terr := RanDoor;


	{ Add the jellies }
	for X := ( R^.X + 7 ) to ( R^.X + R^.W - 8 ) do begin
		for Y := ( R^.Y + 7 ) to ( R^.Y + R^.H - 8 ) do begin
			AddCritter( SC^.CList , SC^.gb , 23 , X , Y );
		end;
	end;

	{ Add the payoff. }
	I := NewDCItem;
	I^.IKind := IKIND_Wep;
	I^.ICode := 16;
	I^.ID := False;
	PlaceDCItem(SC^.gb,SC^.ig,I, R^.X+ ( R^.W div 2 ) , R^.Y+ ( R^.H div 2 ) );

	{ Add some traps. }
	SC^.GB^.Map[R^.X+ ( R^.W div 2 ) , R^.Y+ ( R^.H div 2 )].Trap := 5;
	for X := R^.X+ ( R^.W div 2 )-1 to R^.X+ ( R^.W div 2 )+1 do begin
		for Y := R^.Y+ ( R^.H div 2 )-1 to R^.Y+ ( R^.H div 2 )+1 do begin
			SC^.GB^.Map[X,Y].Trap := -4;
		end;
	end;
	SC^.GB^.Map[R^.X+ ( R^.W div 2 ) , R^.Y+ ( R^.H div 2 )].Trap := 5;
end;

Procedure DetailDesCartes( SC: ScenarioPtr; R: RoomPtr );
	{ Fill out the life support control center. From here, the }
	{ player can de-activate the force field around the museum. }
var
	MP: MPUPtr;
begin
	SetSAtt( SC^.PLLocal , 'GotoTURNOFFFIELD <ChangeTerr 43 44>' );

	AddCritter(SC^.CList,SC^.gb,22,R^.X+1,R^.Y+1);
	AddCritter(SC^.CList,SC^.gb,22,R^.X+1,R^.Y+R^.H-2);
	AddCritter(SC^.CList,SC^.gb,22,R^.X+R^.W-2,R^.Y+1);
	AddCritter(SC^.CList,SC^.gb,22,R^.X+R^.W-2,R^.Y+R^.H-2);


	{ Add DESCARTES to the room. }
	MP := AddMPU( SC^.Comps , SC^.GB , 4 , R^.X + ( R^.W div 2 ) , R^.Y + ( R^.H div 2 ) );
	MP^.Attr := '';
end;

Procedure RenderRoom(SC: ScenarioPtr; R: RoomPtr);
	{Render the room in question. Detail it appropriately.}
	{Add some items if you really must.}
begin
	{First, draw the walls and the floor.}
	RoomFill(SC^.gb,R^.X,R^.Y, R^.X+R^.W-1, R^.Y+R^.H-1,R^.Wall,R^.Floor);

	Case R^.Style of
		3: DetailLounge(SC,R);
		4: DetailSecArea(SC,R);
		5: DetailStorage(SC,R);
		6: DetailBigBox(SC,R);
		7: DetailShuttleBay(SC,R);
		8: DetailTransitway(SC,R,32);
		9: DetailTransitway(SC,R,33);
		10: DetailResidence(SC,R);
		11: DetailAGQ(SC,R);
		12: DetailChapel(SC,R);
		13: DetailReliquary( SC , R );
		14: DetailMedCenter( SC , R );
		15: DetailGravesite( SC , R );
		16: DetailControlCenter( SC , R );
		17: DetailCryoLab( SC , R );
		18: DetailTransitway(SC,R,34);
		19: DetailTransitway(SC,R,35);
		20: DetailMuseum( SC , R );
		21: DetailDesCartes( SC , R );
	end;

end;

Procedure PlaceRoom(SC: ScenarioPtr; R: RoomPtr);
	{Place room R on the map GB. Locate an empty spot for it,}
	{then render it to map memory.}
var
	X1,Y1,C: Integer;
begin
	{Keep looping until we find an empty spot.}
	C := 0;
	While (R^.X = -1) and (C < 10000) do begin
		Inc(C);
		X1 := Random(XMax - R^.W) + 1;
		Y1 := Random(YMax - R^.H) + 1;
		if AreaClear(SC^.gb,X1,Y1,R^.W,R^.H) then begin
			R^.X := X1;
			R^.Y := Y1;
		end;
	end;

	{Add the room}
	RenderRoom(SC,R);
end;

Procedure GFRoom(SC: ScenarioPtr; X,Y,Sens: Integer);
	{Create a random room in the area bounded by X,Y - X+S,Y+S.}
var
	R: RoomPtr;
begin
	R := Nil;
	NewRoom(R);

	{Check to make sure the new room is small enough to fit}
	{into our alloted space.}
	if R^.W >= Sens then R^.W := Sens - 1;
	if R^.H >= Sens then R^.H := Sens - 1;

	{Make sure Lounge type rooms still look pretty.}
	if (R^.Style = 3) or (R^.Style = 12) then begin
		if not Odd(R^.H) then Dec(R^.H);
		if not Odd(R^.W) then Dec(R^.W);
	end;


	{Select a position within our alloted space for the room.}
	R^.X := X + Random(Sens - R^.W);
	R^.Y := Y + Random(Sens - R^.H);

	RenderRoom(SC,R);
	AddWTunnels(SC^.gb,R,5);

	DisposeRoomList(R);
end;

Procedure GapFiller(SC: ScenarioPtr);
	{Check through the map as it currently exists. Upon finding}
	{large patches of unused space, stick something interesting}
	{there. These interesting things will not be guaranteed}
	{accessable, but so what? They're not key rooms. And, if}
	{you really want to get to them, you'll own a las-cutter.}
const
	sens = 32;	{The sensitivity of the search.}
var
	XB,YB: Integer;		{XBlock,YBlock. Loop counters.}
begin
	for XB := 0 to ((XMax div sens) - 1) do begin
		for YB := 0 to ((YMax div sens) - 1) do begin
			{Check this block for stuff.}
			if AreaClear(SC^.gb,XB*sens+1,YB*sens+1,sens,sens) then begin

				{There's nothing in this region. Add a random room,}
				{then connect it to something using WTunnels.}
				GFRoom(SC,XB*sens+1,YB*sens+1,Sens);

			end;
		end;
	end;
end;

Procedure RandomLevel(SC: ScenarioPtr; R: RoomPtr);
	{Generate a random map for use in DeadCold.}
var
	RTemp: RoomPtr;
	T,X,Y: Integer;
begin
	SC^.gb := NewBoard;
	SC^.ig := NewIGrid;

	{Fill every square with the basic wall.}
	RectFill(SC^.gb,1,1,XMax,YMax,EmptyTerrain);

	{Add some rooms to the basic list.}
	for t := 1 to (5 + Random(10)) do begin
		NewRoom(R);
	end;

	{Scramble the order of the rooms.}


	{Place the remaining rooms on the map.}
	RTemp := R;
	while RTemp <> Nil do begin
		PlaceRoom(SC,RTemp);
		RTemp := RTemp^.Next;
	end;

	{Fill in any empty spots with extra stuff.}
	GapFiller(SC);

	{Connect the rooms with halls.}
	RTemp := R;
	while RTemp <> Nil do begin
		ConnectRoom(SC^.gb,Rtemp,NextRoom(R,RTemp));
		RTemp := RTemp^.Next;
	end;

	{ Add some traps. }
	for t := 1 to 100 do begin
		X := Random(XMax) + 1;
		Y := Random(YMax) + 1;
		if GetTerr(SC^.gb,X,Y) = 2 then begin
			SC^.gb^.Map[X,Y].trap := -1;
		end else if GetTerr(SC^.gb,X,Y) = Crawlspace then begin
			SC^.gb^.Map[X,Y].trap := -2;
		end;
	end;

	{Add some stains and other details to the floor. Maybe.}
	for t := 1 to 1000 do begin
		X := Random(XMax) + 1;
		Y := Random(YMax) + 1;
		if GetTerr(SC^.gb,X,Y) = 2 then SC^.gb^.Map[X,Y].terr := 10
		else if GetTerr(SC^.gb,X,Y) = Crawlspace then begin
			if Random(20) = 7 then PlaceItemCache( SC , X , Y )
			else if Random(10) = 7 then RenderCorner(SC^.gb,X,Y)
			else begin
				HallStyle := ServTunnel;
				RenderWTunnel(SC^.gb,X,Y,Random(4)+1);
			end;
		end else if GetTerr(SC^.gb,X,Y) = EmptyTerrain then begin
			HallStyle := ServTunnel;
			RenderWTunnel(SC^.gb,X,Y,Random(4)+1);
		end;
	end;

	DisposeRoomList(R);
end;

Procedure GenerateCurrentLevel( SC: ScenarioPtr );
	{ Generate a random map for the level which is indicated as being the }
	{ current one. }
var
	RList,R: RoomPtr;
	LevelPlan: String;
	RID: Integer;	{ Room ID }
begin
	{ Start by determining the level plan for this module. }
	if ( SC^.Loc_Number < 1 ) or ( SC^.Loc_Number > Num_Levels ) then begin
		LevelPlan := Level_Contents[ 0 ];
	end else begin
		LevelPlan := Level_Contents[ SC^.Loc_Number ];
	end;

	{ Generate rooms for each room indicated in the plans. }
	RList := Nil;
	While LevelPlan <> '' do begin
		RID := ExtractValue( LevelPlan );
		R := AddRoom(RList);
		R^.Style := RID;
		InitRoom(R);
	end;

	{ Actually call the random level procedure to put it all together. }
	RandomLevel( SC , RList );

end;

Procedure FreezeCurrentLevel( SC: ScenarioPtr );
	{ Take the current level, store it in its proper FROZEN slot, }
	{ then clear whatever & prepare for a new level. }
begin
	{ If the level number is in the legal range, freeze it. }
	if ( SC^.Loc_Number >= 1 ) and ( SC^.Loc_Number <= Num_Levels ) then begin
		SC^.Frozen_Levels[ SC^.Loc_Number ].gb := SC^.GB;
		SC^.Frozen_Levels[ SC^.Loc_Number ].ig:= SC^.ig;
		SC^.Frozen_Levels[ SC^.Loc_Number ].PL:= SC^.PLLocal;
		SC^.Frozen_Levels[ SC^.Loc_Number ].CList:= SC^.CList;
		SC^.Frozen_Levels[ SC^.Loc_Number ].Comps:= SC^.Comps;

		{ Get rid of the player's model from the gameboard. }
		RemoveModel( SC^.PC^.M , SC^.GB^.MList , SC^.GB^.Mog );
		SC^.GB^.POV.M := Nil;

		{ Dispose of the clouds on the board. }
		CleanCloud( SC^.GB , SC^.Fog );

		{ Clear all stuff. }
		SC^.GB := Nil;
		SC^.IG := Nil;
		SC^.PLLocal := Nil;
		SC^.CList := Nil;
		SC^.Comps := Nil;

	end else begin
		{ If the level number isn't in the legal range, just }
		{ dispose of the level. }
		DisposeBoard( SC^.GB );
		DisposeIGrid( SC^.IG );
		DisposeSAtt( SC^.PLLocal );
		DisposeCritterList( SC^.CList );
		DisposeMPU( SC^.Comps );

	end;
end;

Procedure UnfreezeLevel( SC: ScenarioPtr; N: Integer );
	{ Restore level N from its frozen state to full playability. }
	{ - Copy pointers from the Frozen record to the Scenario }
	{ - Set pointers in the Frozen record to Nil }
begin
	{ Set the location number. }
	SC^.Loc_Number := N;

	{ Error check - if the requested level is outside of the }
	{ valid range, generate a new completely random level. }	
	if ( N < 1 ) or ( N > Num_Levels ) then begin
		GenerateCurrentLevel( SC );
	end else begin
		{ Move the frozen stuff to the scenario main record... }
		SC^.GB := SC^.Frozen_Levels[N].GB;
		SC^.IG := SC^.Frozen_Levels[N].IG;
		SC^.PLLocal := SC^.Frozen_Levels[N].PL;
		SC^.CList := SC^.Frozen_Levels[N].CList;
		SC^.Comps := SC^.Frozen_Levels[N].Comps;

		{...then set the FROZEN records to Nil. }
		SC^.Frozen_Levels[N].GB := Nil;
		SC^.Frozen_Levels[N].IG := Nil;
		SC^.Frozen_Levels[N].PL := Nil;
		SC^.Frozen_Levels[N].CList := Nil;
		SC^.Frozen_Levels[N].Comps := Nil;
	end;
end;

Procedure GotoLevel( SC: ScenarioPtr; N, Entry_Terrain: Integer );
	{ - Freeze current level, if one exists }
	{ - Set Loc_Number field to the requested number }
	{ - If requested level exists, unfreeze it }
	{ - If requested level is empty, generate it }
	{ - Deploy a PC model on the game board }
var
	X,Y: Integer;
	M: ModelPtr;
begin
	{ Check the current level to see if it needs to be frozen. }
	if SC^.GB <> Nil then begin
		{ If it exists, freeze it. }
		FreezeCurrentLevel( SC );
	end;

	{ Set the location number. }
	SC^.Loc_Number := N;

	{ Unfreeze the level, if it exists. }
	if ( N >= 1 ) and ( N <= Num_Levels ) and ( SC^.Frozen_Levels[ N ].gb <> Nil ) then begin
		UnfreezeLevel( SC , N );
	end else begin
		{ It doesn't exist. Generate it. }
		GenerateCurrentLevel( SC );
	end;

	{ Deploy a model for the PC. Start the model on the first }
	{ tile found with the specified terrain. If no tile with }
	{ this terrain is found, we're in serious trouble. }
	X := 1;
	Y := 1;
	repeat
		X := X + 1;
		if X > XMax then begin
			X := 1;
			Y := Y + 1;
		end;
	until ( SC^.gb^.map[X,Y].terr = Entry_Terrain ) or ( Not OnTheMap( X , Y ) );
	if not OnTheMap( X , Y ) then begin
		X := Random( XMax ) + 1;
		Y := Random( YMax ) + 1;
	end;

	{ Set the particulars for the player's model. }
	m := AddModel(sc^.gb^.mlist,sc^.gb^.mog,'@',LightGreen,White,False,X,Y,1);
	SC^.gb^.pov.m := m;
	SC^.PC^.M := M;
	SC^.gb^.pov.range := PCVisionRange(SC^.PC);
	RecenterPOV( SC^.GB );
	UpdatePOV( SC^.GB^.POV , SC^.GB );
	ApplyPOV( SC^.GB^.POV , SC^.GB );
	DisplayMap( SC^.GB );

	{ Add the START trigger. }
	SetTrigger( SC , 'START' );
end;



end.
