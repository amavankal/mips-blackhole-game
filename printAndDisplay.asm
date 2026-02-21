#-----------------------------------------------------------------------
# printAndDisplay.asm
# description: macros to display message w/ MIPS' MMIO simulator or
#   to display message in standard output
#   
# display_text (%start_address): basically, it loops 
#   through your string from given start address, and it waits for 
#   display control to be ready (1), before printing a character. 
#   The argument must be a data memory location (like a label, for 
#   example), and it should point to a **NULL-TERMINATED** string.
#
# print_text (%start_address): prints text to standard output
#   using Mars' syscalls
#
# author: Asha Mavankal
# last updated: 20 Feb 2026
#-----------------------------------------------------------------------

# DISPLAY_TEXT - will stall if MMIO is not connected
.macro display_text (%start_address)
    la $t0, %start_address     # store start address in $t0
    li $t1, 0xFFFF000C      # address of display --> lui & ori
    li $t2, 0xFFFF0008      # address of control register

loop:
    lbu $t3, 0($t0)     # load character byte @ address to $t3
    andi $t3, 0x000000FF # isolate last byte
    beq $t3, $zero, exit_loop   # check if null

wait_ready:
    # check if can write to output; try again if can't
    lw $t4, 0($t2)
    andi $t4, $t4, 1    # isolate last bit
    beq $t4, $zero, wait_ready

    # can write, so write:
    sb $t3, 0($t1)

    # increment $t0 address by 1 byte
    addi $t0, $t0, 1
    j loop
exit_loop:
.end_macro

# PRINT_TEXT
.macro print_text (%start_address)
    li $v0, 4
    la $a0, %start_address
    syscall
.end_macro
