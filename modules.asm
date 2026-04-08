#-----------------------------------------------------------------------
# modules.asm
# Description: Contains useful subroutines that may be used throughout
#   the program.
#
# Subroutines:
#   display_string: 
#   is_go_character: 
#   is_up_only_character: 
#   is_down_only_character: 
#   is_up_character: 
#   is_down_character: 
#   is_left_character: 
#   is_right_character: 
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

## subroutines ##
.text
.globl display_string
.globl display_number
.globl is_go_character
.globl is_up_only_character
.globl is_down_only_character
.globl is_up_character
.globl is_down_character
.globl is_left_character
.globl is_right_character
.globl draw_turn_message
.globl draw_number
.globl erase_number
.globl draw_circle
.globl get_row_from_index

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
    bge $sp, $fp, exit_write_loop_number     # exit loop once gotten through array

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
exit_write_loop_number:
    # subroutine epilogue - take down stack frame
    move $sp, $fp
    lw $fp, 0($sp)
    addi $sp, $sp, 4

    # exit subroutine
    jr $ra

#########################################
### user input processing subroutines ###
#########################################

.data
## user input controls
up_only:    .ascii "wWaA"
down_only:  .ascii "sSdD"
go:         .ascii " \n\t"
up:         .ascii "wW"
down:       .ascii "sS"
left:       .ascii "aA"
right:      .ascii "dD"

.text

### check if character is one of the GO characters ###
# $a0 - character to check (doesn't modify $a0)
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
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_up_only_character:
    # store up address in $t0
    la $t0, up_only

    # check if it's "w"
    lb $t1, 0($t0)
    beq $a0, $t1, matches_up_only

    # check if it's "W"
    lb $t1, 1($t0)
    beq $a0, $t1, matches_up_only

    # check if it's "a"
    lb $t1, 2($t0)
    beq $a0, $t1, matches_up_only

    # check if it's "A"
    lb $t1, 3($t0)
    beq $a0, $t1, matches_up_only

    # no match
    li $v0, 0
    jr $ra

matches_up_only: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the DOWN ONLY characters ###
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_down_only_character:
    # store down address in $t0
    la $t0, down_only

    # check if it's "s"
    lb $t1, 0($t0)
    beq $a0, $t1, matches_down_only

    # check if it's "S"
    lb $t1, 1($t0)
    beq $a0, $t1, matches_down_only

    # check if it's "d"
    lb $t1, 2($t0)
    beq $a0, $t1, matches_down_only

    # check if it's "D"
    lb $t1, 3($t0)
    beq $a0, $t1, matches_down_only

    # no match
    li $v0, 0
    jr $ra

matches_down_only: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the UP characters ###
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_up_character:
    # store up address in $t0
    la $t0, up

    # check if it's a space
    lb $t1, 0($t0)
    beq $a0, $t1, matches_up

    # check if it's a newline
    lb $t1, 1($t0)
    beq $a0, $t1, matches_up

    # no match
    li $v0, 0
    jr $ra

matches_up: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the DOWN characters ###
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_down_character:
    # store up address in $t0
    la $t0, down

    # check if it's a space
    lb $t1, 0($t0)
    beq $a0, $t1, matches_down

    # check if it's a newline
    lb $t1, 1($t0)
    beq $a0, $t1, matches_down

    # no match
    li $v0, 0
    jr $ra

matches_down: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the LEFT characters ###
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_left_character:
    # store up address in $t0
    la $t0, left

    # check if it's a space
    lb $t1, 0($t0)
    beq $a0, $t1, matches_left

    # check if it's a newline
    lb $t1, 1($t0)
    beq $a0, $t1, matches_left

    # no match
    li $v0, 0
    jr $ra

matches_left: # there is a match
    li $v0, 1
    jr $ra

### check if character is one of the RIGHT characters ###
# $a0 - character to check (doesn't modify $a0)
# $v0 - 0 if false, 1 if true
is_right_character:
    # store up address in $t0
    la $t0, right

    # check if it's a space
    lb $t1, 0($t0)
    beq $a0, $t1, matches_right

    # check if it's a newline
    lb $t1, 1($t0)
    beq $a0, $t1, matches_right

    # no match
    li $v0, 0
    jr $ra

matches_right: # there is a match
    li $v0, 1
    jr $ra

#####################################################
################## GUI subroutines ##################
#####################################################

