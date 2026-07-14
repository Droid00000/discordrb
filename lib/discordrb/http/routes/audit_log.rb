# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/audit-log
  module AuditLogEndpoints
    # @see https://docs.discord.com/developers/resources/audit-log#get-guild-audit-log
    def get_guild_audit_log(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/audit-logs", guild_id],
              params: filter_undef(params)
    end
  end
end
