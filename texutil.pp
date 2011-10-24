unit texutil;
	{This unit contains various useful functions for dealing}
	{with strings.}


interface

Procedure DeleteWhiteSpace(var S: String);
Function ExtractWord(var S: String): String;
Function ExtractValue(var S: String): Integer;
Function RetrieveAString(S: String): String;
Function BStr( N: Integer ): String;
Function ExtractNumber(S: String; Start,L: Integer): Integer;
Procedure DeleteFirstChar(var S: String);


implementation

Procedure DeleteWhiteSpace(var S: String);
	{Delete any whitespace which is at the beginning of}
	{string S. If S is nothing but whitespace, or if it}
	{contains nothing, return an empty string.}
	{ BUGS - None detected. Test harnessed and everything.}
var
	P: Integer;
begin
	{Locate the first relevant char.}
	P := 1;
	while (P < Length(S)) and ((S[P] = ' ') or (S[P] = #9)) do begin
		Inc(P);
	end;

	{Copy the string from the first nonspace to the end.}
	if (S[P] = ' ') or (S[P] = #9) then S := ''
	else S := Copy(S,P,Length(S));
end;

Function ExtractWord(var S: String): String;
	{Extract the next word from string S.}
	{Return this substring as the function's result;}
	{truncate S so that it is now the remainder of the string.}
	{If there is no word to extract, both S and the function}
	{result will be set to empty strings.}
	{ BUGS - None found.}
var
	P: Integer;
	it: String;
begin
	{To start the process, strip all whitespace from the}
	{beginning of the string.}
	DeleteWhiteSpace(S);

	{Error check- make sure that we have something left to}
	{extract! The string could have been nothing but white space.}
	if S <> '' then begin

		{Determine the position of the next whitespace.}
		P := Pos(' ',S);
		if P = 0 then P := Pos(#9,S);

		{Extract the command.}
		if P <> 0 then begin
			it := Copy(S,1,P-1);
			S := Copy(S,P,Length(S));
		end else begin
			it := Copy(S,1,Length(S));
			S := '';
		end;

	end else begin
		it := '';
	end;

	ExtractWord := it;
end;

Function ExtractValue(var S: String): Integer;
	{This is similar to the above procedure, but}
	{instead of a word it extracts a numeric value.}
	{Return 0 if the extraction should fail for any reason.}
var
	S2: String;
	it,C: Integer;
begin
	S2 := ExtractWord(S);
	Val(S2,it,C);
	if C <> 0 then it := 0;
	ExtractValue := it;
end;

Function RetrieveAString(S: String): String;
	{Retrieve an Alligator String from S.}
	{Alligator Strings are defined as the part of the string}
	{that both alligarors want to eat, i.e. between < and >.}
var
	A1,A2: Integer;
begin
	{Locate the position of the two alligators.}
	A1 := Pos('<',S);
	A2 := Pos('>',S);

	{If the string has not been declared with <, return}
	{an empty string.}
	if A1 = 0 then Exit('');

	{If the string has not been closed with >, return the}
	{entire remaining length of the string.}
	if A2 = 0 then A2 := Length(S)+1;

	RetrieveAString := Copy(S,A1+1,A2-A1-1);
end;

Function BStr( N: Integer ): String;
	{ This function functions as the BASIC Str function. }
var
	it: String;
begin
	Str(N, it);
	BStr := it;
end;

Function ExtractNumber(S: String; Start,L: Integer): Integer;
	{This procedure will extract a numerical value from the}
	{string, starting at point Start and continuing for L}
	{characters. Return a 0 for a failed conversion.}
var
	it,C: Integer;
begin
	Val( Copy( S, Start, L ) , it , C );
	if C <> 0 then it := 0;
	ExtractNumber := it;
end;

Procedure DeleteFirstChar(var S: String);
	{ Remove the first character from string S. }
begin
	{Copy the string from the first nonspace to the end.}
	if Length( S ) < 2 then S := ''
	else S := Copy(S,2,Length(S));
end;


end.
