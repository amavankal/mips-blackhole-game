/*
 *	pngToASM.c takes in png files as command line arguments, assumes they're 256x256 pixels,
 *		and writes an .ASM data file with an array of the frames.
 *
 *  compile with: gcc pngToASM.c -o pngToASM -I/opt/homebrew/include -L/opt/homebrew/lib -lpng
 *
 *	TODO: implement diffs
 *	TODO: implement reading numbered frames in a directory
 *	TODO: decide how to organize animation framesx
 */

#include <stdio.h>	// fopen,fprintf
#include <string.h> // memset, strcpy, strchr
#include <stdlib.h> // malloc
#include <png.h> // png_structp, png_infop, etc..
#include <stdbool.h> // booleans
#include <unistd.h> // getopt
#include <getopt.h> // getopt_long
#include <sys/stat.h> // mkdir
#include <dirent.h> // opendir, dirent*, scandir
#include <errno.h> // errno
#include <ctype.h> // isdigit
#include <stdint.h> // uint8_t

// options
static struct option long_options[] = {
	{"src-dir", required_argument, 0, 'd'},
	{"out-dir", required_argument, 0, 'o'},
	{"make-diffs-file", required_argument, 0, 'm'},
	{"no-alpha", no_argument, 0, 'A'},
	{"usage", no_argument, 0, 0},
	{"help", no_argument, 0, 0}, // alias for usage
	{0, 0, 0, 0}
};

// Image struct - image + metadata
typedef struct {
	png_bytepp image;
	int height;
	int pixelsPerRow;
	int bytesPerPixel;
} Image;

// Pixel struct - offset from image base + new color
typedef struct {
	int offset;
	uint8_t R;
	uint8_t G;
	uint8_t B;
} Pixel;

// constant for files
const char* HEADING_COMMENT_BOX = "#-----------------------------------------------------------------------\n";

// buffer to hold filenames
char filename_buffer[300];

// buffer to hold diffs
Pixel diffs_buffer[65536];
int num_diffs;

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
 * 
 * 		Prints error if issue opening filename to write.
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
	if (!fp) {
		fprintf(stderr, "Error opening %s for writing: %s\n", filename, strerror(errno));
		return false;
	}

	// print header comment & data directive + frame label
	fprintf(fp, "%s# %s holds image data for %s\n%s\n", 
		HEADING_COMMENT_BOX, filename, imagename, HEADING_COMMENT_BOX);
	fprintf(fp, ".data\n\n");
	fprintf(fp, "%s:\n", filename); // TODO

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
			
			// if last in group of 8 or last in row, print \n; else print ,
			if (p % 8 == 7 || p == img.pixelsPerRow - 1)
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

/**	Fills diffs_buffer with Pixel diffs between source and compare
 */
int loadDiffs(Image source, Image compare) {
	num_diffs = 0;

	printf("pixels per row = %d", source.pixelsPerRow);

	// fill diffs buffer with diffs
	for (int row = 0; row < source.height && row < compare.height; row++) // rows
		for (int p = 0; p < source.pixelsPerRow && p < compare.pixelsPerRow; p++) { // pixels
			for (int i = 0; i < 3; i++) // check R G B
				if (source.image[row][p * source.bytesPerPixel + i]
				!= compare.image[row][p * compare.bytesPerPixel + i]) {
					// create difference Pixel
					Pixel pixel = {
						.offset = row * source.pixelsPerRow + p,
						.R = compare.image[row][p * compare.bytesPerPixel],
						.G = compare.image[row][p * compare.bytesPerPixel + 1],
						.B = compare.image[row][p * compare.bytesPerPixel + 2]
					};

					// add to Pixels array
					diffs_buffer[num_diffs++] = pixel;
					break;
				}
		}
	
	// return the # diffs (may be redundant, but useful for checks)
	return num_diffs;
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
		.pixelsPerRow = width, .bytesPerPixel = rowbytes / width};
}

/** getPNGAsArray returns an Image byte array for a given image.
 *	@return the image from the png as a byte array along with metadata.
 *		The .image needs to be freed by end of program.
 *
 * 	Prints errors if read fails.
 */
Image getPNGAsArray(char* filename, bool alpha) {
	// intialize bianry file to read, and png_structp
	FILE* pngp = fopen(filename, "rb");
	png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING,
		NULL, NULL, NULL);

	// initialize Image struct & png info structs
	png_infop info = NULL; Image img = {NULL, 0, 0, 0};
	
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
		fprintf(stderr, "Issue reading %s\n", filename);
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

