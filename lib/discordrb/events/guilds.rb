# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for guild events.
  class GuildEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:id].to_i)
    end
  end

  # Raised whenever a guild is created.
  class GuildCreateEvent < GuildEvent; end

  # Raised whenever a guild is updated.
  class GuildUpdateEvent < GuildEvent; end

  # Raised whenever a guild is deleted.
  class GuildDeleteEvent < Event
    # @return [Guild] the ID of the guild associated with the event.
    attr_reader :guild_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild_id = data[:id].to_i
    end
  end

  # Generic event handler for guilds.
  class GuildEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildEvent)

      [
        matches_all(@attributes[:id], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:name], event.guild) do |a, e|
          case a
          when String
            a == e.name
          when Regexp
            a.match?(e.name)
          end
        end,

        matches_all(@attributes[:owner], event.guild) do |a, e|
          a&.resolve_id == e&.owner&.resolve_id
        end,

        matches_all(@attributes[:locale], event.guild) do |a, e|
          case a
          when Regexp
            a.match?(e.locale)
          else
            a&.to_s == e.locale
          end
        end,

        matches_all(@attributes[:nsfw_level], event.guild) do |a, e|
          case a
          when String, Symbol
            a.to_sym == e&.nsfw_level
          when Integer
            Discordrb::Guild::NSFW_LEVELS.key(a) == e&.nsfw_level
          end
        end,

        matches_all(@attributes[:description], event.guild) do |a, e|
          case a
          when String, Symbol
            a == (e.description || '')
          when Regexp
            a.match?(e.description || '')
          end
        end,

        matches_all(@attributes[:vanity_invite_code], event.guild) do |a, e|
          case a
          when String, Symbol
            a&.to_s == e&.vanity_invite_code
          when Regexp
            a.match?(e&.vanity_invite_code || '')
          end
        end,

        matches_all(@attributes[:premium_tier] || @attributes[:boost_level], event.guild) do |a, e|
          a&.to_i == e&.premium_tier
        end,

        matches_all(@attributes[:premium_count] || @attributes[:boost_count], event.guild) do |a, e|
          a&.to_i == e&.premium_tier
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for GUILD_CREATE events.
  class GuildCreateEventHandler < GuildEventHandler; end

  # Event handler for GUILD_UPDATE events.
  class GuildUpdateEventHandler < GuildEventHandler; end

  # Event handler for GUILD_DELETE events.
  class GuildDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildDeleteEvent)

      [
        matches_all(@attributes[:id], event.guild_id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever an audit log entry is created.
  class GuildAuditLogEntryCreateEvent < Event
    # @return [Guild] the guild of the audit log event.
    attr_reader :guild

    # @return [AuditLogs::Entry] the entry of the audit log event.
    attr_reader :entry

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
      @entry = Discordrb::AuditLog::Entry.new(data, nil, @bot)
    end
  end

  # Event handler for GUILD_AUDIT_LOG_ENTRY_CREATE events.
  class GuildAuditLogEntryCreateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(AuditLogEntryCreateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:action], event.entry.action) do |a, e|
          case a
          when Numeric
            a == e
          when String, Symbol
            Discordrb::AuditLog::Entry::ACTIONS[a.to_sym] == e
          end
        end,

        matches_all(@attributes[:reason], event.entry.reason) do |a, e|
          if e.reason
            case a
            when String
              a == e.reason
            when Regexp
              a.match?(e.reason || '')
            end
          end
        end,

        matches_all(@attributes[:user], event.entry.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:target], event.entry.target_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever the emojis for a guild are updated.
  class GuildEmojisUpdateEvent < Event
    # @return [Guild] the guild where the emojis were updated.
    attr_reader :guild

    # @!attribute [r] emojis
    #   @return [Array<Emoji>] all of the emojis in the guild.
    delegate :emojis, to: :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
    end
  end

  # Event handler for GUILD_EMOJIS_UPDATE events.
  class GuildEmojisUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildEmojisUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever the stickers for a guild are updated.
  class GuildStickersUpdateEvent < Event
    # @return [Guild] the guild where the stickers were updated.
    attr_reader :guild

    # @!attribute [r] stickers
    #   @return [Array<Sticker>] all of the stickers in the guild.
    delegate :stickers, to: :guild

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
    end
  end

  # Event handler for GUILD_STICKERS_UPDATE events.
  class GuildStickersUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(GuildStickersUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
