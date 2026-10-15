#-----------------------------------------------------------------------
# draw-arrows.asm
# Description: Contains subroutine that draw selector arrows for the
#   home subroutine.
#
# Author: Asha Mavankal
#-----------------------------------------------------------------------

.globl draw_arrow
.globl erase_arrow

.text

### DRAW arrow ###
# draws arrow on GUI
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

    # increment arrow erasing variables
    addi $t0, $t0, 4

    # loop
    j erase_arrow_loop

exit_erase_arrow_loop:
    jr $ra
