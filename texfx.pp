unit texfx;
	{This unit handles special graphics effects in ASCII mode.}

interface

uses crt,rpgtext,texmodel,texmaps;

const
	PathColor: Byte = Yellow;
	ShotColor: Byte = LightRed;

Procedure IndicateModel(gb: GameBoardPtr; M: ModelPtr);
Procedure DeIndicateModel(gb: GameBoardPtr; M: ModelPtr);
Procedure IndicatePath(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer; LOS: Boolean);
Procedure DeIndicatePath(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer);
Procedure DisplayShot(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer; c: Byte; hit: Boolean);
Procedure ModelFlash(gb: GameBoardPtr; M: ModelPtr);
Procedure LaserCut(gb: GameBoardPtr; X,Y: Integer);
Procedure DakkaDakka(gb: GameBoardPtr; X,Y: Integer);
Procedure PikaPikaOuch(gb: GameBoardPtr; X,Y: Integer);


implementation

Procedure IndicateModel(gb: GameBoardPtr; M: ModelPtr);
	{Set the model's color to BColor.}
begin
	M^.Color := M^.BColor;
	DisplayTile(gb,M^.X,M^.Y);
end;

Procedure DeIndicateModel(gb: GameBoardPtr; M: ModelPtr);
	{Set the model's color to AColor.}
begin
	M^.Color := M^.AColor;
	DisplayTile(gb,M^.X,M^.Y);
end;

Procedure IndicatePath(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer; LOS: Boolean);
	{Draw a line to indicate the distance between point 1 and}
	{point 2. Do not indicate the points 1 and 2 themselves,}
	{just the points in between.}
var
	P: Point;	{For the line calculator.}
	T,L: Integer;	{A loop counter, and the length of the line.}
begin
	{Calculate Length.}
	if Abs(X2 - X1) > Abs(Y2 - Y1) then
		L := Abs(X2 - X1)
	else
		L := Abs(Y2 - Y1);

	if L > 1 then begin
		for t := 1 to (L-1) do begin
			P := SolveLine(X1,Y1,X2,Y2,t);
			MapSplat(gb,'-',PathColor,p.X,p.Y,LOS);
		end;
	end;

	{Indicate the terminus of the line.}
	P := SolveLine(X1,Y1,X2,Y2,L);
	if gb^.mog[p.x,p.y] and TileLOS(gb^.pov,p.x,p.y) then begin
		IndicateModel(gb,FindModelXY(gb^.mlist,p.X,p.Y));
	end else begin
		MapSplat(gb,'+',PathColor,p.X,p.Y,LOS);
	end;
end;

Procedure DeIndicatePath(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer);
	{There's a big line currently marring our screen display.}
	{Clean it up, wouldja?}
var
	P: Point;	{For the line calculator.}
	T,L: Integer;	{A loop counter, and the length of the line.}
begin
	{Calculate Length.}
	if Abs(X2 - X1) > Abs(Y2 - Y1) then
		L := Abs(X2 - X1)
	else
		L := Abs(Y2 - Y1);

	if L > 1 then begin
		for t := 1 to (L-1) do begin
			P := SolveLine(X1,Y1,X2,Y2,t);
			DisplayTile(gb,p.X,p.Y);
		end;
	end;

	{Indicate the terminus of the line.}
	P := SolveLine(X1,Y1,X2,Y2,L);
	if gb^.mog[p.x,p.y] then begin
		DeIndicateModel(gb,FindModelXY(gb^.mlist,p.X,p.Y));
	end else begin
		DisplayTile(gb,p.X,p.Y);
	end;
end;

Procedure DisplayShot(gb: GameBoardPtr; X1,Y1,X2,Y2: Integer; c: Byte; hit: Boolean);
	{A projectlie attack has just been launched. Display its}
	{trajectory in glorious ASCII graphics.}
	{At the terminus of the shot, display a * if the attack}
	{hit and a - if it didn't. This info is contained in the}
	{parameter named HIT, of course.}
var
	P: Point;	{For the line calculator.}
	T,L: Integer;	{A loop counter, and the length of the line.}
begin
	{Calculate Length.}
	if Abs(X2 - X1) > Abs(Y2 - Y1) then
		L := Abs(X2 - X1)
	else
		L := Abs(Y2 - Y1);

	if L > 1 then begin
		for t := 1 to (L-1) do begin
			P := SolveLine(X1,Y1,X2,Y2,t);

			{Display bullet...}
			MapSplat(gb,'+',C,p.X,p.Y,false);

			{Wait a bit...}
			if FrameDelay > 0 then Delay(FrameDelay);

			{Restore the display.}
			DisplayTile(gb,p.X,p.Y);
		end;
	end;

	{Display the terminus.}
	if HIT then MapSplat(gb,'*',C,X2,Y2,false)
	else MapSplat(gb,'-',C,X2,Y2,false);

	if FrameDelay > 0 then Delay(FrameDelay);
	DisplayTile(gb,X2,Y2);
end;



Procedure ModelFlash(gb: GameBoardPtr; M: ModelPtr);
	{Flash the POV model, then flash the indicated model.}
var
	t: Integer;
begin
	for t := 1 to 3 do begin
		IndicateModel(gb,gb^.POV.M);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		DeIndicateModel(gb,gb^.POV.M);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
	end;

	for t := 1 to 3 do begin
		IndicateModel(gb,M);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		DeIndicateModel(gb,M);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
	end;
end;

Procedure LaserCut(gb: GameBoardPtr; X,Y: Integer);
	{Do the laser cut animation at location X,Y.}
	Procedure Stroke(C: Byte);
	begin
		MapSplat(gb,'|',C,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		MapSplat(gb,'/',C,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		MapSplat(gb,'-',C,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		MapSplat(gb,'/',C,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
	end;
begin
	Stroke(LightGreen);
	Stroke(Yellow);
	Stroke(White);
	DisplayTile(gb,X,Y);
end;

Procedure DakkaDakka(gb: GameBoardPtr; X,Y: Integer);
	{Do a machinegun type animation at the desired spot.}
var
	t: Integer;
begin
	for t := 1 to 5 do begin
		MapSplat(gb,'+',Yellow,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		MapSplat(gb,'x',Yellow,X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
	end;
	DisplayTile(gb,X,Y);
end;

Procedure PikaPikaOuch(gb: GameBoardPtr; X,Y: Integer);
	{Do an electrocution effect at the desired point.}
const
	PikaColor: Array [1..5] of byte = (lightblue,lightcyan,white,lightcyan,white);
var
	t: Integer;
begin
	for t := 1 to 5 do begin
		MapSplat(gb,'X',PikaColor[Random(5)+1],X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
		MapSplat(gb,'%',PikaColor[Random(5)+1],X,Y,False);
		if FrameDelay > 0 then Delay(FrameDelay div 2);
	end;
	DisplayTile(gb,X,Y);
end;


end.
