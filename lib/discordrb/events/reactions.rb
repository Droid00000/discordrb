# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for reaction events.
  class MessageReactionEvent < Event
    # Mapping of types.
    TYPES = Discordrb::Reaction::TYPES

    # @return [Integer, nil] the ID of the associated guild.
    attr_reader :guild_id

    # @return [Integer] the ID of the channel the message is in.
    attr_reader :channel_id

    # @return [Integer] the ID of the message associated with the event.
    attr_reader :message_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild_id = data[:guild_id]&.to_i
      @channel_id = data[:channel_id]&.to_i
      @message_id = data[:message_id]&.to_i
    end

    # Get the guild associated with the event.
    # @return [Guild, nil] The guild associated with the event, if any.
    def guild
      channel.guild
    end

    # Get the channel associated with the event.
    # @return [Channel] The channel that the associated message was sent in.
    def channel
      @channel ||= @bot.channel(@channel_id)
    end

    # Get the message associated with the event.
    # @return [Message, nil] The message that had a reaction added or removed.
    def message
      @message ||= channel.message(@message_id)
    end
  end

  # Raised whenever a reaction is added to a message.
  class MessageReactionAddEvent < MessageReactionEvent
    # @return [Integer] the type of the added reaction.
    attr_reader :type

    # @return [Emoji] the emoji that had a reaction added.
    attr_reader :emoji

    # @return [Integer] the ID of the user who added the reaction.
    attr_reader :user_id

    # @return [Array<ColorRGB>] the colours that were used for the super reaction.
    attr_reader :burst_colors
    alias burst_colours burst_colors

    # @return [Integer, nil] the ID of the user who sent the message that was reacted to.
    attr_reader :message_author_id

    # @!visibility private
    def initialize(data, bot)
      super

      @type = data[:type]
      @user_id = data[:user_id]&.to_i
      @emoji = Discordrb::Emoji.new(data[:emoji], @bot)
      @message_author_id = data[:message_author_id]&.to_i
      @burst_colors = data[:burst_colors]&.map { |item| Discordrb::ColorRGB.new(item) } || []
    end

    # Get the user who added the reaction.
    # @return [Member, User] The user that added the reaction.
    def member
      @member ||= guild&.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :user, :member

    # @!method burst?
    #   @return [true, false] whether the reaction is super reaction.
    # @!method normal?
    #   @return [true, false] whether the reaction is a normal reaction.
    TYPES.each { |key, value| define_method("#{key}?") { @type == value } }
  end

  # Raised whenever a reaction is removed on a message.
  class MessageReactionRemoveEvent < MessageReactionEvent
    # @return [Integer] the type of the removed reaction.
    attr_reader :type

    # @return [Emoji] the emoji that had a reaction removed.
    attr_reader :emoji

    # @return [Integer] the ID of the user who removed the reaction.
    attr_reader :user_id

    # @!visibility private
    def initialize(data, bot)
      super

      @type = data[:type]
      @user_id = data[:user_id]&.to_i
      @emoji = Discordrb::Emoji.new(data[:emoji], @bot)
    end

    # Get the user who added the reaction.
    # @return [Member, User] The user that added the reaction.
    def member
      @member ||= guild&.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :user, :member

    # @!method burst?
    #   @return [true, false] whether the reaction is super reaction.
    # @!method normal?
    #   @return [true, false] whether the reaction is a normal reaction.
    TYPES.each { |key, value| define_method("#{key}?") { @type == value } }
  end

  # Raised whenever all of the reactions for an emoji are removed.
  class MessageReactionRemoveEmojiEvent < MessageReactionEvent
    # @return [Emoji] the emoji whose reactions were completely removed.
    attr_reader :emoji

    # @!visibility private
    def initialize(data, bot)
      super

      @emoji = Discordrb::Emoji.new(data[:emoji], @bot)
    end
  end

  # Raised whenever all of the reactions for a message are removed.
  class MessageReactionRemoveAllEvent < MessageReactionEvent; end

  # Generic event handler for reactions.
  class MessageReactionEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(MessageReactionEvent)

      [
        matches_all(@attributes[:guild], event.guild_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:message], event.message_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for MESSAGE_REACTION_ADD events.
  class MessageReactionAddEventHandler < MessageReactionEventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(MessageReactionAddEvent) && super

      [
        matches_all(@attributes[:type], event.type) do |a, e|
          case a
          when Integer
            a == e
          when String, Symbol
            Discordrb::Reaction::TYPES[a.to_sym] == e
          end
        end,

        matches_all(@attributes[:emoji], event.emoji) do |a, e|
          case a
          when String
            a.to_i.zero? ? a == e.name : a.to_i == e.id
          when Reaction
            a.emoji == e
          else
            a == e
          end
        end,

        matches_all(@attributes[:message_author], event.message_author_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for MESSAGE_REACTION_REMOVE events.
  class MessageReactionRemoveEventHandler < MessageReactionEventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(MessageReactionRemoveEvent) && super

      [
        matches_all(@attributes[:type], event.type) do |a, e|
          case a
          when Integer
            a == e
          when String, Symbol
            Discordrb::Reaction::TYPES[a.to_sym] == e
          end
        end,

        matches_all(@attributes[:emoji], event.emoji) do |a, e|
          case a
          when String
            a.to_i.zero? ? a == e.name : a.to_i == e.id
          when Reaction
            a.emoji == e
          else
            a == e
          end
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for MESSAGE_REACTION_REMOVE_EMOJI events.
  class MessageReactionRemoveEmojiEventHandler < MessageReactionEventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(MessageReactionRemoveEmoji) && super

      [
        matches_all(@attributes[:emoji], event.emoji) do |a, e|
          case a
          when String
            a.to_i.zero? ? a == e.name : a.to_i == e.id
          when Reaction
            a.emoji == e
          else
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for MESSAGE_REACTION_REMOVE_ALL events.
  class MessageReactionRemoveAllEventHandler < MessageReactionEventHandler; end
end
