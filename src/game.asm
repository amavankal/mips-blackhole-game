#-----------------------------------------------------------------------
# game.asm
# Description: Contains game subroutine, which runs a game with the
#   given number of players (only accepts 1 or 2). It draws the game on
#   the bitmap display by writing to graphics_board in driver.asm. 
#   It reads board data from the files in graphics/game (assembled and
#   listed in graphics-wrapper.asm). Displays results message at the 
#   end of the game.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl game
.globl board

.data

## board: 1-player game uses 21 indeces (42 bytes); 2-player game uses
#   28 indeces (56 bytes). 1 index has 2 bytes: user # (0 = computer,
#   1 = player 1, 2 = player 2), and value (1-10 for 1-player, 1-9 for
#   2-player)
board:
    .byte -1 : 56

.text

## $a0 - index of game
game:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp -36
    sw $fp, 32($sp)
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)
    move $fp, $sp

    ## game variables
    move $s0, $a0   # game mode
    li $s1, 1       # next number to draw for player 1
    li $s2, 1       # next number to draw for player 2
    li $s3, 1       # next number to draw for computer
    li $s4, -1      # position of user's cursor (0 - 20 or 0 - 27)
    jal get_num_spots 
    move $s5, $v0   # number of remaining spots in game board

    ## draw base frame + board ($a0 alr holds game mode)
    jal draw_game_board

    ## gameplay loop: wait for p1 to take turn, then p2 if applicable, then comp
    #   and keep going until there is 1 empty spot left
gameplay_loop:
    # exit if spots remaining <= 1
    ble $s5, 1, exit_gameplay_loop

    ## run player loop however many players there are
    li $s6, 1   # current player idx, 1-indexed
player_loop:
    # break if player idx > # players
    bgt $s6, $s0, exit_player_loop

    ## find first free cursor position for player & set it as cursor
    move $a0, $s0
    jal find_first_free_cursor
    move $s4, $v0

    ## draw turn message
    move $a0, $s6
    jal draw_turn_message

    ## get user selection & draw it on board GUi
    move $a0, $s6
    jal get_user_selection

    ## display board to MMIO display
    move $a0, $s0
    li $a1, -1 # -1 means don't display temp spot 
    jal display_board

    ## erase turn message
    move $a0, $s6
    jal erase_turn_message

    ## increment player loop
    addi $s6, $s6, 1

    j player_loop

exit_player_loop:
    ## take computer's turn
    move $a0, $s5
    move $a1, $s3
    move $a2, $s0
    jal take_computer_turn

    # update computer's next number & spots remaining on board
    move $s3, $v0
    move $s5, $v1

    ## display board to MMIO display
    move $a0, $s0
    li $a1, -1 # -1 means don't display temp spot 
    jal display_board

    j gameplay_loop

exit_gameplay_loop:
    ## calculate points - $v0 comp, $v1 p1, $a3 p2
    move $a0, $s0
    jal calculate_scores

    ## display results
    move $a0, $v0   # computer score
    move $a1, $v1   # player 1 score
    move $a2, $a3   # player 2 score

    jal display_results

    ## wait for user to enter a go character before exiting
    li $t0, 0xFFFF0000       # $t0 holds address of keyboard control register

await_end_input:
    lw $t1, 0($t0)              # read control bit
    andi $t1, $t1, 1            # isolate control bit
    beqz $t1, await_end_input   # if no input, wait for more

    # read input
    li $t1, 0xFFFF0004
    lw $a0, 0($t1)      # put user input in $a0

    # if input is NOT go char, keep looping until it is
    jal is_go_character

    # loop if invalid
    li $t0, 0xFFFF0000
    beqz $v0, await_end_input

    ## reset board to all -1s to allow for reuse
    li $t0, 0
    li $t1, -1

reset_board_loop:
    beq $t0, 56, reset_board_done
    sb $t1, board($t0)
    addi $t0, $t0, 1
    j reset_board_loop

