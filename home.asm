#-----------------------------------------------------------------------
# home.asm
# Description: Contains home subroutine, which animates the home frame
#   and processes user input to the MMIO simulator. Returns the user's
#   selection (0 = exit, 1 = 1 player, or 2 = 2 player) in $v0.
#
# Uses data in graphics/home/home-frame-1.asm and 
#   graphics/home/home-animation-diffs.asm:
#       home_base_frame, home_offsets, and home_colors
# Uses data in graphics/home/arrows.asm:
#       arrow_offsets & arrow_colors
#
# Subroutines:
#   home (global): animates home animation and processes user input
#   draw_arrow: helper subroutine for home. draws user selection arrow
#   erase_arrow: helper subroutine for home. erases user selection arrow
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.data
frame_lag:
    .word 10

.text
.globl home

### HOME playback loop - run animations / read input ###
# no arguments
# uses $t0 - $t3
# $v0 - 0 if user wants to exit, 1 if 1 player, 2 if 2 player
home:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp -24
    sw $fp, 20($sp)
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    move $fp, $sp

    ## home variables
    li $s0, 1       # $s0 will hold the user's current selection (where to paint arrow)
    li $s2, 1       # $s2 will hold user's old selection (for erasing)
    li $s1, 0       # $s1 will hold the index of the animation frame to draw
    li $s3, 1       # $s3 will hold poll counter

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

    # sleep for 1 cycle (doesn't read input but that's okay)
    li $v0, 32
    lw $a0, frame_lag
    syscall

    ### HOME loop: go through animation frames, and see if user input exists
home_loop:
    ## check if there's user input. if there is, process it
    ## if user hits enter, load results into $v0
    # read control register
    li $t0, 0xFFFF0000  # $t0 holds address of keyboard control register
    lw $t0, 0($t0)      # read control bit
    andi $t0, $t0, 1    # isolate control bit
    beq $t0, $zero, check_update_frame       # if no input, update frame

    # read input
    li $t0, 0xFFFF0004
    lw $a0, 0($t0)

    # check if input is enter character
    jal is_go_character
    bgtz $v0, exit_home_loop    # if > 0 (1), exit loop

    # check if input is up character
    jal is_up_only_character
    beqz $v0, check_down    # if not up character, check if down

    move $s2, $s0           # store old selection in $s2
    addi $s0, $s0, -1       # decrement user selection $s0
    
    # circle around if $s0 goes below 0
    bgez $s0, check_update_frame
    li $s0, 2

check_down:    
    # check if input is down character
    jal is_down_only_character
    beqz $v0, check_update_frame  # if not down character, continue

    move $s2, $s0               # store old selection in $s2
    addi $s0, $s0, 1            # increment user selection

    # circle around if $s0 goes above 2
    li $t0, 3
    blt $s0, $t0, check_update_frame
    li $s0, 0

check_update_frame:
    # increment poll counter
    addi $s3, $s3, 1
    li $t0, 16
    blt $s3, $t0, continue_check_update_frame

    li $s3, 1

continue_check_update_frame:
    ### only update frame if poll counter is 15
    li $t0, 15
    beq $s3, $t0, update_frame

    # not updating frame, so sleep
    li $v0, 32
    lw $a0, frame_lag
    syscall

    j home_loop

update_frame:
    ## draw next frame
    la $t0, home_offsets
    sll $t2, $s1, 2     # get word offset for animation frame
    add $t0, $t0, $t2   # address of address of next offset
    lw $t0, 0($t0)      # $t0: address of next offset

    la $t1, home_colors
    add $t1, $t1, $t2   # address of address of next color
    lw $t1, 0($t1)      # $t1: address of next color

draw_updates_loop:
    lw $t2, 0($t0)      # next offset
    bltz $t2, exit_draw_updates_loop    # exit if last offset

    sll $t2, $t2, 2     # convert next offset to word offset
    lw $t3, 0($t1)      # next color

    # store color @ offset
    sw $t3, graphics_board($t2)

    # increment address of next offset + address of next color
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j draw_updates_loop

exit_draw_updates_loop:
    # increment $s1 (frame index)
    addi $s1, $s1, 1

    # $s1 loops back to 0 if it reaches 15
    li $t0, 15
    blt $s1, $t0, continue_update_frame
    li $s1, 0

continue_update_frame:
    ## draw arrow
    beq $s2, $s0, skip_arrow_update

    move $a0, $s2
    jal erase_arrow
    move $a0, $s0
    jal draw_arrow
    
skip_arrow_update:
    ## sleep
    li $v0, 32
    lw $a0, frame_lag
    syscall

    ## loop
    j home_loop

exit_home_loop:
    ## update $v0 with $so selection
    move $v0, $s0

    ## subroutine epilogue - take down stack frame
    move $sp, $fp
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    lw $fp, 20($sp)
    addi $sp, $sp, 24

    ## exit subroutine
    jr $ra


################################
###### helper subroutines ######
################################

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

    # increment arrow erasing variables
    addi $t0, $t0, 4

    # loop
    j erase_arrow_loop

exit_erase_arrow_loop:
    jr $ra
