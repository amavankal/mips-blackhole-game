#-----------------------------------------------------------------------
# calculate-scores.asm
# Description: Contains subroutine that calculates the scores from the
#   state of the game board at the end of a game
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl calculate_scores

.text

### CALCULATE SCORES ###
# assumes there is at least 1 open spot
# $a0 - game mode
# $v0 - computer points
# $v1 - player 1 points
# $a3 - player 2 points
calculate_scores:
    ## subroutine prologue -- set up stack frame
    # leave a spot to save index of open spot
    addi $sp, $sp, -16
    sw $a0, 12($sp)
    sw $fp, 8($sp)
    sw $ra, 4($sp)
    move $fp, $sp

    # first, find index of only open spot
    li $t0, 0
find_open_spot:
    li $t1, 28
    bge $t0, $t1, spot_found    # should never go here, this just in case

    # get player # at $t0
    sll $t1, $t0, 1
    lb $t1, board($t1)
    
    # if free spot, go to spot found
    bltz $t1, spot_found

    # increment & loop
    addi $t0, $t0, 1
    j find_open_spot

spot_found:
    # save index of free spot on stack
    sw $t0, 0($sp)

    # $t1: get 1-indexed row number 
    move $a0, $t0
    jal get_row_from_index
    move $t1, $v0

    # get first column in row idx: (r * (r-1) / 2) -- 0 indexed
    addi $t2, $t1, -1
    mulo $t2, $t1, $t2
    srl $t2, $t2, 1

    # $t2: column index in row = idx - idx of first column in row
    lw $t0, 0($sp)
    sub $t2, $t0, $t2

    # $v0 holds comp pts, $v1 holds player 1 points, $a3 holds player 2 points
    li $v0, 0
    li $v1, 0
    li $a3, 0

    ## check left & top left if NOT FIRST in row (c != 0)
    beqz $t2, skip_left
    
    # check left
    addi $t3, $t0, -1   # $t3 is idx of left
    sll $t3, $t3, 1     # $t3 is 2-byte offset for left idx

    lb $a0, board($t3)   # $a0 is player idx at left
    addi $t3, $t3, 1
    lb $a1, board($t3)   # $a1 is value at left

    jal increment_scores

    # check top left
    sub $t3, $t0, $t1   # $t3 is idx of top left
    sll $t3, $t3, 1     # $t3 is 2-byte offset for top left idx

    lb $a0, board($t3)  # $a0 is player idx at top left
    addi $t3, $t3, 1
    lb $a1, board($t3)   # $a1 is value @ top left

    jal increment_scores

skip_left:
    ## check right & top right if NOT LAST in row (c != r - 1)
    addi $t3, $t1, -1       # $t3 = r - 1 (last index of row)
    beq $t2, $t3, skip_right

    # check right
    addi $t3, $t0, 1    # $t3 is idx of right
    sll $t3, $t3, 1     # $t3 is 2-byte offset for right idx

    lb $a0, board($t3)   # $a0 is player idx at right
    addi $t3, $t3, 1
    lb $a1, board($t3)   # $a1 is value at right

    jal increment_scores

    # check top right
    sub $t3, $t0, $t1
    addi $t3, $t3, 1    # $t3 is idx of top right
    sll $t3, $t3, 1     # $t3 is 2-byte offset for top right idx

    lb $a0, board($t3)  # $a0 is player idx at top left
    addi $t3, $t3, 1
    lb $a1, board($t3)   # $a1 is value @ top left

    jal increment_scores

skip_right:
    # check bottom right & left if NOT LAST ROW (r !=  or 7)
    lw $t3, 12($sp)
    beq $t3, 2, set_last_row_2player
    li $t3, 6
    j continue_check_bottom
set_last_row_2player:
    li $t3, 7

continue_check_bottom:
    beq $t1, $t3, skip_bottom   # skip if last row

    # check bottom left
    add $t3, $t0, $t1  # $t3 is idx of bottom left (i + r)
    sll $t3, $t3, 1     # convert to 2-byte offset

    lb $a0, board($t3)
    addi $t3, $t3, 1
    lb $a1, board($t3)

    jal increment_scores

    # check bottom right - go over 1
    addi $t3, $t3, 1

    lb $a0, board($t3)
    addi $t3, $t3, 1
    lb $a1, board($t3)

    jal increment_scores

skip_bottom:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 4($sp)
    lw $fp, 8($sp)
    addi $sp, $sp, 16

    jr $ra
## -----------------------------------------------------

### INCREMENT SCORE ###
## increment $v0 for computer, increment $v1 for player1, increment $a0 for player2
# $a0 - user # (0, 1, or 2)
# $a1 - value to add
# $v0 - adds value to this register if user # = 0
# $v1 - adds value to this register if user # = 1
# $a3 - adds value to this register if user # = 2
increment_scores:
    bnez $a0, check_player1or2
    # add to computer
    add $v0, $v0, $a1
    jr $ra

check_player1or2:
    bgt $a0, 1, add_to_player2
    # add to player 1
    add $v1, $v1, $a1
    jr $ra

add_to_player2:
    add $a3, $a3, $a1
    jr $ra

## -----------------------------------------------------