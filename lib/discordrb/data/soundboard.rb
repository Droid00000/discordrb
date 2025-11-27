# frozen_string_literal: true

module Discordrb
  # A soundboard sound that can be played.
  class SoundboardSound
    include IDObject

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Float] the volume of the soundboard sound.
    attr_reader :volume

    # @return [User, nil] the creator of the soundboard sound.
    attr_reader :creator

    # @return [true, false] whether the soundboard sound can be used.
    attr_reader :available
    alias_method :available?, :available

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['sound_id'].to_i
      from_other(data)
    end

    # Check if this soundboard sound is a default sound.
    # @return [true, false] whether or this the soundboard sound is a default sound.
    def default?
      @id < Discordrb::DISCORD_EPOCH
    end

    # Get the emoji for this soundboard sound.
    # @return [Emoji, nil] the emoji of this soundboard sound, or `nil` for no emoji.
    def emoji
      @emoji_id ? @server&.emojis[@emoji_id] : @emoji_name
    end

    # Set the name of this soundboard sound to something new.
    # @param name [String] The new 2-32 character name of the soundboard sound.
    def name=(name)
      update_data(name: name)
    end

    # Set the volume of this soundboard sound to something new.
    # @param volume [Float, Integer, nil] The new volume of the soundboard sound, between 0 to 1.
    def volume=(volume)
      update_data(volume: volume&.to_f)
    end

    # Set the emoji of this soundboard sound to something new.
    # @param emoji [Emoji, Reaction, Integer, String, nil] The new emoji of the soundboard sound.
    def emoji=(emoji)
      emoji = case emoji
              when Integer, String
                name.to_i.zero? ? { name: emoji, id: nil } : { id: emoji, name: nil }
              when Emoji, Reaction
                emoji.id ? { id: emoji, name: nil } : { name: emoji, id: nil }
              when NilClass
                { name: nil, id: nil }
              else
                raise "Unsupported type: #{emoji.class}"
              end

      update_data(emoji.transform_keys! { |key| :"emoji_#{key}" })
    end

    # Delete this soundboard sound. This cannot be undone, so use with caution.
    # @param reason [String, nil] The audit log reason for deleting this soundboard sound.
    # @return [void]
    def delete(reason: nil)
      API::Server.delete_soundboard_sound(@bot.token, @server.id, @id, reason: reason)
      @server.soundboard_sounds.delete(@id)
    end

    # Play this soundboard sound in a voice channel. The bot must be connected to the voice channel.
    # @param channel [Integer, String, Channel] the voice channel to play this soundboard sound in.
    # @raise [ArgumentError] this can happen if the provided channel is not a voice channel.
    # @return [void]
    def play(channel)
      raise ArgumentError, 'Invalid channel type' unless @bot.channel(channel).voice?

      API::Channel.send_soundboard_sound(@bot.token, @id, channel.resolve_id, @server&.id)
    end

    # @!visibility private
    def inspect
      "<SoundboardSound id=#{@id} name=\"#{@name}\" volume=#{@volume} emoji=#{emoji.inspect}"
    end

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @volume = new_data['volume']&.to_f
      @available = new_data['available']
      @emoji_id = new_data['emoji_id']&.to_i
      @creator = bot.ensure_user(new_data['user']) if new_data['user']
      @emoji_name = new_data['emoji_name'] ? Emoji.new({ 'name' => new_data['emoji_name'] }, @bot) : nil
    end

    private

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.update_soundboard_sound(@bot.token, @server.id, @id, **new_data)))
    end
  end
end
