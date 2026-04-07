

## subroutines ##
.text
.globl display_string
.globl is_go_character
.globl is_up_only_character
.globl is_down_only_character

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

#########################################
### user input processing subroutines ###
#########################################

.data
## user input controls
up_only:
    .ascii "wWaA"
down_only:
    .ascii "sSdD"
go:
    .ascii " \n\t"

.text

### check if character is one of the GO characters ###
# $a0 - character to check
# $v0 - 0 if false, 1 if true
is_go_character:
    # store go address in $t0
    la $t0, go

    # check if it's a space
    lb $t1, 0($t0)
    beq $a0, $t1, matches_go

    # check if it's a newline
    lb $t1, 1($t0)
    beq $a0, $t1, matches_go

    # check if it's a tab
    lb $t1, 2($t0)
    beq $a0, $t1, matches_go

    # no match
    li $v0, 0
    jr $ra

matches_go: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the UP ONLY characters ###
# $a0 - character to check
# $v0 - 0 if false, 1 if true
is_up_only_character:
    # store up address in $t0
    la $t0, up

    # check if it's "w"
    lb $t1, 0($t0)
    beq $a0, $t1, matches_up

    # check if it's "W"
    lb $t1, 1($t0)
    beq $a0, $t1, matches_up

    # check if it's "a"
    lb $t1, 2($t0)
    beq $a0, $t1, matches_up

    # check if it's "A"
    lb $t1, 3($t0)
    beq $a0, $t1, matches_up

    # no match
    li $v0, 0
    jr $ra

matches_up: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the DOWN ONLY characters ###
# $a0 - character to check
# $v0 - 0 if false, 1 if true
is_down_only_character:
    # store down address in $t0
    la $t0, down

    # check if it's "s"
    lb $t1, 0($t0)
    beq $a0, $t1, matches_down

    # check if it's "S"
    lb $t1, 1($t0)
    beq $a0, $t1, matches_down

    # check if it's "d"
    lb $t1, 2($t0)
    beq $a0, $t1, matches_down

    # check if it's "D"
    lb $t1, 3($t0)
    beq $a0, $t1, matches_down

    # no match
    li $v0, 0
    jr $ra

matches_down: # there is a match
    li $v0, 1
    jr $ra