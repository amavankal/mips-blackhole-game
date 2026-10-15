# Helper subroutines

This directory contains this game's helper subroutines. They are grouped into 4 logical modules:

 - `display`: for displaying the board to the Keyboard and Display MMIO Simulator display
 - `game`: for game logic
 - `gui`: for displaying the game on the Bitmap Display
 - `input`: for processing user input

## Global subroutine labels by module and file

### Display module

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global subroutine labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>display-board.asm</code></td>
      <td>
        <ul>
          <li><code>display_board</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>display-results.asm</code></td>
      <td>
        <ul>
          <li><code>display_results</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>display-user-selection.asm</code></td>
      <td>
        <ul>
          <li><code>display_user_selection</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>display-utils.asm</code></td>
      <td>
        <ul>
          <li><code>display_string</code></li>
          <li><code>display_number</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

### Game module

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global subroutine labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>calculate-cursor.asm</code></td>
      <td>
        <ul>
          <li><code>find_first_free_cursor</code></li>
          <li><code>get_cursor_from_input</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>calculate-score.asm</code></td>
      <td>
        <ul>
          <li><code>calculate_scores</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>game-utils.asm</code></td>
      <td>
        <ul>
          <li><code>get_num_spots</code></li>
          <li><code>get_row_from_index</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>take-computer-turn.asm</code></td>
      <td>
        <ul>
          <li><code>take_computer_turn</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

### GUI module

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global subroutine labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>draw-arrows.asm</code></td>
      <td>
        <ul>
          <li><code>draw_arrow</code></li>
          <li><code>erase_arrow</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>draw-assets.asm</code></td>
      <td>
        <ul>
          <li><code>draw_user_selection</code></li>
          <li><code>erase_user_selection</code></li>
          <li><code>draw_final_user_selection</code></li>
          <li><code>draw_win_message</code></li>
          <li><code>draw_home_message</code></li>
          <li><code>draw_turn_message</code></li>
          <li><code>erase_turn_message</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>draw-block-assets.asm</code></td>
      <td>
        <ul>
          <li><code>draw_number</code></li>
          <li><code>erase_number</code></li>
          <li><code>draw_circle</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>draw-game-board.asm</code></td>
      <td>
        <ul>
          <li><code>draw_game_board</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

### Input module

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Global subroutine labels</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>input-utils.asm</code></td>
      <td>
        <ul>
          <li><code>is_go_character</code></li>
          <li><code>is_up_only_character</code></li>
          <li><code>is_down_only_character</code></li>
          <li><code>is_up_character</code></li>
          <li><code>is_down_character</code></li>
          <li><code>is_left_character</code></li>
          <li><code>is_right_character</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>
