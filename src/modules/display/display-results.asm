#-----------------------------------------------------------------------
# display-results.asm
# Description: Contains subroutine that displays the results of a game
#   to the MMIO Display.
#
# Author: Asha Mavankal
#-----------------------------------------------------------------------

.globl display_results

.data
player1_score:      .asciiz "\nPlayer 1 score: "
player2_score:      .asciiz "\nPlayer 2 score: "
computer_score:     .asciiz "\nComputer score: "

computer_wins:      .asciiz "\n\nComputer won! Better luck next time :)\n"
player1_wins:       .asciiz "\n\nPlayer 1 won! Congratulations!\n"
player2_wins:       .asciiz "\n\nPlayer 2 won! Congratulations!\n"

back_home:          .asciiz "\nPress RETURN, TAB, or SPACE to go back home\n"

.text

## display results
# $a0 - computer score
# $a1 - player 1 score
# $a2 - player 2 score
# $a3 - game mode
display_results:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -24
    sw $fp, 20($sp)
    sw $ra, 16($sp)
    sw $a0, 12($sp)  # computer
    sw $a1, 8($sp)  # player 1
    sw $a2, 4($sp)  # player 2
    sw $a3, 0($sp)  # game mode
    move $fp, $sp

    # display computer score
    la $a0, computer_score
    jal display_string

    lw $a0, 12($sp)
    jal display_number

    # display p1 score
    la $a0, player1_score
    jal display_string

    lw $a0, 8($sp)
    jal display_number

    # display p2 score, if 2 player game
    lw $t0, 0($sp)
    bne $t0, 2, skip_display_p2score
    la $a0, player2_score
    jal display_string

    lw $a0, 4($sp)
    jal display_number

skip_display_p2score:
    ## find the lowest score
    lw $t0, 12($sp)  # computer score
    lw $t1, 8($sp)  # player 1 score
    lw $t2, 4($sp)  # player 2 score

    move $t4, $t0     # set minimum to computer score
    li $t5, 0         # index of minimum (comp)
    bgt $t1, $t4, check_p2

    # $t1 <= min, so set minimum to $t1
    move $t4, $t1
    li $t5, 1

check_p2:
    # only check p2 score if game mode == 2
    lw $t6, 0($sp)
    bne $t6, 2, finish_find_minimum
    bgt $t2, $t4, finish_find_minimum

    # $t2 <= min, so set minimum to $t2
    move $t4, $t2
    li $t5, 2

finish_find_minimum:
    # display winner to MMIO display
    beq $t5, 0, display_computer_win
    beq $t5, 1, display_player1_win
    beq $t5, 2, display_player2_win

display_computer_win:
    la $a0, computer_wins
    jal display_string
    j end_display_winner

display_player1_win:
    la $a0, player1_wins
    jal display_string
    j end_display_winner

display_player2_win:
    la $a0, player2_wins
    jal display_string
    j end_display_winner

end_display_winner:

    # draw win message on GUI
    move $a0, $t5
    jal draw_win_message

    # draw back to home message on GUI
    jal draw_home_message

    # draw go back home message on MMIO display
    la $a0, back_home
    jal display_string

    ## subroutine epilogue -- restore stack frame and return
    move $sp, $fp
    lw $ra, 16($sp)
    lw $fp, 20($sp)
    addi $sp, $sp, 24

    jr $ra