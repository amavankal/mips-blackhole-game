#-----------------------------------------------------------------------
# display-utils.asm
# Description: Contains subroutines that are used throughout the
#   program to display data to the MMIO display register.
#
# Author: Asha Mavankal
#-----------------------------------------------------------------------

.globl display_number
.globl display_string

.text

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


### write text to MMIO display ###
# $a0 - int to display
display_number:
    # subroutine prologue - set up stack frame
    addi $sp, $sp, -4
    sw $fp, 0($sp)
    move $fp, $sp

    # if number is 0, just print 0
    bnez $a0, calc_digits

    # number is 0, so just wait till write is ready & write
    li $t1, 0xFFFF000C          # address of display --> lui & ori
    li $t2, 0xFFFF0008          # address of control register

wait_ready_zero:
    lw $t4, 0($t2)
    andi $t4, $t4, 1    # isolate last bit
    beq $t4, $zero, wait_ready_zero

    li $t4, 48  # 0 is 48
    sb $t4, 0($t1)

    j exit_display_number

    # store number's digits on stack
calc_digits:
    beqz $a0, exit_calc_digits

    # div by 10, store rem on stack, result in self
    li $t0, 10
    div $a0, $t0

    # store remainder on stack
    mfhi $t0
    addi $sp, $sp, -1
    sb $t0, 0($sp)

    # set $a0 to result
    mflo $a0

    j calc_digits

exit_calc_digits:
    # write to display
    li $t1, 0xFFFF000C          # address of display --> lui & ori
    li $t2, 0xFFFF0008          # address of control register

write_loop_number:
    lb $t3, 0($sp)                    # load int byte @ $sp to $t3
    addi $t3, $t3, 48                 # add '0' to make it to ASCII
    bge $sp, $fp, exit_display_number  # exit loop once gotten through array

wait_ready_number:
    # check if can write to output; try again if can't
    lw $t4, 0($t2)
    andi $t4, $t4, 1    # isolate last bit
    beq $t4, $zero, wait_ready_number

    # can write, so write:
    sb $t3, 0($t1)

    # increment stack pointer
    addi $sp, $sp, 1

    j write_loop_number
exit_display_number:
    # subroutine epilogue - take down stack frame
    move $sp, $fp
    lw $fp, 0($sp)
    addi $sp, $sp, 4

    # exit subroutine
    jr $ra
