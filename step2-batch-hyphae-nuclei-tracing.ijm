// TO RUN: select batch directory for analysis

// GOALS:
// 1) measure width of hyphae on red channel
// 2) save length measurement in microns

mainDir = getDirectory("Choose a directory containing your files:"); 
mainList = getFileList(mainDir); 
newDir = mainDir+"Internuclear-distance-Results"+File.separator;
File.makeDirectory(newDir);

// next pull out the values from the dialog box and save them as variables
imageType = ".tif";

for (m=0; m<mainList.length; m++) { //clunky, loops thru all items in folder looking for image
	if (endsWith(mainList[m], imageType)) { 
		open(mainDir+mainList[m]); //open image file on the list
		title = getTitle(); //save the title of the movie
		run("Split Channels");

		selectWindow("C2-"+title);
		run("Brightness/Contrast...");
		//run("Enhance Contrast", "saturated=0.35");
		//run("Apply LUT");
		
		// prompt user to select regions of interest and save them using t shortcut
		run("Set Measurements...", "mean centroid redirect=None decimal=3");
		setTool("polyline");
		run("Line Width...", "line=20");
		waitForUser("Start your trace from the hyphal tip, press t to save, then click OK"); 

		if (roiManager("Count") > 0){
			// loop thru ROI list and measure line
			for (n = 0; n < roiManager("count"); n++){
				selectWindow("C2-"+title); // selects your movie
				roiManager("Select", n);
				profile = getProfile();
				for (i=0; i<profile.length; i++)
  					setResult("Value", i, profile[i]);
				updateResults();
				saveAs("Measurements", newDir+title+"_Results_"+n+".csv");
				run("Close"); //close Results
				
				roiManager("Save", newDir+title+"_line_"+n+".roi"); // saves the roiset   		
        		}
		
			selectWindow("ROI Manager");
			run("Close"); //close ROI manager
		}
		close("*"); // close all open images
	}
}