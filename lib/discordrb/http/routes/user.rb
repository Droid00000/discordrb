# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/user
  module UserEndpoints
    # @see https://docs.discord.com/developers/resources/user#get-current-user
    def get_current_user(**params)
      request Route[:GET, '/users/@me'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/user#get-user
    def get_user(user_id, **params)
      request Route[:GET, "/users/#{user_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/user#modify-current-user
    def modify_current_user(**body)
      request Route[:PATCH, '/users/@me'],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/user#get-current-user-guilds
    def get_current_user_guilds(**params)
      request Route[:GET, '/users/@me/guilds'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/user#leave-guild
    def leave_guild(guild_id, **params)
      request Route[:DELETE, "/users/@me/guilds/#{guild_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/user#create-dm
    def create_dm_channel(**body)
      request Route[:POST, '/users/@me/channels'],
              body: filter_undef(body)
    end
  end
end
