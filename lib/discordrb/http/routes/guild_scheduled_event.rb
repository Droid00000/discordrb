# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/guild-scheduled-event
  module GuildScheduledEventEndpoints
    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#list-scheduled-events-for-guild
    def list_guild_scheduled_events(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/scheduled-events", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#get-guild-scheduled-event
    def get_guild_scheduled_event(guild_id, guild_scheduled_event_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#create-guild-scheduled-event
    def create_guild_scheduled_event(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/scheduled-events", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#modify-guild-scheduled-event
    def modify_guild_scheduled_event(guild_id, guild_scheduled_event_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#delete-guild-scheduled-event
    def delete_guild_scheduled_event(guild_id, guild_scheduled_event_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}", guild_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/guild-scheduled-event#get-guild-scheduled-event-users
    def list_guild_scheduled_event_users(guild_id, guild_scheduled_event_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}/users", guild_id],
              params: filter_undef(params)
    end
  end
end
