# mosaicify

ImageJ macro to assemble a collection of tile-images to recreate a provided template-image in a mosaic fashion



---



mosaicify.ijm - Version for final mosaic in b/w





---



Usage:



Download the .ijm file.

Put all the tile-images into one directory, that is otherwise empty.

Put the template-image in a different directory than your tile-images, crop the template image if necessary. Reduce the resolution of your template image, so the amount of pixels are less or equal to the number of provided tiles.

Drag-and-Drop the .ijm file into an open ImageJ/FIJI window.

The scripting window should open, press Ctrl+R.

Follow the instructions of the macro \& let it run (might take a while for large amount of pixels



---



Method:



The macro creates a list of the pixel intensities of the template image. 

It then crops all tile images to an aspect ratio of 1, reduces their resolution (user specified), and saves these altered images in a different folder, sorted by intensity.

A list of the tile-image intensities gets sorted according to the order of pixel intensites in the template image, and this determines the order in which the images get fed into the Grid stitching macro in ImageJ. The stitching is performed without overlap.

The final mosaic is output as a .tif with _mosaic.tif added to the previous name
