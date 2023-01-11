// TO RUN: select batch directory for analysis

// GOALS:
// 1) automatically split long stacks into hyperstacks with 2-4 channels and X time points

mainDir = getDirectory("Choose a directory containing your files:"); 
mainList = getFileList(mainDir); 

Dialog.create("Define the image type");
Dialog.addString("Input Image Type:", ".tif"); //default is .tif
Dialog.addCheckbox("Check if brightfield is included (3 channels vs. 2)", false);
Dialog.addCheckbox("Check if BFP channel is included (4 channels vs. 3)", false);

// next pull out the values from the dialog box and save them as variables
Dialog.show();
imageType = Dialog.getString();
brightfield = Dialog.getCheckbox();
bfpchannel = Dialog.getCheckbox();

// make sub directory for the analysis
newDir = mainDir+"Output-stacks"+File.separator;
File.makeDirectory(newDir);

for (m=0; m<mainList.length; m++) { //clunky, loops thru all items in folder looking for image
	if (endsWith(mainList[m], imageType)) { 
		open(mainDir+mainList[m]); //open image file on the list
		title = getTitle(); //save the title of the movie
		// find dimensions of the movie
		getDimensions(width, height, channels, slices, frames);

		// change the micron scale
		Stack.setXUnit("micron");
		// microns per pixel hard coded below, 100X = 0.11
		run("Properties...", "channels=1 slices=1 frames=&slices pixel_width=0.11 pixel_height=0.11 voxel_depth=0.11 frame=[&fps sec]");
		// use number of slices and divide by 2 for number of z slices

		if (bfpchannel) {
			newSlices = slices / 4;
			nchannels = 4;
		} else {
			if (brightfield) {
			newSlices = slices / 3;
			nchannels = 3;
			} else {
				newSlices = slices / 2;
				nchannels = 2;
			}
		}
		
		run("Stack to Hyperstack...", "order=xyczt(default) channels=&nchannels slices=&newSlices frames=1 display=Grayscale");

		// save tiff
		saveAs("Tiff", newDir+getTitle());
		close("*");
	}
}