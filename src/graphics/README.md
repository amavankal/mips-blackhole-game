# Graphics

This directory contains the data files needed to render the game's GUI on the bitmap display. This data is grouped into 2 directories:

 - `home`: selection arrows, animation frame data
 - `game`: game board arrangements, sprites (numbers, selection circle), and messages

The raw data in these files was generated using the `pngToAsm` command-line tool I wrote in C to convert PNG files into arrays of colors and positions in MIPS assembly (see [`tools/generate-graphics/`](../../tools/generate-graphics)). I then went in and gave the data better names and added documentation in comments.

## Global data labels by file

### Home

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global data labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>arrows.asm</code></td>
      <td>
        <ul>
            <li><code>arrow_offsets</code></li>
            <li><code>arrow_colors</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>home-animation-diffs.asm</code></td>
      <td>
        <ul>
            <li><code>home_offsets</code></li>
            <li><code>home_colors</code></li>
        </ul>
      </td>
    </tr>
    <tr>
    <td><code>home-base-frame.asm</code></td>
      <td>
        <ul>
            <li><code>home_base_frame</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

### Game

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global data labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>block-assets.asm</code></td>
      <td>
        <ul>
          <li><code>number_offsets</code></li>
          <li><code>circle_offsets</code></li>
          <li><code>circle_color</code></li>
          <li><code>selected_circle_color</code></li>
          <li><code>computer_color</code></li>
          <li><code>player1_color</code></li>
          <li><code>player1_color_temp</code></li>
          <li><code>player2_color</code></li>
          <li><code>player2_color_temp</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>game-base-frame.asm</code></td>
      <td>
        <ul>
          <li><code>game_base_frame</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>game-end-messages.asm</code></td>
      <td>
        <ul>
          <li><code>back_home_offsets</code></li>
          <li><code>back_home_colors</code></li>
          <li><code>player1_win_offsets</code></li>
          <li><code>player1_win_colors</code></li>
          <li><code>player2_win_offsets</code></li>
          <li><code>player2_win_colors</code></li>
          <li><code>computer_win_offsets</code></li>
          <li><code>computer_win_colors</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>one-player-board.asm</code></td>
      <td>
        <ul>
          <li><code>one_player_board_offsets</code></li>
          <li><code>one_player_board_colors</code></li>
          <li><code>one_player_block_offsets</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>turn-messages.asm</code></td>
      <td>
        <ul>
          <li><code>p1_turn_offsets</code></li>
          <li><code>p1_turn_colors</code></li>
          <li><code>p2_turn_offsets</code></li>
          <li><code>p2_turn_colors</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>two-player-board.asm</code></td>
      <td>
        <ul>
          <li><code>two_player_block_offsets</code></li>
          <li><code>two_player_board_offsets</code></li>
          <li><code>two_player_board_colors</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>
