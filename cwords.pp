unit cwords;
	{This unit is brought to you by the letter "C".}
	{It handles two different "C" words - Clouds and}
	{Computers.}

interface

uses crt,texmodel,texmaps;

Type
	CloudDesc = Record
		name: String;
		color: Byte;
		Obscurement: SmallInt;
		Pass: Boolean;
	end;

	Cloud = Record
		Kind: Integer;
		Duration: LongInt;	{The ComTime at which the cloud dissipates.}
		M: ModelPtr;
		Next: ^Cloud;
	end;
	CloudPtr = ^Cloud;

	MPUDesc = Record
		name: String;
		color: Byte;
		SecPass: Integer;
	end;

	MPU = Record	{This is the record that describes computer}
			{terminals. The name, MPU, comes from the}
			{anime series Cowboy Bebop.}
		Kind: Integer;
		M: ModelPtr;
		Attr: String;	{ MPU Attributes }
		Next: ^MPU;
	end;
	MPUPtr = ^MPU;

Const
	NumCloud = 3;

	{ NOTE: A cloud with an obscurement value of -1 will completely block }
	{ line of sight, and cannot even be fired through. Such a cloud should }
	{ have Pass set to False, or bad things may result. }

	CloudMan: Array [1..NumCloud] of CloudDesc = (
		(	name: 'Etherial Mist';
			color: LightCyan;
			Obscurement: 3;
			pass: True;		),
		(	name: 'Smoke Screen';
			color: LightGray;
			Obscurement: 3;
			pass: True;		),
		(	name: 'Force Field';
			color: Yellow;
			Obscurement: -1;
			pass: False;		)
	);

	NumMPU = 4;
	MPUMan: Array [1..NumMPU] of MPUDesc = (
		(	name: 'Info Terminal';
			color: Yellow;
			SecPass: 2;		),
		(	name: 'Medical Unit';
			color: Red;
			SecPass: 12;		),
		(	name: 'Primary Server "Morgan"';
			color: LightMagenta;
			SecPass: 9;		),
		(	name: 'Primary Server "DesCartes"';
			color: Green;
			SecPass: 10;		)
	);


	MKIND_Cloud = 3;
	MKIND_MPU = 4;
	CloudGFX = '*';
	MPUGFX   = '&';



Function AddCloud(var CList: CloudPtr; gb: GameBoardPtr; C,X,Y: Integer; D: LongInt): Cloudptr;
Procedure DisposeCloud(var LList: CloudPtr);
Procedure CleanCloud( gb: GameBoardPtr; var LList: CloudPtr);
Procedure RemoveCloud(var LList,LMember: CloudPtr; gb: GameBoardPtr);
Function LocateCloud(M: ModelPtr; C: CloudPtr): CloudPtr;

Function AddMPU(var CList: MPUPtr; gb: GameBoardPtr; C,X,Y: Integer): MPUptr;
Procedure DisposeMPU(var LList: MPUPtr);
Procedure RemoveMPU(var LList,LMember: MPUPtr; gb: GameBoardPtr);
Function LocateMPU(M: ModelPtr; C: MPUPtr): MPUPtr;

Procedure WriteClouds(CL: CloudPtr; var F: Text);
Function ReadClouds(var F: Text; gb: GameBoardPtr): CloudPtr;
Procedure WriteMPU(CL: MPUPtr; var F: Text);
Function ReadMPU(var F: Text; gb: GameBoardPtr): MPUPtr;


implementation

Function AddCloud(var CList: CloudPtr; gb: GameBoardPtr; C,X,Y: Integer; D: LongInt): Cloudptr;
	{Add a cloud to the map at location X,Y.}
var
	it: CloudPtr;
begin
	{Allocate memory for IT.}
	New(it);
	if it = Nil then Exit(Nil);

	{Attach IT to the list.}
	it^.Next := CList;
	CList := it;

	it^.Kind := C;
	it^.Duration := D;
	it^.M := GAddModel(gb,CloudGFX,CloudMan[C].color,White,CloudMan[C].Pass,X,Y,MKIND_Cloud);

	if it^.M = Nil then Dispose(it);

	{Set the obscurement for this model.}
	it^.M^.Obs := CloudMan[C].Obscurement;

	AddCloud := it;
end;

