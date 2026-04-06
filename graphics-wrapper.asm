#-----------------------------------------------------------------------
# graphics-wrapper.asm
# Description: brings graphics data in directories up to root so that
#   they can be assembled with "Assemble all files in directory" in 
#   MARS.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

# data for drawing the home animations--animations + selector arrows
.include "graphics/home/home-base-frame.asm"
.include "graphics/home/home-animation-diffs.asm"
.include "graphics/home/arrows.asm"