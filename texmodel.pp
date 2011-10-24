unit texmodel;
	{This unit handles models. That is to say, things which will appear}
	{on the playing field, but which are not bits of terrain.}
	{ *** GFX UNIT *** }

interface

Const
	{These values hold the size of the game map.}
	XMax = 256;
	YMax = 256;


Type
	Model = Record
		gfx: char;
		color,acolor,bcolor: byte;
		Obs: Integer;		{How much vision obscurement does this model cause?}
		CoHab: boolean;		{Can this model share its location?}
		X,Y: Integer;		{X and Y.}
		Kind: Integer;		{What KIND of a model is this?}
		Next: ^Model;
	end;
	ModelPtr = ^Model;
	ModelGrid = Array [1..XMax,1..YMax] of boolean;

Function AddModel(var MP: ModelPtr; var MG: ModelGrid; gfx: char; color,bc: byte; choab: boolean; X,Y,Kind: Integer): ModelPtr;
Procedure DisposeModelList(MP: ModelPtr);
Function FindModelXY(MP: ModelPtr; X,Y: Integer): ModelPtr;
Function ModelPresent(var mg: ModelGrid; X,Y: Integer): Boolean;
Procedure SetModelLoc(m,mlist: ModelPtr; var mg: ModelGrid; X2,Y2: Integer);
Procedure RemoveModel(var LMember,LList: ModelPtr; var mg: ModelGrid );


implementation

Function LastModel(MP: ModelPtr): ModelPtr;
	{Locate the last model in the linked list.}
begin
	While MP^.next <> Nil do begin
		MP := MP^.next;
	end;
	LastModel := MP;
end;

Function AddModel(var MP: ModelPtr; var MG: ModelGrid; gfx: char; color,bc: byte; cohab: boolean; X,Y,Kind: Integer): ModelPtr;
	{Add a model to the model list.}
var
	it: ModelPtr;
begin
	{Allocate memory for IT}
	New(it);

	{Do a range check on X and Y to make sure they lie inside the playfield.}
	if x < 1 then
		x := 1
	else if x > XMax then
		x := XMax;
	if y < 1 then
		y := 1
	else if y > YMax then
		y := YMax;

	{Initialize all of ITs fields}
	it^.gfx := gfx;
	it^.color := color;
	it^.cohab := cohab;
	it^.acolor := color;
	it^.bcolor := bc;
	it^.Obs := 0;		{Default obscurement}
	it^.X := X;
	it^.Y := Y;
	it^.Kind := Kind;
	it^.Next := Nil;

	{Modify the model grid to show that the spot is occupied.}
	MG[X,Y] := True;

	{Locate a good position to attach it to.}
	if MP = Nil then begin
		{the list is currently empty. Attach it as the first model.}
		MP := it;
		end
	else begin
		{The list has stuff in it. Attach IT to the end.}
		LastModel(MP)^.next := it;
	end;

	AddModel := it;
end;

Procedure DisposeModelList(MP: ModelPtr);
	{Given a linked list of models starting at MP, dispose of all of them}
	{and free the system resources.}
var
	MPtemp: ModelPtr;
begin
	while MP <> Nil do begin
		MPtemp := MP^.Next;
		Dispose(MP);
		MP := MPtemp;
	end;
end;

Function FindModelXY(MP: ModelPtr; X,Y: Integer): ModelPtr;
	{Search through the models list, searching for a model in location}
	{X,Y. Return a ptr to that model, or Nil if no such model exists.}
var
	temp: ModelPtr;		{Used to store the address of the model.}
begin
	{Initialize temp to Nil}
	temp := Nil;

	{Loop through all of the models, searching for one that fits.}
	while MP <> Nil do begin
		if (MP^.X = X) and (MP^.Y = Y) then begin
			{If this is the first model we've found at this location,}
			{save it's pointer.}
			if temp = Nil then
				temp := MP

			{If this isn't the first, save the pointer to the model}
			{that doesn't normally cohabitate.}
			else begin
				if temp^.cohab then temp := MP;

			end;
		end;
		MP := MP^.next;
	end;

	FindModelXY := temp;
end;

Function ModelPresent(var mg: ModelGrid; X,Y: Integer): Boolean;
	{Check location X,Y and see if there's a model. Check the values}
	{of X and Y to make sure they're in the boundaries.}
var
	temp: boolean;
begin

	if (x>=1) and (X<=XMax) and (y>=1) and (y<=YMax) then
		temp := mg[X,Y]
	else
		temp := false;

	ModelPresent := temp;
end;

Procedure SetModelLoc(m,mlist: ModelPtr; var mg: ModelGrid; X2,Y2: Integer);
	{Move the model M to location X2,Y2, adjusting the contents of}
	{the modelgrid accordingly.}
var
	X1,Y1: Integer;
begin
	{Range check. If X2,Y2 lie out of bounds, bring them back into}
	{bounds.}
	if X2<1 then
		X2 := 1
	else if X2> XMax then
		X2 := XMax;
	if Y2<1 then
		Y2 := 1
	else if Y2> YMax then
		Y2 := YMax;

	{Save the initial position of the model.}
	X1 := m^.x;
	Y1 := m^.y;

	{Change the position of the model.}
	m^.x := X2;
	m^.y := Y2;

	if FindModelXY(MList,X1,Y1) = Nil then
		mg[X1,Y1] := false;
	mg[X2,Y2] := true;

end;

Procedure RemoveModel(var LMember,LList: ModelPtr; var mg: ModelGrid );
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: ModelPtr;
	X,Y: Integer;
begin
	{ Initialize A and B }
	B := LList;
	A := Nil;

	{ Save the X,Y position of the model. }
	X := LMember^.X;
	Y := LMember^.Y;

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
		writeln('ERROR- RemoveModel asked to remove a model that doesnt exist.');
	end else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		LList := B^.Next;
		B^.Next := Nil;
		DisposeModelList(B);
	end else begin
		{We found the model we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;
		B^.Next := Nil;
		DisposeModelList(B);
	end;

	{ Update the model grid. }
	if FindModelXY(LList,X,Y) = Nil then mg[X,Y] := false;
end;


end.
