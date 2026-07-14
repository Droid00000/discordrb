# frozen_string_literal: true

module Discordrb
  # A reaction on a message.
  class Reaction
    # Mapping of types.
    TYPES = {
      normal: 0,
      burst: 1
    }.freeze

    # @return [Emoji] the emoji of the reaction.
    attr_reader :emoji

    # @return [Integer] the total number of reactions for the emoji,
    #   including super reactions and regular reactions.
    attr_reader :total_count

    # @return [Integer] the total number of super reactions for the emoji.
    attr_reader :burst_count

    # @return [true, false] whether or not the the bot account has reacted.
    attr_reader :current_bot

    # @return [Array<ColorRGB>] the colors associated with the super reaction.
    attr_reader :burst_colors

    # @return [Integer] the total number of non-super reactions for the emoji.
    attr_reader :standard_count

    alias_method :current_bot?, :current_bot
    alias_method :burst_colours, :burst_colors

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @current_bot = data[:me]
      @total_count = data[:count]
      @emoji = Emoji.new(data[:emoji], @bot)
      @burst_count = data[:count_details][:burst]
      @standard_count = data[:count_details][:normal]
      @burst_colors = data[:burst_colors]&.map { |item| ColourRGB.new(item) } || []
    end

    # @!visibility private
    def to_h
      emoji.to_h
    end

    # @!visibility private
    def to_s
      emoji.to_reaction
    end

    # Get the users who reacted with the emoji.
    # @return [Array<User>] The users for the reaction.
    # @see Message#reacted_with
    def users(**)
      @message.reacted_with(emoji: @emoji, **)
    end

    # Delete the reactions that are associated with the emoji.
    # @return [nil]
    # @see Message#delete_reactions
    def remove(**)
      @message.remove_reaction(emoji: @emoji, **)
    end

    alias_method :delete, :remove
    alias_method :to_reaction, :to_s
  end
end
