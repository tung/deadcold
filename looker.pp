unit looker;
	{What is this? It's the unit which supports the 'Look'}
	{command. Basically, it provides a UI for the user to select}
	{a map tile which is currently on-screen.}

interface

uses crt,rpgtext,texmodel,texmaps,texfx,critters,gamebook;

Function SelectPoint(SC: ScenarioPtr; Render, SeekModel: Boolean; M: ModelPtr): Point;

implementation

Procedure MoveMapCursor(gb: GameBoardPtr; D: Integer; var P: Point);
	{Move the map cursor point. This can be used for the Select}
	{Target routine, or for the PCLook routine. In any case,}
	{the big point is to make sure that the point doesn't go off}
	{the screen.}
begin
	if OnTheScreen(gb,p.x + VecDir[D,1],p.y + VecDir[D,2]) then begin
		p.x := p.x + VecDir[D,1];
		p.y := p.y + VecDir[D,2];
	end;
end;

Function NextVisibleModel(gb: GameBoardPtr; M: ModelPtr): ModelPtr;
	{Locate the next visible model in the models list. If}
	{the end of the list is encountered, start looking again}
	{at the beginning. If no visible models are found,}
	{return Nil.}
var
	M1,M2: ModelPtr;
	GetOutOfLoopFree: Boolean;
begin
	{ERROR CHECK- exit immediately if there are no models present.}
	if gb^.MList = Nil then Exit(Nil);

	M2 := Nil;
	M1 := M;
	if M = Nil then M := gb^.MList;

	GetOutOfLoopFree := False;

	repeat
		if M1 <> Nil then begin
			{Move to the next model in the list.}
			M := M^.Next;
			if M = Nil then M := gb^.MList;
		end;

		if TileLOS(gb^.POV,M^.X,M^.Y) and (M <> gb^.POV.M) and OnTheScreen(gb,M^.X,M^.Y) and (M^.Kind = MKIND_Critter) then M2 := M;

		if M1 = Nil then begin
			M := M^.Next;
			if M = Nil then GetOutOfLoopFree := True;
		end else begin
			if M = M1 then GetOutOfLoopFree := True;
		end;
	until (M2 <> Nil) or GetOutOfLoopFree;

	NextVisibleModel := M2;
end;

Function SelectPoint(SC: ScenarioPtr; Render,SeekModel: Boolean; M: ModelPtr): Point;
	{This function is a UI utility. It allows a target}
	{square to be chosen, centered on the POV model.}
	{If CANCEL is chosen instead of a target, the X value}
	{of the returned point will be set to -1.}
var
	p: Point;
	a: Char;
begin
	if SeekModel then begin
		if M = Nil then M := NextVisibleModel(SC^.gb,M)
		else if not TileLOS(SC^.gb^.POV,M^.X,M^.Y) or not OnTheScreen(SC^.gb,M^.X,M^.Y) then M := NextVisibleModel(SC^.gb,M);
	end;

	if M <> Nil then begin
		{Start the point selector centered on the selected model.}
		p.x := M^.X;
		p.y := M^.Y;
	end else begin
		{Start the point centered on the POV origin.}
		p.x := SC^.gb^.POV.M^.X;
		p.y := SC^.gb^.POV.M^.Y;
	end;

	{Start the loop.}
	repeat
		{Indicate the point.}
		if Render then
			IndicatePath(SC^.gb,SC^.gb^.pov.m^.x,SC^.gb^.pov.m^.y,p.x,p.y,true)
		else
			HighlightTile(SC^.gb,p.x,p.y);
		DCPointMessage(TileName(SC,p.x,p.y));

		{Get player input and act upon it.}
		a := RPGKey;

		{Deindicate the point.}
		if Render then
			DeIndicatePath(SC^.gb,SC^.gb^.pov.m^.x,SC^.gb^.pov.m^.y,p.x,p.y)
		else
			DisplayTile(SC^.gb,p.x,p.y);

		case A of
			'1': MoveMapCursor(SC^.gb,1,p);
			'2': MoveMapCursor(SC^.gb,2,p);
			'3': MoveMapCursor(SC^.gb,3,p);
			'4': MoveMapCursor(SC^.gb,4,p);
			'6': MoveMapCursor(SC^.gb,6,p);
			'7': MoveMapCursor(SC^.gb,7,p);
			'8': MoveMapCursor(SC^.gb,8,p);
			'9': MoveMapCursor(SC^.gb,9,p);
			#9: begin
				M := NextVisibleModel(SC^.gb,M);
				if M <> Nil then begin
					p.x := M^.X;
					p.y := M^.Y;
					end;
				end;
		end;		
	until (a = ' ') or (a = #27) or (a = KMap[13].Key) or (a = KMap[14].Key);

	if a = #27 then p.x := -1;
	SelectPoint := P;
end;

end.
