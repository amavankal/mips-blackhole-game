#-----------------------------------------------------------------------
# calculate-cursor.asm
# Description: Contains subroutines calculate cursor positions for the
#   game subroutine.
#
# Author: Asha Mavankal
#-----------------------------------------------------------------------

.globl find_first_free_cursor
.globl get_cursor_from_input

.text

## find first free cursor position
# $a0 - game mode
# $v0 - first free cursor
find_first_free_cursor:
    # index (also byte offset) in board
    li $t0, 0
find_cursor_pos_loop:
    # guard: if cursor goes above 42 or 56, some logic has gone wrong
    beq $a0, 2, validate_two_player

    # validate 1 player
    bge $t0, 42, find_free_cursor_error
    j check_cursor

validate_two_player:
    # validate 2 player
    bge $t0, 56, find_free_cursor_error

check_cursor:
    # load signed byte @ pos $t0 in board
    lb $t1, board($t0)
    bgez $t1, increment_find_cursor_pos_loop    # alr filled, keep looking

    # found free spot! $t1 = -1. so cursor pos is $t0 / 2
    srl $v0, $t0, 1
    jr $ra

increment_find_cursor_pos_loop:
    # increment position (by 2--skip 2nd num byte, only reading person byte)
    addi $t0, $t0, 2

    j find_cursor_pos_loop

find_free_cursor_error:
    # if there's an error, terminate execution
    li $v0, 10
    syscall
## -----------------------------------------------------

### CALCULATE CURSOR based on user input
# reads the board
# $a0 - user input character
# $a1 - current cursor
# $a2 - game mode
# $v0 - the resultant cursor
get_cursor_from_input:
    ## subroutine prologue -- set up stack frame
    addi $sp, $sp, -20
    sw $fp, 16($sp)
    sw $ra, 12($sp)
    sw $a2, 8($sp)  # game mode
    sw $a1, 4($sp)  # current cursor
    sw $a0, 0($sp)  # user input character
    move $fp, $sp

    # check left
    lw $a0, 0($sp)   # reload user input into $a0
    jal is_left_character
    bnez $v0, do_handle_left

    # check right
    lw $a0, 0($sp)
    jal is_right_character
    bnez $v0, do_handle_right

    # check up
    lw $a0, 0($sp)
    jal is_up_character
    bnez $v0, do_handle_up

    # check down
    lw $a0, 0($sp)
    jal is_down_character
    bnez $v0, do_handle_down

    # invalid selection: return same cursor
    move $v0, $a1
    j exit_get_cursor_from_input

do_handle_left:
    lw $a0, 4($sp)      # pass cursor
    lw $a1, 8($sp)      # pass game mode
    jal handle_left
    j exit_get_cursor_from_input

do_handle_right:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jal handle_right
    j exit_get_cursor_from_input

do_handle_up:
    lw $a0, 4($sp)
    jal handle_up
    j exit_get_cursor_from_input

do_handle_down:
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jal handle_down
    j exit_get_cursor_from_input

exit_get_cursor_from_input:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $ra, 12($sp)
    lw $fp, 16($sp)
    addi $sp, $sp, 20

    jr $ra
## -----------------------------------------------------

## handle left
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_left:
    # store current pos in $t0
    move $t0, $a0

    # shift left
    addi $t0, $t0, -1
    bgez $t0, left_loop
    beq $a1, 2, wrap_2players
    li $t0, 20   # wrap around if needed- set $t0 to max idx
    j left_loop
wrap_2players:
    li $t0, 27   # wrap around if needed- set $t0 to max idx

left_loop:
    beq $t0, $a0, exit_left_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, board($t1)   # get player num @ index $t0
    bltz $t2, exit_left_loop        # if free spot (player num = -1), done

    # increment loop: move left
    addi $t0, $t0, -1
    bgez $t0, left_loop
    beq $a1, 2, wrap_2players2

    li $t0, 20   # wrap around if needed - set $t0 to max idx
    j left_loop

wrap_2players2:
    li $t0, 27  # wrap around if needed - set $t0 to max idx
    j left_loop

exit_left_loop:
    # put results in $v0 and exit
    move $v0, $t0
    jr $ra
## -----------------------------------------------------

## handle right
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_right:
    # store current pos in $t0
    move $t0, $a0

    # shift right
    addi $t0, $t0, 1
    beq $a1, 2, wrap_check_2players
    blt $t0, 21, right_loop
    j wrap
wrap_check_2players:
    blt $t0, 28, right_loop
wrap:
    li $t0, 0   # wrap around if needed- set $t0 to min idx

right_loop:
    beq $t0, $a0, exit_right_loop   # if looped back to self, can't go further

    # check for free spot
    sll $t1, $t0, 1                 # byte offset = index * 2 (player num, value)
    lb $t2, board($t1)   # get player num @ index $t0
    bltz $t2, exit_right_loop       # if free spot (player num = -1), done

    # increment loop: move right
    addi $t0, $t0, 1
    li $t1, 21
    beq $a1, 2, wrap_check_2players2
    blt $t0, $t1, right_loop
    j wrap2
