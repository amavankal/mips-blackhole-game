#-----------------------------------------------------------------------
# one-player-game.asm
# Description: Contains one_player_game subroutine, which runs a 1
#   player game taking input from the MMIO simulator. Displays results
#   message at the end of the game.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.data

# 21 spots. Each spot has 2 bytes: 1st byte is player # (0 = comp, 1).
# 2nd byte is value (1-10)
one_player_board:
    .byte -1 : 42

## used as global data for decisions based on game mdoe
game_mode:
    .byte -1

.text
.globl one_player_game

one_player_game:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp -24
    sw $fp, 20($sp)
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    move $fp, $sp

    ## one player game variables
    li $s0, 1       # next number to draw for user
    li $s1, 1       # next number to draw for computer
    li $s2, -1      # position of user's cursor (0 - 20)
    li $s3, 21      # number of spots on board remaining

    ## first, draw base frame + board
    la $t0, graphics_board              # where to write data
    la $t1, game_base_frame             # where to read data if no offset
    la $t2, one_player_board_offsets    # where to read data
    la $t3, one_player_board_colors     # where to read daata

    li $t4, 0   # LCV
draw_base_frame_loop:
    beq $t4, 65536, gameplay_loop

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

    ## gameplay loop -- user turn, then computer turn
gameplay_loop:
    # exit if spots remaining <= 1
    li $t0, 1
    ble $s3, $t0, exit_gameplay_loop

    ## determine where user's cursor should go by iterating through board
    #       and finding first empty slot
    li $t0, 0   # index (also byte offset) in one_player_board
find_cursor_pos_loop:
    # this check is to guard; if it actually evaluates to true something has gone wrong
    li $t1, 42
    beq $t0, 42, exit_gameplay_loop

    # load signed byte @ pos $t0 in one_player_board
    lb $t1, one_player_board($t0)
    bgez $t1, increment_find_cursor_pos_loop

    # $t1 = -1. so cursor pos is $t0 / 2
    srl $s2, $t0, 1
    j exit_find_cursor_pos_loop

increment_find_cursor_pos_loop:
    # increment position (by 2--skip 2nd num byte, only reading person byte)
    addi $t0, $t0, 2

    j find_cursor_pos_loop

exit_find_cursor_pos_loop:
    ## draw p1 turn message
    li $a0, 1
    jal draw_turn_message

wait_for_user_final_selection:
    ## draw selector circle
    sll $a0, $s2, 2
    lw $a0, one_player_block_offsets($a0)
    lw $a1, selected_circle_color
    jal draw_circle

    ## draw number: temp
    move $a0, $s0
    sll $a1, $s2, 2
    lw $a1, one_player_block_offsets($a1)
    lw $a2, player1_color_temp
    jal draw_number

    ## await valid input
await_input:
    li $t0, 0xFFFF0000       # $t0 holds address of keyboard control register
    lw $t0, 0($t0)           # read control bit
    andi $t0, $t0, 1         # isolate control bit
    beqz $t0, await_input    # if no input, update frame

    # read input
    li $t0, 0xFFFF0004
    lw $a0, 0($t0)      # put user input in $a0

    # if input is go char, take computer's turn
    jal is_go_character
    bnez $v0, finalize_user_selection

    # manage user input - $v0 has resultant cursor
    move $a1, $s2   # put cursor in $a1
    jal get_new_cursor_from_input

    # if $v0 != $s2, erase number & reset circle
    beq $v0, $s2, set_cursor

    # erase number & reset circle
    ## draw selector circle
    sll $a0, $s2, 2
    lw $a0, one_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    ## draw number: temp
    move $a0, $s0   # number to erase
    sll $a1, $s2, 2
    lw $a1, one_player_block_offsets($a1)   # offset on board
    jal erase_number

set_cursor:
    # $v0 == $s2.. nothing happens
    move $s2, $v0

    j wait_for_user_final_selection

