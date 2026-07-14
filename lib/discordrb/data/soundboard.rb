# frozen_string_literal: true

module Discordrb
  # A sound that can be played in voice channels.
  class SoundboardSound
    include Snowflake

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Guild, nil] the guild of the soundboard sound.
    attr_reader :guild

    # @return [Float] the volume of the soundboard sound; between 0-1.
    attr_reader :volume

    # @return [true, false] whether or not the soundboard sound can be used.
    attr_reader :available
    alias available? available

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @id = data[:sound_id].to_i
      update_data(data)
    end

    # The CDN URL of the soundboard sound.
    # @return [String] The CDN URL of the soundbord sound.
    # @note You can save the URL to a file in `.mp3` or `.ogg` format.
    def url
      Assets[:soundboard_sound, @id]
    end

    # Get the emoji of the soundboard sound.
    # @return [Emoji, nil] The emoji of the soundboard sound, or `nil`.
    def emoji
      @emoji_id ? @guild.emoji(@emoji_id) : @emoji_name
    end

    # Get the creator of the soundboard sound.
    # @return [User, nil] The user who created the soundboard sound, or `nil`.
    def creator
      return @creator unless @creator.nil? && !(me = @guild&.bot)

      return unless me.can_create_expressions? || me.can_manage_expressions?

      update_data(@bot.http.get_guild_soundboard_sound(@guild.resolve_id, @id))

      @creator
    end

    # Delete the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for deleting the soundboard sound.
    # @return [nil]
    def delete(reason: nil)
      @bot.http.delete_guild_soundboard_sound(@guild.resolve_id, @id, reason: reason)
      nil.tap { @guild.delete_soundboard_sound(@id) }
    end

    # Play the soundboard sound in a voice channel.
    # @param channel [Channel, Integer, String] The channel where the soundboard sound should be played.
    # @return [nil]
    def play(channel)
      @bot.http.send_soundboard_sound(channel.resolve_id, sound_id: @id, source_guild_id: @guild&.id)
      nil
    end

    # Modify the properties of the soundboard sound.
    # @param name [String] The new name of the soundboard sound; between 2-32 characters.
    # @param volume [Float, #to_f, nil] The new volume of the soundboard sound; between 0-1.
    # @param emoji [Emoji, Integer, String, Reaction, nil] The new emoji of the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for modifying the soundboard sound.
    # @return [nil]
    def modify(name: :undef, volume: :undef, emoji: :undef, reason: nil)
      data = {
        name: name,
        volume: volume == :undef ? volume : volume&.to_f,
        **(emoji == :undef ? {} : Emoji.build_hash(emoji))
      }

      update_data(@bot.http.modify_guild_soundboard_sound(@guild.id, @id, **data, reason: reason))
      nil
    end

    # @!visibility private
    def inspect
      "<SoundboardSound id=#{@id} name=\"#{@name}\" volume=#{@volume} available=#{@available.inspect}>"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data[:name]
      @volume = new_data[:volume].to_f
      @available = new_data[:available]
      @emoji_id = new_data[:emoji_id]&.to_i
      @creator = @bot.ensure_user(new_data[:user]) if new_data[:user]
      @emoji_name = new_data[:emoji_name] ? Emoji.new({ name: new_data[:emoji_name] }, @bot) : nil
    end
  end
end
