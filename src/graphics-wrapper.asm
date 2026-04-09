#-----------------------------------------------------------------------
# graphics-wrapper.asm
# Description: brings graphics data in subdirectories up to root so
#   that they can be assembled with "Assemble all files in directory"
#   in MARS.
#
# Summaries of global data labels:
#   graphics/home:
#        - home_base_frame           (color array to draw home base frame)
#        - home_offsets              (array of offsets arrays to draw home animations)
#        - home_colors               (array of color arrays to draw home animations)
#        - arrow_offsets             (array of offsets arrays to draw 3 arrows)
#        - arrow_colors              (color array to draw arrows)
#
#   graphics/game:
#        - game_base_frame           (color array to draw game base frame)
#        - circle_offsets            (offsets array to draw 1 circle)
#        - number_offsets            (array of offsets arrays to draw 1-10)
#        - p1_turn_offsets           (offsets array to draw "Player 1's Turn" message)
#        - p1_turn_colors            (color array to draw "Player 1's Turn" message)
#        - p2_turn_offsets           (offsets array to draw "Player 2's Turn" message)
#        - p2_turn_colors            (color array to draw "Player 2's Turn" message)
#        - one_player_board_offsets  (offsets array to draw 1-player board)
#        - one_player_board_colors   (color array to draw 1-player board)
#        - one_player_block_offsets  (offsets array that holds starts of 21 1-player board blocks)
#        - two_player_board_offsets  (offsets array to draw 2-player board)
#        - two_player_board_colors   (color array to draw 2-player board)
#        - two_player_block_offsets  (offsets array that holds starts of 28 2-player board blocks)
#
#        - back_home_offsets         (offsets array to draw "Back Home" option)
#        - back_home_colors          (color array to draw "Back Home" option)
#        - player1_win_offsets       (offsets array to draw "Player 1 Wins" message)
#        - player1_win_colors        (color array to draw "Player 1 Wins" message)
#        - player2_win_offsets       (offsets array to draw "Player 2 Wins" message)
#        - player2_win_colors        (color array to draw "Player 2 Wins" message)
#        - computer_win_offsets      (offsets array to draw "Computer Wins" message)
#        - computer_win_colors       (color array to draw "Computer Wins" message)
#
# Author: Asha Mavankal
# Professor: Nhut Nguyen
# Section: HN1
# Due date: 04-07-2026
#-----------------------------------------------------------------------

# data for drawing the home animations--animations + selector arrows
.include "graphics/home/home-base-frame.asm"
.include "graphics/home/home-animation-diffs.asm"
.include "graphics/home/arrows.asm"

# data for drawing the game boards
.include "graphics/game/game-base-frame.asm"
.include "graphics/game/block-assets.asm"
.include "graphics/game/turn-messages.asm"

.include "graphics/game/one-player-board.asm"
.include "graphics/game/two-player-board.asm"

.include "graphics/game/game-end-messages.asm"