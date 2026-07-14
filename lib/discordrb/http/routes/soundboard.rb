# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/soundboard
  module SoundboardEndpoints
    # @see https://docs.discord.com/developers/resources/soundboard#send-soundboard-sound
    def send_soundboard_sound(channel_id, **body)
      request Route[:POST, "/channels/#{channel_id}/send-soundboard-sound", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/soundboard#list-default-soundboard-sounds
    def list_default_soundboard_sounds(**params)
      request Route[:GET, '/soundboard-default-sounds'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/soundboard#list-guild-soundboard-sounds
    def list_guild_soundboard_sounds(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/soundboard-sounds", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/soundboard#get-guild-soundboard-sound
    def get_guild_soundboard_sound(guild_id, soundboard_sound_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/soundboard-sounds/#{soundboard_sound_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/soundboard#create-guild-soundboard-sound
    def create_guild_soundboard_sound(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/soundboard-sounds", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/soundboard#modify-guild-soundboard-sound
    def modify_guild_soundboard_sound(guild_id, soundboard_sound_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/soundboard-sounds/#{soundboard_sound_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/soundboard#delete-guild-soundboard-sound
    def delete_guild_soundboard_sound(guild_id, soundboard_sound_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/soundboard-sounds/#{soundboard_sound_id}", guild_id],
              params: filter_undef(params), reason: reason
    end
  end
end
