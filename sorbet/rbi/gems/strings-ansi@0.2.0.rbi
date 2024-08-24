# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `strings-ansi` gem.
# Please instead update this file by running `bin/tapioca gem strings-ansi`.


# source://strings-ansi//lib/strings/ansi/version.rb#3
module Strings; end

# Helper functions for handling ANSI escape sequences
#
# source://strings-ansi//lib/strings/ansi/version.rb#4
module Strings::ANSI
  private

  # Check if string contains ANSI codes
  #
  # @api public
  # @example
  #   Strings::ANSI.ansi?("\e[33mfoo\[e0m")
  #   # => true
  # @param string [String] the string to check
  # @return [Boolean]
  #
  # source://strings-ansi//lib/strings/ansi.rb#45
  def ansi?(string); end

  # Check if string contains only ANSI codes
  #
  # @api public
  # @example
  #   Strings::ANSI.only_ansi?("\e[33mfoo\[e0m")
  #   # => false
  #
  #   Strings::ANSI.only_ansi?("\e[33m")
  #   # => false
  # @param string [String] the string to check
  # @return [Boolean]
  #
  # source://strings-ansi//lib/strings/ansi.rb#65
  def only_ansi?(string); end

  # Return a copy of string with ANSI characters removed
  #
  # @api public
  # @example
  #   Strings::ANSI.sanitize("\e[33mfoo\[e0m")
  #   # => "foo"
  # @param string [String]
  # @return [String]
  #
  # source://strings-ansi//lib/strings/ansi.rb#28
  def sanitize(string); end

  class << self
    # Check if string contains ANSI codes
    #
    # @api public
    # @example
    #   Strings::ANSI.ansi?("\e[33mfoo\[e0m")
    #   # => true
    # @param string [String] the string to check
    # @return [Boolean]
    #
    # source://strings-ansi//lib/strings/ansi.rb#45
    def ansi?(string); end

    # Check if string contains only ANSI codes
    #
    # @api public
    # @example
    #   Strings::ANSI.only_ansi?("\e[33mfoo\[e0m")
    #   # => false
    #
    #   Strings::ANSI.only_ansi?("\e[33m")
    #   # => false
    # @param string [String] the string to check
    # @return [Boolean]
    #
    # source://strings-ansi//lib/strings/ansi.rb#65
    def only_ansi?(string); end

    # Return a copy of string with ANSI characters removed
    #
    # @api public
    # @example
    #   Strings::ANSI.sanitize("\e[33mfoo\[e0m")
    #   # => "foo"
    # @param string [String]
    # @return [String]
    #
    # source://strings-ansi//lib/strings/ansi.rb#28
    def sanitize(string); end
  end
end

# The regex to match ANSI codes
#
# source://strings-ansi//lib/strings/ansi.rb#15
Strings::ANSI::ANSI_MATCHER = T.let(T.unsafe(nil), String)

# The control sequence indicator
#
# source://strings-ansi//lib/strings/ansi.rb#9
Strings::ANSI::CSI = T.let(T.unsafe(nil), String)

# The code for reseting styling
#
# source://strings-ansi//lib/strings/ansi.rb#12
Strings::ANSI::RESET = T.let(T.unsafe(nil), String)

# source://strings-ansi//lib/strings/ansi/version.rb#5
Strings::ANSI::VERSION = T.let(T.unsafe(nil), String)