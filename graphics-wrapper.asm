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

# data for drawing the game boards
.include "graphics/game/game-base-frame.asm"
.include "graphics/game/block-assets.asm"
.include "graphics/game/turn-messages.asm"

.include "graphics/game/one-player-board.asm"
.include "graphics/game/two-player-board.asm"

# data for printing the win messages
.include "graphics/win-messages/win-message-comp.asm"
.include "graphics/win-messages/win-message-player.asm"
.include "graphics/win-messages/win-message-p1.asm"
.include "graphics/win-messages/win-message-p2.asm"