reset_board_done:

    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s6, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    lw $fp, 32($sp)
    addi $sp, $sp, 36

    jr $ra


#########################################################
#########################################################
#########################################################

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

## find first free cursor position
# $a0 - game mode
# $v0 - first free cursor
find_first_free_cursor:
    # index (also byte offset) in board
    li $t0, 0
find_cursor_pos_loop:
    # guard: if cursor goes above 42 or 56, some logic has gone wrong
    beq $a0, 2, validate_two_player

    # validate 1 player
    bge $t0, 42, find_free_cursor_error
    j check_cursor

validate_two_player:
    # validate 2 player
    bge $t0, 56, find_free_cursor_error

check_cursor:
    # load signed byte @ pos $t0 in board
    lb $t1, board($t0)
    bgez $t1, increment_find_cursor_pos_loop    # alr filled, keep looking

    # found free spot! $t1 = -1. so cursor pos is $t0 / 2
    srl $v0, $t0, 1
    jr $ra

increment_find_cursor_pos_loop:
    # increment position (by 2--skip 2nd num byte, only reading person byte)
    addi $t0, $t0, 2

    j find_cursor_pos_loop

find_free_cursor_error:
    # if there's an error, terminate execution
    li $v0, 10
    syscall
## -----------------------------------------------------

## keep reading user input until they have selected
#   a final spot to put their number
# reads $s0 for game mode, $s1 and $s2 for next numbers,
#   and $s4 for cursor position
# $a0 - player # (only necessary if $s0 = 2; can hold 1 or 2)
get_user_selection:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # store player # in $t9
    move $t9, $a0

wait_for_user_final_selection:
    ### draw selector circle & number, based on game mode
    move $a0, $s0
    move $a1, $t9
    move $a2, $s4

    beq $t9, 2, draw_p2_number
    move $a3, $s1
    j call_draw_user_selection
draw_p2_number:
    move $a3, $s2
call_draw_user_selection:
    jal draw_user_selection

    ### await valid input
await_input:
    li $t0, 0xFFFF0000       # $t0 holds address of keyboard control register
    lw $t0, 0($t0)           # read control bit
    andi $t0, $t0, 1         # isolate control bit
    beqz $t0, await_input    # if no input, update frame

    # read input
    li $t0, 0xFFFF0004
    lw $a0, 0($t0)      # put user input in $a0

    # if input is go char, finalize selection
    move $t8, $a0   # save user input in $t8
    jal is_go_character
    bnez $v0, finalize_user_selection

    # manage user input - $v0 has resultant cursor
    move $a0, $t8   # pass input char
    move $a1, $s4   # put cursor in $a1
    move $a2, $s0   # pass game mode
    jal get_cursor_from_input

    # if $v0 != $s4, erase number & reset circle
    beq $v0, $s4, set_cursor

    # erase number & reset circle, based on game mode
    move $a0, $s0
    move $a1, $s4
    beq $t9, 2, erase_p2_number
    move $a2, $s1
    j call_erase_user_selection
erase_p2_number:
    move $a2, $s2
call_erase_user_selection:
    jal erase_user_selection

set_cursor:
    # set cursor to $v0
    move $s4, $v0

    j wait_for_user_final_selection

finalize_user_selection:
    ## add to board
    # add player idx
    sll $t0, $s4, 1
    move $t1, $t9
    sb $t1, board($t0)

    # add value
    addi $t0, $t0, 1
    beq $t9, 2, store_p2_value
# store p1 value
    sb $s1, board($t0)
    j draw_final
store_p2_value:
    sb $s2, board($t0)

draw_final:
    ### draw selector circle & number, based on game mode
    move $a0, $s0
    move $a1, $t9
    move $a2, $s4

    beq $t9, 2, draw_p2_number_final
    move $a3, $s1
    j call_draw_final_user_selection
draw_p2_number_final:
    move $a3, $s2
call_draw_final_user_selection:
    jal draw_final_user_selection

    ## increment user's next num
    beq $t9, 2, increment_p2_num
    addi $s1, $s1, 1 # increment p1's num
    j decrement_spots
