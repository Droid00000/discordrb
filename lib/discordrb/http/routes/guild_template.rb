# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/guild-template
  module GuildTemplateEndpoints
    # @see https://docs.discord.com/developers/resources/guild-template#get-guild-template
    def get_guild_template(template_code, **params)
      request Route[:GET, "/guilds/templates/#{template_code}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild-template#get-guild-templates
    def list_guild_templates(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/templates", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild-template#create-guild-template
    def create_guild_template(guild_id, **body)
      request Route[:POST, "/guilds/#{guild_id}/templates", guild_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/guild-template#sync-guild-template
    def sync_guild_template(guild_id, template_code, **body)
      request Route[:PUT, "/guilds/#{guild_id}/templates/#{template_code}", guild_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/guild-template#modify-guild-template
    def modify_guild_template(guild_id, template_code, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/templates/#{template_code}", guild_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/guild-template#delete-guild-template
    def delete_guild_template(guild_id, template_code, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/templates/#{template_code}", guild_id],
              params: filter_undef(params)
    end
  end
end
