# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever a user is banned.
  class GuildBanAddEvent < Event
    # @return [User] the user that was banned.
    attr_reader :user

    # @return [Guild] the guild the user was banned from.
    attr_reader :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user = bot.ensure_user(data[:user])
      @guild = bot.guild(data[:guild_id].to_i)
    end
  end

  # Raised whenever a user is unbanned.
  class GuildBanRemoveEvent < GuildBanAddEvent; end

  # Event handler for GUILD_BAN_ADD events.
  class GuildBanAddEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildBanAddEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for GUILD_BAN_REMOVE events.
  class GuildBanRemoveEventHandler < GuildBanAddEventHandler; end
end
