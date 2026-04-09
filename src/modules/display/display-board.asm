#-----------------------------------------------------------------------
# display-board.asm
# Description: Contains subroutine that displays the board state to
#   the MMIO Display.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl display_board

.data

empty_space:  .asciiz "----"
comp_space:   .asciiz "c: "
p1_space:     .asciiz "1: "
p2_space:     .asciiz "2: "
newline:      .asciiz "\n"
newline2:      .asciiz "\n\n"
space:        .asciiz " "
block:        .asciiz "  "

p1_turn:      .asciiz "Player 1's turn: \n"
p2_turn:      .asciiz "Player 2's turn: \n"
temp_buffer:  .asciiz "[  ]"

.text

## display board
# $a0 - game mode
# $a1 - temp cursor position (if -1 just print regular board; won't read folowing args)
# $a2 - number to display (only used if $a0 >= -1)
# $a3 - user # (only used if $a0 >= -1)
display_board:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $fp, 24($sp)
    sw $s1, 20($sp)    # $s1 - current row in board
    sw $s2, 16($sp)     # $s2 - index on board
    sw $s3, 12($sp)     # $s3 - # rows to print
    sw $s4, 8($sp)     # $s4 - LCV to print columns
    sw $s5, 4($sp)     # $s5 - temp cursor pos
    sw $s6, 0($sp)     # $s6 - number to display
    move $fp, $sp

    ## initialize variables
    li $s1, 1   # display board LCV (current row to print)
    li $s2, 0   # index of board value to print
    move $s5, $a1   # temp index to draw

    # $s3: load num rows, based on $a0, game mode
    beq $a0, 2, load_7_rows
    li $s3, 6   # 1 player mode; load 6 rows
    j print_starting_newline
load_7_rows:
    li $s3, 7   # 2 player mode; load 7 rows

print_starting_newline:
    # first print 2 newlines to display
    la $a0, newline2
    jal display_string

    ## then if $a1 >= 0, print user turn message & intialize $s5/$s6
    bltz $a1, display_board_loop

    # initialize $s6
    move $s6, $a2

    # print turn messages
    beq $a3, 2, print_two_message

    la $a0, p1_turn # print one message
    j print_turn_message
print_two_message:  # print two message
    la $a0, p2_turn
print_turn_message:
    jal display_string

## loops through rows on board and displays them
display_board_loop:
    bgt $s1, $s3, exit_display_board_loop   # if LCV > num rows, exit loop

    ## print (num rows - this row) * 2 spaces
    sub $a0, $s3, $s1
    sll $a0, $a0, 2     # $a0: num spaces to print

    jal display_spaces

    ## print spots in this row (space [char] space space)
    # calc first index of next row: loop break condition
    add $s4, $s1, 1
    mulo $s4, $s4, $s1
    srl $s4, $s4, 1     # $s4: index of first spot in next row

write_spots_loop:
    # exit once reach next row
    bge $s2, $s4, exit_write_spots_loop

    # print block
    la $a0, block
    jal display_string

    # if s2 == temp cursor, call, temp display spot
    beq $s2, $s5, temp_display

    # print appropriate spot value (4 chars long)
    # $a0 - idx of spot to display
    move $a0, $s2
    jal display_spot
    j end_temp_display

temp_display:
    # print temp spot value
    # $a0 - value to display
    move $a0, $s6
    jal display_temp_spot

end_temp_display:
    # print block
    la $a0, block
    jal display_string

    # increment loop & loop
    addi $s2, $s2, 1
    j write_spots_loop

exit_write_spots_loop:
    ## print 2 newlines
    la $a0, newline2
    jal display_string

    ## increment display board loop
    addi $s1, $s1, 1

    # loop
    j display_board_loop

exit_display_board_loop:

    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s6, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $fp, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32

    jr $ra

## helper subroutine: display n spaces
# $a0 - # spaces to write
display_spaces:
    # initialize variables
    li $t0, 0       # LCV
    lb $t1, space   # $t6: value of space

    # read / write variables
    li $t2, 0xFFFF0008          # address of control register
    li $t3, 0xFFFF000C          # address of display print register

write_space_loop:
    beq $t0, $a0, exit_write_space_loop   # exit loop once printed desired spaces

board_wait_ready:
    # check if can write to output; try again if can't
    lw $t4, 0($t2)  # control value
    andi $t4, $t4, 1    # isolate last bit in control
    beqz $t4, board_wait_ready

    # can write, so write:
    sb $t1, 0($t3)

    # increment $t0 space count by 1
    addi $t0, $t0, 1
    j write_space_loop

exit_write_space_loop:
    jr $ra


## helper subroutine: display character
# $a0 - index of spot to display
display_spot:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $fp, 8($sp)
    sw $s0, 4($sp)  # spot player num
    sw $s1, 0($sp)  # spot value
    move $fp, $sp

    # convert $a0 to 2-byte index
    sll $t0, $a0, 1

    # read player number & value from board
    lb $s0, board($t0)  # player num
    addi $t0, $t0, 1
    lb $s1, board($t0)  # value

    # decide what to print based on player #
    bltz $s0, print_empty
    beq $s0 0, print_computer
    beq $s0, 1, print_p1
    beq $s0, 2, print_p2

print_empty:    # print empty then skip to end
    la $a0, empty_space
    jal display_string
    j exit_display_spot

print_computer: # print c: then print value
    la $a0, comp_space
    jal display_string
    j print_value

print_p1:   # print 1: then print value
    la $a0, p1_space
    jal display_string
    j print_value

print_p2:   # print 2: then print value
    la $a0, p2_space
    jal display_string
    j print_value

print_value:    # print value for non-empty spots
    move $a0, $s1
    jal display_number

exit_display_spot:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $fp, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16

    jr $ra

## helper subroutine: display temp spot [# ]
# $a0 - value to display
display_temp_spot:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $fp, 0($sp)
    move $fp, $sp

    # print temp spot
    beq $a0, 10, print_10
    
    # print value for 1-9
    addi $t0, $a0, 48   # convert value to char
    la $a0, temp_buffer
    sb $t0, 1($a0)
    jal display_string
    j exit_display_temp_spot

print_10:
    # print value for 10
    la $a0, temp_buffer
    li $t0, 49
    sb $t0, 1($a0)
    li $t0, 48
    sb $t0, 2($a0)
    jal display_string

    li $t0, 32 # space
    sb $t0, 2($a0)

exit_display_temp_spot:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $fp, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

    jr $ra