wrap_check_2players2:
    blt $t0, 28, right_loop

wrap2:
    li $t0, 0  # wrap around if needed - set $t0 to min idx
    j right_loop  # loop

exit_right_loop:
    move $v0, $t0
    jr $ra
## -----------------------------------------------------

## handle up
# $a0 - cursor position
# $v0 - resultant cursor
handle_up:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # store row in $t0
    jal get_row_from_index
    move $t0, $v0

    # if row is first, leave
    beq $t0, 1, up_failed

continue_handle_up:
    # store column number idx - (r * (r-1) / 2) - in $t1
    addi $t1, $t0, -1
    mulo $t1, $t0, $t1
    srl $t1, $t1, 1 # 1st idx in row r

    # column # for idx (cursor - first in row)
    sub $t4, $a0, $t1

    # compute midpoint
    srl $t2, $t0, 1     # r / 2
    add $t2, $t1, $t2   # midpoint of row

    # if current idx < midpoint, try top right, else top left
    blt $a0, $t2, try_top_right_first_up

try_top_left_first_up:
    # $t1: top left cursor ( - r)
    sub $t1, $a0, $t0

    # see if top left is full
    sll $t2, $t1, 1     # multiply top left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_top_right_up     # if top left has smth, try right

    # top left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

try_top_right_up:
    addi $t5, $t0, -1
    beq $t4, $t5, up_failed # if last in row, skip

    addi $t1, $t1, 1    # top right cursor = top left cursor + 1
    
    # see if top right is full
    sll $t2, $t1, 1
    lb $t2, board($t2)

    bgez $t2, up_failed

    # top right is valid and free.. return index
    move $v0, $t1
    j exit_handle_up

try_top_right_first_up:
    # $t1: top right cursor ( - r + 1)
    sub $t1, $a0, $t0
    addi $t1, $t1, 1

    # see if top right is full
    sll $t2, $t1, 1     # multiply top right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_top_left_up     # if top right has smth, try left

    # top right is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

try_top_left_up:
    beqz $t4, up_failed    # if first in row, skip

    addi $t1, $t1, -1    # top left cursor = top right cursor - 1

    # see if top left is full
    sll $t2, $t1, 1     # multiply top left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, up_failed     # if top left has smth, stop

    # top left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_up

up_failed:
    move $v0, $a0

exit_handle_up:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra
## -----------------------------------------------------

## handle down
# $a0 - cursor position
# $a1 - game mode
# $v0 - resultant cursor
handle_down:
    ## subroutine prologue -- build stack frame
    addi $sp, $sp, -8
    sw $fp, 4($sp)
    sw $ra, 0($sp)
    move $fp, $sp

    # store row in $t0
    jal get_row_from_index
    move $t0, $v0

    # if row is last, leave
    beq $a1, 2, check_2player_lastrow
    beq $t0, 6, down_failed
    j continue_handle_down
check_2player_lastrow:
    beq $t0, 7, down_failed

continue_handle_down:
    # store first column number idx - (r * (r-1) / 2) - in $t1
    addi $t1, $t0, -1
    mulo $t1, $t0, $t1
    srl $t1, $t1, 1

    # store column number for idx
    sub $t2, $t0, $t1

    # compute midpoint
    srl $t3, $t0, 1     # r / 2
    add $t3, $t1, $t3   # midpoint of row

    # if current idx >= midpoint, try bottom right, else bottom left
    bge $a0, $t3, try_bottom_right_first

try_bottom_left_first:
    # try bottom left first (+ r)), then bottom right (+ r + 1))
    add $t1, $a0, $t0

    # see if bottom left is full
    sll $t2, $t1, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_bottom_right     # if bottom left has smth, try bottom right

    # bottom left is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_down

try_bottom_right:
    # bottom right idx - add 1 to bottom left
    addi $t1, $t1, 1

    # see if bottom right is full
    sll $t2, $t1, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, down_failed   # if bottom right also full, nothing

    # bottom right is valid & free
    move $v0, $t1
    j exit_handle_down

try_bottom_right_first:
    # store bottom right cursor in $t1 (cursor + row)
    add $t1, $a0, $t0
    addi $t1, $t1, 1   

    # see if bottom right is full
    sll $t2, $t1, 1     # multiply bottom right cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, try_bottom_left     # if bottom right has smth, try bottom left

    # bottom right is valid, and free.. return that index
    move $v0, $t1
    j exit_handle_down

try_bottom_left:
    # bottom left idx - sub 1 from bottom right
    addi $t1, $t1, -1

    # see if bottom left is full
    sll $t2, $t1, 1     # multiply bottom left cursor * 2 for idx in board
    lb $t2, board($t2)

    bgez $t2, down_failed

    # bottom left is valid & free
    move $v0, $t1
    j exit_handle_down

down_failed:
    move $v0, $a0

exit_handle_down:
    ## subroutine epilogue -- take down stack frame
    move $sp, $fp
    lw $ra, 0($sp)
    lw $fp, 4($sp)
    addi $sp, $sp, 8

    jr $ra
