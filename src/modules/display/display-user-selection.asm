#-----------------------------------------------------------------------
# display-user-selection.asm
# Description: Contains subroutine that displays a user selection from
#   the home menu to the MMIO display.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl display_user_selection

.data
select_mode:        .asciiz "  SELECT GAME MODE: (Press RETURN to confirm)\n"

one_player_option:  .asciiz "    1 Player v. Computer\n"
two_player_option:  .asciiz "    2 Players v. Computer\n"
exit_option:        .asciiz "    Exit\n\n\n"

selected_one_player_option:  .asciiz "  > 1 Player v. Computer\n"
selected_two_player_option:  .asciiz "  > 2 Players v. Computer\n"
selected_exit_option:        .asciiz "  > Exit\n\n\n"

.text

### display user selection
# $a0 - user selection (0 = exit, 1 = 1-player, 2 = 2-player)
display_user_selection:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $fp, 4($sp)
    sw $s0, 0($sp)
    move $fp, $sp

    # move $a0 to $s0 for storage
    move $s0, $a0

    # print selection message
    la $a0, select_mode
    jal display_string

    # print player 1 option
    beq $s0, 1, select_one_player_option

    la $a0, one_player_option
    jal display_string

    j print_two_player

select_one_player_option:
    la $a0, selected_one_player_option
    jal display_string

    # print player 2 option
print_two_player:
    beq $s0, 2, select_two_player_option

    la $a0, two_player_option
    jal display_string

    j print_exit

select_two_player_option:
    la $a0, selected_two_player_option
    jal display_string
    
    # print exit option
print_exit:
    beq $s0, 0, select_exit_option

    la $a0, exit_option
    jal display_string

    j exit_display_user_selection

select_exit_option:
    la $a0, selected_exit_option
    jal display_string

exit_display_user_selection:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s0, 0($sp)
    lw $fp, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12

    jr $ra
