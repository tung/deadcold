unit rpgdice;
	{This unit handles some of my frequently-wanted dice}
	{routines.}

	{ *** GFX CLEARED! *** }

interface

Const
	DieSize: Array [1..5] of byte = (4,6,8,10,12);
	DieStep: Array [1..10,1..5] of byte = (
	{	d4	d6	d8	d10	d12	}
	(	1,	0,	0,	0,	0),
	(	0,	1,	0,	0,	0),
	(	0,	0,	1,	0,	0),
	(	0,	0,	0,	1,	0),
	(	0,	0,	0,	0,	1),

	(	0,	1,	1,	0,	0),
	(	0,	1,	0,	1,	0),
	(	0,	0,	1,	1,	0),
	(	0,	0,	0,	2,	0),
	(	0,	0,	0,	1,	1)
	);

Function Dice(die: integer): Integer;
Function RollStep(n: Integer): Integer;
Function RollStat(n: integer): integer;
	{Roll Nd6; take the three highest values, add them together,}
	{and return the result. N must be in the range of 1 to 10.}

implementation

Function Dice(die: integer): Integer;
	{Roll a die- D(6), D(8), D(100), whatever.}
	{Die rolling is done as per Earthdawn- whenever a maximum is}
	{rolled, the score is kept and the die rerolled. We're gonna}
	{use recursion to handle this.}

	Function VictoriasSecret(die,it: integer): Integer;
		{WHat's this!? It's the function's underwear of course.}
	var
		r: Integer;
	begin
		{Roll the die.}
		r := Random(die) + 1;

		{If you've rolled the maximum, and we've recursed less}
		{than 100 times, recurse again!}
		if (r = die) and (it<100) then begin
			r := r + VictoriasSecret(die,it + 1);
		end;

		{Slip the address into the underwear.}
		VictoriasSecret := r;
	end;
begin
	{Range check}
	if die < 2 then die := 2;

	Dice := VictoriasSecret(die,1);
end;

Function RollStep(n: Integer): Integer;
	{Roll a dice step number, a la Earthdawn.}
var
	N2,t1,t2,RS: Integer;
begin
	RS := 0;
	While N > 0 do begin
		if N > 10 then
			N2 := 10
		else
			N2 := N;
		for t1 := 1 to 5 do begin
			if DieStep[N2,t1] > 0 then begin
				for t2 := 1 to DieStep[N2,t1] do RS := RS + Dice(DieSize[t1]);
			end;
		end;

		{Decrease N by 10.}
		N := N - 10;
	end;
	RollStep := RS;
end;

Function RollStat(n: integer): integer;
	{Roll Nd6; take the three highest values, add them together,}
	{and return the result. N must be in the range of 1 to 10.}
var
	k: array [1..10] of integer;
	t,tt: integer;	{Loop counters.}
	l: integer;	{in theory, the low value.}
	stat: integer;	{The total value rolled}
begin
	{Range check.}
	if n>10 then n := 10;

	{Initialize stat}
	stat := 0;

	{Roll the indicated number of dice.}
	for t := 1 to n do begin
		{Roll the die}
		k[t] := Random(6) + 1;

		{Add it to the total}
		stat := stat + k[t];
	end;

	{If we rolled more dice than we need, go through and eliminate}
	{the low rolls.}
	if n > 3 then for t := 1 to n-3 do begin
		{locate the first nonzero value for l}
		l := 1;

		while k[l] = 0 do Inc(l);

		for tt := 1 to n do begin
			if (k[tt] > 0) and (k[tt] < k[l]) then l := tt
		end;
		stat := stat - k[l];
		k[l] := 0;
	end;

	RollStat := stat;
end;


initialization
	{Set the random seed}
	Randomize;

end.
