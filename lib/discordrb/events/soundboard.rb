# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for soundboard sound events.
  class SoundboardSoundEvent < Event
    # @return [Server] the server of the soundboard sound.
    attr_reader :server

    # @return [Sound] the soundboard sound that was actioned.
    attr_reader :soundboard_sound

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @soundboard_sound = @server.soundboard_sound(data['sound_id'].to_i)
    end
  end

  # Raised whenever a soundboard sound is created.
  class SoundboardSoundCreateEvent < SoundboardSoundEvent; end

  # Raised whenever a soundboard sound is updated.
  class SoundboardSoundUpdateEvent < SoundboardSoundEvent; end

  # Raised whenever a soundboard sound is deleted.
  class SoundboardSoundDeleteEvent < Event
    # @return [Server] the server of the deleted soundboard sound.
    attr_reader :server

    # @return [Integer] the ID of the soundboard sound that was deleted.
    attr_reader :soundboard_sound_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @soundboard_sound_id = data['sound_id'].to_i
    end
  end

  # Generic event handler for soundboard sound events.
  class SoundboardSoundEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SoundboardSoundEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.soundboard_sound) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:creator], event.soundboard_sound) do |a, e|
          a.resolve_id == e.creator&.resolve_id
        end,

        matches_all(@attributes[:name], event.soundboard_sound.name) do |a, e|
          case a
          when Regexp
            a.match?(e)
          else
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for the GUILD_SOUNDBOARD_SOUND_CREATE event.
  class SoundboardSoundCreateEventHandler < SoundboardSoundEventHandler; end

  # Event handler for the GUILD_SOUNDBOARD_SOUND_UPDATE event.
  class SoundboardSoundUpdateEventHandler < SoundboardSoundEventHandler; end

  # Event handler for the GUILD_SOUNDBOARD_SOUND_DELETE event.
  class SoundboardSoundDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SoundboardSoundDeleteEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.soundboard_sound_id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Sent whenever someone plays a voice channel effect.
  class VoiceChannelEffectEvent < Event
    # @return [Emoji, nil] the emoji of the effect.
    attr_reader :emoji

    # @return [Channel] the channel the effect was sent in.
    attr_reader :channel

    # @return [Integer] the ID of the user who sent the effect.
    attr_reader :user_id

    # @return [Intger, nil] The animation ID of the effect that was sent.
    attr_reader :animation_id

    # @return [Integer, nil] the animation type of the effect that was sent.
    attr_reader :animation_type

    # @return [Integer, nil] the ID of the soundboard sound, if applicable.
    attr_reader :soundboard_sound_id

    # @return [Float, nil] the volume of the soundboard sound, if applicable.
    attr_reader :soundboard_sound_volume

    # @!attribute [r] server
    #   @return [Server] the ID of the server the effect was sent in.
    #   @see Channel#server
    # @!attribute [r] bitrate
    #   @return [Integer] the bitrate of the channel the effect was sent in.
    #   @see Channel#bitrate
    # @!attribute [r] user_limit
    #   @return [Integer] the user limit of the channel the effect was sent in.
    #   @see Channel#user_limit
    # @!attribute [r] voice_region
    #   @return [String] the voice region of the channel the effect was sent in.
    #   @see Channel#voice_region
    delegate :server, :bitrate, :user_limit, :voice_region, to: :channel

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id']&.to_i
      @animation_id = data['animation_id']
      @animation_type = data['animation_type']
      @soundboard_sound_id = data['sound_id']&.to_i
      @soundboard_sound_volume = data['sound_volume']&.to_f

      @channel = @bot.channel(data['channel_id']&.to_i)
      @emoji = Discordrb::Emoji.new(data['emoji'], @bot) if data['emoji']
    end

    # Get the soundboard sound that was played, if applicable.
    # @return [Sound, nil] The soundboard sound that was identified, or `nil`.
    def soundboard_sound
      return unless @soundboard_sound_id

      if @soundboard_sound_id < Discordrb::DISCORD_EPOCH
        # Default sounds have an ID which is a normal number
        # like 1 or 2. So we can check if the ID is smaller than
        # the base DISCORD_EPOCH (which is a big number), and thus
        # we can determine if the sound is a default soundboard sound or not.
        @bot.default_soundboard_sound(@soundboard_sound_id)
      else
        sounds = @bot.servers.values.flat_map(&:soundboard_sounds)

        sounds.find { |sound| sound.resolve_id == @soundboard_sound_id }
      end
    end

    # Check if the animation was the standard animation.
    # @return [true, false] Whether or not the animation type is for a standard user.
    def basic?
      @animation_type == 1
    end

    # Check if the animation was a fun animation sent by a nitro subscriber.
    # @return [true, false] Whether or not the animation type is for a premium subscriber.
    def nitro?
      @animation_type.zero?
    end

    alias_method :premium?, :nitro?

    # Get the member that sent the voice channel effect.
    # @return [User, Member] The member or user that sent the voice channel effect.
    #   This will almost always be a server member, but there are some edge-cases where it
    #   can be a user. E.g. one of the homies played a soundboard sound they shouldn't have and got banned.
    def member
      @member ||= (server.member(@user_id) || @bot.user(@user_id))
    end

    alias_method :user, :member
  end

  # Event handler for the VOICE_CHANNEL_EFFECT_SEND event
  class VoiceChannelEffectEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceChannelEffectEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:animation_type], event.animation_type) do |a, e|
          case a
          when :nitro, :premium, 0
            e&.zero?
          when :basic, 1
            e == 1
          end
        end,

        matches_all(@attributes[:member] || @attributes[:user], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:soundboard_sound], event.soundboard_sound_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
