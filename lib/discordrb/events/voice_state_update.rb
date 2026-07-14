# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever a member's voice state is updated.
  class VoiceStateUpdateEvent < Event
    # @return [Member] the member whose voice state was updated.
    attr_reader :user
    alias member user

    # @return [Guild] the guild where the voice state was updated.
    attr_reader :guild

    # @return [VoiceState] the current voice state of the guild member.
    attr_reader :voice_state

    # @return [Channel, nil] the old voice channel the user was connected
    #   to, or `nil` if the user is newly connecting to the voice channel.
    attr_reader :old_channel

    # @!visibility private
    def initialize(data, old_channel, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
      @user = @guild&.member(data[:user_id].to_i)
      @voice_state = Discordrb::VoiceState.new(data, bot)
      @old_channel = bot.channel(old_channel) if old_channel
    end
  end

  # Event handler for VOICE_STATE_UPDATE events.
  class VoiceStateUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceStateUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:old_channel], event.old_channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:muted], event.voice_state.muted?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:camera], event.voice_state.camera?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:deafened], event.voice_state.deafened?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:streaming], event.voice_state.streaming?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:suppressed], event.voice_state.suppressed?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:self_muted], event.voice_state.self_muted?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:self_deafened], event.voice_state.self_deafened?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:requested_to_speak], event.voice_state.requested_to_speak?) do |a, e|
          a == e
        end,

        matches_all(@attributes[:member] || @attributes[:user] || @attributes[:user_id], event.user) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
