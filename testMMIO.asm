#-----------------------------------------------------------------------
# testMMIO.asm
# description: testing out MMIO tools
#
# author: Asha Mavankal
# last updated: 20 Feb 2026
#-----------------------------------------------------------------------
.include "printAndDisplay.asm"
.include "displayBoard.asm"

.data
board:	# 0x10010000
	.space 262144 # reserve 256 px * 256 px * 4 bytes each

text_welcome:
	.ascii	"#########################################\n\n"
	.ascii	"     Welcome to the Black Hole Game!\n\n"
	.asciiz	"#########################################\n\n"
text_select_mode:
	.asciiz "Type 1 for 1-player mode, 2 for 2-player mode, and 0 to exit\n"

text_set_up:
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

.include "boardData.asm"

.text
	# start program w/ terminal instructions
	print_text (text_set_up)

	# write welcome message
	#la $t0, text_welcome
	display_text (text_welcome)

	# write instructions
	display_text (text_select_mode)

	# initialize board
	draw_board (board, frame)

	# exit program
	li $v0, 10
	syscall
