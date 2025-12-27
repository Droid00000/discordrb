# frozen_string_literal: true

module Discordrb
  # A sound that can be played in voice channels.
  class Sound
    include IDObject

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Float] the volume of the soundboaard sound; between 0-1.
    attr_reader :volume

    # @return [true, false] whether or not this soundboard sound is available.
    attr_reader :available
    alias available? available

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['sound_id'].to_i
      @server_id = data['guild_id']&.to_i
      from_other(data)
    end

    # Check if the soundboard sound is a default sound.
    # @return [true, false] If the soundboard sound is a default sound.
    def default?
      @server_id.nil?
    end

    # Get the emoji of the soundboard sound.
    # @return [Emoji, nil] The emoji of the soundboard sound, or `nil`.
    def emoji
      @emoji_id ? @bot.server(@server_id).emojis[@emoji_id] : @emoji_name
    end

    # Get the user who uploaded the soundboard sound.
    # @return [User, nil] The user who uploaded the soundboard sound, or `nil`.
    def creator
      return @creator if @creator || default?

      from_other(JSON.parse(API::Server.get_soundboard_sound(@bot.token, @server_id, @id)))
      @creator
    end

    # Set the name of the soundboard sound to something new.
    # @param name [String] The new 2-32 character name of the soundboard sound.
    def name=(name)
      update_soundboard_sound(name: name)
    end

    # Set the emoji of the soundboard sound to something new.
    # @param emoji [String, Emoji, Integer, nil] The new emoji of the soundboard sound.
    def emoji=(emoji)
      update_soundboard_sound(Emoji.to_h(emoji))
    end

    # Set the volume of the soundboard sound to something new.
    # @param volume [Numeric, nil] The new volume of the soundboard sound, between 0-1.
    def volume=(volume)
      update_soundboard_sound(volume: volume&.to_f)
    end

    # Play the soundboard sound in a voice channel that the bot is currnetly connected to.
    # @param channel [Channel, Integer, String] The channel to play the soundboard sound in.
    # @return [nil]
    def play(channel)
      API::Channel.send_soundboard_sound(@bot.token, channel.resolve_id, @id, @server_id)
      nil
    end

    # Delete the soundboard sound. If this method is used on a default sound, an error is raised.
    # @param reason [String, nil] The audit log reason to show for deleting the soundboard sound.
    # @return [nil]
    def delete(reason: nil)
      raise Discordrb::Errors::NoPermission, 'You cannot delete a default soundboard sound' if default?

      API::Server.delete_soundboard_sound(@bot.token, @server_id, @id, reason: reason)
      @bot.server(@server_id).delete_soundboard_sound(@id)
      nil
    end

    # @!visibility private
    def inspect
      "<Sound id=#{@id} name=\"#{@name}\" volume=#{@volume} available=#{@available} emoji=#{emoji.inspect}"
    end

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @volume = new_data['volume']
      @available = new_data['available']
      @emoji_id = new_data['emoji_id']&.to_i
      @creator = @bot.ensure_user(new_data['user']) if new_data['user']
      @emoji_name = new_data['emoji_name'] ? Emoji.new({ 'name' => new_data['emoji_name'] }, @bot) : nil
    end

    private

    # @!visibility private
    def update_soundboard_sound(new_data)
      raise Discordrb::Errors::NoPermission, 'You cannot update a default soundboard sound' if default?

      from_other(JSON.parse(API::Server.update_soundboard_sound(@bot.token, @server_id, @id, **new_data)))
    end
  end
end
