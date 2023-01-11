// TO RUN: select batch directory for analysis

// GOALS:
// 1) measure width of nuclei in one channel
// 2) save length measurement in microns

// NOTE - change the channel # in line 27 to match the channel # for labelled nuclei

mainDir = getDirectory("Choose a directory containing your files:"); 
mainList = getFileList(mainDir); 
newDir = mainDir+"Nuclei-Width-Results"+File.separator;
newDir2 = mainDir+"Nuclei-Width-ROIs"+File.separator;
File.makeDirectory(newDir);
File.makeDirectory(newDir2);

// now prompt user
Dialog.create("Define the image type");
Dialog.addString("Input Image Type:", ".tif"); //default is .tif
Dialog.addString("Microns per pixel (default 100x):", "0.11"); //for 60x used 0.18
Dialog.addString("Channel number with labelled nuclei:", "2"); //default assumes brightfield is channel 1

// next pull out the values from the dialog box and save them as variables
Dialog.show();
imageType = Dialog.getString();
micronsPerPixel = Dialog.getString();
nucleiChannel = Dialog.getString();
//micronsPerPixel = "0.18"; // 60x

for (m=0; m<mainList.length; m++) { //clunky, loops thru all items in folder looking for image
	if (endsWith(mainList[m], imageType)) { 
		open(mainDir+mainList[m]); //open image file on the list
		title = getTitle(); //save the title of the movie
		name = substring(title, 0, lengthOf(title)-4); // extract name of file without suffix
		
		getDimensions(width, height, channels, slices, frames);
		run("Properties...", "channels=&channels slices=&slices frames=&frames pixel_width=&micronsPerPixel pixel_height=&micronsPerPixel voxel_depth=1");
		run("Split Channels");
		
		// keep only the red/second channel; adjust brightness
		// selectWindow("C1-"+title);
		// close();
		selectWindow("C"+nucleiChannel+"-"+title);
		// run("Brightness/Contrast...");
		run("Enhance Contrast", "saturated=0.35");
		
		// prompt user to select regions of interest and save them using t shortcut
		setTool("line");
		run("Set Measurements...", "mean centroid redirect=None decimal=3");
		run("ROI Manager...");
		waitForUser("Trace nuclei along long axis, press t to save, repeat, then click OK"); 

		if (roiManager("Count") > 0){
			// loop thru ROI list and measure line
			for (n = 0; n < roiManager("count"); n++){
				selectWindow("C2-"+title); // selects your movie
				roiManager("Select", n);
				run("Measure");
				selectWindow("Results");
				saveAs("Results", newDir+name+"_Results_"+n+".csv");
				run("Close"); //close Results
				
				roiManager("Save", newDir2+name+"_line_"+n+".roi"); // saves the roiset   		
        		}
		
			selectWindow("ROI Manager");
			run("Close"); //close ROI manager
		}
		close("*"); // close all open images
	}
}