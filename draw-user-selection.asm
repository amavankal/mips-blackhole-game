### modules for game.asm


.text
.globl draw_user_selection
.globl erase_user_selection
.globl draw_final_user_selection

## draw selector circle & temp num for given user
#   in given game mode, given the cursor position
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