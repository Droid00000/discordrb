# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/emoji
  module EmojiEndpoints
    # @see https://docs.discord.com/developers/resources/emoji#list-guild-emojis
    def list_guild_emojis(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/emojis", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/emoji#get-guild-emoji
    def get_guild_emoji(guild_id, emoji_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/emojis/#{emoji_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/emoji#create-guild-emoji
    def create_guild_emoji(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/emojis", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/emoji#modify-guild-emoji
    def modify_guild_emoji(guild_id, emoji_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/emojis/#{emoji_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/emoji#delete-guild-emoji
    def delete_guild_emoji(guild_id, emoji_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/emojis/#{emoji_id}", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/emoji#list-application-emojis
    def list_application_emojis(application_id, **params)
      request Route[:GET, "/applications/#{application_id}/emojis"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/emoji#get-application-emoji
    def get_application_emoji(application_id, emoji_id, **params)
      request Route[:GET, "/applications/#{application_id}/emojis/#{emoji_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/emoji#create-application-emoji
    def create_application_emoji(application_id, **body)
      request Route[:POST, "/applications/#{application_id}/emojis"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/emoji#modify-application-emoji
    def modify_application_emoji(application_id, emoji_id, **body)
      request Route[:PATCH, "/applications/#{application_id}/emojis/#{emoji_id}"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/emoji#delete-application-emoji
    def delete_application_emoji(application_id, emoji_id, **params)
      request Route[:DELETE, "/applications/#{application_id}/emojis/#{emoji_id}"],
              params: filter_undef(params)
    end
  end
end