finalize_user_selection:
    ## add to board
    sll $t0, $s2, 1
    li $t1, 1
    sb $t1, one_player_board($t0)

    addi $t0, $t0, 1
    sb $s0, one_player_board($t0)

    ## draw circle
    sll $a0, $s2, 2
    lw $a0, one_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    ## draw number
    move $a0, $s0
    sll $a1, $s2, 2
    lw $a1, one_player_block_offsets($a1)
    lw $a2, player1_color
    jal draw_number

    ## increment user's next num, decrement spots remaining
    addi $s0, $s0, 1
    addi $s3, $s3, -1

computer_turn:
    ## generate random number from spots remaining [0, spots left)
    li $v0, 42
    li $a0, 0
    move $a1, $s3
    syscall

    ## select next free spot
    li $t0, 0   # LCV
    li $t1, 0   # num spots skipped
    move $t2, $a0   # num free spots to skip 

computer_free_spot_loop:
    li $t3, 21
    beq $t0, $t3, exit_computer_free_spot_loop # should never reach this: just in case

    # load byte @ idx $t0 * 2
    sll $t3, $t0, 1
    lb $t3, one_player_board($t3)

    # check if spot is full or empty
    bgez $t3, increment_computer_free_spot_loop # spot is full

    # spot is not full-- if # spots skipped == spots to skip, this is spot
    bge $t1, $t2, exit_computer_free_spot_loop

    # more spots to skip: increment # spots skipped & increment loop
    addi $t1, $t1, 1
    j increment_computer_free_spot_loop

increment_computer_free_spot_loop:
    # increment LCV by 1 bytes
    addi $t0, $t0, 1

    j computer_free_spot_loop

exit_computer_free_spot_loop:
    # add comp (0) and its next num ($s1) to board. $t0 holds cursor idx
    sll $t2, $t0, 1
    li $t1, 0
    sb $t1, one_player_board($t2)

    addi $t2, $t2, 1
    sb $s1, one_player_board($t2)

    ## draw number
    move $a0, $s1
    sll $a1, $t0, 2 # $t0 * 4 to become word offset for its index
    lw $a1, one_player_block_offsets($a1)
    lw $a2, computer_color
    jal draw_number

    ## increment computer's next num, decrement spots remaining
    addi $s1, $s1, 1
    addi $s3, $s3, -1

    # loop back to gameplay loop
    j gameplay_loop

exit_gameplay_loop:
    ## calculate points
    jal calculate_scores

    ## subroutine epilogue -- take down stack frame
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

### CALCULATE SCORES ###
# assumes there is at least 1 open spot
# $v0 - computer points
# $v1 - player 1 points
calculate_scores:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -4
    sw $fp, 4($sp)
    sw $ra, 0($ra)
    move $fp, $sp

    # first, find index of only open spot
    li $t0, 0
find_open_spot:
    li $t1, 21
    bge $t0, $t1, spot_found    # should never go here, this just in case

    # get player # at $t0
    sll $t1, $t0, 1
    lb $t1, one_player_board($t1)
    
    # if free spot, go to spot found
    bltz $t1, spot_found

    # increment & loop
    addi $t0, $t0, 1
    j find_open_spot

spot_found:
    # $t0: index of free spot
    move $a0, $t0
    jal get_row_from_index

    # $t1: row number of free spot - 1 indexed
    move $t1, $v0

    # $t2: column number (r * (r-1) / 2) - 0 indexed
    addi $t2, $t1, -1
    mulo $t2, $t1, $t2

    srl $t2, $t2, 1

    # $v0 holds comp pts, $v1 holds player points
    li $v0, 0
    li $v1, 0

    ## check left & top left if NOT FIRST in row (c != 0)
    beqz $t2, skip_left
    
    # check left
    addi $t3, $t0, -1   # $t3 is idx of left
    sll $t3, $t3, 1     # $t3 is 2-byte offset for left idx

    lb $a0, one_player_board($t3)   # $a0 is player idx at left
    addi $t3, $t3, 1
    lb $a1, one_player_board($t3)   # $a1 is value at left

    jal increment_scores

    # check top left
    sub $t3, $t0, $t1   # $t3 is idx of top left
    sll $t3, $t3, 1     # $t3 is 2-byte offset for top left idx

    lb $a0, one_player_board($t3)  # $a0 is player idx at top left
    addi $t3, $t3, 1
    lb $a1, one_player_board($t3)   # $a1 is value @ top left

    jal increment_scores

