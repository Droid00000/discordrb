# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/webhook
  module WebhookEndpoints
    # @see https://docs.discord.com/developers/resources/webhook#get-guild-webhooks
    def list_guild_webhooks(guild_id, **params)
      request Route[:GET, "/guilds/#{guild_id}/webhooks", guild_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/webhook#get-channel-webhooks
    def list_channel_webhooks(channel_id, **params)
      request Route[:GET, "/channels/#{channel_id}/webhooks", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/webhook#get-webhook
    def get_webhook(webhook_id, **params)
      request Route[:GET, "/webhooks/#{webhook_id}", webhook_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/webhook#get-webhook-with-token
    def get_webhook_with_token(webhook_id, webhook_token, **params)
      request Route[:GET, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/webhook#create-webhook
    def create_webhook(channel_id, reason: :undef, **body)
      request Route[:POST, "/channels/#{channel_id}/webhooks", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/webhook#modify-webhook
    def modify_webhook(webhook_id, reason: :undef, **body)
      request Route[:PATCH, "/webhooks/#{webhook_id}", webhook_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/webhook#modify-webhook-with-token
    def modify_webhook_with_token(webhook_id, webhook_token, reason: :undef, **body)
      request Route[:PATCH, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/webhook#delete-webhook
    def delete_webhook(webhook_id, reason: :undef, **params)
      request Route[:DELETE, "/webhooks/#{webhook_id}", webhook_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/webhook#delete-webhook-with-token
    def delete_webhook_with_token(webhook_id, webhook_token, reason: :undef, **params)
      request Route[:DELETE, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id],
              params: filter_undef(params), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/webhook#get-webhook-message
    def get_webhook_message(webhook_id, webhook_token, message_id, **params)
      request Route[:GET, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/webhook#execute-webhook
    def execute_webhook(webhook_id, webhook_token, wait: :undef, with_components: :undef, thread_id: :undef, files: :undef, **body)
      request Route[:POST, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id],
              body: make_attachments(files, body), params: filter_undef({ wait:, with_components:, thread_id: })
    end

    # @see https://docs.discord.com/developers/resources/webhook#edit-webhook-message
    def edit_webhook_message(webhook_id, webhook_token, message_id, thread_id: :undef, with_components: :undef, files: :undef, **body)
      request Route[:PATCH, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id],
              body: make_attachments(files, body), params: filter_undef({ with_components:, thread_id: })
    end

    # @see https://docs.discord.com/developers/resources/webhook#delete-webhook-message
    def delete_webhook_message(webhook_id, webhook_token, message_id, **params)
      request Route[:DELETE, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id],
              params: filter_undef(params)
    end
  end
end