Procedure DisposeCloud(var LList: CloudPtr);
	{Dispose of the list, freeing all associated system resources.}
	{The models associated with each cloud will have to be removed}
	{somewhere else, since this unit ain't messing with them.}
var
	LTemp: CloudPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure CleanCloud( gb: GameBoardPtr; var LList: CloudPtr);
	{Dispose of the list, freeing all associated system resources.}
	{The models associated with each cloud will also be removed.}
var
	LTemp: CloudPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		RemoveModel( LList^.M , GB^.MList , GB^.Mog );
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure RemoveCloud(var LList,LMember: CloudPtr; gb: GameBoardPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: CloudPtr;
begin
	{Initialize A and B}
	B := LList;
	A := Nil;

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
		writeln('ERROR- RemoveLink asked to remove a link that doesnt exist.');
		end
	else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		LList := B^.Next;

		{Get rid of the model.}
		GRemoveModel(B^.M,gb);

		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;

		{Get rid of the model.}
		GRemoveModel(B^.M,gb);

		Dispose(B);
	end;
end;

Function LocateCloud(M: ModelPtr; C: CloudPtr): CloudPtr;
	{Given model M, locate the cloud that is being referred to.}
	{Return Nil if no such cloud can be found.}
var
	it: CloudPtr;
begin
	it := Nil;
	while (C <> Nil) and (it = Nil) do begin
		if C^.M = M then it := C;
		C := C^.Next;
	end;
	LocateCloud := it;
end;

Function AddMPU(var CList: MPUPtr; gb: GameBoardPtr; C,X,Y: Integer): MPUptr;
	{Add a MPU to the map at location X,Y.}
var
	it: MPUPtr;
begin
	{Allocate memory for IT.}
	New(it);
	if it = Nil then Exit(Nil);

	{Attach IT to the list.}
	it^.Next := CList;
	CList := it;

	it^.Kind := C;
	it^.M := GAddModel(gb,MPUGFX,MPUMan[C].color,White,False,X,Y,MKIND_MPU);

	if it^.M = Nil then Dispose(it);

	AddMPU := it;
end;

Procedure DisposeMPU(var LList: MPUPtr);
	{Dispose of the list, freeing all associated system resources.}
	{The models associated with each MPU will have to be removed}
	{somewhere else, since this unit ain't messing with them.}
var
	LTemp: MPUPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure RemoveMPU(var LList,LMember: MPUPtr; gb: GameBoardPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: MPUPtr;
begin
	{Initialize A and B}
	B := LList;
	A := Nil;

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
		writeln('ERROR- RemoveLink asked to remove a link that doesnt exist.');
		end
	else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		LList := B^.Next;

		{Get rid of the model.}
		GRemoveModel(B^.M,gb);

		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;

		{Get rid of the model.}
		GRemoveModel(B^.M,gb);

		Dispose(B);
	end;
end;

Function LocateMPU(M: ModelPtr; C: MPUPtr): MPUPtr;
	{Given model M, locate the MPU that is being referred to.}
	{Return Nil if no such MPU can be found.}
var
	it: MPUPtr;
begin
	it := Nil;
	while (C <> Nil) and (it = Nil) do begin
		if C^.M = M then it := C;
		C := C^.Next;
	end;
	LocateMPU := it;
end;

Procedure WriteClouds(CL: CloudPtr; var F: Text);
	{Save the linked list of clouds to the file F.}
begin
	while CL <> Nil do begin
		writeln(F,CL^.kind);

		{Record the position of the cloud}
		writeln(F,CL^.M^.X);
		writeln(F,CL^.M^.Y);

		writeln(F,CL^.duration);
		CL := CL^.Next;
	end;
	writeln(F,-1);
end;

Function ReadClouds(var F: Text; gb: GameBoardPtr): CloudPtr;
	{Read a list of clouds from disk.}
var
	CList: CloudPtr;
	N,X,Y,D: Integer;	{Cloud info.}
begin
	{Initialize the list to NIL.}
	CList := Nil;

	{Keep reading data until we get a termination value, -1.}
	repeat
		ReadLn(F,N);

		{If this isn't the termination character, add this cloud to}
		{the list.}
		if N <> -1 then begin
			{Read the rest of the cloud data.}
			ReadLn(F,X);
			ReadLn(F,Y);
			ReadLn(F,D);

			{Add this cloud to the list.}
			AddCloud(CList,gb,N,X,Y,D);
		end;
	until N = -1;

	ReadClouds := CList;
end;

Procedure WriteMPU(CL: MPUPtr; var F: Text);
	{Save the linked list of computers to the file F.}
begin
	while CL <> Nil do begin
		writeln(F,CL^.kind);

		{Record the position of the computer}
		writeln(F,CL^.M^.X);
		writeln(F,CL^.M^.Y);

		writeln( F , CL^.Attr );
		CL := CL^.Next;
	end;
	writeln(F,-1);
end;

Function ReadMPU(var F: Text; gb: GameBoardPtr): MPUPtr;
	{Read a list of computers from disk.}
var
	CList,Current: MPUPtr;
	N,X,Y: Integer;	{Computer info.}
begin
	{Initialize the list to NIL.}
	CList := Nil;

	{Keep reading data until we get a termination value, -1.}
	repeat
		ReadLn(F,N);

		{If this isn't the termination character, add this cloud to}
		{the list.}
		if N <> -1 then begin
			{Read the rest of the cloud data.}
			ReadLn(F,X);
			ReadLn(F,Y);

			{Add this computer to the list.}
			Current := AddMPU(CList,gb,N,X,Y);
			ReadLn( F , Current^.Attr );
		end;
	until N = -1;

	ReadMPU := CList;
end;


end.
