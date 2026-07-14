# frozen_string_literal: true

module Discordrb
  # Information about a member connected to a voice channel.
  class VoiceState
    # @!visibility private
    PREDICATES = %i[
      muted?
      camera?
      deafened?
      streaming?
      suppressed?
      self_muted?
      self_deafened?
    ].freeze

    # @return [Integer] the user ID of the member the voice state is for.
    attr_reader :user_id

    # @return [String, nil] the ID of the session associated with the voice state.
    attr_reader :session_id

    # @return [Integer] the ID of the voice or stage channel that the user is connected to.
    attr_reader :channel_id

    # @return [Time, nil] the time at when the member requested to speak in the stage channel.
    attr_reader :requested_to_speak_at

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data[:user_id].to_i
      update_data(data)
    end

    # Get the guild the voice state is for.
    # @return [Guild] The guild that that the voice state is for.
    def guild
      channel&.guild || @bot.guild(@guild_id)
    end

    # Get the voice channel the member is connected to.
    # @return [Channel, nil] the channel that the member is connected to.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # Check if the member requested to speak in the stage channel.
    # @return [true, false] Whether or not the member requested to speak.
    def requested_to_speak?
      !@requested_to_speak.nil?
    end

    # @!attribute [r] muted?
    #   @return [true, false] whether the member has been muted by the guild.
    # @!attribute [r] camera?
    #   @return [true, false] whether the member has enabled their camera/webcam.
    # @!attribute [r] deafened?
    #   @return [true, false] whether the member has been deafened by the guild.
    # @!attribute [r] streaming?
    #   @return [true, false] whether the member is streaming using "Go Live".
    # @!attribute [r] suppressed?
    #   @return [true, false] whether the member cannot talk in the stage channel.
    # @!attribute [r] self_muted?
    #   @return [true, false] whether the member has locally muted themselves.
    # @!attribute [r] self_deafened?
    #   @return [true, false] whether the member has locally deafened themselves.
    PREDICATES.each do |name|
      define_method(name) { instance_variable_get(:"@#{name[..-2]}") }
    end

    # @!visibility private
    def update_data(new_data)
      @muted = new_data[:mute]
      @camera = new_data[:video]
      @deafened = new_data[:deaf]
      @suppressed = new_data[:suppress]
      @self_muted = new_data[:self_mute]
      @session_id = new_data[:session_id]
      @self_deafened = new_data[:self_deaf]
      @guild_id = new_data[:guild_id]&.to_i
      @channel_id = new_data[:channel_id]&.to_i
      @streaming = new_data[:self_stream] || false
      request = new_data[:request_to_speak_timestamp]
      @requested_to_speak_at = request ? Time.iso8601(request) : request
    end
  end
end
