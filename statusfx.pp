unit StatusFX;
	{This unit deals with status change effects.}

Interface

{ Needs PLOTBASE for the NAtt type }
uses plotbase;

Const
	{ By the new system, status changes don't have a value and }
	{ duration; they have a value, and that's about it. }
	NAG_StatusChange = 10;

	{Status Change Values}
	{Positive ones are good for you, Negative ones are bad}
	{ Zero is used as the status change save file sentinel. }
	SEF_DrainBase = 3;	{Used to calculate Attribute Drain codes}
	SEF_Poison = -3;
	SEF_Sleep = -2;
	SEF_Paralysis = -1;
	SEF_VisionBonus = 1;
	SEF_Regeneration = 2;
	SEF_ArmorBonus = 3;
	SEF_CCDmgBonus = 4;
	SEF_StealthBonus = 5;
	SEF_SpeedBonus = 6;
	SEF_H2HBonus = 7;
	SEF_MslBonus = 8;
	SEF_Restoration = 9;
	SEF_BoostBase = 9;	{ Used to calculate Attribute Boost codes }

	NumNegSF = 11;
	NegSFName: Array [1..NumNegSF] of string = (
		'Paralyzed','Asleep','Poisoned','Weakened','Fatigued',
		'Slowed','Dizzy','Jinxed','Dazed','Light Headed',
		'Cursed'
	);

	{Element values.}
	NumElem = 5;
	ELEM_Normal = 0;
	ELEM_Fire = 1;
	ELEM_Cold = 2;
	ELEM_Lit = 3;
	ELEM_Acid = 4;
	ELEM_Holy = 5;


Procedure UpdateStatusList( var SL: NAttPtr );
Procedure ReadObsoleteSFX( var F: Text );

Implementation

Procedure UpdateStatusList( var SL: NAttPtr );
	{ Scan through the status list SL. }
	{ For each status whose value isn't -1, value gets decremented }
	{ by one. If value has reached zero, the status change is }
	{ removed from the list. }
var
	l,l2: NAttPtr;
begin
	l := SL;
	while l <> Nil do begin
		l2 := l^.Next;
		if L^.V > 0 then Dec( L^.V );
		if L^.V = 0 then RemoveNAtt(SL,l);
		l := l2;
	end;
end;

Procedure ReadObsoleteSFX( var F: Text );
	{ From file F, read a list of obsolete status FX descriptions. }
var
	S: String;
begin
	repeat
		readln( F , S );
	until EoF( F ) or ( S = '0' );
end;

end.
