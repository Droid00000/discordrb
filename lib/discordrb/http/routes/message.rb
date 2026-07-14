# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/messages
  module MessageEndpoints
    # @see https://docs.discord.com/developers/resources/message#get-channel-messages
    def list_channel_messages(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/messages", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#search-guild-messages
    def search_guild_messages(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/messages/search", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#get-channel-message
    def get_channel_message(channel_id, message_id, **params)
      request Route[:GET, "/channels/#{channel_id}/messages/#{message_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#create-message
    def create_message(channel_id, files: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/messages", channel_id],
              body: make_attachments(files, body)
    end

    # @see https://docs.discord.com/developers/resources/message#crosspost-message
    def crosspost_message(channel_id, message_id, **body)
      request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/crosspost", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/message#create-reaction
    def create_reaction(channel_id, message_id, emoji, **body)
      request Route[:PUT, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{uri_quote(emoji)}/@me", channel_id],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/message#delete-own-reaction
    def delete_own_reaction(channel_id, message_id, emoji, **params)
      request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{uri_quote(emoji)}/@me", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#delete-user-reaction
    def delete_user_reaction(channel_id, message_id, emoji, user_id, **params)
      request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{uri_quote(emoji)}/#{user_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#get-reactions
    def list_reactions(channel_id, message_id, emoji, **params)
      request Route[:GET, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{uri_quote(emoji)}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#delete-all-reactions
    def delete_all_reactions(channel_id, message_id, **params)
      request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#delete-all-reactions-for-emoji
    def delete_all_reactions_for_emoji(channel_id, message_id, emoji, **params)
      request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{uri_quote(emoji)}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#edit-message
    def edit_message(channel_id, message_id, files: :undef, **body)
      request Route[:PATCH, "/channels/#{channel_id}/messages/#{message_id}", channel_id],
              body: make_attachments(files, body)
    end

    # @see https://docs.discord.com/developers/resources/message#delete-message
    def delete_message(channel_id, message_id, reason: :undef, **params)
      # https://github.com/Rapptz/discord.py/blob/master/discord/http.py#L898
      time = (Time.now.utc - Discordrb::Snowflake.decompose(message_id.to_i))

      hash = if time <= 10
               [nil, 'under-10-seconds']
             elsif time >= 1_209_600
               [nil, 'older-than-two-weeks']
             else
               [nil, '10-seconds-to-14-days']
             end

      request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}", channel_id, *hash],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/message#bulk-delete-messages
    def bulk_delete_messages(channel_id, reason: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/messages/bulk-delete", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/message#get-channel-pins
    def list_channel_pins(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/messages/pins", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/message#pin-message
    def pin_message(channel_id, message_id, reason: :undef, **params)
      request Route[:PUT, "/channels/#{channel_id}/messages/pins/#{message_id}", channel_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/message#unpin-message
    def unpin_message(channel_id, message_id, reason: :undef, **params)
      request Route[:DELETE, "/channels/#{channel_id}/messages/pins/#{message_id}", channel_id],
              params: filter_undef(params), reason: reason
    end
  end
end
