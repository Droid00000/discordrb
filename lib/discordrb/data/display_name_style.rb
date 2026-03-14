# frozen_string_literal: true

module Discordrb
  # Effects and colours applied to a display name.
  class DisplayNameStyle
    # Mapping of fonts.
    FONTS = {
      bangers: 1,
      bio_rhyme: 2,
      cherry_bomb: 3,
      chicle: 4,
      compagnon: 5,
      museo_moderno: 6,
      neo_castel: 7,
      pixelify: 8,
      ribes: 9,
      sinistre: 10,
      default: 11,
      zilla_slab: 12
    }.freeze

    # Mapping of effects.
    EFFECTS = {
      solid: 1,
      gradient: 2,
      neon: 3,
      toon: 4,
      pop: 5,
      glow: 6
    }.freeze

    # @return [Integer] the font of the display name style.
    attr_reader :font

    # @return [Integer] the effect of the display name style.
    attr_reader :effect

    # @return [Array<ColourRGB>] the colours of the display name style.
    attr_reader :colours
    alias colors colours

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @font = data['font_id']
      @effect = data['effect_id']
      @colours = data['colors']&.map { |colour| ColourRGB.new(colour) } || []
    end

    # @!method cherry_bomb?
    #   @return [true, false] whether or not the font of the display name style is `cherry_bomb`.
    # @!method chicle?
    #   @return [true, false] whether or not the font of the display name style is `chicle`.
    # @!method museo_moderno?
    #   @return [true, false] whether or not the font of the display name style is `museo_moderno`.
    # @!method neo_castel?
    #   @return [true, false] whether or not the font of the display name style is `neo_castel`.
    # @!method pixelify?
    #   @return [true, false] whether or not the font of the display name style is `pixelify`.
    # @!method sinistre?
    #   @return [true, false] whether or not the font of the display name style is `sinistre`.
    # @!method default?
    #   @return [true, false] whether or not the font of the display name style is the default font.
    # @!method zilla_slab?
    #   @return [true, false] whether or not the font of the display name style is `zilla_slab`.
    FONTS.each do |name, value|
      define_method("#{name}?") do
        @font == value
      end
    end

    # @!method solid?
    #   @return [true, false] whether or not the effect of the display name style is a solid colour.
    # @!method gradient?
    #   @return [true, false] whether or not the effect of the display name style is a two-point gradient.
    # @!method neon?
    #   @return [true, false] whether or not the effect of the display name style is a glow around the name.
    # @!method toon?
    #   @return [true, false] whether or not the effect of the display name style is a vertical gradient and stroke.
    # @!method pop?
    #   @return [true, false] whether or not the effect of the display name style is a coloured drop shadow.
    EFFECTS.each do |name, value|
      define_method("#{name}?") do
        @effect == value
      end
    end

    # Check if two display name styles are equal to each other.
    # @param other [DisplayNameStyle, Object] The other object to compare against.
    # @return [true, false] Whether or not the two objects are equal to each other.
    def ==(other)
      return false unless other.is_a?(DisplayNameStyle)

      @effect == other.effect && @font == other.font && @colours == other.colours
    end

    alias_method :eql?, :==
  end
end
