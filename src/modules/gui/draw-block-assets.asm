#-----------------------------------------------------------------------
# draw-block-assets.asm
# Description: Contains subroutines that draw blocks assets on the game
#   board given offsets to draw them at. They are used by subroutines
#   in draw-assets.asm.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl draw_number
.globl erase_number
.globl draw_circle

.text

### DRAW number ###
# draws number on the game board
# $a0 - number to draw
# $a1 - offset to draw it at (in pixels)
# $a2 - color
draw_number:
    # first load number's first offset
    la $t0, number_offsets
    addi $t1, $a0, -1       # -1 to make 0 indexed
    sll $t1, $t1, 2         # *4 to make word offset

    add $t0, $t0, $t1       # $t0 is addr of addr of first offset
    lw $t0, 0($t0)          # $t0 is addr of first offset

draw_number_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_draw_number_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a1, $t1
    sll $t1, $t1, 2

    # store color @ calculated offset
    sw $a2, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j draw_number_loop

exit_draw_number_loop:
    jr $ra

### ERASE number ###
# erases given number on the game board (for responsive spot selection)
# $a0 - number to erase
# $a1 - offset to erase it from (in pixels)
erase_number:
    # first load number's first offset
    la $t0, number_offsets
    addi $t1, $a0, -1       # -1 to make 0 indexed
    sll $t1, $t1, 2         # *4 to make word offset

    add $t0, $t0, $t1       # $t0 is addr of addr of first offset
    lw $t0, 0($t0)          # $t0 is addr of first offset

erase_number_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_erase_number_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a1, $t1
    sll $t1, $t1, 2

    # store color from game base @ calculated offset in final board
    lw $t2, game_base_frame($t1)
    sw $t2, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j erase_number_loop

exit_erase_number_loop:
    jr $ra

### DRAW CIRCLE ###
# $a0 - offset to erase circle from  (in pixels)
# $a1 - color
draw_circle:
    # first load circle's first offset
    la $t0, circle_offsets      # $t0 is addr of first offset

draw_circle_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_draw_circle_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a0, $t1
    sll $t1, $t1, 2

    # store color @ calculated offset
    sw $a1, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j draw_circle_loop

exit_draw_circle_loop:
    jr $ra
