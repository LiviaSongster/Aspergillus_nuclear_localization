// TO RUN: select batch directory for analysis

// GOALS:
// 1) automatically split long stacks into hyperstacks with 2 channels and X z plane
// 2) allow user to select ROIs and make crops from a big batch of movies quickly

mainDir = getDirectory("Choose a directory containing your files:"); 
mainList = getFileList(mainDir); 

Dialog.create("Define the image type");
Dialog.addString("Input Image Type:", ".nd2"); //default is .tif

// next pull out the values from the dialog box and save them as variables
Dialog.show();
imageType = Dialog.getString();

// make sub directory for the analysis
newDir = mainDir+"Output-SumZ"+File.separator;
File.makeDirectory(newDir);

newDir2 = mainDir+"Output-MaxZ"+File.separator;
File.makeDirectory(newDir2);


for (m=0; m<mainList.length; m++) { //clunky, loops thru all items in folder looking for image
	if (endsWith(mainList[m], imageType)) { 
		open(mainDir+mainList[m]); //open image file on the list
		title2 = getTitle(); 
		name = substring(title2, 0, lengthOf(title2)-4);
		run("Duplicate...", "duplicate");
		title = getTitle();
		
		// max Z project all channels
		run("Z Project...", "projection=[Sum Slices]");

		// save tiff of max projection
		saveAs("Tiff", newDir+"SumZ-"+name+".tif");

		selectWindow(title2);
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Tiff", newDir2+"MaxZ-"+name+".tif");
		
		close("*");
	}
}