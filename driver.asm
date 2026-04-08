#-----------------------------------------------------------------------
# driver.asm
# Description: driver for Black Hole game.
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.data

.globl graphics_board

# graphics_board: 0x10010000. Reserved space used for MMIO
graphics_board:
	.space 262144 # reserve 256 px * 256 px * 4 bytes each for colors

welcome_and_instructions:
	.ascii	"\n#######################################################\n\n"
	.ascii	"            Welcome to the Black Hole Game!\n\n"
	.ascii	"#######################################################\n\n"
instructions:
	.ascii "Instructions: Use WASD keys to navigate, and press RETURN, TAB, or SPACE to select.\n\n"
    .ascii "Take turns with the computer and optionally another player selecting a spot in the\n"
    .ascii "pyramidal game board to enter the numbers 1-10 (1 player mode) or 1-9 (2 player mode).\n"
    .ascii "The goal of this game is to have the smallest sum of numbers surrounding the one remaining\n"
    .ascii "empty spot on the game board (the black hole).\n\n"
    .ascii "(Note: regarding WASD navigation, if you are having trouble with the up/down W/S keys\n"
    .ascii "once the board fills up (since they have limited jumping range), the left and right keys\n"
    .asciiz "A/D will ALWAYS work to access any spot on the board)\n\n"

how_to_set_up:
	.ascii	"\n############################################################################\n\n"
	.ascii	"    Hi! Welcome to the Black Hole game!\n\n"
	.ascii	"    This game uses MARS' bitmap display and MMIO simulator tools to\n"
	.ascii	"    display graphics and utilize non-blocking I/O. In order to play,\n"
	.ascii	"    you will need to set up these tools. Here's how:\n\n"
	.ascii	"  Bitmap display\n"
	.ascii	"    (1) go to [Tools] in the MARS Menu bar. Ex:\n\n"
	.ascii	"        File    Edit    Run     Settings   *Tools*   Help\n\n"
	.ascii	"    (2) select [Bitmap Display] from the dropdown. Ex:\n\n"
	.ascii	"        BHT Simulator\n"
	.ascii	"     >> Bitmap Display\n"
	.ascii	"        Data Cache Simulator\n"
	.ascii	"        ...\n\n"
	.ascii	"    (3) Set the display values as follows:\n\n"
	.ascii	"        Unit Width in Pixels:      2\n"
	.ascii	"        Unit Height in Pixels:     2\n"
	.ascii	"        Display Width in Pixels:   512\n"
	.ascii	"        Display Height in Pixels:  512\n"
	.ascii	"        Base address for display:  0x10010000 (static data)\n\n"
	.ascii	"    (4) [IMPORTANT] Then, hit the [Connect to MIPS] button\n"
	.ascii	"        at the bottom left of the window. You may also want to\n"
	.ascii	"        resize the window to see the full 512x512 square frame.\n\n"
	.ascii	"  MMIO Simulator\n"
	.ascii	"    (1) go to [Tools] in the MARS Menu bar again.\n\n"
	.ascii	"    (2) This time, select [Keyboard and Display MMIO Simulator] from the\n"
	.ascii	"        dropdown. Ex:\n\n"
	.ascii	"        BHT Simulator\n"
	.ascii	"        Bitmap Display\n"
	.ascii	"        Data Cache Simulator\n"
	.ascii	"        Digital Lab Sim\n"
	.ascii	"        Floating Point Representation\n"
	.ascii	"        Instruction Counter\n"
	.ascii	"        Instruction Statistics\n"
	.ascii	"        Introduction to Tools\n"
	.ascii	"     >> Keyboard and Display MMIO Simulator\n"
	.ascii	"        Mars Bot\n"
	.ascii	"        ...\n\n"
	.ascii	"    (3) [IMPORTANT] Once you see the MMIO simulator, hit the [Connect\n"
	.ascii	"        to MARS] button on the bottom left of the window. You may want to\n"
	.ascii	"        resize the window so you can see the DISPLAY box (top box), the\n"
	.ascii	"        bitmap display box, and the KEYBOARD input box (bottom box).\n\n"
	.ascii	"        From now on, read the instructions in the DISPLAY box and enter all\n"
	.ascii	"        inputs into the KEYBOARD input box. Have fun playing!\n\n"
	.asciiz	"############################################################################\n\n"

.text

.globl main
main:
    # print how to use message to console
    li $v0, 4
    la $a0, how_to_set_up
    syscall

game_loop:
    # display welcome message to MMIO Display
    la $a0, welcome_and_instructions
    jal display_string

    # run HOME animation / input loop
    jal home

    # user's choice is stored in $v0-- make decision based on that
    beqz $v0, exit_termination  # check if user selected 0: exit

    # only choices are 1 or 2 now
    move $a0, $v0   # parameters for game subroutine
    jal game

    # keep looping
    j game_loop

exit_termination:
    # exit termination
    li $v0, 10
    syscall