/**	Stores in filename_buffer the resultant ASM filepath for the given 
 * 		PNG source filepath. If outdir exists, it appends the filename 
 * 		to that path; if not, it puts the file in the working directory.
 * 		It also adds an .asm extension to the final filepath.
 *	@param outdir the path to the output directory to store the resultant 
 *		file in. If this is null, resultant file is put in working directory.
 *	@param filepath the path to the source png file to find the .asm path for
 */
void loadAsmPath(char* outdir, char* filepath) {
	// keep track of append position in filename buffer to create filename
	char* spot = filename_buffer;

	// determine overall file path for resultant file
	if (outdir) {
		// if output directory is given, add it to path
		strcpy(spot, outdir);
		spot += strlen(spot);

		// verify / is there: if not, add it
		if (*(spot - 1) != '/')
			*spot++ = '/';
		
		// if there's a previous path, add only filename part
		// else add whole filename
		char* lastslash = strrchr(filepath, '/');
		if (lastslash)
			strcpy(spot, lastslash + 1);
		else
			strcpy(spot, filepath);
		spot += strlen(spot);
	} else {
		// if no outdir given, create new file in working directory
		// that is, just remove any previous paths.
		char* lastslash = strrchr(filepath, '/');
		if (lastslash)
			strcpy(spot, lastslash + 1);
		else
			strcpy(spot, filepath);
		spot += strlen(spot);
	}
	
	// add .asm extension to file; replace if can; else just add extension
	spot = strrchr(filename_buffer, '.');
	if (!spot) {
		spot = strchr(filename_buffer, '\0');
		*spot = '.';
	}

	strcpy(spot + 1, "asm");
}

/** Creates given directory if it's valid and doesn't alr exist
 *	@param dir directory to potentially create. If NULL, does nothing.
 */
void makeDir(char* dir) {
	// if output directory is given, create it
	if (dir) {
		if (mkdir(dir, 0755) == 0)
			printf("Created %s directory successfully.\n", dir);
		else if (errno != EEXIST) {
			fprintf(stderr, "Failed to create %s directory: %s\n", dir, strerror(errno));
			exit(1);
		}
	}
}

int filesonly(const struct dirent* entry) {
	return entry->d_type == DT_REG ? 1 : 0;
}

int natStrCmp(const char *a, const char *b) {
	// while 2 chars are comparable
    while (*a && *b) {
		// if the chars are digits get rest of number 
		//	and compare whole numbers
        if (isdigit(*a) && isdigit(*b)) {
            int num1 = strtol(a, (char**)&a, 10); // will move a to next non-int
            int num2 = strtol(b, (char**)&b, 10); // will move b to next non-int
            if (num1 != num2) 
				return num1 - num2;
        } else // regular alphabetic compare
            if (*a++ != *b++)	
				return *a - *b;
    }

	// if 1 or more of chars is null--returns longer string (ex: ba vs. b)
    return *a - *b;
}

int versionsort(const struct dirent** a, const struct dirent** b) {
	return natStrCmp((*a)->d_name, (*b)->d_name);
}

/**	creates diffs file called filename-diffs
 * 
 */
bool initializeDiffs(char* filename) {
	// check if file w/ filename alr exists--manage
	if (!checkContinue(filename))
		return false;

	// open file for writing--overwrites any old files
	FILE* fp = fopen(filename, "w");

	// check that file was opened
	if (!fp) {
		fprintf(stderr, "Error opening %s for writing: %s\n", filename, strerror(errno));
		return false;
	}

	// print header comment & data directive
	fprintf(fp, "%s# %s holds image diffs\n%s\n", HEADING_COMMENT_BOX, filename, HEADING_COMMENT_BOX);
	fprintf(fp, ".data\n\n");

	fclose(fp);

	return true;
}

void addDiffs(char* filename, int diffNum) {
	// open file for appending
	FILE* fp = fopen(filename, "a");;

	// write offsets label
	fprintf(fp,"diff_%d_offsets:\n", diffNum);

	// write data (stored in diffs_buffer)
	for (int i = 0; i < num_diffs; i++) {
		// group as 8--only print .word at start of every 8 chars
		if (i % 8 == 0)
			fprintf(fp, "\t.word\t");
		
		// print offset, 10 width columns (to align w/ colors)
		fprintf(fp, "%10d", diffs_buffer[i].offset);
		
		// if last in group of 8, print \n, else print ,
		if (i % 8 == 7 || i == num_diffs - 1)
			fputs("\n", fp);
		else
			fputs(", ", fp);
	}

	// write colors label
	fprintf(fp, "\ndiff_%d_colors:\n", diffNum);

	// write data (stored in diffs_buffer)
	for (int i = 0; i < num_diffs; i++) {
		// group as 8--only print .word at start of every 8 chars
		if (i % 8 == 0)
			fprintf(fp, "\t.word\t");
		
		// print data (MIPS reads colors as RGB--no alpha (2 leading 0s))
		fprintf(fp, "0x00%02X%02X%02X",diffs_buffer[i].R,
			diffs_buffer[i].G, diffs_buffer[i].B);
		
		// if last in group of 8, print \n, else print ,
		if (i % 8 == 7 || i == num_diffs - 1)
			fputs("\n", fp);
		else
			fputs(", ", fp);
	}

	fputs("\n", fp);

	// close fp
	fclose(fp);
}

