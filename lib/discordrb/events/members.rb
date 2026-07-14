# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for guild member events.
  class GuildMemberEvent < Event
    # @return [Integer] the user ID of the guild member.
    attr_reader :user_id

    # @return [true, false] whether the member is pending.
    attr_reader :pending
    alias pending? pending

    # @return [String, nil] the nickname of the guild member.
    attr_reader :nickname

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @pending = data[:pending]
      @user_id = data[:user][:id]&.to_i
      @guild_id = data[:guild_id]&.to_i
      @nickname = data[:nick] == '' ? nil : data[:nick]
    end

    # Get the guild associated with the event.
    # @return [Guild] The guild associated with the event.
    def guild
      @bot.guild(@guild_id)
    end

    # Get the member associated with the event.
    # @return [Member] The member associated with the event.
    def member
      guild&.member(@user_id)
    end
  end

  # Raised whenever a guild member is added.
  class GuildMemberAddEvent < GuildMemberEvent; end

  # Raised whenever a guild member is updated.
  class GuildMemberUpdateEvent < GuildMemberEvent; end

  # Raised whenever a guild member is removed.
  class GuildMemberRemoveEvent < Event
    # @return [User] the user that was removed.
    attr_reader :user

    # @return [Guild] the guild the user was removed from.
    attr_reader :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user = bot.ensure_user(data[:user])
      @guild = bot.guild(data[:guild_id].to_i)
    end
  end

  # Generic event handler for guild member events.
  class GuildMemberEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildMemberEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:pending], event.pending?) do |a, e|
          case a
          when TrueClass
            e.pending? == true
          when FalseClass
            e.pending? == false
          end
        end,

        matches_all(@attributes[:nickname], event.nickname) do |a, e|
          case a
          when String
            a == (e.nickname || '')
          when Regexp
            a.match?(e.nickame || '')
          end
        end,

        matches_all(@attributes[:user] || @attributes[:id], event.user_id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for GUILD_MEMBER_ADD events.
  class GuildMemberAddEventHandler < GuildMemberEventHandler; end

  # Event handler for GUILD_MEMBER_UPDATE events.
  class GuildMemberUpdateEventHandler < GuildMemberEventHandler; end

  # Event handler for GUILD_MEMBER_REMOVE events.
  class GuildMemberRemoveEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildMemberRemoveEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:id], event.user) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