### DRAW TURN message ###
# $a0 - which player # (1 or 2): does p1 if any # but 2
# no return, just does the thing
draw_turn_message:
    ## store addresses of offsets
    li $t0, 2
    beq $a0, $t0, use_p2_addresses

    # use p1 addresses
    la $t0, p1_turn_offsets  # $t0: address of next offset for p2 msg
    la $t1, p1_turn_colors   # $t1: address of next color for p2 msg

    j draw_msg_loop

use_p2_addresses:
    la $t0, p2_turn_offsets  # $t0: address of next offset for p1 msg
    la $t1, p2_turn_colors   # $t1: address of next color for p1 msg

draw_msg_loop:
    lw $t2, 0($t0)                  # $t2: next offset
    bltz $t2, exit_draw_msg_loop    # exit if next offset is -1 (last)

    sll $t2, $t2, 2     # convert next offset to word offset
    lw $t3, 0($t1)      # $t3: next color

    # store color @ offset on board
    sw $t3, graphics_board($t2)

    # increment address of next offset + address of next color
    addi $t0, $t0, 4
    addi $t1, $t1, 4

    # loop
    j draw_msg_loop

exit_draw_msg_loop:
    jr $ra

### DRAW number ###
# draws number on the game board
# $a0 - number to draw
# $a1 - offset to draw it at (in pixels)
# $a2 - color
draw_number:
    # first load number's first offset
    la $t0, number_offsets
    addi $t1, $a0, -1       # -1 to make 0 indexed
    sll $t1, $t1, 2         # *4 to make word offset

    add $t0, $t0, $t1       # $t0 is addr of addr of first offset
    lw $t0, 0($t0)          # $t0 is addr of first offset

draw_number_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_draw_number_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a1, $t1
    sll $t1, $t1, 2

    # store color @ calculated offset
    sw $a2, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j draw_number_loop

exit_draw_number_loop:
    jr $ra

### ERASE number ###
# erases given number on the game board (for responsive spot selection)
# $a0 - number to erase
# $a1 - offset to erase it from (in pixels)
erase_number:
    # first load number's first offset
    la $t0, number_offsets
    addi $t1, $a0, -1       # -1 to make 0 indexed
    sll $t1, $t1, 2         # *4 to make word offset

    add $t0, $t0, $t1       # $t0 is addr of addr of first offset
    lw $t0, 0($t0)          # $t0 is addr of first offset

erase_number_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_erase_number_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a1, $t1
    sll $t1, $t1, 2

    # store color from game base @ calculated offset in final board
    lw $t2, game_base_frame($t1)
    sw $t2, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j erase_number_loop

exit_erase_number_loop:
    jr $ra

### DRAW CIRCLE ###
# $a0 - offset to erase circle from  (in pixels)
# $a1 - color
draw_circle:
    # first load circle's first offset
    la $t0, circle_offsets      # $t0 is addr of first offset

draw_circle_loop:
    # load next offset - break if -1 reached
    lw $t1, 0($t0)
    bltz $t1, exit_draw_circle_loop

    # add offset to given offset, then convert to word offset
    add $t1, $a0, $t1
    sll $t1, $t1, 2

    # store color @ calculated offset
    sw $a1, graphics_board($t1)

    # increment addr of offset
    addi $t0, $t0, 4

    # loop
    j draw_circle_loop

exit_draw_circle_loop:
    jr $ra

### GET ROW FROM INDEX ####
# helper for get_new_cursor_from_input; uses $t0
# brute force--highkey might be faster than floating point math
# $a0 - cursor
# $v0 - row
get_row_from_index:
    # check if row 1
    li $t0, 1
    bge $a1, $t0, not_row1
    # is row 1
    li $v0, 1
    jr $ra
not_row1:   # check if row 2
    li $t0, 3
    bge $a1, $t0, not_row2
    # is row 2
    li $v0, 2
    jr $ra
not_row2:   # check if row 3
    li $t0, 6
    bge $a1, $t0, not_row3
    # is row 3
    li $v0, 3
    jr $ra
not_row3:   # check if row 4
    li $t0, 10
    bge $a1, $t0, not_row4
    # is row 4
    li $v0, 4
    jr $ra
not_row4:   # check if row 5
    li $t0, 15
    bge $a1, $t0, not_row5
    # is row 5
    li $v0, 5
    jr $ra
not_row5:   # check if row 6
    li $t0, 21
    bge $a1, $t0, not_row6
    # is row 6
    li $v0, 6
    jr $ra
not_row6:
    # must be row 7
    li $v0, 7
    jr $ra