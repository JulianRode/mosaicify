endAR = 1; //target aspect ratio
dir = getDirectory("Choose the directory with the tile-images");
template_dir = File.openDialog("Choose the template-image");

Dialog.create("Tile resolution");
Dialog.addMessage("Please provided the desired resolution of individual tiles in the mosaic");
endwidth = Dialog.getNumber();
Dialog.addNumber("resolution", 250, 0, 4, "pixels");
Dialog.show();

setBatchMode(true);
open(template_dir);

//get all initial data from the template-image
original = getTitle();

//template-image gets turned to b/w image
run("8-bit");
getDimensions(width, height, channels, slices, frames);
ori_width = width;
ori_height = height;

//collect the pixel values of the template-image
pixel_list = newArray();

for (i = 0; i < height; i++) {
	for (j = 0; j < width; j++) {
		pixel_list[i*width+j]=getPixel(j, i);
	}
}


close(original);

sourcedir = File.getDirectory(dir);
outdir = sourcedir + File.getNameWithoutExtension(dir) + "_sorted\\"
Files = getFileList(dir);

//create empty arrays in which the tile-image data will be stored
image_list = newArray(Files.length);
mean_list = newArray(Files.length);
i_list = newArray(Files.length);

//if there are less tiles supplied than pixels in the template image, return an error and terminate
if (Files.length < pixel_list.length) {
	exit("The supplied template image has " + pixel_list.length + " pixels, while there are only " + Files.length + " supplied tile-images. This macro does not scale down the template image automatically. Please either reduce the resolution of your template-image or provide more tile-images.");
}

//create an output directory where sorted, cropped, and scaled tiles will be stored
File.makeDirectory(outdir);

//cycle through the tile-images, crop them if they do not have an aspect ratio of 1
for (i = 0; i < Files.length; i++) {
	open(dir + Files[i]);
	run("8-bit");
	getDimensions(width, height, channels, slices, frames);
	aspectRatio=width/height;
	//crops the tile (either in y direction when too wide
	if(aspectRatio>endAR){
		distance_x = width/2-endAR*height/2;
		xpoints = newArray(distance_x, width-distance_x, width-distance_x, distance_x);
		ypoints = newArray(0,0,height,height);
		makeSelection("polygon", xpoints, ypoints);
		run("Crop");
		run("Select None");
	}
	//or in x direction when too tall
	else{
		if(aspectRatio<endAR){
			distance_y = height/2-width/endAR/2;
			xpoints = newArray(0,width,width,0);
			ypoints = newArray(distance_y, distance_y, height-distance_y, height-distance_y);
			makeSelection("polygon", xpoints, ypoints);
			run("Crop");
			run("Select None");
		}
	}
	
	//scale to the tile-resolution
	getDimensions(width, height, channels, slices, frames);
	run("Size...", "width=" + endwidth + " height=" + endwidth/endAR + " depth=1 average interpolation=Bilinear");
	
	//record mean intesity of the tile and store that
	//save the modified tile in the output folder, save its name to the image list, so the assembly knows in which order it needs to reassemble images
	run("8-bit");
	getStatistics(area, mean, min, max, std, histogram);
	newname ="" + mean +" "+ i;
	image_list[i] = newname;
	mean_list[i] = mean;
	i_list[i] = i;
	//newname="" + IJ.pad(i, 3);
	rename(newname);
	saveAs("tiff", outdir + newname);
	close("*");
}

//if there are too many tiles provided, just use the first ones
if(pixel_list.length<mean_list.length){
	mean_list = Array.trim(mean_list, pixel_list.length);
	i_list = Array.trim(i_list, pixel_list.length);
	image_list = Array.trim(image_list, pixel_list.length);
}


//get the order of pixel-intensity in the template image 
ori_pixels_sorted = Array.rankPositions(pixel_list);
//create the sorting table, with the image index and its mean intensity
Table.create("sorting");
Table.setColumn("Mean", mean_list);
Table.setColumn("I", i_list);

//sort the table by assending mean intensity
Table.sort("Mean");

//add the pixel-intenisty order of the template image
Table.setColumn("Ori", ori_pixels_sorted); //Ori: "original"

//sort by the template-image pixel-intensity order
Table.sort("Ori");

//retrieve the new tile order
mean_list = Table.getColumn("Mean");
i_list = Table.getColumn("I");
close("sorting");

//update the image name array, this is used for image retrieval and stitching
for (i = 0; i < lengthOf(mean_list); i++) {
	image_list[i] = "" + mean_list[i] + " " + i_list[i];
}

//adjust the tile intensity to exactly match that of the template pixel
for(i = 0; i<lengthOf(image_list); i++){
	open(outdir + image_list[i] + ".tif");
	getStatistics(area, mean, min, max, std, histogram);
	factor = mean/pixel_list[i];
	run("Divide...", "value="+factor);
	saveAs("tiff", outdir + image_list[i] + ".tif");
	close("*");
	
}

for (i = 0; i < image_list.length; i++) {
	File.rename(outdir + image_list[i] +".tif", outdir + IJ.pad(i+1, 4) +".tif");
}

setBatchMode(false);

//report that sorting is finished and start the stitching
print("Finished sorting of tiles, assembling mosaic");
//using the FIJI grid stitching
run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x=" + ori_width + " grid_size_y=" + ori_height + " 24 tile_overlap=0 first_file_index_i=1 directory=[" + outdir + "] file_names={iiii}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display] use");
saveAs("tiff", template_dir + "_mosaic");
print("Finished assembling mosaic");
close("*");
