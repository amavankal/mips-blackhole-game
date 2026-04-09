#-----------------------------------------------------------------------
# utils.asm
# Description: Contains useful miscellaneous subroutines that are used
#   during the game.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl get_num_spots
.globl get_row_from_index

.text

## get number of board spots based on player mode
# $a0 - game mode
# $v0 - # spots 
get_num_spots:
    beq $a0, 2, two_player_mode

    # 1 player mode
    li $v0, 21
    jr $ra

two_player_mode:
    li $v0, 28
    jr $ra
## -----------------------------------------------------

### GET ROW FROM INDEX ####
# helper for get_new_cursor_from_input; uses $t0
# brute force--highkey might be faster than floating point math
# $a0 - cursor
# $v0 - row
get_row_from_index:
    # check if row 1
    bgtz $a0, not_row1
    # is row 1
    li $v0, 1
    jr $ra
not_row1:   # check if row 2
    bgt $a0, 2, not_row2
    # is row 2
    li $v0, 2
    jr $ra
not_row2:   # check if row 3
    bgt $a0, 5, not_row3
    # is row 3
    li $v0, 3
    jr $ra
not_row3:   # check if row 4
    bge $a0, 9, not_row4
    # is row 4
    li $v0, 4
    jr $ra
not_row4:   # check if row 5
    bgt $a0, 14, not_row5
    # is row 5
    li $v0, 5
    jr $ra
not_row5:   # check if row 6
    bgt $a0, 20, not_row6
    # is row 6
    li $v0, 6
    jr $ra
not_row6:
    # must be row 7
    li $v0, 7
    jr $ra
