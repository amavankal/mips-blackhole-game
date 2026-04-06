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
.globl one_player_board
.globl two_player_board

# graphics_board: 0x10010000. Reserved space used for MMIO
graphics_board:
	.space 262144 # reserve 256 px * 256 px * 4 bytes each for colors

# boards: 21 and 28 spots respectively. Each spot has 2 bytes: 1st byte
#       is player # (0 = comp, 1, 2). 2nd byte is value (1-10 for one, 1-9 for two)
one_player_board:
    .byte 0 : 42
two_player_board:
    .byte 0 : 56

welcome_and_instructions:
	.ascii	"#############################################\n\n"
	.ascii	"       Welcome to the Black Hole Game!\n\n"
	.ascii	"############################################\n\n"
instructions:
	.asciiz "Instructions: Use WASD keys to navigate, and hit RETURN or SPACE to select\n"

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

    # display welcome message to MMIO Display
    la $a0, welcome_and_instructions
    jal display_string

    # run HOME animation / input loop
    jal home

    # user's choice is stored in $v0-- make decision based on that