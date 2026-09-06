# frozen_string_literal: true

module Discordrb
  # A color (red, green and blue values). If you prefer the
  #   British spelling, the alias {Colour} is also available.
  class Color
    # @return [Integer] the RGB values for the color as an integer.
    attr_reader :combined
    alias_method :to_i, :combined

    # Create a new colour from a given value.
    # @example Create a color using a base 10 integer.
    #   Discordrb::Color.new(7506394) # => Discordrb::Color
    # @example Create a color using a hexadecimal string.
    #   Discordrb::Color.new('7289da') # => Discordrb::Color
    # @param value [String, Integer] The color combined as an integer
    #   or a hexadecimal string.
    def initialize(value)
      @combined = if value.is_a?(Numeric)
                    value
                  else
                    value.delete_prefix('#').to_i(16)
                  end
    end

    # Convert the color to its hexadecimal form.
    # @return [String] The color in its hexadecimal form.
    def hex
      @combined.to_s(16)
    end

    # Get the blue part of the color.
    # @return [Integer] the blue part of the color (0-255).
    def blue
      @blue ||= (@combined & 0xFF)
    end

    # Get the red part of the color.
    # @return [Integer] the red part of the color (0-255).
    def red
      @red ||= ((@combined >> 16) & 0xFF)
    end

    # Get the green part of the color.
    # @return [Integer] the green part of the color (0-255).
    def green
      @green ||= ((@combined >> 8) & 0xFF)
    end

    # Check if two color objects are equivalent.
    # @param other [Object] The object to compare against for equality.
    # @return [true, false] Whether or not the two objects are equivalent.
    def ==(other)
      other.is_a?(Color) ? @combined == other.combined : false
    end

    alias_method :eql?, :==
    alias_method :to_s, :hex
    alias_method :hexadecimal, :hex

    # @!visibility private
    def inspect
      "<Color combined=#{@combined}>"
    end
  end

  # Alias for the {Color} class.
  Colour = Color
end
