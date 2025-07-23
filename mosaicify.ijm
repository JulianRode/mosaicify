endAR = 1; //target aspect ratio
tile_dir = getDirectory("Choose the directory with the tile-images");
template_dir = File.openDialog("Pick the template-image");

//check whether template image is actually an image and reprompt if not 
template_not_image = true;
while (template_not_image) {
	if(endsWith(toLowerCase(template_dir), ".png") || endsWith(toLowerCase(template_dir), ".jpg") || endsWith(toLowerCase(template_dir), ".tif") || endsWith(toLowerCase(template_dir), ".tiff")) {
		template_not_image = false;
		break;
	}
	else {
		template_dir = File.openDialog("The template image must be .png, .jpg, .tif or .tiff");
	}
}


sourcedir = File.getDirectory(tile_dir);
outdir = sourcedir + File.getNameWithoutExtension(tile_dir) + "_sorted\\";

Files = getFileList(tile_dir);

//check, which files do not have a valid image type extension
check_for_tile_extensions = newArray();
for (i = 0; i < Files.length; i++) {
	if(endsWith(toLowerCase(Files[i]), ".png") || endsWith(toLowerCase(Files[i]), ".jpg") || endsWith(toLowerCase(Files[i]), ".tif") || endsWith(toLowerCase(Files[i]), ".tiff")) {
		
	}
	else {
		check_for_tile_extensions = Array.reverse(Array.concat(check_for_tile_extensions,i)); 
	}
}

//remove files that are not images from the list of tiles to be used
for (i = 0; i < check_for_tile_extensions.length; i++) {
	Files = Array.deleteIndex(Files, check_for_tile_extensions[i]);
}

tile_image_number = Files.length;


open(template_dir);
//get all initial data from the template-image
original = getTitle();

//template-image gets turned to b/w image
run("8-bit");
getDimensions(width, height, channels, slices, frames);
ori_width = width;
ori_height = height;

ori_resolution = ori_width * ori_height;


template_resolution_dialog();

//make the template resolution dialog recursive, so the user can iteratively crop and scale the template
function template_resolution_dialog() {
	
	selectWindow(original);
	//call the dimensions of the original image
	getDimensions(width, height, channels, slices, frames);
	ori_width = width;
	ori_height = height;
	
	ori_resolution = ori_width * ori_height;

	//open dialog window to get the desired template image resolution (which is the same as the amount of tile images that will be used)
	Dialog.create("Template resolution");
	Dialog.addMessage("Your template image currently has a height of " + ori_height + " pixels and a width of " + ori_width + " pixels.");
	Dialog.addMessage("That results in a template resolution of " + ori_resolution + " pixels and would require as many tile pixels.");
	if (tile_image_number >= ori_resolution) {
		Dialog.addMessage("You have provided " + tile_image_number + " tile image(s), which is enough for the template resolution, please procede by pressing OK.");
		Dialog.show();
	}
	else {
		Dialog.addMessage("You have provided " + tile_image_number + " tile images, which is not enough for the template resolution.");
		Dialog.addMessage("You can either: provide more tile images or crop your template image, rescale it, or both, so you reach a final resolution of " + tile_image_number + " or less.");
		
		possible_actions = newArray("Provide Tiles", "Crop Template", "Rescale Template");
		Dialog.addRadioButtonGroup("Action", possible_actions, 1, 3, "Provide Tiles");
		Dialog.show();
		
		fix_resolution_action = Dialog.getRadioButton();
		
		//wait for the user to add more files and reindex the tile tile_dir
		if (fix_resolution_action == "Provide Tiles") {
			Dialog.create("Provide Tiles");
			Dialog.addMessage("Please add more images to the tile image folder under: " + tile_dir + " and press OK once finished");
			Dialog.show();
			
			Files = getFileList(tile_dir);
			
			tile_image_number = Files.length;
			
			template_resolution_dialog();
		}
		
		//waits for the user to make a rectangular selection and then crop the image to that selection
		if (fix_resolution_action == "Crop Template") {
			while(selectionType() != 0) {// 0 is the number for if there is a rectangular selection present
				selectWindow(original);
				waitForUser("Please create a rectangular selection in your image and press OK, your image will be cropped to that selection");
			}
			
			run("Crop");
			template_resolution_dialog();
		}
		
		if (fix_resolution_action == "Rescale Template") {
			scaling_factor = floor(tile_image_number / ori_resolution * 10000) / 10000;
			

			Dialog.create("Rescale Template");
			Dialog.addMessage("To achieve a sufficiently low resolution the template needs to be scaled by " + scaling_factor + ".");
			Dialog.addSlider("Scale by:", 0.0001, 1, scaling_factor);
			Dialog.show();
			
			Dialog.getNumber();
			new_ori_height = ori_height * scaling_factor;
			new_ori_width = ori_width * scaling_factor;
			run("Scale...", "x=" + scaling_factor + " y=" + scaling_factor + " interpolation=Bilinear average");
			
			template_resolution_dialog();
		}
	}
}



//collect the pixel values of the template-image
pixel_list = newArray();

for (i = 0; i < height; i++) {
	for (j = 0; j < width; j++) {
		pixel_list[i*width+j]=getPixel(j, i);
	}
}
close(original);

Dialog.create("Tile resolution");
Dialog.addMessage("Please provided the desired resolution of individual tiles in the mosaic");
endwidth = Dialog.getNumber();
Dialog.addNumber("resolution", 250, 0, 4, "pixels");
Dialog.show();
setBatchMode(true);



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
	open(tile_dir + Files[i]);
	run("8-bit");
	getDimensions(width, height, channels, slices, frames);
	aspectRatio=width/height;
	//crops the tile (either in y direction when too wide
	if(aspectRatio>endAR){
		distance_x = width/2-endAR*height/2;
		xpoints = newArray(distance_x, width-distance_x, width-distance_x, distance_x);
		ypoints = newArray(0,0,height,height);
		makeSelection(0, xpoints, ypoints); // 0 is the selection type for rectangle
		run("Crop");
		run("Select None");
	}
	//or in x direction when too tall
	else{
		if(aspectRatio<endAR){
			distance_y = height/2-width/endAR/2;
			xpoints = newArray(0,width,width,0);
			ypoints = newArray(distance_y, distance_y, height - distance_y, height - distance_y);
			makeSelection(0, xpoints, ypoints); //see above
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
