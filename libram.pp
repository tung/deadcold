unit libram;
	{This unit contains all of the books which the player}
	{can find over the course of the game.}

Interface

uses gamebook;

Procedure ReadBook(SC: ScenarioPtr; N: Integer);


Implementation

uses crt,rpgtext,rpgmenus;

Type
	BPage = Record
		name: String;	{A name for the page, for the menu}
		page: PChar;	{The contents of the page.}
	end;

Const
	NumPage = 15;
	ThePages: Array [1..NumPage] of BPage = (
		(	name: '05/33/64';
			page: 'Today I led the visitors group on a tour of the archive. It''s so nice to get the chance to talk with fellow taphophiles.';),
		(	name: '05/36/64 (1)';
			page: 'An archaeological dig site on Taltuo has uncovered an ancient burial site. The artefacts are being sent here for analysis- I''ll be in charge of catelogueing the inventory. I am so excited.'),
		(	name: '05/36/64 (2)';
			page: 'There are several monument stones and a time capsule full of books which will need to be recorded and translated. This is the kind of research I''ve always dreamed of doing- it doesn''t come to DeadCold often.';),
		(	name: '06/01/64 (1)';
			page: 'The computers were shut down again, today. Moira couldn''t do her work without the research database so the two of us managed to spend most of the day together. Technology does improve our lives, sometimes.'),
		(	name: '06/01/64 (2)';
			page: 'Balordo promised the system would be back up tomorrow. Later on, I saw off several members of the tour group as this was the last day of their visit.';),
		(	name: '06/02/64';
			page: 'Today is a sad day. My task for this morning is to record the identity chips obtained from the casulties at Nogun-3. I am always saddened by the senseless loss of young lives.';),
		(	name: '06/05/64 (1)';
			page: 'The artefacts from Taltuo have arrived at last! It''s an impressive collection. Four stone urns engraved with alien writing; jewelry, masks, swords, and other ceremonial items; a cabinet containing a book.'),
		(	name: '06/05/64 (2)';
			page: 'The book is especially interesting. It is constructed from embossed metal sheets, held together with an elaborate hinge. Once translated, it could answer many questions about this culture.';),
		(	name: '06/07/64';
			page: 'It never rains on board the station. I mention this because it''s raining on Earth today, according to the net. Next weekend I''ll take the shuttle to Mascan and look at the sky.'),
		(	name: '06/08/64 (1)';
			page: 'It is odd for a technological society, such as that which obviously existed on the moon of Taltuo, to bury their dead with so much paraphenalia. Were they hoping to provide useful information for future historians? The answer will have to wait...'),
		(	name: '06/08/64 (2)';
			page: 'The computers are on the blink again, and the translation software won''t run. Nick threatened that if I call him one more time asking about it, he''ll brain me. I hate the computers. I need this info now.';),
		(	name: '06/09/64 (1)';
			page: 'Everything is up and running, the first of the translations have been produced. The four corpses were priests in some kind of religious sect, which explains all the gear buried along with them.'),
		(	name: '06/09/64 (2)';
			page: 'Writing on the urns confirms that the four corpses were interred one after the other over a period of about 50My.';),
		(	name: '06/12/64';
			page: 'I have been reading the holy book from Taltuo for the past few days. Earlier on, Moira dragged me out of the archive to go have lunch with her. I came back here immediately afterwards.';),
		(	name: '06/13/64';
			page: 'This page is blank. All the pages following this one have been ripped out of the book.';)

	);

Procedure ReadBook(SC: ScenarioPtr; N: Integer);
	{Read book # N.}
var
	RPM: RPGMenuPtr;
	T,P: Integer;
begin
	{Set up the screen.}
	window(1,4,80,24);
	ClrScr;
	window(1,1,80,24);

	{Create the menu.}
	RPM := CreateRPGMenu(LightGray,Green,LightGreen,55,8,75,20);
	for t := 1 to NumPage do AddRPGMenuItem(RPM,ThePages[t].name,T,Nil);

	repeat
		P := SelectMenu(RPM,RPMNoCleanup);

		if P <> -1 then begin
			TextColor(Black);
			TextBackground(Yellow);
			window(6,5,33,23);
			ClrScr;
			window(9,7,30,21);
			Delineate(ThePages[P].page,21,1);
			TextBackground(Black);
			window(1,1,80,25);
		end;
	until P = -1;
	DisposeRPGMenu( RPM );
end;

end.
