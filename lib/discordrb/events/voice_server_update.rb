# frozen_string_literal: true

module Discordrb::Events
  # Raised whenever initially connecting to voice.
  class VoiceServerUpdateEvent < Event
    # @return [String] The voice connection token.
    attr_reader :token

    # @return [Guild] The guild associated with the event.
    attr_reader :guild

    # @return [String, nil] The host of the voice server, if any.
    attr_reader :endpoint

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @token = data[:token]
      @endpoint = data[:endpoint]
      @guild = bot.guild(data[:guild_id])
    end
  end

  # Event handler for VOICE_SERVER_UPDATE events.
  class VoiceServerUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceServerUpdateEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