void pngDirToASMDiffs(char* srcdir, char* outdir, bool use_alpha) {
	// use scandir to get the ordered directory contents
	struct dirent** entries; // must free later
	int num_files = scandir(srcdir, &entries, filesonly, versionsort);

	// iterate over the files if they could be read
	if (num_files < 0) {
		fprintf(stderr, "Error reading %s: %s", srcdir, strerror(errno));
		exit(1);
	} else {	
		// store prev image for comparisons
		Image prev = {NULL, 0, 0, 0};
		bool diffs_made = false;

		// keep rreading next entry, calculating diffs
		for (int n = 0; n <= num_files; n++) {
			// use filename_buffer to store full filepath for src directory entries
			strcpy(filename_buffer, srcdir);
			if (*(filename_buffer + strlen(filename_buffer) - 1) != '/')
				strncat(filename_buffer, "/", 299 - strlen(filename_buffer));
			strncat(filename_buffer, entries[n == num_files ? 0 : n]->d_name, 299 - strlen(filename_buffer));

			// try to retrieve image associated with filepath
			Image img = getPNGAsArray(filename_buffer, use_alpha);

			// if img was not read correctly, continue loop
			if (img.image == NULL)
				continue;

			// fill filename buffer with .asm filepath
			loadAsmPath(outdir, entries[n == num_files ? 0 : n]->d_name);

			if (prev.image == NULL) {
				// write the first image to a new file
				if (generateASM(img, filename_buffer, entries[n == num_files ? 0 : n]->d_name)) {
					printf("Created %s\n", filename_buffer);
					prev = img;
				} else // either user chose not to overwrite, or creation error
					fprintf(stderr, "Failed to create %s\n", filename_buffer);
			} else {
				// load diffs between this image and prev into diffs
				int num_diffs = loadDiffs(prev, img);

				// create diffs file if it doesn't exist - exits on fail
				// load diffs file into filename buffer
				loadAsmPath(outdir, "diffs");

				if (!diffs_made) {
					if (!initializeDiffs(filename_buffer)) {
						// cleanup then exit
						free(img.image);
						free(prev.image);
						for (int i = n; i < num_files; i++)
							free(entries[i]);
						free(entries[0]);
						free(entries);
						return;
					}
					diffs_made = true;
				}
				
				// append to diffs file
				addDiffs(filename_buffer, n == num_files ? 0 : n);

				// cleanup, set prev to curr img
				free(prev.image);
				prev = img;
				img.image = NULL; // only ref to img.image is in prev now
			}

			// cleanup
			if (n > 0)
				free(entries[n == num_files ? 0 : n]);
		}

		// free entries pointer (it now points to a bunch of freed pointers)
		free(entries);
	}
}

void pngArgsToASMDiffs (int argc, char* argv[], char* outdir, bool use_alpha) {
	// store prev image for comparisons
	Image prev = {NULL, 0, 0, 0};
	bool diffs_made = false;

	// keep reading next entry, calculating diffs
	for (int i = optind - 1; i < argc; i++) {
		// retrieve image associated with the file
		Image img = getPNGAsArray(argv[i], use_alpha);

		// if img was not read correctly, continue loop
		if (img.image == NULL)
			continue;

		// fill filename buffer with .asm filepath, if possible
		loadAsmPath(outdir, argv[i]);

		if (prev.image == NULL) { // first img
			// write the first image to a new file
			if (generateASM(img, filename_buffer, argv[i])) {
				printf("Created %s\n", filename_buffer);
				prev = img;
			} else
				fprintf(stderr, "Failed to create %s\n", filename_buffer);
		} else {
			// load diffs between this image and prev into diffs
			int num_diffs = loadDiffs(prev, img);

			// create diffs file if it doesn't exist - exits on fail
			// load diffs file into filename buffer
			loadAsmPath(outdir, "diffs");

			if (!diffs_made) {
				if (!initializeDiffs(filename_buffer)) {
					// cleanup then exit
					free(img.image);
					free(prev.image);
					return;
				}
				diffs_made = true;
			}
			
			// append to diffs file
			addDiffs(filename_buffer, i - optind + 1);

			// cleanup, set prev to curr img
			free(prev.image);
			prev = img;
			img.image = NULL; // only ref to img.image is in prev now
		}
	}
}

