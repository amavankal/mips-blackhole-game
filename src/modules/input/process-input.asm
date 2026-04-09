#-----------------------------------------------------------------------
# process-input.asm
# Description: Contains subroutines that process user input characters
#   and determine their validity / type.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl is_go_character          # shared

.globl is_up_only_character     # home
.globl is_down_only_character   # home

.globl is_up_character          # game
.globl is_down_character        # game
.globl is_left_character        # game
.globl is_right_character       # game

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