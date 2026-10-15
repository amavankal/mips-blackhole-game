#-----------------------------------------------------------------------
# draw-game-board.asm
# Description: Contains subroutine that draws the game board.
#
# Author: Asha Mavankal
#-----------------------------------------------------------------------

.globl draw_game_board

.text

# $a0 - game mode (1 or 2)
draw_game_board:
    ## load shared read/write data
    la $t0, graphics_board              # where to write data
    la $t1, game_base_frame             # where to read data if no offset

    ## load data that depends on game mode
    beq $a0, 2, load_two_player_data

    # 1-player mode
    la $t2, one_player_board_offsets    # where to read data
    la $t3, one_player_board_colors     # where to read data

    j draw_base_frame

load_two_player_data:
    # 2-player mode
    la $t2, two_player_board_offsets    # where to read data
    la $t3, two_player_board_colors     # where to read data

draw_base_frame:
    ## loop to draw the board
    li $t4, 0   # LCV

draw_base_frame_loop:
    beq $t4, 65536, exit_draw_base_frame_loop

    # check if can read from offset
    lw $t5, 0($t2)
    bne $t4, $t5, read_from_base

    # read from offsets, then increment
    lw $t5, 0($t3)      # load next color into $t5
    sw $t5, 0($t0)

    # increment loop variables specific to offsets
    addi $t2, $t2, 4
    addi $t3, $t3, 4

    j increment_draw_base_frame_loop

read_from_base:
    # read from base frame
    lw $t5, 0($t1)
    sw $t5, 0($t0)

increment_draw_base_frame_loop:
    addi $t0, $t0, 4    # next word in write frame
    addi $t1, $t1, 4    # next word in read frame
    addi $t4, $t4, 1    # LCV += 1

    j draw_base_frame_loop

exit_draw_base_frame_loop:
    # exit subroutine
    jr $ra