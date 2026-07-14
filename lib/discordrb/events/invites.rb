# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever an invite is created.
  class InviteCreateEvent < Event
    # @return [Invite] the invite that was created.
    attr_reader :invite

    # @return [Guild] the guild the invite was created for.
    attr_reader :guild

    # @return [Channel] the channel the invite was created for.
    attr_reader :channel

    # @!visibility private
    def initialize(data, invite, bot)
      @bot = bot
      @invite = invite
      @channel = bot.channel(data[:channel_id])
      @guild = bot.guild(data[:guild_id]) if data[:guild_id]
    end
  end

  # Raised whenever an invite is deleted.
  class InviteDeleteEvent < Event
    # @return [String] the code of the invite that was deleted.
    attr_reader :code

    # @return [Guild] the guild associated with the deleted invite.
    attr_reader :guild

    # @return [Channel] the channel associated with the deleted invite.
    attr_reader :channel

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @code = data[:code]
      @channel = bot.channel(data[:channel_id])
      @guild = bot.guild(data[:guild_id]) if data[:guild_id]
    end
  end

  # Event handler for INVITE_CREATE events.
  class InviteCreateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(InviteCreateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:creator], event.invite.creator) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:temporary], event.invite.temporary?, &:==)
      ].reduce(true, &:&)
    end
  end

  # Event handler for INVITE_DELETE events.
  class InviteDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(InviteDeleteEvent)

      [
        matches_all(@attributes[:code], event.code) do |a, e|
          a == e
        end,

        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
