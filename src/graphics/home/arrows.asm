#-----------------------------------------------------------------------
# arrows.asm
# Description: contains an array of 3 -1 terminated offset arrays that
#	are used to draw selector arrows on the home frame to indicate 
#	which of the 3 game options the user has currently selected.
#
#	Also contains a color array to colorize those arrows (there is only
#	one, as all the arrows have the same color; they are just at
#	different positions on the board).
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

.globl arrow_offsets
.globl arrow_colors

.data

arrow_offsets:
	.word exit_arrow_offsets, p1_arrow_offsets, p2_arrow_offsets
	.word 0

arrow_colors:
	.word	0x0001011C, 0x0001011C, 0x0001011C
	.word	0x0001011C, 0x0000C853, 0x0001011C, 0x0001011C
	.word	0x0001011C, 0x0000C853, 0x0000C853, 0x0001011C, 0x0001011C
	.word	0x0001011C, 0x0000C853, 0x0000C853, 0x0000C853, 0x0001011C
	.word	0x0001011C, 0x0000C853, 0x0000C853, 0x0001011C, 0x0001011C
	.word	0x0001011C, 0x0000C853, 0x0001011C, 0x0001011C
	.word	0x0001011C, 0x0001011C, 0x0001011C

p1_arrow_offsets:
	.word	     38269,      38270,      38271
	.word		 38525,      38526,      38527,      38528
	.word        38781,      38782,      38783,      38784,      38785
	.word        39037,      39038,      39039,      39040,      39041
	.word        39293,      39294,      39295,      39296,      39297
	.word        39549,      39550,      39551,      39552
	.word        39805,      39806,      39807
	.word		 -1

p2_arrow_offsets:
	.word        42873,      42874,      42875
	.word	     43129,      43130,      43131,      43132
	.word        43385,      43386,      43387,      43388,      43389
	.word        43641,      43642,      43643,      43644,      43645
	.word        43897,      43898,      43899,      43900,      43901
	.word        44153,      44154,      44155,      44156
	.word        44409,      44410,      44411
	.word		 -1

exit_arrow_offsets:
	.word        47526,      47527,      47528
	.word        47782,      47783,      47784,      47785
	.word        48038,      48039,      48040,      48041,      48042
	.word        48294,      48295,      48296,      48297,      48298
	.word        48550,      48551,      48552,      48553,      48554
	.word	     48806,      48807,      48808,      48809
	.word        49062,      49063,      49064
	.word		 -1
