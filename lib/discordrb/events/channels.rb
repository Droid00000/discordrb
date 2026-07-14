# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for channel events.
  class ChannelEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [Channel] the channel associated with the event.
    # @note Due to a Discord limitation, when a thread is deleted,
    #   only the following methods will be available: {Snowflake#id id},
    #   {Channel#parent parent}, {Channel#guild guild}, and {Channel#type type}.
    attr_reader :channel

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id])
      @channel = bot.channel(data[:id].to_i)
    end
  end

  # Raised whenever a channel is created.
  class ChannelCreateEvent < ChannelEvent; end

  # Raised whenever a channel is updated.
  class ChannelUpdateEvent < ChannelEvent; end

  # Raised whenever a channel is deleted.
  class ChannelDeleteEvent < ChannelEvent
    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id])
      @channel = Discordrb::Channel.new(data, @bot)
    end
  end

  # Generic event handler for channel events.
  class ChannelEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ChannelEvent)

      [
        matches_all(@attributes[:id], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:name], event.channel) do |a, e|
          case a
          when Regexp
            e.name ? a.match?(e.name) : false
          when String
            a == e.name
          end
        end,

        matches_all(@attributes[:topic], event.channel) do |a, e|
          case a
          when Regexp
            e.topic ? a.match?(e.name) : false
          when String
            a == e.topic
          end
        end,

        matches_all(@attributes[:type], event.channel) do |a, e|
          case a
          when :thread
            e.thread?
          when Symbol, String
            Discordrb::Channel::TYPES[a.to_sym] == e.type
          else
            a == e.type
          end
        end,

        matches_all(@attributes[:locked], event.channel) do |a, e|
          case a
          when TrueClass
            e.thread? ? (e.locked? == true) : false
          when FalseClass
            e.thread? ? (e.locked? == false) : false
          end
        end,

        matches_all(@attributes[:archived], event.channel) do |a, e|
          case a
          when TrueClass
            e.thread? ? (e.archived? == true) : false
          when FalseClass
            e.thread? ? (e.archived? == false) : false
          end
        end,

        matches_all(@attributes[:parent], event.channel.parent_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:auto_archive_duration], event.channel) do |a, e|
          e.thread? ? e.auto_archive_duration == a.to_i : false
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for CHANNEL_CREATE and THREAD_CREATE events.
  class ChannelCreateEventHandler < ChannelEventHandler; end

  # Event handler for CHANNEL_UPDATE and THREAD_UPDATE events.
  class ChannelUpdateEventHandler < ChannelEventHandler; end

  # Event handler for CHANNEL_DELETE and THREAD_DELETE events.
  class ChannelDeleteEventHandler < ChannelEventHandler; end

  # Raised whenever a message is pinned or un-pinned in a channel.
  class ChannelPinsUpdateEvent < Event
    # @return [Guild, nil] the guild associated with the
    #   event. Will be `nil` when a message is pinned in a DM
    #   channel with the current bot account.
    attr_reader :guild

    # @return [Channel] the channel associated with the event.
    attr_reader :channel

    # @return [Time, nil] the time at when the last pinned message
    #   was pinned in the channel.
    attr_reader :last_message_pinned_at

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id]) if data[:guild_id]
      @channel = bot.channel(data[:channel_id]) if data[:channel_id]
      @last_message_pinned_at = Time.iso8601(data[:last_pin_timestamp]) if data[:last_pin_timestamp]
    end
  end

  # Event handler for CHANNEL_PINS_UPDATE events.
  class ChannelPinsUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ChannelPinsUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever the start time of a voice channel is updated.
  class VoiceChannelStartTimeUpdateEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [Channel] the channel associated with the event.
    attr_reader :channel

    # @return [Time, nil] the new start time of the voice channel.
    attr_reader :start_time

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @channel = bot.channel(data[:id])
      @guild = @channel.guild
      @start_time = Time.at(data[:voice_start_time]) if data[:voice_start_time]
    end
  end

  # Event handler for VOICE_CHANNEL_START_TIME_UPDATE events.
  class VoiceChannelStartTimeUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceChannelStartTimeUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:after], event.start_time) do |a, e|
          (e > a) if e
        end,

        matches_all(@attributes[:before], event.start_time) do |a, e|
          (e < a) if e
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever the status of a voice channel is updated.
  class VoiceChannelStatusUpdateEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [String, nil] the status of the voice channel.
    attr_reader :status

    # @return [Channel] the channel associated with the event.
    attr_reader :channel

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id])
      @channel = bot.channel(data[:id].to_i)
      @status = data[:status] == '' ? nil : data[:status]
    end
  end

  # Event handler for VOICE_CHANNEL_STATUS_UPDATE events.
  class VoiceChannelStatusUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceChannelStatusUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:status], event.status) do |a, e|
          case a
          when Regexp
            a.match?(e) if e
          else
            a == e
          end
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
