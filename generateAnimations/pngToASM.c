/*
 *	pngToASM.c takes in png files as command line arguments, assumes they're 256x256 pixels,
 *		and writes an .ASM data file with an array of the frames.
 *
 *  compile with: gcc pngToASM.c -o pngToASM -I/opt/homebrew/include -L/opt/homebrew/lib -lpng
 *
 *	TODO: implement diffs
 *	TODO: implement reading numbered frames in a directory
 *	TODO: decide how to organize animation frames
 *
 */

#include <stdio.h>	// fopen,fprintf
#include <string.h> // memset, strcpy, strchr
#include <stdlib.h> // malloc
#include <png.h> // png_structp, png_infop, etc..
#include <stdbool.h> // booleans
#include <unistd.h> // getopt

// constant for files
const char* HEADING_COMMENT_BOX = "#-----------------------------------------------------------------------\n";

// buffer to hold filenames
char filenameBuffer[200];

// Image struct - image + metadata
typedef struct {
	png_bytepp image;
	int height;
	int pixelsPerRow;
	int bytesPerPixel;
} Image;

/** Helper method for generateASM that determines whether the
 * 		given file can be overwritten by prompting the user
 * 		if they would like to overwrite an existing file if
 * 		necessary.
 * 	@param filename the name of the file to check
 * 	@return whether or not the given file should be overwritten
 */
bool checkContinue(char* filename) {
	// open file to test if it exists
	FILE* fp = fopen(filename, "r");

	// if file exists, ask user if they want to overwrite it or not
	if (fp) {
		printf("%s already exists. Would you like to overwrite it? ", filename);
		char buffer[20] = {};

		while (true) {
			scanf("%s", buffer);
			if (buffer[0] == 'y' || buffer[0] == 'Y')
				return true;
			else if (buffer[0] == 'n' || buffer[0] == 'N')
				return false;
			else
				printf("Invalid answer. Would you like to overwrite %s? ", filename);
		}
	}

	// if file doesn't exist, can continue
	return true;
}

/**	Takes the given image and stores it as an array
 * 		of words under the label frame: in an ASM file with the 
 * 		given filename, checking with the user if it should 
 * 		continue if the file already exists.
 *	@param img
 *	@param filename
 *	@return whether or not an ASM file was generated
 */
bool generateASM(Image img, char* filename, char* imagename) {
	// check if file w/ filename alr exists--manage
	if (!checkContinue(filename))
		return false;

	// open file for writing--overwrites any old files
	FILE* fp = fopen(filename, "w");

	// check that file was opened
	if (!fp)
		return false;

	// print header comment & data directive + frame label
	fprintf(fp, "%s# %s holds image data for %s\n%s\n", 
		HEADING_COMMENT_BOX, filename, imagename, HEADING_COMMENT_BOX);
	fprintf(fp, ".data\n\n");
	fprintf(fp, "frame:\n"); // TODO

	// print data rows
	for (int r = 0; r < img.height; r++) {
		// print row delimiter
		fprintf(fp, "###   Row %d   ###\n", r + 1);

		// print row data, grouped by 8
		for (int p = 0; p < img.pixelsPerRow; p++) {
			// group as 8--only print .word at start of every 8 chars
			if (p % 8 == 0)
				fprintf(fp, "\t.word\t");
			
			// print data (MIPS reads colors as RGB--no alpha (2 leading 0s))
			fprintf(fp, "0x00%02X%02X%02X",
				img.image[r][p * img.bytesPerPixel],
				img.image[r][p * img.bytesPerPixel + 1], 
				img.image[r][p * img.bytesPerPixel + 2]);
			
			// if last in group of 8, print \n, else print ,
			if (p % 8 == 7)
				fputs("\n", fp);
			else
				fputs(", ", fp);
		}

		// newline between rows
		fputs("\n", fp);
	}
	
	// close file
	fclose(fp);

	return true;
}

/**	Helper method for getPNGAsArray that generates an Image using libpng
 * 		given an initialized png reader, info object, and metadata.
 *	@return an Image that contains the image data 
 */
Image generateImage(png_structp png, png_infop info, FILE* pngp, char* filename, bool alpha) {
	// connect png file to libpng (the png_structp), and read its info
	png_init_io(png, pngp);
	png_read_info(png, info);
	
	// ensure image is RGB
	int color_type = png_get_color_type(png, info);
	
	// normalize image -- so only read RGB or RGBA
	png_set_expand(png);          // palette → RGB, grayscale expansion
	png_set_strip_16(png);        // 16-bit → 8-bit
	png_set_gray_to_rgb(png);     // grayscale → RGB

	// don't use alpha values if not desired
	if (!alpha)
		png_set_strip_alpha(png);
	else
		png_set_add_alpha(png, 0xFF, PNG_FILLER_AFTER); // ensure RGBA

	// update info
	png_read_update_info(png, info);

	// get image specs
	int height = png_get_image_height(png, info);
	int width = png_get_image_width(png, info);
	int rowbytes = png_get_rowbytes(png, info);

	// set up image containers (2d array is array of pointers to rows in 1d array)
	png_bytep image_bytes = malloc(height * rowbytes); // 1d array of image
	png_bytepp image = malloc(height * sizeof(png_bytep)); // 2d array of rows in image_bytes

	// fill image w/ pointers to rows in image_bytes
	for (int j = 0; j < height; j++)
		image[j] = image_bytes + (j * rowbytes);
	
	// read image w/ libpng
	png_read_image(png, image);

	// return image
	return (Image) {.image = image, .height = height,
		.pixelsPerRow = rowbytes, .bytesPerPixel = rowbytes / width};
}

/** generateASM generates an ASM file from the given existant file.
 *	@return the image from the png as a byte array along with metadata.
 *		The .image needs to be freed by end of program.
 */
Image getPNGAsArray(char* filename, bool alpha) {
	// intialize bianry file to read, and png_structp
	FILE* pngp = fopen(filename, "rb");
	png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING,
		NULL, NULL, NULL);

	// initialize Image struct & png info structs
	png_infop info = NULL; Image img = {NULL, 0, 0};
	
	// verify file was successfully opened & png struct was intialized
	if (!pngp || !png) {
		fprintf(stderr, pngp ? "Failed to create png_structp for %s\n"
			: "Failed to open file %s\n", filename);
		goto cleanup;
	}
	
	// create info struct and verify it was successfully initialized
	info = png_create_info_struct(png);

	if (!info) {
		fprintf(stderr, "Failed to create png_infop for %s\n", filename);
		goto cleanup;
	}
	
	// error handling - libpng uses longjmp if it encounters errors
	// if an error is encountered it'll read this if statement
	if (setjmp(png_jmpbuf(png))) {
		fprintf(stdout, "There was an issue parsing %s with libpng\n", filename);
		goto cleanup;
	}
	
	// generate image
	img = generateImage(png, info, pngp, filename, alpha);

	// free memory used to read png & close png pointer
	cleanup:
	if (png)
		png_destroy_read_struct(&png, &info, NULL);
	if (pngp)
		fclose(pngp);

	// return image
	return img;
}

// take in files to read
// -A means no alpha values. uses alpha values by defauly
// Usage: pngToAsm [-A] [-d pngDir | png1.png ...]
int main(int argc, char* argv[]) {

	return 0;
}
