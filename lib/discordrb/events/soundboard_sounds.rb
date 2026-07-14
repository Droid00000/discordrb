# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for soundboard sound events.
  class SoundboardSoundEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [SoundboardSound] the soundboard sound associated with the event.
    attr_reader :soundboard_sound

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
      @soundboard_sound = @guild.soundboard_sound(data[:sound_id].to_i)
    end
  end

  # Raised whenever a soundboard sound is created.
  class SoundboardSoundCreateEvent < SoundboardSoundEvent; end

  # Raised whenever a soundboard sound is updated.
  class SoundboardSoundUpdateEvent < SoundboardSoundEvent; end

  # Raised whenever a soundboard sound is deleted.
  class SoundboardSoundDeleteEvent < Event
    # @return [Guild] the guild associated with the event.
    attr_reader :guild

    # @return [Integer] the ID of the soundboard sound associated with the event.
    attr_reader :soundboard_sound_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @guild = bot.guild(data[:guild_id].to_i)
      @soundboard_sound_id = data[:sound_id].to_i
    end
  end

  # Generic event handler for soundboard sound events.
  class SoundboardSoundEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SoundboardSoundEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.soundboard_sound) do |a, e|
          a&.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:creator], event.soundboard_sound) do |a, e|
          a&.resolve_id == e.creator&.id
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

  # Event handler for GUILD_SOUNDBOARD_SOUND_CREATE events.
  class SoundboardSoundCreateEventHandler < SoundboardSoundEventHandler; end

  # Event handler for GUILD_SOUNDBOARD_SOUND_UPDATE events.
  class SoundboardSoundUpdateEventHandler < SoundboardSoundEventHandler; end

  # Event handler for GUILD_SOUNDBOARD_SOUND_DELETE events.
  class SoundboardSoundDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(SoundboardSoundDeleteEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.soundboard_sound_id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever a voice channel effect is sent.
  class VoiceChannelEffectEvent < Event
    # @return [Emoji, nil] the emoji of the effect.
    attr_reader :emoji

    # @return [Channel] the channel the effect was sent in.
    attr_reader :channel

    # @return [Integer] the ID of the user who sent the effect.
    attr_reader :user_id

    # @return [Integer, nil] the animation ID of the sent effect.
    attr_reader :animation_id

    # @return [Integer, nil] the animation type of the sent effect.
    attr_reader :animation_type

    # @return [Integer, nil] the ID of the soundboard sound, if applicable.
    attr_reader :soundboard_sound_id

    # @return [Float, nil] the volume of the soundboard sound, if applicable.
    attr_reader :soundboard_sound_volume

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data[:user_id]&.to_i
      @animation_id = data[:animation_id]
      @animation_type = data[:animation_type]
      @soundboard_sound_id = data[:sound_id]&.to_i
      @soundboard_sound_volume = data[:sound_volume]&.to_f
      @channel = @bot.channel(data[:channel_id]&.to_i)
      @emoji = Discordrb::Emoji.new(data[:emoji], @bot) if data[:emoji]
    end

    # Get the guild assoicated with the event.
    # @return [Guild] The guild that the effect was sent in.
    def guild
      @channel.guild
    end

    # Get the soundboard sound that was played, if applicable.
    # @return [SoundboardSound, nil] The soundboard sound that was identified.
    def soundboard_sound
      return unless @soundboard_sound_id

      if @soundboard_sound_id < Discordrb::DISCORD_EPOCH
        # Default soundboard sounds have IDs smaller than the DISCORD_EPOCH.
        @bot.default_soundboard_sound(@soundboard_sound_id)
      else
        @bot.guilds.each_value do |guild|
          sound = guild.soundboard_sound(@soundboard_sound_id, request: false)
          return sound if sound
        end
      end

      nil
    end

    # Get the CDN URL to the soundboard sound that was played, if applicable.
    # @return [String, nil] The CDN URL to the soundboard sound that was played.
    def soundboard_sound_url
      return unless @soundboard_sound_id

      Discordrb::Assets[:soundboard_sound, @soundboard_sound_id]
    end

    # Check if the animation was the standard animation.
    # @return [true, false] Whether or not the animation type is for a standard user.
    def basic_animation?
      @animation_type == 1
    end

    # Check if the animation was a fun animation sent by a nitro subscriber.
    # @return [true, false] Whether or not the animation type is for a nitro subscriber.
    def premium_animation?
      @animation_type.zero?
    end

    # Get the member that sent the voice channel effect.
    # @return [User, Member] The member or user that sent the voice channel effect.
    #   Should always be a member, unless the member was recently removed from the guild.
    def member
      @member ||= (guild&.member(@user_id) || @bot.user(@user_id))
    end

    alias_method :user, :member
  end

  # Event handler for VOICE_CHANNEL_EFFECT_SEND events.
  class VoiceChannelEffectEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(VoiceChannelEffectEvent)

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:soundboard_sound], event.soundboard_sound_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
