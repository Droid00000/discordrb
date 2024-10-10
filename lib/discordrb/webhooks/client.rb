# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'

require 'discordrb/webhooks/builder'

module Discordrb::Webhooks
  # A client for a particular webhook added to a Discord channel.
  class Client
    # Create a new webhook
    # @param url [String] The URL to post messages to.
    # @param id [Integer] The webhook's ID. Will only be used if `url` is not
    #   set.
    # @param token [String] The webhook's authorisation token. Will only be used
    #   if `url` is not set.
    def initialize(url: nil, id: nil, token: nil)
      @url = url || generate_url(id, token)
      @faraday = Faraday.new(@url) do |f|
        f.request :multipart
        f.request :json
      end
    end

    # Executes the webhook this client points to with the given data.
    # @param builder [Builder] The builder to start out with, or nil if one should be created anew.
    # @param wait [true, false] Whether Discord should wait for the message to be successfully received by clients, or
    #   whether it should return immediately after sending the message.
    # @yield [builder] Gives the builder to the block to add additional steps, or to do the entire building process.
    # @yieldparam builder [Builder] The builder given as a parameter which is used as the initial step to start from.
    # @example Execute the webhook with an already existing builder
    #   builder = Discordrb::Webhooks::Builder.new # ...
    #   client.execute(builder)
    # @example Execute the webhook by building a new message
    #   client.execute do |builder|
    #     builder.content = 'Testing'
    #     builder.username = 'discordrb'
    #     builder.add_embed do |embed|
    #       embed.timestamp = Time.now
    #       embed.title = 'Testing'
    #       embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/PcMltU7.jpg')
    #     end
    #   end
    # @return [Faraday::Response] the response returned by Discord.
    # rubocop:disable Lint/UselessAssignment
    def execute(builder = nil, wait = false, components = nil)
      raise TypeError, 'builder needs to be nil or like a Discordrb::Webhooks::Builder!' unless
        (builder.respond_to?(:file) && builder.respond_to?(:to_multipart_hash)) || builder.respond_to?(:to_h) || builder.nil?

      builder ||= Builder.new
      view = View.new

      yield(builder, view) if block_given?

      components ||= view

      @faraday.post(wait ? '?wait=true' : '', builder.to_h)
    end
    # rubocop:enable Lint/UselessAssignment

    # Modify this webhook's properties.
    # @param name [String, nil] The default name.
    # @param avatar [String, #read, nil] The new avatar, in base64-encoded JPG format.
    # @param channel_id [String, Integer, nil] The channel to move the webhook to.
    # @return [Faraday::Response] the response returned by Discord.
    def modify(name: nil, avatar: nil, channel_id: nil)
      @faraday.patch({ name: name, avatar: avatarise(avatar), channel_id: channel_id }.compact)
    end

    # Delete this webhook.
    # @param reason [String, nil] The reason this webhook was deleted.
    # @return [Faraday::Response] the response returned by Discord.
    # @note This is permanent and cannot be undone.
    def delete(reason: nil)
      @faraday.delete(nil, { 'X-Audit-Log-Reason': reason })
    end

    # Edit a message from this webhook.
    # @param message_id [String, Integer] The ID of the message to edit.
    # @param builder [Builder] The builder to start out with, or nil if one should be created anew.
    # @param content [String] The message content.
    # @param embeds [Array<Embed, Hash>]
    # @param allowed_mentions [Hash]
    # @return [RestClient::Response] the response returned by Discord.
    # @example Edit message content
    #   client.edit_message(message_id, content: 'goodbye world!')
    # @example Edit a message via builder
    #   client.edit_message(message_id) do |builder|
    #     builder.add_embed do |e|
    #       e.description = 'Hello World!'
    #     end
    #   end
    # @note Not all builder options are available when editing.
    def edit_message(message_id, builder: nil, content: nil, embeds: nil, allowed_mentions: nil)
      builder ||= Builder.new

      yield builder if block_given?

      data = builder.to_h.merge({ content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact)
      @faraday.patch("messages/#{message_id}", data.compact)
    end

    # Delete a message created by this webhook.
    # @param message_id [String, Integer] The ID of the message to delete.
    # @return [Faraday::Response] the response returned by Discord.
    def delete_message(message_id)
      @faraday.delete("messages/#{message_id}")
    end

    private

    # Convert an avatar to API ready data.
    # @param avatar [String, #read] Avatar data.
    def avatarise(avatar)
      if avatar.respond_to? :read
        "data:image/jpg;base64,#{Base64.strict_encode64(avatar.read)}"
      else
        avatar
      end
    end

    def generate_url(id, token)
      "https://discord.com/api/v9/webhooks/#{id}/#{token}"
    end
  end
end
