# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/voice
  module VoiceEndpoints
    # @see https://docs.discord.com/developers/resources/voice#list-voice-regions
    def list_voice_regions(**params)
      request Route[:GET, '/voice/regions'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/voice#get-current-user-voice-state
    def get_current_user_voice_state(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/voice-states/@me", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/voice#get-user-voice-state
    def get_user_voice_state(guild_id, user_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/voice-states/#{user_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/voice#modify-current-user-voice-state
    def modify_current_user_voice_state(guild_id, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/voice-states/@me", guild_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/voice#modify-user-voice-state
    def modify_user_voice_state(guild_id, user_id, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/voice-states/#{user_id}", guild_id],
              body: filter_undef(body)
    end
  end
end
