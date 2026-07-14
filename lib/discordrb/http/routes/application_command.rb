# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://discord.com/developers/docs/interactions/application-commands
  module ApplicationCommandEndpoints
    # @see https://docs.discord.com/developers/interactions/application-commands#get-global-application-commands
    def get_global_application_commands(application_id, **params)
      request Route[:GET, "/applications/#{application_id}/commands"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#create-global-application-command
    def create_global_application_command(application_id, **body)
      request Route[:POST, "/applications/#{application_id}/commands"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#get-global-application-command
    def get_global_application_command(application_id, command_id, **params)
      request Route[:GET, "/applications/#{application_id}/commands/#{command_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#edit-global-application-command
    def modify_global_application_command(application_id, command_id, **body)
      request Route[:PATCH, "/applications/#{application_id}/commands/#{command_id}"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#delete-global-application-command
    def delete_global_application_command(application_id, command_id, **params)
      request Route[:DELETE, "/applications/#{application_id}/commands/#{command_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#bulk-overwrite-global-application-commands
    def bulk_overwrite_global_application_commands(application_id, application_commands)
      request Route[:PUT, "/applications/#{application_id}/commands"],
              body: application_commands
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#get-guild-application-commands
    def get_guild_application_commands(application_id, guild_id, **params)
      request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#get-guild-application-command
    def get_guild_application_command(application_id, guild_id, command_id, **params)
      request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#create-guild-application-command
    def create_guild_application_command(application_id, guild_id, **body)
      request Route[:POST, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#edit-guild-application-command
    def modify_guild_application_command(application_id, guild_id, command_id, **body)
      request Route[:PATCH, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#delete-guild-application-command
    def delete_guild_application_command(application_id, guild_id, command_id, **params)
      request Route[:DELETE, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#bulk-overwrite-guild-application-commands
    def bulk_overwrite_guild_application_commands(application_id, guild_id, application_commands)
      request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
              body: application_commands
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#get-guild-application-command-permissions
    def get_guild_application_command_permissions(application_id, guild_id, **params)
      request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/permissions"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/application-commands#get-application-command-permissions
    def get_application_command_permissions(application_id, guild_id, command_id, **params)
      request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions"],
              params: filter_undef(params)
    end
  end
end
