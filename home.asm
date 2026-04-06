#-----------------------------------------------------------------------
# home.asm
# Description: draws home animation and reads user input
#
# Uses data in home-frame-1.asm and home-animation-diffs.asm:
#       home_base_frame, home_offsets, and home_colors
# Uses data in arrows.asm:
#       arrow_offsets & arrow_colors
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.data
frame_lag:
    .word 150

### HOME playback loop - run animations / read input ###
# no arguments
# uses $t0 - $t3
# $v0 - 0 if user wants to exit, 1 if 1 player, 2 if 2 player

.text

.globl home
home:
    ## draw base frame
    la $t0, graphics_board    # where to write data
    la $t1, home_base_frame   # where to read data

    li $t2, 0   # LCV
draw_base_frame_loop:
    beq $t2, 65536, exit_draw_base_frame_loop

    lw $t3, 0($t1)
    sw $t3, 0($t0)

    addi $t0, $t0, 4    # next word in write frame
    addi $t1, $t1, 4    # next word in read frame
    addi $t2, $t2, 1    # LCV += 1

    j draw_base_frame_loop

exit_draw_base_frame_loop:

    li $v0, 0
    # exit subroutine
    jr $ra