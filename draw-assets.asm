### drawing modules for game.asm


.text
.globl draw_user_selection
.globl erase_user_selection
.globl draw_final_user_selection
.globl draw_win_message
.globl draw_home_message

## draw selector circle & temp num for given user
#   in given game mode, given the cursor position
#  also draw board to MMIO display
# $a0 - game mode
# $a1 - user #
# $a2 - cursor position
# $a3 - number to draw
draw_user_selection:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -24
    sw $fp, 20($sp)
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    move $fp, $sp

    # store arguments
    move $s0, $a0   # game mode
    move $s1, $a1   # user #
    move $s2, $a2   # cursor position
    move $s3, $a3   # number to draw

    ## first call method to display selection to MMIO
    move $a0, $s0
    move $a1, $s2   # pass cursor position
    move $a2, $s3   # pass number to draw
    move $a3, $s1   # pass user # (1 or 2)
    jal display_board

    ## determine what to draw based on game mode
    beq $s0, 2, draw_two_player_selections

    ## draw 1 player selections
    # draw selector circle
    sll $a0, $s2, 2             # $a0 - offset, based on cursor pos
    lw $a0, one_player_block_offsets($a0)
    lw $a1, selected_circle_color
    jal draw_circle

    # draw number: temp
    move $a0, $s3       # $a0 - num to draw
    sll $a1, $s2, 2
    lw $a1, one_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    lw $a2, player1_color_temp  # $a2 - color
    jal draw_number

    j exit_draw_user_selection

draw_two_player_selections:
    ## draw 2 player selections
    # draw selector circle
    sll $a0, $s2, 2             # $a0 - offset, based on cursor pos
    lw $a0, two_player_block_offsets($a0)
    lw $a1, selected_circle_color
    jal draw_circle

    # draw number: load number & offset
    move $a0, $s3       # $a0 - num to draw
    sll $a1, $s2, 2
    lw $a1, two_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    
    # load color based on player #
    beq $s1, 2, use_player2_color
        lw $a2, player1_color_temp
        j call_draw_number
    use_player2_color:
        lw $a2, player2_color_temp  # $a2 - color
call_draw_number:
    jal draw_number

exit_draw_user_selection:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    lw $fp, 20($sp)
    addi $sp, $sp, 24

    jr $ra
## -----------------------------------------------------

## erase selector circle & temp num for given user
#   in given game mode, given the cursor position
# $a0 - game mode
# $a1 - cursor position
# $a2 - number to erase
erase_user_selection:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -20
    sw $fp, 16($sp)
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)
    move $fp, $sp

    # store arguments
    move $s0, $a0   # game mode
    move $s1, $a1   # cursor position
    move $s2, $a2   # number to erase

    ## determine what to erase based on game mode
    beq $s0, 2, erase_two_player_selections

    ## erase 1 player selections
    # erase original circle
    sll $a0, $s1, 2             # $a0 - offset, based on cursor pos
    lw $a0, one_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    # erase number: temp
    move $a0, $s2       # $a0 - num to erase
    sll $a1, $s1, 2
    lw $a1, one_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    jal erase_number

    j exit_erase_user_selection

erase_two_player_selections:
    ## erase 2 player selections
    # erase selector circle
    sll $a0, $s1, 2        # $a0 - offset, based on cursor pos
    lw $a0, two_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    # erase number: load number & offset
    move $a0, $s2       # $a0 - num to erase
    sll $a1, $s1, 2
    lw $a1, two_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    jal erase_number

exit_erase_user_selection:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    lw $fp, 16($sp)
    addi $sp, $sp, 20

    jr $ra
## -----------------------------------------------------

## draw final circle & permanent num for given user
#   in given game mode, given the cursor position
# $a0 - game mode
# $a1 - user #
# $a2 - cursor position
# $a3 - number to draw
draw_final_user_selection:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -24
    sw $fp, 20($sp)
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    move $fp, $sp

    # store arguments
    move $s0, $a0   # game mode
    move $s1, $a1   # user #
    move $s2, $a2   # cursor position
    move $s3, $a3   # number to draw

    ## determine what to draw based on game mode
    beq $s0, 2, draw_final_two_player_selections

    ## draw 1 player selections
    # draw selector circle
    sll $a0, $s2, 2             # $a0 - offset, based on cursor pos
    lw $a0, one_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    # draw number: final
    move $a0, $s3       # $a0 - num to draw
    sll $a1, $s2, 2
    lw $a1, one_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    lw $a2, player1_color  # $a2 - color
    jal draw_number

    j exit_draw_final_user_selection

draw_final_two_player_selections:
    ## draw 2 player selections
    # draw selector circle
    sll $a0, $s2, 2             # $a0 - offset, based on cursor pos
    lw $a0, two_player_block_offsets($a0)
    lw $a1, circle_color
    jal draw_circle

    # draw number: load number & offset
    move $a0, $s3       # $a0 - num to draw
    sll $a1, $s2, 2
    lw $a1, two_player_block_offsets($a1)   # $a1 - offset, based on cursor pos
    
    # load color based on player #
    beq $s1, 2, use_player2_color_final
        lw $a2, player1_color
        j call_draw_number
    use_player2_color_final:
        lw $a2, player2_color  # $a2 - color
call_draw_number_final:
    jal draw_number

exit_draw_final_user_selection:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    lw $fp, 20($sp)
    addi $sp, $sp, 24

    jr $ra
## -----------------------------------------------------

## draw win message on GUI
# $a0 - player # of who won
draw_win_message:
    beq $a0, 0, load_computer_wins
    beq $a0, 1, load_player1_wins
    beq $a0, 2, load_player2_wins

load_computer_wins:
    la $t0, computer_win_offsets
    la $t1, computer_win_colors
    j draw_win_message_loop

load_player1_wins:
    la $t0, player1_win_offsets
    la $t1, player1_win_colors
    j draw_win_message_loop

load_player2_wins:
    la $t0, player2_win_offsets
    la $t1, player2_win_colors

    ## loop to draw the win message
draw_win_message_loop:
    lw $t2, 0($t0)                         # $t2: next offset
    bltz $t2, exit_draw_win_message_loop   # exit if next offset is -1 (last)

    sll $t2, $t2, 2     # convert next offset to word offset
    lw $t3, 0($t1)      # $t3: next color

    # store color @ offset on board
    sw $t3, graphics_board($t2)

    # increment address of next offset + address of next color
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j draw_win_message_loop

exit_draw_win_message_loop:
    jr $ra
## -----------------------------------------------------

## draw home message on GUI
draw_home_message:
    la $t0, back_home_offsets
    la $t1, back_home_colors

    ## loop to draw the home message
home_message_loop:
    lw $t2, 0($t0)                     # $t2: next offset
    bltz $t2, exit_home_message_loop   # exit if next offset is -1 (last)

    sll $t2, $t2, 2     # convert next offset to word offset
    lw $t3, 0($t1)      # $t3: next color

    # store color @ offset on board
    sw $t3, graphics_board($t2)

    # increment address of next offset + address of next color
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j home_message_loop

exit_home_message_loop:
    jr $ra
## -----------------------------------------------------