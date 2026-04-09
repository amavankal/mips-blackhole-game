# Graphics Generation: PNG to ASM

This directory contains the tool I created to convert the graphics I designed for this game from PNGs to .asm data files, pngToAsm, and the original graphics files. The graphics (in `assets`, `base-frames`, and `home-animation-frames`) were created with pixilart.com's drawing tools.

Usage: pngToAsm [-A] [-m] [-o outdir] -d pngDir | png1.png ...

    -A (--no-alpha): don't use alpha values. MARS can't read alpha values anyways, so in the end for ASM data file generation this option doesn't matter, but it affects whether the PNG is parsed with alpha values within the tool

    -m (--make-diffs-file): tells the tool to create a diffs file. It'll still create a full ASM file for the first PNG listed (found via natural sort if a source directory is given), and then add diffs to a diffs file called diffs.asm, where the diffs are between consecutive arguments.

    -o (--out-dir): tells the tool to create output files in given output directory. It'll create the directory if it doesn't already exist.

    -d (--src-dir): tells the tool to read PNG files in given source directory.


The tool uses the C library libpng to parse PNGs into readable arrays of bytes. On Mac libpng can be installed with homebrew (brew install libpng), and the source file pngToAsm.c can be compiled with `gcc pngToASM.c -o pngToASM -I/opt/homebrew/include -L/opt/homebrew/lib -lpng`.