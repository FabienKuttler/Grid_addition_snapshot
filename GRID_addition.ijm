
//	*************************************************************************
//	*************************************************************************
//	
//		Macro for well names +/- Grid addition on an image
//		to create a full plate overview from any opened image
//		Fabien Kuttler, 2022, EPFL-SV-PTECH-PTCB BSF, http://bsf.epfl.ch
//
//	*************************************************************************
//	*************************************************************************

while (nImages == 0) {
	waitForUser("please open the image on which the grids/well names have to be applied");
}
getDimensions(width, height, channels, slices, frames);
run("RGB Color");
title = getTitle();

formatPlate = newArray("384-well", "96-well", "60-well", "48-well", "24-well", "12-well", "6-well", "CUSTOM overview (from well X to well Y)");
grid = newArray("Well names + Grid lines", "Well names only", "Grid lines only");
colorChoice = newArray("white", "black", "red", "yellow");
Dialog.create("plate overview");
Dialog.addMessage("Add grids and well names to \nany opened image to create \na ' multiwell plate overview '", 18, "red");
Dialog.addMessage("Plate format", 20, "blue");
Dialog.addRadioButtonGroup("", formatPlate, 8, 1, "96-well");
Dialog.addMessage("Add grid lines / well names?", 18, "#00b935");
Dialog.addRadioButtonGroup("", grid, 3, 1, "Well names + Grid lines");
Dialog.addMessage("Color for grid and well names", 18, "#ff6900");
Dialog.addRadioButtonGroup("", colorChoice, 1, 4, "white");
Dialog.show();

formatPlate = Dialog.getRadioButton();
grid = Dialog.getRadioButton();
colorChoice = Dialog.getRadioButton();

setBatchMode(true);
var start_h = 0;
var start_i = 1;
run("Colors...", "foreground=white background=black selection=yellow");
letters = newArray("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P");
numbers = newArray("01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24");

if(formatPlate=="384-well") {hmax = 16; kmax = 25; cols=24; rows=16; wells=384;}
if(formatPlate=="96-well") 	{hmax = 8;  kmax = 13; cols=12; rows=8;  wells=96;}
if(formatPlate=="60-well")  {hmax = 7;  kmax = 12; cols=10; rows=6;  wells=60; start_h = 1; start_i = 2;}
if(formatPlate=="48-well") 	{hmax = 6;  kmax = 9;  cols=8;  rows=6;  wells=48;}
if(formatPlate=="24-well") 	{hmax = 4;  kmax = 7;  cols=6;  rows=4;  wells=24;}
if(formatPlate=="12-well") 	{hmax = 3;  kmax = 5;  cols=4;  rows=3;  wells=12;}
if(formatPlate=="6-well") 	{hmax = 2;  kmax = 4;  cols=3;  rows=2;  wells=6;}
if(formatPlate=="CUSTOM overview (from well X to well Y)"){
	Dialog.create("partial plate overview");
	Dialog.addMessage("FIRST well of the overview: ", 18, "red");
	Dialog.addChoice("               row", letters);
	Dialog.addToSameRow();	
	Dialog.addChoice("   column",numbers);
	Dialog.addMessage("LAST well of the overview: ", 18, "blue");
	Dialog.addChoice("               row", letters);
	Dialog.addToSameRow();	
	Dialog.addChoice("   column",numbers);	
	Dialog.show();	
	firstRowLetter = Dialog.getChoice();
	firstColumnNumber = Dialog.getChoice();
	lastRowLetter = Dialog.getChoice();
	lastColumnNumber = Dialog.getChoice();		
	firstColumn = parseInt(firstColumnNumber);
	lastColumn = parseInt(lastColumnNumber);
	if(firstColumn>lastColumn){exit("Error in selection of first and last columns");}		
	start_h = indexOf("ABCDEFGHIJKLMNOP", firstRowLetter);
	hmax = 1+(indexOf("ABCDEFGHIJKLMNOP", lastRowLetter));
	if(start_h>(hmax-1)){exit("Error in selection of first and last rows");}	
	start_i = firstColumn;
	kmax = 1+lastColumn;
	cols = (lastColumn-firstColumn)+1;
	rows = hmax-start_h;
	wells = cols*rows;
}

// creation of empty images
for (h = start_h; h<hmax; h++){
	j = letters[h];
	for (k = start_i; k<kmax; k++) {
		if (k<10) {	i = "0" + k;}
		else {i = k;}
		newImage("temp", "16-bit black", 300, 300, 1);
		rename("well"+ j + i);
		if(grid!="Grid lines only") {run("Label...", "format=Text starting=0 interval=1 x=5 y=5 font=50 text=" + j + i + "  range=1-1 use use_text");}	
		run("Flatten");		
		selectWindow("well"+j + i);
		run("Close");
	}
}

// creation of the grid
run("Images to Stack", "name=StackGrid title=well use");

if(grid=="Well names + Grid lines"){
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=2 font=20 use");
	rename("montage_grids");
}
else if(grid=="Well names only") {
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=0 font=20 use");
	rename("montage_grids");
}
else if(grid=="Grid lines only") {
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=2");
	rename("montage_grids");
}

selectWindow("StackGrid");
run("Close");

// addition of the grid / well names on the original image
selectWindow("montage_grids");
run("Size...", "width=width height=height depth=1 interpolation=Bilinear");
run("Convert to Mask");
run("Create Selection");
selectWindow(title);
run("Restore Selection");
run("Overlay Options...", "stroke=" + colorChoice + " width=1 fill=" + colorChoice + " set");
run("Add Selection...");
run("Flatten");
selectWindow("montage_grids");
run("Close");
