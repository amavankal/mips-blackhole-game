#-----------------------------------------------------------------------
# take-computer-turn.asm
# Description: Contains subroutine that executes the computer's turn
#   by selecting a random spot to put its number in and entering the
#   number.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl take_computer_turn

.text

## take the computer's turn. generate random spot, and
#   fill it.
# $a0 - number of spots remaining on board ($s5)
# $a1 - computer's next number to draw ($s3)
# $a2 - game mode ($s0)
# $v0 - computer's new next number (new $s3)
# $v1 - new number of spots remaining on board (new $s5)
take_computer_turn:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -20
    sw $fp, 16($sp)
    sw $ra, 12($sp)
    sw $a2, 8($sp)  # $s0 - game mode
    sw $a1, 4($sp)  # $s3 - next number to draw
    sw $a0, 0($sp)  # $s5 - number of spots remaining on board
    move $fp, $sp
    
    ## generate random number from spots remaining [0, spots left)
    li $v0, 42
    li $a0, 0
    move $a1, $a0
    syscall

    ## select next free spot
    li $t0, 0   # LCV
    li $t1, 0   # num spots skipped
    move $t2, $a0   # num free spots to skip 

computer_free_spot_loop:
    li $t3, 28
    beq $t0, $t3, exit_computer_free_spot_loop # should never reach this: just in case

    # load byte @ idx $t0 * 2
    sll $t3, $t0, 1
    lb $t3, board($t3)

    # check if spot is full or empty
    bgez $t3, increment_computer_free_spot_loop # spot is full

    # spot is not full-- if # spots skipped == spots to skip, this is spot
    bge $t1, $t2, exit_computer_free_spot_loop

    # more spots to skip: increment # spots skipped & increment loop
    addi $t1, $t1, 1

increment_computer_free_spot_loop:
    # increment LCV by 1 bytes
    addi $t0, $t0, 1

    j computer_free_spot_loop

exit_computer_free_spot_loop:
    # add comp (0) and its next num to board. $t0 holds cursor idx
    sll $t2, $t0, 1     # 2 * idx
    li $t1, 0
    sb $t1, board($t2)

    addi $t2, $t2, 1
    lw $t3, 4($sp)
    sb $t3, board($t2)

    ## draw number
    move $a0, $t3   # num to draw
    
    # get offset based on game mode
    move $a1, $t0
    sll $t1, $a1, 2

    lw $t3, 8($sp)
    beq $t3, 2, use_two_player_offsets

    lw $a1, one_player_block_offsets($t1)
    j computer_call_draw_number

use_two_player_offsets:
    lw $a1, two_player_block_offsets($t1)

computer_call_draw_number:
    # get computer color and draw number
    lw $a2, computer_color
    jal draw_number

    ## increment computer's next num, decrement spots remaining
    lw $v0, 4($sp)
    addi $v0, $v0, 1

    lw $v1, 0($sp)
    addi $v1, $v1, -1

    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 12($sp)
    lw $fp, 16($sp)
    addi $sp, $sp, 20

    # exit subroutine
    jr $ra
## -----------------------------------------------------