increment_p2_num:
    addi $s2, $s2, 1

decrement_spots:
    ## decrement spots remaining
    addi $s5, $s5, -1

    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra
## -----------------------------------------------------

### CALCULATE CURSOR based on user input
# reads the board
# $a0 - user input character
# $a1 - current cursor
# $a2 - game mode
# $v0 - the resultant cursor
get_cursor_from_input:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -20
    sw $fp, 16($sp)
    sw $ra, 12($sp)
    sw $a2, 8($sp)  # game mode
    sw $a1, 4($sp)  # current cursor
    sw $a0, 0($sp)  # user input character
    move $fp, $sp

    # check left
    lw $a0, 0($sp)   # reload user input into $a0
    jal is_left_character
    bnez $v0, do_handle_left

    # check right
    lw $a0, 0($sp)
    jal is_right_character
    bnez $v0, do_handle_right

    # check up
    lw $a0, 0($sp)
    jal is_up_character
    bnez $v0, do_handle_up

    # check down
    lw $a0, 0($sp)
    jal is_down_character
    bnez $v0, do_handle_down

    # invalid selection: return same cursor
    move $v0, $a1
    j exit_get_cursor_from_input

do_handle_left:
    lw $a0, 4($sp)      # pass cursor
    lw $a1, 8($sp)      # pass game mode
    jal handle_left
    j exit_get_cursor_from_input

do_handle_right:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jal handle_right
    j exit_get_cursor_from_input

do_handle_up:
    lw $a0, 4($sp)
    jal handle_up
    j exit_get_cursor_from_input

do_handle_down:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jal handle_down
    j exit_get_cursor_from_input

exit_get_cursor_from_input:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    lw $fp, 16($sp)
    addi $sp, $sp, 20

    jr $ra
## -----------------------------------------------------

## handle left
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_left:
    # store current pos in $t0
    move $t0, $a0

    # shift left
    addi $t0, $t0, -1
    bgez $t0, left_loop
    beq $a1, 2, wrap_2players
    li $t0, 20   # wrap around if needed- set $t0 to max idx
    j left_loop
wrap_2players:
    li $t0, 27   # wrap around if needed- set $t0 to max idx

left_loop:
    beq $t0, $a0, exit_left_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, board($t1)   # get player num @ index $t0
    bltz $t2, exit_left_loop        # if free spot (player num = -1), done

    # increment loop: move left
    addi $t0, $t0, -1
    bgez $t0, left_loop
    beq $a1, 2, wrap_2players2

    li $t0, 20   # wrap around if needed - set $t0 to max idx
    j left_loop

wrap_2players2:
    li $t0, 27  # wrap around if needed - set $t0 to max idx
    j left_loop

exit_left_loop:
    # put results in $v0 and exit
    move $v0, $t0
    jr $ra

## handle right
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_right:
    # store current pos in $t0
    move $t0, $a0

    # shift right
    addi $t0, $t0, 1
    beq $a1, 2, wrap_check_2players
    blt $t0, 21, right_loop
    j wrap
wrap_check_2players:
    blt $t0, 28, right_loop
wrap:
    li $t0, 0   # wrap around if needed- set $t0 to min idx

right_loop:
    beq $t0, $a0, exit_right_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, board($t1)   # get player num @ index $t0
    bltz $t2, exit_right_loop       # if free spot (player num = -1), done

    # increment loop: move right
    addi $t0, $t0, 1
    li $t1, 21
    beq $a1, 2, wrap_check_2players2
    blt $t0, $t1, right_loop
    j wrap2
wrap_check_2players2:
    blt $t0, 28, right_loop

wrap2:
    li $t0, 0  # wrap around if needed - set $t0 to min idx
    j right_loop  # loop

exit_right_loop:
    move $v0, $t0
    jr $ra

## handle up
# $a0 - cursor position
# $v0 - resultant cursor
handle_up:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # store row in $t0
    jal get_row_from_index
    move $t0, $v0

    # if row is first, leave
    beq $t0, 1, up_failed

