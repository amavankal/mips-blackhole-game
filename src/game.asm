#-----------------------------------------------------------------------
# game.asm
# Description: Contains game subroutine, which runs a game with the
#   given number of players (only accepts 1 or 2). It draws the game on
#   the bitmap display by writing to graphics_board in driver.asm. 
#   It reads board data from the files in graphics/game (assembled and
#   listed in graphics-wrapper.asm). Displays results message at the 
#   end of the game.
#
#   Also contains get_user_selection subroutine, which is a helper
#   subroutine that allows for the user to select a spot on the board
#   interactively.
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

    ## display board to MMIO display if $s5 == 1
    bgt $s5, 1, skip_display_board
    move $a0, $s0
    li $a1, -1 # -1 means don't display temp spot 
    jal display_board

skip_display_board:
    j gameplay_loop

exit_gameplay_loop:
    ## calculate points - $v0 comp, $v1 p1, $a3 p2
    move $a0, $s0
    jal calculate_scores

    ## display results
    move $a0, $v0   # computer score
    move $a1, $v1   # player 1 score
    move $a2, $a3   # player 2 score
    move $a3, $s0   # game mode

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
