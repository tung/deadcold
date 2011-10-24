unit plotbase;
	{This unit defines the Plot Arc type, and provides several}
	{procedures for dealing with it.}

	{ PLOTBASE MARK II -  technology marches on and DeadCold with it. }
	{ I have replaced the original PlotBase/PlotLine stuff with the }
	{ considerably more elegant GearHead Arena Script code. }

interface

uses texutil;

const
	NAG_ScriptVar = 0;
	NAG_MonsterMemory = 1;

Type
	SAtt = Record		{*** STRING ATTRIBUTE ***}
		info: String;
		next: ^SAtt;
	end;
	SAttPtr = ^SAtt;

	NAtt = Record		{*** NUMERICAL ATTRIBUTE ***}
		G,S: Integer;		{General, Specific, Value}
		V: LongInt;
		next: ^NAtt;
	end;
	NAttPtr = ^NAtt;


Function CreateSAtt(var LList: SAttPtr): SAttPtr;
Procedure DisposeSAtt(var LList: SAttPtr);
Procedure RemoveSAtt(var LList,LMember: SAttPtr);
Function FindSAtt(LList: SAttPtr; Code: String): SAttPtr;
Function SetSAtt(var LList: SAttPtr; Info: String): SAttPtr;
Function StoreSAtt(var LList: SAttPtr; Info: String): SAttPtr;
Function SAttValue(LList: SAttPtr; Code: String): String;

Function CreateNAtt(var LList: NAttPtr): NAttPtr;
Procedure DisposeNAtt(var LList: NAttPtr);
Procedure RemoveNAtt(var LList,LMember: NAttPtr);
Function FindNAtt(LList: NAttPtr; G,S: Integer): NAttPtr;
Function SetNAtt(var LList: NAttPtr; G,S: Integer; V: LongInt): NAttPtr;
Function AddNAtt(var LList: NAttPtr; G,S: Integer; V: LongInt): NAttPtr;
Function NAttValue(LList: NAttPtr; G,S: Integer): LongInt;

Procedure WriteNAtt( NA: NAttPtr; var F: Text );
Procedure WriteSAtt( SA: SAttPtr; var F: Text );
Function ReadNAtt( var F: Text ): NAttPtr;
Function ReadSAtt( var F: Text ): SAttPtr;


implementation

const
	SaveFileContinue = 0;
	SaveFileSentinel = -1;


Function CreateSAtt(var LList: SAttPtr): SAttPtr;
	{Add a new element to the head of LList.}
var
	it: SAttPtr;
begin
	{Allocate memory for our new element.}
	New(it);
	if it = Nil then exit;

	{Attach IT to the list.}
	it^.Next := LList;
	LList := it;

	{Return a pointer to the new element.}
	CreateSAtt := it;
end;

Procedure DisposeSAtt(var LList: SAttPtr);
	{Dispose of the list, freeing all associated system resources.}
