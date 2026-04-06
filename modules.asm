

## subroutines ##
.text
.globl display_string

### write message to MMIO display ###
# $a0 - address of string to display
# modifies temp registers $t0 - $t4
display_string:
    move $t0, $a0               # store start address in $t0
    li $t1, 0xFFFF000C          # address of display --> lui & ori
    li $t2, 0xFFFF0008          # address of control register

write_loop:
    lbu $t3, 0($t0)                   # load character byte @ address to $t3
    andi $t3, 0x000000FF              # isolate last byte
    beq $t3, $zero, exit_write_loop   # exit loop if last byte is null

wait_ready:
    # check if can write to output; try again if can't
    lw $t4, 0($t2)
    andi $t4, $t4, 1    # isolate last bit
    beq $t4, $zero, wait_ready

    # can write, so write:
    sb $t3, 0($t1)

    # increment $t0 address by 1 byte
    addi $t0, $t0, 1
    j write_loop
exit_write_loop:
    # exit subroutine
    jr $ra
