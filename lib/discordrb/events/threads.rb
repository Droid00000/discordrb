# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever a member is added to a thread.
  class ThreadMemberAddEvent < Event
    # @return [Channel] the thread associated with the event.
    attr_reader :channel
    alias thread channel

    # @return [ThreadMember] the thread member associated with the event.
    attr_reader :thread_member

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @thread_member = Discordrb::ThreadMember.new(data, @channel, @bot)
    end
  end

  # Raised whenever a member is removed from a thread.
  class ThreadMemberRemoveEvent < Event
    # @return [Channel] the thread associated with the event.
    attr_reader :channel
    alias thread channel

    # @return [Integer] the ID of the thread member that was removed.
    attr_reader :user_id

    # @!visibility private
    def initialize(user_id, channel, bot)
      @bot = bot
      @channel = channel
      @user_id = user_id&.to_i
    end
  end

  # Event handler for THREAD_MEMBERS_UPDATE events.
  class ThreadMemberAddEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ThreadMemberAddEvent)

      [
        matches_all(@attributes[:guild], event.channel.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel] || @attributes[:thread], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:member] || @attributes[:user], event.thread_member) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for THREAD_MEMBERS_UPDATE events.
  class ThreadMemberRemoveEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ThreadMemberRemoveEvent)

      [
        matches_all(@attributes[:guild], event.channel.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:member] || @attributes[:user], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel] || @attributes[:thread], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
