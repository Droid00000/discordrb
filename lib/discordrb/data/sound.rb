# frozen_string_literal: true

module Discordrb
  # A soundboard sound that can be played in a voice channel.
  class Sound
    include IDObject

    # @return [String] The name of this soundboard sound.
    attr_reader :name

    # @return [Integer] The volume of this sound. Ranges between 0-1.
    attr_reader :volume

    # @return [Server, nil] The server of this sound, or nil if this sound isn't from a server.
    attr_reader :server

    # @return [true, false, nil] If this sound is usable. May be false due to a lack of server boosts.
    attr_reader :available
    alias_method :available?, :available

    # @return [User, nil] The user who created this sound, or nil if the bot doesn't have the permissions to view this.
    attr_reader :user

    # @!visibility hidden
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = server
      @name = data['name']
      @id = data['sound_id']
      @volume = data['volume']
      @available = data['available']
      @emoji_name = data['emoji_name']
      @emoji_id = data['emoji_id']&.to_i
      @user = data['user'] ? bot.ensure_user(data['user']) : nil
    end

    # Set the name of this sound.
    # @param [String, nil]
    def name=(name)
      update_data(name: name)
    end

    # Set the volume of this sound.
    # @param [Integer, nil]
    def volume=(volume)
      update_data(volume: volume)
    end

    # @return [Integer, String, Emoji, nil] Unicode emoji, emoji object, or ID if the emoji's server is unknown.
    def emoji
      @emoji_name || @bot.emoji(@emoji_id) || @emoji_id
    end

    # Set the emoji of this sound.
    # @param [Integer, String, Emoji, nil]
    def emoji=(emoji)
      emoji = case emoji
              when Integer, String
                emoji.to_i.zero? ? e_name = emoji : e_id = emoji
              when respond_to?(:to_h)
                emoji.id ? e_id = emoji.id : e_name = emoji
              else
                @emoji_id ? e_id = emoji : e_name = emoji
              end

      update_data(emoji_name: e_name, emoji_id: e_id)
    end

    # URL of this soundboard sound.
    # @return [String] CDN URL of this sound.
    def url
      API.soundboard_sound(@id)
    end

    # Delete this sound. This cannot be undone.
    # @param reason [String, nil] The reason for deleting this sound.
    def delete(reason = nil)
      API::Server.delete_soundboard_sound(@bot.token, @server.id, @id, reason)
      @server.soundboard_sounds.delete(@id)
    end

    # @!visibility hidden
    def update_sound_data(data)
      data.transform_keys(&:to_s)
      
      @name = data['name']
      @volume = data['volume']
      @emoji_id = data['emoji_id'] if data.key?('emoji_id')
      @emoji_name = data['emoji_name'] if data.key?('emoji_name')
    end

    # @!visibility hidden
    def update_data(data)
      update_sound_data(JSON.parse(API::Server.update_soundboard_sound(@bot.token,
                                                                       @server.id, @id,
                                                                       data[:name] || @name,
                                                                       data[:volume] || @volume,
                                                                       data.key?(:emoji_id) ? data[:emoji_id] : @emoji_id,
                                                                       data.key?(:emoji_name) ? data[:emoji_name] : @emoji_name)))
    end
  end
end
