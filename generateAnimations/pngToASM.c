/*
 *	pngToASM.c takes in png files as command line arguments, assumes they're 256x256 pixels,
 *		and writes an .ASM data file with an array of the frames.
 *
 *	TODO: implement diffs
 *	TODO: implement reading numbered frames in a directory
 *	TODO: decide how to organize animation frames
 *
 *	compile with gcc -o pngToASM pngToASM.c -I/opt/homebrew/include -L/opt/homebrew/lib -lpng
 */

#include <stdio.h>	// fopen,fprintf
#include <string.h> // memset, strcpy, strchr
#include <stdlib.h> // malloc
#include <png.h> // png_structp, png_infop, etc..

const char* files[] = {"pixil-frame-0", "pixil-frame-1"};

// take in file to read
int main(int argc, char* argv[]) {
	if (argc >= 2) {
		for (int i = 1; i < argc; i++) {
			FILE* pngp = fopen(argv[i], "rb"); // binary mode
			
			// check that file was successfully opened
			if (!pngp) {
				fprintf(stdout, "%s could not be opened\n", argv[i]);
				continue;
			}
			
			// create png_structp and verify it was successfully created
			png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING,
				NULL, NULL, NULL);
			if (!png) {
				fprintf(stdout, "Failed to create png_structp for %s\n", argv[i]);
				continue;
			}
			
			// create info struct and verify it was successfully created
			png_infop info = png_create_info_struct(png);
			if (!info) {
				png_destroy_read_struct(&png, NULL, NULL);
				fprintf(stdout, "Failed to create png_infop for %s\n", argv[i]);
				continue;
			}
			
			// error handling - libpng uses longjmp if it encounters errors
			if (setjmp(png_jmpbuf(png))) {
				png_destroy_read_struct(&png, &info, NULL); // png_struct, png_info, png_end_info
				fprintf(stdout, "There was an issue reading %s\n", argv[i]);
				continue;
			}

			// connect png file to libpng (the png_structp)
			png_init_io(png, pngp);
			
			// initialize info
			png_read_info(png, info);
			
			// ensure image is RGB
			int color_type = png_get_color_type(png, info);
			fprintf(stdout, "Color type for %s is %d\n", argv[i], color_type);
			
			// don't use alpha values
			png_set_strip_alpha(png);
			png_read_update_info(png, info);

			// get # bytes (R G B) per row
			int rowbytes = png_get_rowbytes(png, info);
			fprintf(stdout, "# bytes in row for %s is %d\n", argv[i], rowbytes);
			
			// set up image container
			int height = png_get_image_height(png, info);
			png_bytep image_bytes = malloc(height * rowbytes);
			png_bytepp image = malloc(height * sizeof(png_bytep));
			for (int j = 0; j < height; j++)
				image[j] = image_bytes + (j * rowbytes); // set row pointers to first in each row
			
			// read image w/ libpng
			png_read_image(png, image);

			// free memory
			png_destroy_read_struct(&png, &info, NULL);
			fclose(pngp);

			// print data to .asm file
			char filename[strlen(argv[i])];
			strlcpy(filename, argv[i], strlen(argv[i]));
			char* dot = strchr(filename, '.');
			dot++;
			dot[0] = 'a';
			dot[1] = 's';
			dot[2] = 'm';
			dot += 3;
			*dot = '\0';
			
			// avoid overwriting
			if (!strcmp(filename, argv[i])) {
				fprintf(stdout, "Not creating %s to avoid overwriting source %s\n", filename, argv[i]);
			}

			FILE* fp = fopen(filename, "w"); // automaticaly creates new or replaces old
			fprintf(fp, "###################\n# %s holds image data\n###################\n\n", filename);
			fprintf(fp, ".data\n\n");
			fprintf(fp, "frame:\n");

			for (int r = 0; r < height; r++) {
				for (int c = 0; c < rowbytes; c += 3) {
					if ((c / 3) % 8 == 0) // group into 8 words-- 1 row in image is 32 rows in file
						fprintf(fp, "\t.word\t");
					if ((c / 3) % 8 == 7) {
						fprintf(fp, "0x00%02X%02X%02X", (unsigned int) image[r][c], 
							(unsigned int) image[r][c + 1], (unsigned int) image[r][c + 2]);
						fputs("\n", fp);
					} else
						fprintf(fp, "0x00%02X%02X%02X, ", (unsigned int) image[r][c], 
							(unsigned int) image[r][c + 1], (unsigned int) image[r][c + 2]);
				}
				fputs("\n", fp);
			}
			
			// close files
			fclose(fp);
		}
	}

	return 0;
}