continue_handle_up:
    # store column number idx - (r * (r-1) / 2) - in $t1
    addi $t1, $t0, -1
    mulo $t1, $t0, $t1
    srl $t1, $t1, 1 # 1st idx in row r

    # column # for idx (cursor - first in row)
    sub $t4, $a0, $t1

    # compute midpoint
    srl $t2, $t0, 1     # r / 2
    add $t2, $t1, $t2   # midpoint of row

    # if current idx < midpoint, try top right, else top left
    blt $a0, $t2, try_top_right_first_up

try_top_left_first_up:
    # $t1: top left cursor ( - r)
    sub $t1, $a0, $t0

    # see if top left is full
    sll $t2, $t1, 1     # multiply top left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_top_right_up     # if top left has smth, try right

    # top left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

try_top_right_up:
    addi $t5, $t0, -1
    beq $t4, $t5, up_failed # if last in row, skip

    addi $t1, $t1, 1    # top right cursor = top left cursor + 1
    
    # see if top right is full
    sll $t2, $t1, 1
    lb $t2, board($t2)

    bgez $t2, up_failed

    # top right is valid and free.. return index
    move $v0, $t1
    j exit_handle_up

try_top_right_first_up:
    # $t1: top right cursor ( - r + 1)
    sub $t1, $a0, $t0
    addi $t1, $t1, 1

    # see if top right is full
    sll $t2, $t1, 1     # multiply top right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_top_left_up     # if top right has smth, try left

    # top right is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

try_top_left_up:
    beqz $t4, up_failed    # if first in row, skip

    addi $t1, $t1, -1    # top left cursor = top right cursor - 1

    # see if top left is full
    sll $t2, $t1, 1     # multiply top left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, up_failed     # if top left has smth, stop

    # top left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

up_failed:
    move $v0, $a0

exit_handle_up:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra

## handle down
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_down:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # store row in $t0
    jal get_row_from_index
    move $t0, $v0

    # if row is last, leave
    beq $a1, 2, check_2player_lastrow
    beq $t0, 6, down_failed
    j continue_handle_down
check_2player_lastrow:
    beq $t0, 7, down_failed

continue_handle_down:
    # store first column number idx - (r * (r-1) / 2) - in $t1
    addi $t1, $t0, -1
    mulo $t1, $t0, $t1
    srl $t1, $t1, 1

    # store column number for idx
    sub $t2, $t0, $t1

    # compute midpoint
    srl $t3, $t0, 1     # r / 2
    add $t3, $t1, $t3   # midpoint of row

    # if current idx >= midpoint, try bottom right, else bottom left
    bge $a0, $t3, try_bottom_right_first

try_bottom_left_first:
    # try bottom left first (+ r)), then bottom right (+ r + 1))
    add $t1, $a0, $t0

    # see if bottom left is full
    sll $t2, $t1, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_bottom_right     # if bottom left has smth, try bottom right

    # bottom left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_down

try_bottom_right:
    # bottom right idx - add 1 to bottom left
    addi $t1, $t1, 1

    # see if bottom right is full
    sll $t2, $t1, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, down_failed   # if bottom right also full, nothing

    # bottom right is valid & free
    move $v0, $t1
    j exit_handle_down

try_bottom_right_first:
    # store bottom right cursor in $t1 (cursor + row)
    add $t1, $a0, $t0
    addi $t1, $t1, 1   

    # see if bottom right is full
    sll $t2, $t1, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_bottom_left     # if bottom right has smth, try bottom left

    # bottom right is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_down

try_bottom_left:
    # bottom left idx - sub 1 from bottom right
    addi $t1, $t1, -1

    # see if bottom left is full
    sll $t2, $t1, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, down_failed

    # bottom left is valid & free
    move $v0, $t1
    j exit_handle_down

down_failed:
    move $v0, $a0

exit_handle_down:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra

## -----------------------------------------------------

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

.data
newline: .asciiz"\n"

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