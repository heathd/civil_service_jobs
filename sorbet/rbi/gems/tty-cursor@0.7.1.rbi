# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `tty-cursor` gem.
# Please instead update this file by running `bin/tapioca gem tty-cursor`.


# source://tty-cursor//lib/tty/cursor/version.rb#3
module TTY; end

# Terminal cursor movement ANSI codes
#
# source://tty-cursor//lib/tty/cursor/version.rb#4
module TTY::Cursor
  private

  # Move the cursor backward by n
  #
  # @api public
  # @param n [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#94
  def backward(n = T.unsafe(nil)); end

  # Erase n characters from the current cursor position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#137
  def clear_char(n = T.unsafe(nil)); end

  # Erase the entire current line and return to beginning of the line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#143
  def clear_line; end

  # Erase from the current position (inclusive) to
  # the end of the line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#157
  def clear_line_after; end

  # Erase from the beginning of the line up to and including
  # the current cursor position.
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#150
  def clear_line_before; end

  # Clear a number of lines
  #
  # @api public
  # @param n [Integer] the number of lines to clear
  # @param :direction [Symbol] the direction to clear, default :up
  #
  # source://tty-cursor//lib/tty/cursor.rb#169
  def clear_lines(n, direction = T.unsafe(nil)); end

  # source://tty-cursor//lib/tty/cursor.rb#169
  def clear_rows(n, direction = T.unsafe(nil)); end

  # Clear the screen with the background colour and moves the cursor to home
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#191
  def clear_screen; end

  # Clear screen down from current position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#179
  def clear_screen_down; end

  # Clear screen up from current position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#185
  def clear_screen_up; end

  # Cursor moves to nth position horizontally in the current line
  #
  # @api public
  # @param n [Integer] the nth aboslute position in line
  #
  # source://tty-cursor//lib/tty/cursor.rb#111
  def column(n = T.unsafe(nil)); end

  # Query cursor current position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#51
  def current; end

  # source://tty-cursor//lib/tty/cursor.rb#94
  def cursor_backward(n = T.unsafe(nil)); end

  # source://tty-cursor//lib/tty/cursor.rb#86
  def cursor_down(n = T.unsafe(nil)); end

  # source://tty-cursor//lib/tty/cursor.rb#102
  def cursor_forward(n = T.unsafe(nil)); end

  # source://tty-cursor//lib/tty/cursor.rb#78
  def cursor_up(n = T.unsafe(nil)); end

  # Move the cursor down by n
  #
  # @api public
  # @param n [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#86
  def down(n = T.unsafe(nil)); end

  # Move the cursor forward by n
  #
  # @api public
  # @param n [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#102
  def forward(n = T.unsafe(nil)); end

  # Hide cursor
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#24
  def hide; end

  # Switch off cursor for the block
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#30
  def invisible(stream = T.unsafe(nil)); end

  # Move cursor relative to its current position
  #
  # @api public
  # @param x [Integer]
  # @param y [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#70
  def move(x, y); end

  # Set the cursor absolute position
  #
  # @api public
  # @param row [Integer]
  # @param column [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#59
  def move_to(row = T.unsafe(nil), column = T.unsafe(nil)); end

  # Move cursor down to beginning of next line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#125
  def next_line; end

  # Move cursor up to beginning of previous line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#131
  def prev_line; end

  # Restore cursor position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#45
  def restore; end

  # Cursor moves to the nth position vertically in the current column
  #
  # @api public
  # @param n [Integer] the nth absolute position in column
  #
  # source://tty-cursor//lib/tty/cursor.rb#119
  def row(n = T.unsafe(nil)); end

  # Save current position
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#39
  def save; end

  # Scroll display down one line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#203
  def scroll_down; end

  # Scroll display up one line
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#197
  def scroll_up; end

  # Make cursor visible
  #
  # @api public
  #
  # source://tty-cursor//lib/tty/cursor.rb#18
  def show; end

  # Move cursor up by n
  #
  # @api public
  # @param n [Integer]
  #
  # source://tty-cursor//lib/tty/cursor.rb#78
  def up(n = T.unsafe(nil)); end

  class << self
    # Move the cursor backward by n
    #
    # @api public
    # @param n [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#94
    def backward(n = T.unsafe(nil)); end

    # Erase n characters from the current cursor position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#137
    def clear_char(n = T.unsafe(nil)); end

    # Erase the entire current line and return to beginning of the line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#143
    def clear_line; end

    # Erase from the current position (inclusive) to
    # the end of the line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#157
    def clear_line_after; end

    # Erase from the beginning of the line up to and including
    # the current cursor position.
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#150
    def clear_line_before; end

    # Clear a number of lines
    #
    # @api public
    # @param n [Integer] the number of lines to clear
    # @param :direction [Symbol] the direction to clear, default :up
    #
    # source://tty-cursor//lib/tty/cursor.rb#169
    def clear_lines(n, direction = T.unsafe(nil)); end

    # Clear the screen with the background colour and moves the cursor to home
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#191
    def clear_screen; end

    # Clear screen down from current position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#179
    def clear_screen_down; end

    # Clear screen up from current position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#185
    def clear_screen_up; end

    # Cursor moves to nth position horizontally in the current line
    #
    # @api public
    # @param n [Integer] the nth aboslute position in line
    #
    # source://tty-cursor//lib/tty/cursor.rb#111
    def column(n = T.unsafe(nil)); end

    # Query cursor current position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#51
    def current; end

    # Move the cursor down by n
    #
    # @api public
    # @param n [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#86
    def down(n = T.unsafe(nil)); end

    # Move the cursor forward by n
    #
    # @api public
    # @param n [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#102
    def forward(n = T.unsafe(nil)); end

    # Hide cursor
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#24
    def hide; end

    # Switch off cursor for the block
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#30
    def invisible(stream = T.unsafe(nil)); end

    # Move cursor relative to its current position
    #
    # @api public
    # @param x [Integer]
    # @param y [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#70
    def move(x, y); end

    # Set the cursor absolute position
    #
    # @api public
    # @param row [Integer]
    # @param column [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#59
    def move_to(row = T.unsafe(nil), column = T.unsafe(nil)); end

    # Move cursor down to beginning of next line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#125
    def next_line; end

    # Move cursor up to beginning of previous line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#131
    def prev_line; end

    # Restore cursor position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#45
    def restore; end

    # Cursor moves to the nth position vertically in the current column
    #
    # @api public
    # @param n [Integer] the nth absolute position in column
    #
    # source://tty-cursor//lib/tty/cursor.rb#119
    def row(n = T.unsafe(nil)); end

    # Save current position
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#39
    def save; end

    # Scroll display down one line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#203
    def scroll_down; end

    # Scroll display up one line
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#197
    def scroll_up; end

    # Make cursor visible
    #
    # @api public
    #
    # source://tty-cursor//lib/tty/cursor.rb#18
    def show; end

    # Move cursor up by n
    #
    # @api public
    # @param n [Integer]
    #
    # source://tty-cursor//lib/tty/cursor.rb#78
    def up(n = T.unsafe(nil)); end
  end
end

# source://tty-cursor//lib/tty/cursor.rb#11
TTY::Cursor::CSI = T.let(T.unsafe(nil), String)

# source://tty-cursor//lib/tty/cursor.rb#12
TTY::Cursor::DEC_RST = T.let(T.unsafe(nil), String)

# source://tty-cursor//lib/tty/cursor.rb#13
TTY::Cursor::DEC_SET = T.let(T.unsafe(nil), String)

# source://tty-cursor//lib/tty/cursor.rb#14
TTY::Cursor::DEC_TCEM = T.let(T.unsafe(nil), String)

# source://tty-cursor//lib/tty/cursor.rb#10
TTY::Cursor::ESC = T.let(T.unsafe(nil), String)

# source://tty-cursor//lib/tty/cursor/version.rb#5
TTY::Cursor::VERSION = T.let(T.unsafe(nil), String)
