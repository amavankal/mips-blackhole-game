#-----------------------------------------------------------------------
# two-player-game.asm
# Description: Contains two_player_game subroutine, which runs a 2
#   player game taking input from the MMIO simulator. Displays results
#   message at the end of the game.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------


.data

# 28 spots. Each spot has 2 bytes: 1st byte is player # (0 = comp, 1, 2).
# 2nd byte is value (1-9 for two)
two_player_board:
    .byte 0 : 56

.text
.globl two_player_game

two_player_game:

    jr $ra