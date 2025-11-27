# frozen_string_literal: true

module Discordrb::Events
  # Generic subclass for soundboard sound events (create/update).
  class SoundboardSoundEvent < Event
    # @return [Server] the server the soundboard sound is from.
    attr_reader :server

    # @return [SoundboardSound] the soundboard sound in question.
    attr_reader :soundboard_sound

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @soundboard_sound = @server.soundboard_sound(data['id'].to_i)
    end
  end

  # Raised when a soundboard sound is deleted.
  class SoundboardSoundDeleteEvent < Event
    # @return [Integer] the ID of the deleted soundboard sound.
    attr_reader :id

    # @return [Server] the server the soundboard sound was deleted from.
    attr_reader :server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['sound_id'].to_i
      @server = bot.server(data['guild_id'].to_i)
    end
  end

  # Raised when multiple soundboard sounds are updated together.
  class SoundboardSoundsUpdateEvent < Event
    # @return [Server] the server the soundboard sounds are from.
    attr_reader :server

    # @return [Array<SoundboardSound>] the soundboard sounds that were updated.
    attr_reader :soundboard_sounds

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @soundboard_sounds = @server.soundboard_sounds
    end
  end

  # Raised when an effect is sent to a voice channel.
  class VoiceChannelEffectSendEvent < Event
    # @!visibility private
    attr_reader :user_id, :sound_id, :server_id, :channel_id

    # @return [Emoji, nil] the emoji that was sent.
    attr_reader :emoji

    # @return [Server] the server the effect was sent in.
    attr_reader :server

    # @return [Channel] the channel the effect was sent in.
    attr_reader :channel

    # @return [Integer, nil] the ID of the emoji animation.
    attr_reader :animation_id

    # @return [Integer, nil] the type of the emoji animation.
    attr_reader :animation_type

    # @return [Float, nil] the volume of the soundboard sound.
    attr_reader :sound_volume

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id'].to_i
      @sound_id = data['sound_id']&.to_i
      @server_id = data['guild_id'].to_i
      @animation_id = data['animation_id']
      @channel_id = data['channel_id'].to_i
      @animation_type = data['animation_type']
      @sound_volume = data['sound_volume']&.to_f
      @emoji = Discordrb::Emoji.new(data['emoji'], @bot) if data['emoji']
    end

    # Whether the animation type of this effect is `:premium`.
    # @return [true, false]
    def premium_animation?
      @animation_type.zero?
    end

    # Whether the animation type of this effect is `:basic`.
    # @return [true, false]
    def standard_animation?
      @animation_type == 1
    end

    # Get the server this voice channel effect was sent in.
    # @return [Server] the server this effect was sent in.
    def server
      @bot.server(@server_id)
    end

    # Get the channel this voice channel effect was sent in.
    # @return [Channel] the channel this effect was sent in.
    def channel
      @bot.channel(@channel_id)
    end

    # Get the member that sent this voice channel effect.
    # @return [Member, User] the member that sent this effect,
    #   or their user, if the member couldn't be resolved.
    def user
      @user ||= (@server.member(@user_id) || @bot.user(@user_id))
    end

    alias_method :member, :user

    # Get the soundboard sound that was played.
    # @return [SoundboardSound, nil] the soundboard sound that was played.
    def soundboard_sound
      @server.soundboard_sound(@sound_id) if @sound_id
    end
  end

  # Raised when an soundboard sound is created.
  class SoundboardSoundCreateEvent < SoundboardSoundEvent; end

  # Raised when an soundboard sound is updated.
  class SoundboardSoundUpdateEvent < SoundboardSoundEvent; end

  # Event handler for generic soundboard sound events.
  class SoundboardSoundEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(SoundboardSoundEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.soundboard_sound) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for soundboard sound delete events.
  class SoundboardSoundDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(SoundboardSoundDeleteEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for soundboard sounds update events.
  class SoundboardSoundsUpdateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(SoundboardSoundsUpdateEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for voice channel effect send events.
  class VoiceChannelEffectSendEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(VoiceChannelEffectSendEvent)

      [
        matches_all(@attributes[:emoji], event.emoji) do |a, e|
          a == e
        end,

        matches_all(@attributes[:user], event.user_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:soundboard_sound], event.sound_id) do |a, e|
          a.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:animation_id], event.animation_id) do |a, e|
          a.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:sound_volume], event.sound_volume) do |a, e|
          e ? ((a.to_f - e.to_f).abs < Float::EPSILON) : false
        end,

        matches_all(@attributes[:animation_type], event.animation_type) do |a, e|
          case a
          when :premium, :nitro
            e.zero?
          when :standard, :basic
            e == 1
          else
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :GUILD_SOUNDBOARD_SOUND_CREATE events.
  class SoundboardSoundCreateEventHandler < SoundboardSoundEventHandler; end

  # Event handler for :GUILD_SOUNDBOARD_SOUND_UPDATE events.
  class SoundboardSoundUpdateEventHandler < SoundboardSoundEventHandler; end
end
