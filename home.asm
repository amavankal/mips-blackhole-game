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
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp -16
    sw $fp, 12($sp)
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    move $fp, $sp

    ## home variables
    li $s0, 1       # $s0 will hold the user's current selection (where to paint arrow)
    li $s1, 0       # $s1 will hold the index of the animation frame to draw

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
    ## draw user selection arrow
    move $a0, $s0
    jal draw_arrow

    ##

    ## subroutine epilogue - take down stack frame
    move $sp, $fp
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    lw $fp, 12($sp)
    addi $sp, $sp, 16

    ## exit subroutine
    jr $ra


#### helper subroutines ####

### DRAW arrow ###
# $a0 - user selection - 0 (exit), 1 (1 player), or 2 (2 player)
# no results - just draws the arrow
draw_arrow:
    la $t0, arrow_offsets
    sll $a0, $a0, 2         # make $a0 hold word offset for user selection
    add $t0, $t0, $a0       # $t0 holds address of addr of first offset

    # arrow drawing variables
    lw $t0, 0($t0)          # $t0 holds address of first offset
    la $t1, arrow_colors    # $t1 holds address of first color

    # write to graphics_board($word_offset)
draw_arrow_loop:
    lw $t2, 0($t0)                  # $t2 holds next offset value
    bltz $t2, exit_draw_arrow_loop  # exit if last offset (array ends w/ -1)

    sll $t2, $t2, 2         # $t2 holds next word offset value (i -> 4 * i)
    lw $t3, 0($t1)          # $t3 holds next color value

    # store the color value on the board
    sw $t3, graphics_board($t2)

    # increment arrow drawing variables
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j draw_arrow_loop

exit_draw_arrow_loop:
    jr $ra

### ERASE arrow ###
# $a0 - index of arrow to erase
# just looks at base frame to erase, since there are no stars near arrows
erase_arrow:
    la $t0, arrow_offsets
    sll $a0, $a0, 2         # make $a0 hold word offset for user selection
    add $t0, $t0, $a0       # $t0 holds address of addr of first offset

    # arrow erasing variables
    lw $t0, 0($t0)          # $t0 holds address of first offset

    # write to graphics_board($word_offset)
erase_arrow_loop:
    lw $t2, 0($t0)                  # $t2 holds next offset value
    bltz $t2, exit_erase_arrow_loop  # exit if last offset (array ends w/ -1)

    sll $t2, $t2, 2                 # $t2 holds next word offset value (i -> 4 * i)
    lw $t3, home_base_frame($t2)    # $t3 holds replacement color value

    # store the color value on the board
    sw $t3, graphics_board($t2)

    # increment arrow drawing variables
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j erase_arrow_loop

exit_erase_arrow_loop:
    jr $ra
