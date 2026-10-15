#-----------------------------------------------------------------------
# modules-wrapper.asm
# Description: includes helper subroutines organized in modules/ in the
#   project root so that they can be assembled with "Assemble all files
#   in directory" in MARS.
#
# Author: Asha Mavankal
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