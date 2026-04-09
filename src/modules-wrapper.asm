#-----------------------------------------------------------------------
# modules-wrapper.asm
# Description: brings modules subroutines in subdirectories up to root so
#   that they can be assembled with "Assemble all files in directory"
#   in MARS.
#
# Summaries of global subroutine labels:
#   modules/display:
#
#   modules/game:
#
#   modules/gui:
#
#   modules/input:
#        - 
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

# MMIO Display modules
.include "modules/display/display-board.asm"
.include "modules/display/display-results.asm"
.include "modules/display/display-utils.asm"
.include "modules/display/display-user-selection.asm"

# Game modules
.include "modules/game/calculate-cursor.asm"
.include "modules/game/calculate-score.asm"
.include "modules/game/game-utils.asm"
.include "modules/game/take-computer-turn.asm"

# GUI modules
.include "modules/gui/draw-arrows.asm"
.include "modules/gui/draw-assets.asm"
.include "modules/gui/draw-block-assets.asm"
.include "modules/gui/draw-game-board.asm"

# Input modules
.include "modules/input/input-utils.asm"