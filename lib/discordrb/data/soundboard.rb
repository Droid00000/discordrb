# frozen_string_literal: true

module Discordrb
  # A soundboard sound that can be played in a voice channel.
  class SoundboardSound
    include IDObject

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Emoji, nil] the emoji of the soundboard sound.
    attr_reader :emoji

    # @return [Float] the volume of the soundboard sound, from 0-1.
    attr_reader :volume

    # @return [Server, nil] the server the soundboard sound is from.
    attr_reader :server

    # @return [User, nil] the user who uploaded the soundboard sound.
    attr_reader :creator

    # @return [true, false] whether the soundboard sound can be used.
    attr_reader :available
    alias_method :available?, :available

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = server
      @id = data['sound_id'].to_i
      @available = data['available']
      @creator = bot.ensure_user(data['user']) if data['user']
      from_other(data)
    end

    # Set the name of this soundboard sound to something new.
    # @param name [String] the new name of this soundboard sound.
    def name=(name)
      update_data(name: name)
    end

    # Set the volume of this soundboard sound to something new.
    # @param volume [Numeric, nil] the new volume of this soundboard sound.
    def volume=(volume)
      update_data(volume: volume&.to_f)
    end

    # Set the emoji of this soundboard sound to something new.
    # @param emoji [String, Integer, Emoji, nil] the new emoji of this soundboard sound.
    def emoji=(emoji)
      emoji = case emoji
              when Integer, String
                emoji.to_i.zero? ? { name: emoji, id: nil } : { id: emoji.to_i, name: nil }
              when Emoji, Reaction
                emoji.id.nil? ? { name: emoji.name, id: nil } : { id: emoji.id, name: nil }
              else
                emoji.nil? ? { name: nil, id: nil } : emoji.to_h
              end

      update_data(emoji&.transform_keys { |key| :"emoji_#{key}" })
    end

    # Get the CDN url of this soundboard sound.
    # @return [String] the CDN url this soundboard sound can be accessed at.
    def url
      API.soundboard_sound_url(@id)
    end

    # Delete this soundboard sound. Use this with caution, as it cannot be undone.
    # @param reason [String, nil] the reason for deleting this soundboard sound.
    # @return [void]
    def delete(reason: nil)
      raise 'You cannot delete a default soundboard sound' if @server.nil?

      API::Soundboard.delete_soundboard_sound(@bot.token, @server.id, @id, reason)
      @server.delete_soundboard_sound(@id)
    end

    # Play this soundboard sound in a voice channel. The user must be connected to the voice channel.
    # @param channel [Integer, String, Channel] the voice channel to play this soundboard sound in.
    # @raise [ArgumentError] this can happen if the provided channel is not a voice channel.
    # @return [void]
    def play(channel)
      raise ArgumentError, 'Invalid channel type' unless @bot.channel(channel).voice?

      API::Soundboard.send_soundboard_sound(@bot.token, channel.resolve_id, @id, @server&.id)
    end

    # @!visibility private
    def inspect
      "<SoundboardSound id=#{@id} name=\"#{@name}\" volume=#{@volume} emoji=#{@emoji} creator=#{@creator}"
    end

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @volume = new_data['volume'].to_f
      @emoji = @server.emojis[new_data['emoji_id'].to_i] if new_data['emoji_id']
      @emoji = Emoji.new({ 'name' => new_data['emoji_name'], 'animated' => false }, @bot) if new_data['emoji_name']
    end

    # @!visibility private
    def update_data(new_data)
      raise 'You cannot update a default soundboard sound.' if @server.nil?

      from_other(JSON.parse(API::Soundboard.update_soundboard_sound(@bot.token,
                                                                    @server.id, @id,
                                                                    new_data[:name] || :undef,
                                                                    new_data.key?(:volume) ? new_data[:volume] : :undef,
                                                                    new_data.key?(:emoji_id) ? new_data[:emoji_id] : :undef,
                                                                    new_data.key?(:emoji_name) ? new_data[:emoji_name] : :undef)))
    end
  end
end
