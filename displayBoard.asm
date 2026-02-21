#-----------------------------------------------------------------------
# displayBoard.asm
# description: macros to update board with given values
#   
# draw_board (%board_address, data_address): 
#
# update_board (%board_address, delta_addresses):
#
# author: Asha Mavankal
# last updated: 20 Feb 2026
#-----------------------------------------------------------------------

# board address is the start of 256x256 color array
.macro draw_board (%board_address, %data_address)
    la $t0, %board_address # where to write data
    la $t1, %data_address   # where to read data

    li $t2, 0   # LCV
loop:
    beq $t2, 65536, exit_loop

    lw $t3, 0($t1)
    sw $t3, 0($t0)

    addi $t0, $t0, 4    # next word
    addi $t1, $t1, 4    # next word
    addi $t2, $t2, 1    # LCV += 1

    j loop

exit_loop:
.end_macro

# update board: efficient; uses deltas
.macro update_board (%board_address, %delta_addresses)
    # TODO
.end_macro
