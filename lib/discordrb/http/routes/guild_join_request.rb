# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/guild-join-request
  module GuildJoinRequestEndpoints
    # @see https://docs.discord.com/developers/resources/guild-join-request#list-guild-join-requests
    def list_guild_join_requests(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/requests", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild-join-request#action-guild-join-request
    def action_guild_join_request(guild_id, request_id, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/requests/#{request_id}", guild_id],
              body: filter_undef(body)
    end
  end
end