var
	LTemp: SAttPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure RemoveSAtt(var LList,LMember: SAttPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: SAttPtr;
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
		writeln('ERROR- RemoveSAtt asked to remove a link that doesnt exist.');
		end
	else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		LList := B^.Next;
		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;
		Dispose(B);
	end;
end;

Function FindSAtt(LList: SAttPtr; Code: String): SAttPtr;
	{Search through the list looking for a String Attribute}
	{whose code matches CODE and return its address.}
	{Return Nil if no such SAtt can be found.}
var
	it: SAttPtr;
	S: STring;
begin
	{Initialize IT to Nil.}
	it := Nil;

	Code := UpCase(Code);

	{Check through all the SAtts looking for the SATT in question.}
	while LList <> Nil do begin
		S := LList^.info;
		S := UpCase(ExtractWord(S));

		if S = Code then it := LList;

		LList := LList^.Next;
	end;

	FindSAtt := it;
end;

Function SetSAtt(var LList: SAttPtr; Info: String): SAttPtr;
	{Add string attribute Info to the list. However, a gear}
	{may not have two string attributes with the same name.}
	{So, check to see whether or not the list already contains}
	{a string attribute of this type; if so, just replace the}
	{INFO field. If not, create a new SAtt and fill it in.}
var
	it: SAttPtr;
	code: String;
begin
	{Determine the CODE of the string.}
	code := Info;
	code := ExtractWord(code);

	{See if that code already exists in the list,}
	{if not create a new entry for it.}
	it := FindSAtt(LList,code);

	{Plug in the value.}
	if RetrieveAString( Info ) = '' then begin
		if it <> Nil then RemoveSAtt( LList , it );
	end else begin
		if it = Nil then it := CreateSAtt(LList);
		it^.info := Info;
	end;

	{Return a pointer to the new attribute.}
	SetSAtt := it;
end;

Function StoreSAtt(var LList: SAttPtr; Info: String): SAttPtr;
	{ Add string attribute Info to the list. This procedure }
	{ doesn't check to make sure this attribute isn't duplicated. }
var
	it: SAttPtr;
begin
	it := CreateSAtt(LList);
	it^.info := Info;

	{Return a pointer to the new attribute.}
	StoreSAtt := it;
end;

Function SAttValue(LList: SAttPtr; Code: String): String;
	{Find a String Attribute which corresponds to Code, then}
	{return its embedded alligator string.}
var
	it: SAttPtr;
begin
	it := FindSAtt(LList,Code);

	if it = Nil then Exit('');

	SAttValue := RetrieveAString(it^.info);
end;


Function CreateNAtt(var LList: NAttPtr): NAttPtr;
	{Add a new element to the head of LList.}
var
	it: NAttPtr;
begin
	{Allocate memory for our new element.}
	New(it);
	if it = Nil then exit;

	{Initialize values.}

	it^.Next := LList;
	LList := it;

	{Return a pointer to the new element.}
	CreateNAtt := it;
end;

Procedure DisposeNAtt(var LList: NAttPtr);
	{Dispose of the list, freeing all associated system resources.}
var
	LTemp: NAttPtr;
begin
	while LList <> Nil do begin
		LTemp := LList^.Next;
		Dispose(LList);
		LList := LTemp;
	end;
end;

Procedure RemoveNAtt(var LList,LMember: NAttPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: NAttPtr;
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
		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;
		Dispose(B);
	end;
end;

Function FindNAtt(LList: NAttPtr; G,S: Integer): NAttPtr;
	{Locate the numerical attribute described by G,S and}
	{return a pointer to it. If no such attribute exists}
	{in the list, return Nil.}
var
	it: NAttPtr;
begin
	{Initialize it to Nil.}
	it := Nil;

	{Loop through all the elements.}
	while LList <> Nil do begin
		if (LList^.G = G) and (LList^.S = S) then it := LList;
		LList := LList^.Next;
	end;

	{Return the value.}
	FindNatt := it;
end;

Function SetNAtt(var LList: NAttPtr; G,S: Integer; V: LongInt ): NAttPtr;
	{Set the Numerical Attribute described by G,S to value V.}
	{If the attribute already exists, change its value. If not,}
	{create the attribute.}
var
	it: NAttPtr;
begin
	it := FindNAtt(LList,G,S);

	if it = Nil then begin
		{The attribute doesn't currently exist. Create it.}
		it := CreateNAtt(LList);
		it^.G := G;
		it^.S := S;
		it^.V := V;
	end else begin
		{The attribute is already posessed. Just change}
		{its Value field.}
		it^.V := V;
	end;

	SetNAtt := it;
end;

Function AddNAtt(var LList: NAttPtr; G,S: Integer; V: LongInt ): NAttPtr;
	{Add value V to the value field of the Numerical Attribute}
	{described by G,S. If the attribute does not exist, create}
	{it and set its value to V.}
	{If, as a result of this operation, V drops below 0,}
	{the numerical attribute will be removed and Nil will}
	{be returned.}
var
	it: NAttPtr;
begin
	it := FindNAtt(LList,G,S);

	if it = Nil then begin
		{The attribute doesn't currently exist. Create it.}
		it := CreateNAtt(LList);
		it^.G := G;
		it^.S := S;
		it^.V := V;
	end else begin
		it^.V := it^.V + V;
	end;

	if it^.V < 0 then RemoveNAtt(LList,it);

	AddNAtt := it;
end;

Function NAttValue(LList: NAttPtr; G,S: Integer): LongInt;
	{Return the value of Numeric Attribute G,S. If this}
	{attribute is not posessed, return 0.}
var
	it: LongInt;
begin
	it := 0;
	while LList <> Nil do begin
		if (LList^.G = G) and (LList^.S = S) then it := LList^.V;
		LList := LList^.Next;
	end;
	NAttValue := it;
end;

Procedure WriteNAtt( NA: NAttPtr; var F: Text );
	{ Output the provided list of string attributes. }
var
	msg: String;
begin
	{ Export Numeric Attributes }
	while NA <> Nil do begin
		msg := BStr( SaveFileContinue ) + ' ' + BStr( NA^.G ) + ' ' + BStr( NA^.S ) + ' ' + BStr( NA^.V );
		writeln( F , msg );
		NA := NA^.Next;
	end;
	{ Write the sentinel line here. }
	writeln( F , SaveFileSentinel );
end;

Procedure WriteSAtt( SA: SAttPtr; var F: Text );
	{ Output the provided list of string attributes. }
begin
	{ Export String Attributes }
	while SA <> Nil do begin
		{ Error check- only output valid string attributes. }
		if Pos('<',SA^.Info) > 0 then writeln( F , SA^.Info );
		SA := SA^.Next;
	end;
	{ Write the sentinel line here. }
	writeln( F , 'Z' );
end;

Function ReadNAtt( var F: Text ): NAttPtr;
	{ Read some numeric attributes from the file. }
var
	N,G,S: Integer;
	V: LongInt;
	it: NAttPtr;
	TheLine: String;
begin
	{ Initialize the list to Nil. }
	it := Nil;
	{ Keep processing this file until either the sentinel }
	{ is encountered or we run out of data. }
	repeat
		{ read the next line of the file. }
		readln( F , TheLine );
		{ Extract the action code. }
		N := ExtractValue( TheLine );
		{ If this action code implies that there's a gear }
		{ to load, get to work. }
		if N = SaveFileContinue then begin
			{ Read the specific values of this NAtt. }
			G := ExtractValue( TheLine );
			S := ExtractValue( TheLine );
			V := ExtractValue( TheLine );
			SetNAtt( it , G , S , V );
		end;
	until ( N = SaveFileSentinel ) or EoF( F );
	ReadNAtt := it;
end;

Function ReadSAtt( var F: Text ): SAttPtr;
	{ Read some string attributes from the file. }
var
	it: SAttPtr;
	TheLine: String;
begin
	it := Nil;
	{ Keep processing this file until either the sentinel }
	{ is encountered or we run out of data. }
	repeat
		{ read the next line of the file. }
		readln( F , TheLine );

		{ If this is a valid string attribute, file it. }
		if Pos('<',TheLine) > 0 then begin
			StoreSAtt( it , TheLine );
		end;
	until ( Pos('<',TheLine) = 0 ) or EoF( F );

	ReadSAtt := it;
end;

end.