void pngDirToASM(char* srcdir, char* outdir, bool use_alpha) {
	// use scandir to get the ordered directory contents
	struct dirent** entries; // must free later
	int num_files = scandir(srcdir, &entries, filesonly, versionsort);

	// iterate over the files if they could be read
	if (num_files < 0) {
		fprintf(stderr, "Error reading %s: %s", srcdir, strerror(errno));
		exit(1);
	} else {
		for (int n = 0; n < num_files; n++) {
			// use filename_buffer to store full filepath for src directory entries
			strcpy(filename_buffer, srcdir);
			if (*(filename_buffer + strlen(filename_buffer) - 1) != '/')
				strncat(filename_buffer, "/", 299 - strlen(filename_buffer));
			strncat(filename_buffer, entries[n]->d_name, 299 - strlen(filename_buffer));

			// try to retrieve image associated with filepath
			Image img = getPNGAsArray(filename_buffer, use_alpha);

			// if img was not read correctly, continue loop
			if (img.image == NULL)
				continue;

			// fill filename buffer with .asm filepath
			loadAsmPath(outdir, entries[n]->d_name);

			// write image to file
			if (generateASM(img, filename_buffer, entries[n]->d_name))
				printf("Created %s\n", filename_buffer);
			else // either user chose not to overwrite, or creation error
				fprintf(stderr, "Failed to create %s\n", filename_buffer);

			// cleanup
			free(img.image);
			free(entries[n]);
		}

		// free entries pointer (it now points to a bunch of freed pointers)
		free(entries);
	}
}

void pngArgsToASM(int argc, char* argv[], char* outdir, bool use_alpha) {
	// parse command line options from optind
	for (int i = optind; i < argc; i++) {
		// retrieve image associated with the file
		Image img = getPNGAsArray(argv[i], use_alpha);

		// if img was not read correctly, continue loop
		if (img.image == NULL)
			continue;

		// fill filename buffer with .asm filepath, if possible
		loadAsmPath(outdir, argv[i]);

		// write image to file
		if (generateASM(img, filename_buffer, argv[i]))
			printf("Created %s\n", filename_buffer);
		else
			fprintf(stderr, "Failed to create %s\n", filename_buffer);

		// cleanup
		free(img.image);
	}
}

// Usage: pngToAsm [-A] [-m] [-o outdir] -d pngDir | png1.png ...
int main(int argc, char* argv[]) {
	// variables to hold option data
	char* srcdir = NULL; char* outdir = NULL;
	bool use_alpha = true; bool make_diffs = false;

	// read options
	int c;
	while ((c = getopt_long(argc, argv, "Ao:d:m", long_options, NULL)) != -1) {
		switch(c) {
			case 'A':
				use_alpha = false;
				break;
			case 'd': 
				srcdir = optarg;
				break;
			case 'o':
				outdir = optarg;
				break;
			case 'm':
				make_diffs = true;
				break;
			case 0:
				printf("Usage: pngToAsm [-A] [-m] [-o outdir] -d pngDir | png1.png ...\n");
				exit(0);
			case '?':
				fprintf(stderr, "%c: invalid option\n", optopt);
		}
	}

	// convert given pngs to .asm data files
	if (srcdir) {
		// open directory
		DIR* dir = opendir(srcdir);

		if (!dir) {
			fprintf(stderr, "Failed to open %s directory for reading: %s\n", srcdir, strerror(errno));
			exit(1);
		}

		// if output directory is given, create it
		makeDir(outdir);

		// create ASM files from the pngs in src directory, no diffs
		if (make_diffs)
			pngDirToASMDiffs(srcdir, outdir, use_alpha);
		else
			pngDirToASM(srcdir, outdir, use_alpha);

	} else { // read files from command line
		// if output directory is given, create it
		makeDir(outdir);

		// create ASM files from command line args, no diffs
		if (make_diffs)
			pngArgsToASMDiffs(argc, argv, outdir, use_alpha);
		else
			pngArgsToASM(argc, argv, outdir, use_alpha);
	}

	return 0;
}
