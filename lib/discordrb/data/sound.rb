# frozen_string_literal: true

module Discordrb
  # A soundboard sound.
  class Sound
    include IDObject

    # @return [String] The name of this soundboard sound.
    attr_reader :name

    # @return [Integer] The volume of this sound. Ranges between 0-1.
    attr_reader :volume

    # @return [Integer, String] The ID of the custom emoji of this sound, or the unicode emoji.
    attr_reader :emoji

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
      @id = data['sound_id']
      @volume = data['volume']
      @available = data['available']
      @user = bot.ensure_user(data['user'])
      @emoji = data['emoji_id']&.to_i || data['emoji_name']
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

    # Set the emoji of this sound.
    # @param [Integer, String, Emoji, nil]
    def emoji=(emoji)
      case emoji
      when Integer, String
        emoji.to_i.positive? ? update_data(emoji_id: emoji) : update_data(emoji_name: emoji)
      when Reaction, Emoji
        emoji.id.nil? ? update_data(emoji_name: emoji.id) : update_data(emoji_id: emoji.id)
      else
        @emoji.is_a?(String) ? update_data(emoji_name: emoji) : update_data(emoji_id: emoji)
      end
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
      @name = data['name'] if data['name']
      @volume = data['volume'] if data['volume']
      @emoji data['emoji_id'] || data['emoji_name'] if data['emoji_id'] || data['emoji_name']
    end

    # @!visibility hidden
    def update_data(new_data)
      update_sound_data(JSON.parse(API::Server.update_soundboard_sound(@bot.token, @server.id, @id,
                                                                       new_data[:name] || @name,
                                                                       new_data[:volume] || @volume,
                                                                       new_data[:emoji_id] || @emoji,
                                                                       new_data[:emoji_name] || @emoji)))
    end
  end
end
