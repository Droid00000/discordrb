# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/auto-moderation
  module AutoModerationEndpoints
    # @see https://docs.discord.com/developers/resources/auto-moderation#list-auto-moderation-rules-for-guild
    def list_auto_moderation_rules(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/auto-moderation#get-auto-moderation-rule
    def get_auto_moderation_rule(guild_id, auto_moderation_rule_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/auto-moderation#create-auto-moderation-rule
    def create_auto_moderation_rule(guild_id, reason: :undef, **body)
      request Route[:POST, "/guilds/#{guild_id}/auto-moderation/rules", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/auto-moderation#modify-auto-moderation-rule
    def modify_auto_moderation_rule(guild_id, auto_moderation_rule_id, reason: :undef, **body)
      request Route[:PATCH, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}", guild_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/auto-moderation#delete-auto-moderation-rule
    def delete_auto_moderation_rule(guild_id, auto_moderation_rule_id, reason: :undef, **params)
      request Route[:DELETE, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}", guild_id],
              params: filter_undef(params), reason: reason
    end
  end
end
