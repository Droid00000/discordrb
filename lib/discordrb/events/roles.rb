# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for role events.
  class GuildRoleEvent < Event
    # @return [Role] the role associated with the event.
    attr_reader :role

    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
      @role = @guild&.role(data[:role][:id].to_i)
    end
  end

  # Raised whenever a guild role is created.
  class GuildRoleCreateEvent < GuildRoleEvent; end

  # Raised whenever a guild role is updated.
  class GuildRoleUpdateEvent < GuildRoleEvent; end

  # Raised whenever a guild role is deleted.
  class GuildRoleDeleteEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [Integer] the ID of the role that was deleted.
    attr_reader :role_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @role_id = data[:role_id]&.to_i
      @guild = bot.guild(data[:guild_id].to_i)
    end
  end

  # Generic event handler for role events.
  class GuildRoleEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildRoleEvent)

      [
        matches_all(@attributes[:id], event.role.id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:name], event.role.name) do |a, e|
          case a
          when String
            a == e
          when Regexp
            a.match?(e)
          end
        end,

        matches_all(@attributes[:unicode_emoji], event.role) do |a, e|
          case a
          when Regexp
            a.match?(e.unicode_emoji || '')
          else
            a&.to_s == e.unicode_emoji
          end
        end,

        matches_all(@attributes[:bot_id], event.role.bot_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:hoisted], event.role.hoisted?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:mentionable], event.role.mentionable?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:color] || @attributes[:colour], event.role.color) do |a, e|
          a&.to_i == e&.to_i
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for GUILD_ROLE_CREATE events.
  class GuildRoleCreateEventHandler < GuildRoleEventHandler; end

  # Event handler for GUILD_ROLE_UPDATE events.
  class GuildRoleUpdateEventHandler < GuildRoleEventHandler; end

  # Event handler for GUILD_ROLE_DELETE events.
  class GuildRoleDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(RoleDeleteEvent)

      [
        matches_all(@attributes[:id], event.role_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