skip_left:
    ## check right & top right if NOT LAST in row (c != r - 1)
    addi $t3, $t1, -1       # $t3 = r - 1 (last index of row)
    beq $t2, $t3, skip_right

    # check right
    addi $t3, $t0, 1    # $t3 is idx of right
    sll $t3, $t3, 1     # $t3 is 2-byte offset for right idx

    lb $a0, one_player_board($t3)   # $a0 is player idx at right
    addi $t3, $t3, 1
    lb $a1, one_player_board($t3)   # $a1 is value at right

    jal increment_scores

    # check top right
    sub $t3, $t0, $t1
    addi $t3, $t3, 1    # $t3 is idx of top right
    sll $t3, $t3, 1     # $t3 is 2-byte offset for top right idx

    lb $a0, one_player_board($t3)  # $a0 is player idx at top left
    addi $t3, $t3, 1
    lb $a1, one_player_board($t3)   # $a1 is value @ top left

    jal increment_scores

skip_right:
    # check bottom right & left if NOT LAST ROW (r != 6)
    li $t3, 6

    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 4

    jr $ra

### INCREMENT SCORE ###
## increment $v0 for computer, increment $v1 for player1, increment $a3 for player2
# $a0 - user # (0, 1, or 2)
# $a1 - value to add
increment_scores:
    bnez $a0, check_player1or2
    # add to computer
    add $v0, $v0, $a1
    jr $ra

check_player1or2:
    bgt $a0, 1, add_to_player2
    # add to player 1
    add $v0, $v0, $a0
    jr $ra

add_to_player2:
    add $v1, $v1, $a0
    jr $ra

### CALCULATE CURSOR based on user input
# reads the one_player_board
# $a0 - user input character
# $a1 - current cursor
# $v0 - the resultant cursor
get_new_cursor_from_input:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # if left or right, easy, just iterate until next free spot
    jal is_left_character
    bnez $v0, handle_left

    jal is_right_character
    bnez $v0, handle_right

    jal is_up_character
    bnez $v0, handle_up

    jal is_down_character
    bnez $v0, handle_down

    # if invalid selection, cursor stays same
    move $v0, $a1
    j exit_get_new_cursor_from_input

## handle left
handle_left:
    move $t0, $a1       # current index in board

    # shift left
    addi $t0, $t0, -1
    bgez $t0, left_loop

    # wrap around if needed- set $t0 to max idx
    li $t0, 20

left_loop:
    beq $t0, $a1, exit_left_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, one_player_board($t1)   # get player num @ index $t0
    bltz $t2, exit_left_loop        # if free spot (player num = -1), done

    # increment loop: move left
    addi $t0, $t0, -1
    bgez $t0, left_loop

    # wrap around if needed - set $t0 to max idx
    li $t0, 20

    # loop
    j left_loop

exit_left_loop:
    move $v0, $t0
    j exit_get_new_cursor_from_input

## handle right
handle_right:
    move $t0, $a1       # current index in board

    # shift right
    addi $t0, $t0, 1
    li $t1, 21
    blt $t0, $t1, right_loop

    # wrap around if needed- set $t0 to min idx
    li $t0, 0

right_loop:
    beq $t0, $a1, exit_right_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, one_player_board($t1)   # get player num @ index $t0
    bltz $t2, exit_right_loop       # if free spot (player num = -1), done

    # increment loop: move right
    addi $t0, $t0, 1
    li $t1, 21
    blt $t0, $t1, right_loop

    # wrap around if needed - set $t0 to min idx
    li $t0, 0

    # loop
    j right_loop

