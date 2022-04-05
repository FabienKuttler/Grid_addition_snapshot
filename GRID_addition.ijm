
//	************************************************************************************************
//	*******				                                                         *******
//	******* 		   Macro for well names +/- Grid addition on an image	         *******
//	******* 		 to create a full plate snapshot from any opened image	         *******
//	*******  	Fabien Kuttler, 2022, EPFL-SV-PTECH-PTCB BSF, http://bsf.epfl.ch	 *******
//	*******								                         *******
//	************************************************************************************************

while (nImages == 0) {
	waitForUser("please open the image on which the grids/well names have to be applied");
}
getDimensions(width, height, channels, slices, frames);
run("RGB Color");
title = getTitle();


formatPlate = newArray("384-well", "96-well", "60-well", "48-well", "24-well", "12-well", "6-well", "x-well ( = FULL snapshot from well A01 to X..)", "x-well partial plate snapshot ( = SELECT from well X.. to Y..)");
grid = newArray("YES", "NO");
colorChoice = newArray("white", "black", "red", "yellow");
Dialog.create("Add well names on a plate snapshot");
Dialog.addRadioButtonGroup("Plate format", formatPlate, 9, 1, "96-well");
Dialog.addChoice("Add grids in addition to names", grid);
Dialog.addRadioButtonGroup("Grid color", colorChoice, 1, 4, "white");
Dialog.show();

formatPlate = Dialog.getRadioButton();
grid = Dialog.getChoice();
colorChoice = Dialog.getRadioButton();

setBatchMode(true);
var start_h = 0;
var start_i = 1;
run("Colors...", "foreground=white background=black selection=yellow");
letters = newArray("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P");

if(formatPlate=="384-well") {
	hmax = 16;
	kmax = 25;
	cols=24;
	rows=16;
	wells=384;
}
if(formatPlate=="96-well") 	{
	hmax = 8;
	kmax = 13;
	cols=12;
	rows=8;
	wells=96;
}
if(formatPlate=="60-well")  {
	hmax = 7;
	kmax = 12;
	cols=10;
	rows=6;
	wells=60;
	start_h = 1;
	start_i = 2;
}
if(formatPlate=="48-well") 	{
	hmax = 6;
	kmax = 9;
	cols=8;
	rows=6;
	wells=48;
}
if(formatPlate=="24-well") 	{
	hmax = 4;
	kmax = 7;
	cols=6;
	rows=4;
	wells=24;
}
if(formatPlate=="12-well") 	{
	hmax = 3;
	kmax = 5;
	cols=4;
	rows=3;
	wells=12;
}
if(formatPlate=="6-well") 	{
	hmax = 2;
	kmax = 4;
	cols=3;
	rows=2;
	wells=6;
}
if(formatPlate=="x-well ( = FULL snapshot from well A01 to X..)"){
	cols = 12;
	rows = 8;
	Dialog.create("x-well plate format");
	Dialog.addNumber("Number of columns", cols);
	Dialog.addNumber("Number of rows", rows);
	Dialog.show();
	cols = Dialog.getNumber();
	rows = Dialog.getNumber();
	wells = cols*rows; hmax = rows; kmax = cols+1;
}
if(formatPlate=="x-well partial plate snapshot ( = SELECT from well X.. to Y..)"){
	cols = 12;
	rows = 8;
	firstRow = 1;
	firstColumn = 1;
	Dialog.create("x-well plate format well selection");
	Dialog.addNumber("Number of columns", cols);
	Dialog.addNumber("Number of rows", rows);
	Dialog.addNumber("Position of first well: row = ", firstRow);
	Dialog.addNumber("Position of first well: column = ", firstColumn);
	Dialog.show();
	cols = Dialog.getNumber();
	rows = Dialog.getNumber();	
	firstRow = Dialog.getNumber();
	firstColumn = Dialog.getNumber();	
	wells = cols*rows;
	start_h = 0+(firstRow-1);
	hmax = rows+start_h;
	start_i = firstColumn;
	kmax = cols+firstColumn;
}

// creation of empty images
for (h = start_h; h<hmax; h++){
	j = letters[h];
	for (k = start_i; k<kmax; k++) {
		if (k<10) {	i = "0" + k;}
		else {i = k;}
		newImage("temp", "16-bit black", 300, 300, 1);
		rename("well"+ j + i);	
		run("Label...", "format=Text starting=0 interval=1 x=5 y=5 font=50 text=" + j + i + "  range=1-1 use use_text");
		run("Flatten");
		selectWindow("well"+j + i);
		run("Close");
	}
}

// creation of the grid
run("Images to Stack", "name=StackGrid title=well use");
if(grid=="Yes"){
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=2 font=20 use");
	rename("montage_grids");
}
else if(grid=="No") {
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=0 font=20 use");
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
