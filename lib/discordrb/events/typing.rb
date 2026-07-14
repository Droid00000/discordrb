# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever a user starts typing in a channel.
  class TypingStartEvent < Event
    include Respondable

    # @return [Integer] the ID of the user that started typing.
    attr_reader :user_id

    # @return [Integer, nil] the ID of the guild where the user
    #   started typing.
    attr_reader :guild_id

    # @return [Time] the timestamp at when the user started typing.
    attr_reader :started_at

    # @return [Integer] the ID of the channel where the user started
    #   typing.
    attr_reader :channel_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data[:user_id]&.to_i
      @guild_id = data[:guild_id]&.to_i
      @channel_id = data[:channel_id]&.to_i
      @started_at = Time.at(data[:timestamp].to_i)
    end

    # Get the guild where the user started typing.
    # @return [Guild, nil] The guild where the user started typing.
    def guild
      @channel.guild
    end

    # Get the channel where the user started typing.
    # @return [Channel] The channel where the user started typing.
    def channel
      @bot.channel(@channel_id)
    end

    # Get the user or member who started typing.
    # @return [User, Member] The user or member that started typing.
    def member
      @channel&.guild&.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :user, :member
  end

  # Event handler for TYPING_START events.
  class TypingStartEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(TypingStartEvent)

      [
        matches_all(@attributes[:guild], event.guild_id) do |a, e|
          a&.resolve_id == e.guild&.id
        end,

        matches_all(@attributes[:after], event.started_at) do |a, e|
          a > e
        end,

        matches_all(@attributes[:before], event.started_at) do |a, e|
          a < e
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