exit_right_loop:
    move $v0, $t0
    j exit_get_new_cursor_from_input

## handle up
handle_up:
    move $a0, $a1   # move current cursor position to $a0
    jal get_row_from_index

    # if in row 1, return same position
    li $t0, 1
    beq $v0, $t0, up_failed

    move $t1, $v0   # $t1: current row of cursor

    # calculate row midpoint ((r-1)r + r(r+1))/4
    addi $t2, $t1, -1   # r - 1
    mulo $t2, $t2, $t1  # r(r - 1)
    addi $t3, $t1, 1    # r + 1
    mulo $t3, $t3, $t1  # r(r + 1)
    add $t2, $t2, $t3   # r(r - 1) + r(r + 1)
    srl $t2, $t2, 2     # (r(r - 1) + r(r + 1)) / 4

    # if $a1 (curr idx) < midpoint, do right; else do left
    blt $a1, $t2, try_top_right

try_top_left:
    # $t0: top left cursor ( - r)
    sub $t0, $a1, $t1

    # see if top left is full
    sll $t2, $t0, 1     # multiply top left cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, up_failed     # if top left has smth, stop

    # top left is valid, and free.. return that index
    move $v0, $t0
    j exit_get_new_cursor_from_input

try_top_right:
    # $t0: top right cursor ( - r + 1)
    sub $t0, $a1, $t1
    addi $t0, $t0, 1

    # see if top right is full
    sll $t2, $t0, 1     # multiply top right cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, up_failed

    # top right is valid, and free.. return that index
    move $v0, $t0
    j exit_get_new_cursor_from_input

up_failed:
    move $v0, $a1
    j exit_get_new_cursor_from_input

## handle down
handle_down:
    move $a0, $a1   # move current index in board to $a0
    jal get_row_from_index

    # if in row 6, return same position
    li $t0, 6
    beq $v0, $t0, down_failed

    move $t1, $v0   # $t1: current row of cursor

    # calculate row midpoint ((r-1)r + r(r+1))/4
    addi $t2, $t1, -1   # r - 1
    mulo $t2, $t2, $t1  # r(r - 1)
    addi $t3, $t1, 1    # r + 1
    mulo $t3, $t3, $t1  # r(r + 1)
    add $t2, $t2, $t3   # r(r - 1) + r(r + 1)
    srl $t2, $t2, 2     # (r(r - 1) + r(r + 1)) / 4

    # if $a1 (curr idx) < midpoint, do left; else do right
    bge $a1, $t2, try_bottom_right_first

try_bottom_left_first:
    # try bottom left first (+ r)), then bottom right (+ r + 1))
    add $t0, $a1, $t1

    # see if bottom left is full
    sll $t2, $t0, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, try_bottom_right     # if bottom left has smth, try bottom right

    # bottom left is valid, and free.. return that index
    move $v0, $t0
    j exit_get_new_cursor_from_input

try_bottom_right:
    # bottom right idx
    addi $t0, $t0, 1

    # see if bottom right is full
    sll $t2, $t0, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, down_failed

    # bottom right is valid & free
    move $v0, $t0
    j exit_get_new_cursor_from_input

try_bottom_right_first:
    # store bottom right cursor in $t0
    add $t0, $a1, $t1
    addi $t0, $t0, 1   

    # see if bottom right is full
    sll $t2, $t0, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, try_bottom_left     # if bottom right has smth, try bottom left

    # bottom right is valid, and free.. return that index
    move $v0, $t0
    j exit_get_new_cursor_from_input

try_bottom_left:
    # bottom left idx
    addi $t0, $t0, -1

    # see if bottom left is full
    sll $t2, $t0, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, one_player_board($t2)

    bgez $t2, down_failed

    # bottom left is valid & free
    move $v0, $t0
    j exit_get_new_cursor_from_input

down_failed:
    move $v0, $a1

exit_get_new_cursor_from_input:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra
