# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/guild
  module GuildEndpoints
    # @see https://docs.discord.com/developers/resources/guild#get-guild
    def get_guild(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-preview
    def get_guild_preview(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/preview", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild
    def modify_guild(guild_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-channels
    def list_guild_channels(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/channels", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#create-guild-channel
    def create_guild_channel(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/channels", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-channel-positions
    def modify_guild_channel_positions(guild_id, channels)
      request Route[:PATCH, "/guilds/#{guild_id}/channels", guild_id],
              body: channels
    end

    # @see https://docs.discord.com/developers/resources/guild#list-active-guild-threads
    def list_active_guild_threads(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/threads/active", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-member
    def get_guild_member(guild_id, user_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#list-guild-members
    def list_guild_members(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/members", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#search-guild-members
    def search_guild_members(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/members/search", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#add-guild-member
    def add_guild_member(guild_id, user_id, **body)
      request Route[:PUT, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-member
    def modify_guild_member(guild_id, user_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-current-member
    def modify_current_guild_member(guild_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/members/@me", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#add-guild-member-role
    def add_guild_member_role(guild_id, user_id, role_id, reason: :undef, **body)
      request Route[:PUT, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#remove-guild-member-role
    def remove_guild_member_role(guild_id, user_id, role_id, reason: :undef, **body)
      request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#remove-guild-member
    def remove_guild_member(guild_id, user_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-bans
    def list_guild_bans(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/bans", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-ban
    def get_guild_ban(guild_id, user_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#create-guild-ban
    def create_guild_ban(guild_id, user_id, reason: :undef, **body)
      request Route[:PUT, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#remove-guild-ban
    def remove_guild_ban(guild_id, user_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#bulk-guild-ban
    def bulk_guild_ban(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/bulk-ban", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-roles
    def list_guild_roles(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/roles", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-role
    def get_guild_role(guild_id, role_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-role-member-counts
    def get_guild_role_member_counts(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/roles/member-counts", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#create-guild-role
    def create_guild_role(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/roles", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-role-positions
    def modify_guild_role_positions(guild_id, roles, reason: :undef)
      request Route[:PATCH, "/guilds/#{guild_id}/roles", guild_id],
              body: roles, reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-role
    def modify_guild_role(guild_id, role_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#delete-guild-role
    def delete_guild_role(guild_id, role_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-prune-count
    def get_guild_prune_count(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/prune", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#begin-guild-prune
    def begin_guild_prune(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/prune", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-voice-regions
    def list_guild_voice_regions(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/regions", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-invites
    def list_guild_invites(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/invites", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-integrations
    def list_guild_integrations(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/integrations", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#delete-guild-integration
    def delete_guild_integration(guild_id, integration_id, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/integrations/#{integration_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-widget-settings
    def get_guild_widget_settings(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/widget", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-widget
    def modify_guild_widget_settings(guild_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/widget", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-vanity-url
    def get_guild_vanity_url(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/vanity-url", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-welcome-screen
    def get_guild_welcome_screen(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/welcome-screen", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-welcome-screen
    def modify_guild_welcome_screen(guild_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/welcome-screen", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#get-guild-onboarding
    def get_guild_onboarding(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/onboarding", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-onboarding
    def modify_guild_onboarding(guild_id, reason: :undef, **body)
      request Route[:PUT, "/guilds/#{guild_id}/onboarding", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild#modify-guild-incident-actions
    def modify_guild_incident_actions(guild_id, reason: :undef, **body)
      request Route[:PUT, "/guilds/#{guild_id}/incident-actions", guild_id],
              body: filter_undef(body), reason: reason
    end
  end
end
