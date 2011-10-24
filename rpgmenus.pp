unit RPGMenus;

	{ BUGS - If SelectMenu is handed an empty menu, all heck will }
	{  break loose. This can be a particular problem for SelectFile. }

interface

uses crt,dos,rpgtext;

const
	{These two constants are used to tell the SELECT procedure whether or not}
	{the user is allowed to cancel.}
	RPMNormal = 0;
	RPMNoCancel = 1;
	RPMNoCleanup = 2; {If you want the menu left on the screen after we've finished, use this.}

type
	RPGMenuKeyPtr = ^RPGMenuKey;
	RPGMenuKey = Record
		k: Char;
		value: integer;		{The value returned when this key is pressed.}
		next: RPGMenuKeyPtr;
	end;

	RPGMenuItemPtr = ^RPGMenuItem;
	RPGMenuItem = Record
		msg: string;		{The text which appears in the menu}
		value: integer;		{A value, returned by SelectMenu. -1 is reserved for Cancel}
		desc: pchar;		{Pointer to the item description. If Nil, no desc.}
		next: RPGMenuItemPtr;
	end;
	RPGMenuPtr = ^RPGMenu;
	RPGMenu = Record
		active: boolean;
		bordercolor,itemcolor,selcolor,x1,y1,x2,y2: byte;
		dborcolor,dtexcolor,dx1,dy1,dx2,dy2: byte; {fields relating to the optional description box.}
		topitem,selectitem,numitem: integer; {fields holding info about the status of the menu.}
		FirstItem: RPGMenuItemPtr;
		FirstKey: RPGMenuKeyPtr;
	end;

Procedure AddRPGMenuItem(var RPM: RPGMenuPtr; msg: string; value: integer; desc: pchar);
Procedure AddRPGMenuItem(var RPM: RPGMenuPtr; msg: string; value: integer);
Procedure AddRPGMenuKey(RPM: RPGMenuPtr; k: Char; value: Integer);
Function CreateRPGMenu(bcolor,icolor,scolor,x1,y1,x2,y2: byte): RPGMenuPtr;
Procedure DisposeRPGMenu(var RPM: RPGMenuPtr);
Procedure DisplayMenu(RPM: RPGMenuPtr);
Function RPMLocateByPosition(RPM: RPGMenuPtr; i: integer): RPGMenuItemPtr;
Function SelectMenu(RPM: RPGMenuPtr;Mode: byte): integer;
Procedure RPMSortAlpha(RPM: RPGMenuPtr);
Procedure BuildFileMenu( RPM: RPGMenuPtr; SearchPattern: String );
Function SelectFile( RPM: RPGMenuPtr ): String;

implementation

Function LastMenuItem(MIList: RPGMenuItemPtr): RPGMenuItemPtr;
	{This procedure will find the last item in the linked list.}
begin
	{While the menu item is pointing to a next menu item, it's not the last. duh.}
	{So, move through the list until we hit a Nil pointer.}
	while MIList^.next <> Nil do begin
		{Check the next one.}
		MIList := MIList^.next;
	end;
	{We've found a MI.next = Nil. Yay! Return its address.}
	LastMenuItem := MIList;
end;

Procedure AddRPGMenuItem(var RPM: RPGMenuPtr; msg: string; value: integer; desc: pchar);
	{This procedure will add an item to the RPGToolMenu.}
	{The new item will be added as the last item in the list.}
var
	it: ^RPGMenuItem;		{Here's a pointer for the item we're creating.}
	temp: RPGMenuItemPtr;
begin
	{Allocate memory for it.}
	New(it);

	{Check to make sure that the allocation succeeded.}
	if it = Nil then begin
		{Oops... something went wrong. Better let the user know.}
		writeln('Error: Popcorn Delta. AddRPGMenuItem messsed up.');
		readkey;
		exit;
	end;

	{Initialize it to the correct values.}
	it^.msg := msg;
	it^.value := value;
	it^.next := Nil;
	it^.desc := desc; 	{The desc field is assigned the value of PChar since it}
				{is assumed that we arent responsible for the allocation,}
				{disposal, or contents of this string.}

	{Locate the last item in the list, then assign "it" to it.}
	{If the list is currently empty, stick "it" in as the first item.}
	if RPM^.firstitem = Nil then
		RPM^.firstitem := it
	else begin
		temp := LastMenuItem(RPM^.FirstItem);
		temp^.next := it;		
	end;

	{Increment the NumItem field.}
	Inc(RPM^.numitem);
end; 

Procedure AddRPGMenuItem(var RPM: RPGMenuPtr; msg: string; value: integer);
	{ Just like the above, but no desc. }
begin
	AddRPGMenuItem( RPM , msg , value , Nil );
end;

Procedure AddRPGMenuKey(RPM: RPGMenuPtr; k: Char; value: Integer);
	{Add a dynamically defined RPGMenuKey to the menu.}
var
	it: RPGMenuKeyPtr;
begin
	New(it);
	if it = Nil then begin
		writeln('ERROR- AddRPGMenuKey failed on memory allocation. Buy some RAM.');
		exit;
	end;

	{Initialize the values.}
	it^.k := k;
	it^.value := value;
	it^.next := RPM^.FirstKey;
	RPM^.FirstKey := it;
end;

Function CreateRPGMenu(bcolor,icolor,scolor,x1,y1,x2,y2: byte): RPGMenuPtr;
	{This function creates a new RPGMenu record, and returns the address.}
var
	it: ^RPGMenu;			{Here's a pointer for the menu we're making.}
begin
	{Allocate memory for it.}
	New(it);

	{Check to make sure that we've actually initialized something.}
	if it = Nil then begin
		{Oops... something went wrong. Better let the user know.}
		writeln('Error: Popaboner Overflow. CreateRPGMenu messsed up. I make no promises.');
		readkey;
		exit;
	end;

	{Initialize the elements of the record.}
	it^.bordercolor := bcolor;
	it^.itemcolor := icolor;
	it^.selcolor := scolor;
	it^.x1 := x1;
	it^.y1 := y1;
	it^.x2 := x2;
	it^.y2 := y2;
	it^.FirstItem := Nil;
	it^.FirstKey := Nil;
	it^.dx1 := 0;	{A X1 value of 0 means there is no desc window.}
	it^.dborcolor := bcolor; {Might as well initialize the desc colors while}
	it^.dtexcolor := icolor; {we're here.}
	it^.active := False;

	{TopItem refers to the highest item on the screen display.}
	it^.topitem := 1;

	{SelectItem refers to the item currently being pointed at by the selector.}
	it^.selectitem := 1;

	{NumItem refers to the total number of items currently in the linked list.}
	it^.numitem := 0;

	{Return the address.}
	CreateRPGMenu := it;
end;

Procedure DisposeRPGMenu(var RPM: RPGMenuPtr);
	{This procedure is called when you want to get rid of the menu. It will deallocate}
	{the memory for the RPGMenu record and also for all of the linked RPGMenuItems.}
var
	a,b: ^RPGMenuItem;	{Counters, for deallocation.}
	c,d: RPGMenuKeyPtr;
begin
	{Check to make sure that we've got a valid pointer here.}
	if RPM = Nil then begin
		writeln('ERROR: Joe is a Doofus. DisposeRPGMenu has been passed a null pointer.');
		readkey;
		exit;
	end;

	{Save the location of the first menu item...}
	a := RPM^.FirstItem;
	c := RPM^.FirstKey;
	{... then get rid of the menu record.}
	Dispose(RPM);
	RPM := Nil;

	{Keep processing the menu items until we hit a Nil nextitem.}
	while a <> Nil do begin
		b := a^.next;
		Dispose(a);
		a := b;
	end;
	while c <> Nil do begin
		d := c^.next;
		Dispose(c);
		c := d;
	end;
end;

Function RPMLocateByPosition(RPM: RPGMenuPtr; i: integer): RPGMenuItemPtr;
	{Locate the i'th element of the item list, then return its address.}
var
	a: RPGMenuItemPtr;	{Our pointer}
	t: integer;		{Our counter}
begin
	{Error check, first off.}
	if i > RPM^.numitem then begin
		writeln('ERROR: RPMLocateByPosition asked to find a message that doesnt exist.');
		readkey;
		exit;
	end;

	a := RPM^.FirstItem;
	t := 1;

	if i > 1 then begin
		for t := 2 to i do
			a := a^.next;
	end;

	RPMLocateByPosition := a;
end;

Procedure RPMRefreshDesc(RPM: RPGMenuPtr);
	{Refresh the menu description box, if appropriate.}
begin
	{Check to make sure that this menu has a description box, first off.}
	if RPM^.dx1 > 0 then begin
		Window(RPM^.DX1+1,RPM^.DY1+1,RPM^.DX2-1,RPM^.DY2-1);
		ClrScr;
		TextColor(RPM^.dtexcolor);
		Delineate(RPMLocateByPosition(RPM,RPM^.selectitem)^.desc,RPM^.DX2 - RPM^.DX1 - 1,1);
		Window(1,1,80,25);
	end;
end;

Procedure DisplayMenu(RPM: RPGMenuPtr);
	{Display the menu on the screen.}
var
	topitem: RPGMenuItemPtr;
	a: RPGMenuItemPtr;		{A pointer to be used while printing.}
	t: integer;
	height, width: integer;		{The height and width of the menu display.}
begin
	{Error check- make sure the menu has items in it.}
	if RPM^.FirstItem = Nil then Exit;

	{Check to see if the user wants a border. If so, draw it.}
	if RPM^.BorderColor <> Black then
		{Draw a LovelyBox first for the menu.}
		LovelyBox(RPM^.BorderColor,RPM^.X1,RPM^.Y1,RPM^.X2,RPM^.Y2);

	{Next draw a LovelyBox for the item description, if applicable.}
	if RPM^.dx1 > 0 then begin
		LovelyBox(RPM^.dborcolor,RPM^.DX1,RPM^.DY1,RPM^.DX2,RPM^.DY2);
	end;

	{Display each menu item.}

	{Open an appropriately sized window and clear that area.}
	Window(RPM^.X1+1,RPM^.Y1+1,RPM^.X2-1,RPM^.Y2-1);
	ClrScr;

	{Calculate the width and the height of the menu.}
	width := RPM^.X2 - RPM^.X1 - 1;
	height := RPM^.Y2 - RPM^.Y1 - 1;

	{Locate the top of the menu.}
	topitem := RPMLocateByPosition(RPM,RPM^.topitem);

	a := topitem;
	for t := 1 to height do begin
		{If we're at the currently selected item, highlight it.}
		if ((t + RPM^.topitem - 1) = RPM^.selectitem) and RPM^.Active then
			TextColor(RPM^.selcolor)
		else
			TextColor(RPM^.itemcolor);

		GotoXY(1,t);
		write(Copy(a^.msg,1,width));
		a := a^.next;

		{Check to see if we've prematurely encountered the end of the list.}
		if a = Nil then
			break;
	end;

	{Restore the window to its regular size.}
	Window(1,1,80,25);

	{If there's an associated Desc field, display it now.}
	RPMRefreshDesc(RPM);
end;

Procedure RPMReposition(RPM: RPGMenuPtr);
	{The selected item has just changed, and is no longer visible on screen.}
	{Adjust the RPGMenu's topitem field to an appropriate value.}
var
	height: integer;	{The height of the menu}
begin
	{When this function is called, there are two possibilities: either the}
	{selector has moved off the bottom of the page or the top.}

	{Calculate the height of the menu.}
	height := RPM^.Y2 - RPM^.Y1 - 1;

	if RPM^.selectitem < RPM^.topitem then begin
		{The selector has moved off the bottom of the list. The new page}
		{display should start with SelectItem on the bottom.}
		RPM^.topitem := RPM^.selectitem - height + 1;

		{Error check- if this moves topitem below 1, that's bad.}
		if RPM^.topitem < 1 then
			RPM^.topitem := 1;
		end
	else begin
		{The selector has moved off the top of the list. The new page should}
		{start with SelectItem at the top, unless this would make things look}
		{funny.}
		if ((RPM^.selectitem + height - 1) > RPM^.numitem) then begin
			{There will be whitespace at the bottom of the menu if we assign}
			{SelectItem to TopItem. Make TopItem equal to the effective last}
			{page.}
			RPM^.topitem := RPM^.numitem - height + 1;
			if RPM^.topitem < 1 then RPM^.topitem := 1;
			end
		else
			RPM^.topitem := RPM^.selectitem;
	end;

end;

Procedure RPMUpKey(RPM: RPGMenuPtr);
	{Someone just pressed the UP key, and we're gonna process that input.}
	{PRECONDITIONS: RPM has been initialized properly, and is currently being}
	{  displayed on the screen.}
var
	width: integer;		{The width of the menu window}
begin
	{Lets set up the window.}
	Window(RPM^.X1+1,RPM^.Y1+1,RPM^.X2-1,RPM^.Y2-1);

	{Calculate the width of the menu.}
	width := RPM^.X2 - RPM^.X1 - 1;

	{De-indicate the old selected item.}
	{Change color to the regular item color...}
	TextColor(RPM^.itemcolor);
	{Then reprint the text of the previously selected item.}
	GotoXY(1,RPM^.selectitem - RPM^.topitem + 1);
	write(Copy(RPMLocateByPosition(RPM,RPM^.selectitem)^.msg,1,width));

	{Decrement the selected item by one.}
	Dec(RPM^.selectitem);
	{If this causes it to go beneath one, wrap around to the last item.}
	if RPM^.selectitem = 0 then
		RPM^.selectitem := RPM^.numitem;

	{If the movement takes the selected item off the screen, do a redisplay.}
	{Otherwise, indicate the newly selected item.}
	if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem) > (RPM^.Y2 - RPM^.Y1 - 2)) then begin
		{First, restore the normal window size, since DisplayMenu will try to resize it.}
		Window(1,1,80,25);

		{Determine an appropriate new value for topitem.}
		RPMReposition(RPM);

		{Redisplay the menu.}
		DisplayMenu(RPM);

		end
	else begin
		TextColor(RPM^.selcolor);
		GotoXY(1,RPM^.selectitem - RPM^.topitem + 1);
		write(Copy(RPMLocateByPosition(RPM,RPM^.selectitem)^.msg,1,width));

		{Restore the window to its regular size.}
		Window(1,1,80,25);

		{If this menu features item descriptions, better refresh the text.}
		if RPM^.dx1 > 0 then begin
			RPMRefreshDesc(RPM);
		end;
	end;

end;

Procedure RPMDownKey(RPM: RPGMenuPtr);
	{Someone just pressed the DOWN key, and we're gonna process that input.}
	{PRECONDITIONS: RPM has been initialized properly, and is currently being}
	{  displayed on the screen.}
var
	width: integer;		{The width of the menu window}
begin
	{Lets set up the window.}
	Window(RPM^.X1+1,RPM^.Y1+1,RPM^.X2-1,RPM^.Y2-1);

	{Calculate the width of the menu.}
	width := RPM^.X2 - RPM^.X1 - 1;

	{De-indicate the item.}
	{Change color to the normal text color, then reprint the item's message.}
	TextColor(RPM^.itemcolor);
	GotoXY(1,RPM^.selectitem - RPM^.topitem + 1);
	write(Copy(RPMLocateByPosition(RPM,RPM^.selectitem)^.msg,1,width));

	{Increment the selected item.}
	Inc(RPM^.selectitem);
	{If this takes the selection out of bounds, restart at the first item.}
	if RPM^.selectitem = RPM^.numitem + 1 then
		RPM^.selectitem := 1;

	{If the movement takes the selected item off the screen, do a redisplay.}
	{Otherwise, indicate the newly selected item.}
	if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem) > (RPM^.Y2 - RPM^.Y1 - 2)) then begin
		{First, restore the normal window size, since DisplayMenu will try to resize it.}
		Window(1,1,80,25);

		{Determine an appropriate new value for topitem.}
		RPMReposition(RPM);

		{Redisplay the menu.}
		DisplayMenu(RPM);

		end
	else begin
		TextColor(RPM^.selcolor);
		GotoXY(1,RPM^.selectitem - RPM^.topitem + 1);
		write(Copy(RPMLocateByPosition(RPM,RPM^.selectitem)^.msg,1,width));

		{Restore the window to its regular size.}
		Window(1,1,80,25);

		{If this menu features item descriptions, better refresh the text.}
		if RPM^.dx1 > 0 then begin
			RPMRefreshDesc(RPM);
		end;
	end;

end;


Function SelectMenu(RPM: RPGMenuPtr;Mode: byte): integer;
	{This function will allow the user to browse through the menu and will}
	{return a value based upon the user's selection.}
var
	getit: char;		{Character used to store user input}
	r: integer;		{The value we'll be sending back.}
	m: RPGMenuKeyPtr;
	UK: Boolean;		{Has a special MenuKey been pressed?}
begin
	{The menu is now active!}
	RPM^.Active := True;

	{Show the menu to the user.}
	DisplayMenu(RPM);

	{Initialize UK}
	UK := False;

	{Start the loop. Remain in this loop until either the player makes a selection}
	{or cancels the menu using the ESC key.}
	repeat
		{Read the input from the keyboard.}
		getit := RPGKey;

		{Certain keys need processing- if so, process them.}
		case getit of
			{Selection Movement Keys}
			'8': RPMUpKey(RPM);
			'2': RPMDownKey(RPM);

			{If we recieve an ESC, better check to make sure we're in a}
			{cancelable menu. If not, convert the ESC to an unused key.}
			#27: If Mode = RPMNoCancel then getit := 'Q';
		end;

		{Check to see if a special MENU KEY has been pressed.}
		if RPM^.FirstKey <> Nil then begin
			m := RPM^.FirstKey;
			while m <> Nil do begin
				if getit = m^.k then begin
					UK := True;
					r := m^.value;
				end;
				m := m^.next;
			end;
		end;

	{Check for a SPACE or ESC.}
	until (getit = ' ') or (getit = #27) or UK;

	{The menu is no longer active.}
	RPM^.Active := False;

	{We have to send back a different value depending upon whether a selection}
	{was made or the menu was cancelled. If an item was selected, return its}
	{value field. The value always returned by a cancel will be -1.}
	{If a MenuKey was pressed, r already contains the right value.}
	if getit = ' ' then begin
			r := RPMLocateByPosition(RPM,RPM^.selectitem)^.value;
		end
	else if not UK then
		r := -1;

	if mode <> RPMNoCleanup then begin
		{Remove the menu from the display. I'm gonna use Window for this, since}
		{ClrScr in this language doesn't take paramters. Bummer.}

		{Check to see whether or not a border was used.}
		if RPM^.BorderColor = Black then begin
			Window(RPM^.X1+1,RPM^.Y1+1,RPM^.X2-1,RPM^.Y2-1);
			ClrScr;
		end else begin
			Window(RPM^.X1,RPM^.Y1,RPM^.X2,RPM^.Y2);
			ClrScr;
		end;

		{If there's an associated description box, clear that too.}
		if RPM^.dx1 > 0 then begin
			Window(RPM^.DX1,RPM^.DY1,RPM^.DX2,RPM^.DY2);
			ClrScr;
		end;
	end;

	{Reset the window to normal values}
	Window(1,1,80,25);

	SelectMenu := r;
end;

Procedure RPMSortAlpha(RPM: RPGMenuPtr);
	{Given a menu, RPM, sort its items based on the alphabetical}
	{order of their msg fields.}
	{I should mention here that I haven't written a sorting}
	{algorithm in years, and only once on a linked list (CS assignment).}
	{I think this is an insertion sort... I checked on internet for}
	{examples of sorting techniques, found a bunch of contradictory}
	{information, and decided to just write the easiest thing that}
	{would work. Since we're dealing with a relatively small number}
	{of items here, speed shouldn't be that big a concern.}
var
	sorted: RPGMenuItemPtr;	{The sorted list}
	a,b,c,d: RPGMenuItemPtr;{Counters. We always need them, you know.}
	youshouldstop: Boolean;	{Can you think of a better name?}
begin
	{Initialize A and Sorted.}
	a := RPM^.firstitem;
	Sorted := Nil;

	while a <> Nil do begin
		b := a;		{b is to be added to sorted}
		a := a^.next;	{increase A to the next item in the menu}

		{Give b's Next field a value of Nil.}
		b^.next := nil;

		{Locate the correct position in Sorted to store b}
		if Sorted = Nil then
			{This is the trivial case- Sorted is empty.}
			Sorted := b
		else if b^.msg < Sorted^.msg then begin
			{b should be the first element in the list.}
			c := sorted;
			sorted := b;
			sorted^.next := c;
			end
		else begin
			{c and d will be used to move through Sorted.}
			c := Sorted;

			{Locate the last item lower than b}
			youshouldstop := false;
			repeat
				d := c;
				c := c^.next;

				if c = Nil then
					youshouldstop := true
				else if c^.msg > b^.msg then begin
					youshouldstop := true;
				end;
			until youshouldstop;
			b^.next := c;
			d^.next := b;
		end;
	end;
	RPM^.firstitem := Sorted;
end;

Procedure BuildFileMenu( RPM: RPGMenuPtr; SearchPattern: String );
	{ Do a DosSearch for files matching SearchPattern, then add }	
	{ each of the files found to the menu. }
var
	F: SearchRec;
	N: Integer;
begin
	N := 1;
	FindFirst( SearchPattern , AnyFile , F );

	While DosError = 0 do begin
		AddRPGMenuItem( RPM , F.Name , N );
		Inc(N);
		FindNext( F );
	end;
end;

Function SelectFile( RPM: RPGMenuPtr ): String;
	{ RPM is a menu created by the BuildFileMenu procedure. }
	{ So, select one of the items and return the item name, which }
	{ should be a filename. }
var
	N: Integer;	{ The number of the file selected. }
	Name: String;	{ The name of the filename selected. }
begin
	{ Do the menu selection first. }
	N := SelectMenu( RPM , RPMNormal );

	if N = -1 then begin
		{ Selection was canceled. So, return an empty string. }
		Name := '';
	end else begin
		{ Locate the selected element of the menu. }
		Name := RPMLocateByPosition(RPM,RPM^.SelectItem)^.msg;
	end;

	SelectFile := Name;
end;


end.
