# frozen_string_literal: true

require 'json'
require 'faraday'
require 'discordrb/webhooks/builder'

module Discordrb::Webhooks
  # A client for a particular webhook added to a Discord channel.
  class Client
    # Create a new webhook.
    # @param url [String] The URL to post messages to.
    def initialize(url: nil, id: nil, token: nil)
      @url = url || "https://discord.com/api/v10/webhooks/#{id}/#{token}"
      @faraday = Faraday.new(@url) do |connection|
        connection.request :multipart
        connection.request :json
        connection.response :json, parser_options: { symbolize_names: true }
      end
    end

    # Executes the webhook this client points to with the given data.
    # @param builder [Builder, nil] The builder to start out with, or nil if one should be created anew.
    # @param wait [true, false] Whether Discord should wait for the message to be successfully received by clients, or
    #   whether it should return immediately after sending the message.
    # @param thread [String, Integer, nil] The thread_id of the thread if a thread should be targeted for the webhook execution
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
    #       embed.image = 'https://i.imgur.com/PcMltU7.jpg'
    #     end
    #   end
    # @return [Hash<Symbol => Object>, Faraday::Response] the response returned by Discord.
    def execute(builder: nil, wait: false, components: nil, thread: nil)
      builder ||= Builder.new
      view = View.new

      yield(builder, view) if block_given?

      builder = if builder.file
                  builder.to_multipart_hash
                else
                  builder.to_json_hash
                end

      view = (components&.to_a || view&.to_a)
      builder[:components] = view if view&.any?

      @faraday.post(encode_url(wait, thread), builder.to_h)
    end

    # Modify this webhook's properties.
    # @param name [String, nil] The default name.
    # @param avatar [String, #read, nil] The new avatar, in base64-encoded JPG format.
    # @return [Hash<Symbol => Object>, Faraday::Response] the response returned by Discord.
    def modify(name: :undef, avatar: :undef)
      data = {
        name: name,
        avatar: avatar.respond_to?(:read) ? encode64(avatar) : avatar
      }

      @faraday.patch(nil, data.reject { |_, value| value == :undef })
    end

    # Delete this webhook.
    # @param reason [String, nil] The reason this webhook was deleted.
    # @return [nil]
    # @note This is permanent and cannot be undone.
    def delete(reason: nil)
      @faraday.delete(nil, { 'X-Audit-Log-Reason': reason })
    end

    # Edit a message from this webhook.
    # @param message [String, Integer] The ID of the message to edit.
    # @param builder [Builder, nil] The builder to start out with, or nil if one should be created anew.
    # @param content [String] The message content.
    # @param embeds [Array<Embed, Hash>]
    # @param allowed_mentions [Hash]
    # @param thread [String, Integer, nil] The id of the thread in which the message resides
    # @return [Hash<Symbol => Object>, Faraday::Response] the response returned by Discord.
    # @example Edit message content
    #   client.edit_message(message: message_id, content: 'goodbye world!')
    # @example Edit a message via builder
    #   client.edit_message(message: message_id) do |builder|
    #     builder.add_embed do |embed|
    #       embed.description = 'Hello World!'
    #     end
    #   end
    # @note Not all builder options are available when editing.
    def edit_message(message:, builder: nil, content: nil, embeds: nil, allowed_mentions: nil, thread: nil)
      builder ||= Builder.new

      yield builder if block_given?

      kwargs = {
        content: content,
        embeds: embeds&.map(&:to_h),
        allowed_mentions: allowed_mentions
      }.compact

      data = builder.to_json_hash.merge!(kwargs)

      query = thread ? "?thread_id=#{thread}" : ''

      @faraday.patch("messages/#{message}#{query}", data.compact)
    end

    # Delete a message created by this webhook.
    # @param message_id [String, Integer] The ID of the message to delete.
    # @return [nil]
    def delete_message(message_id)
      @faraday.delete("messages/#{message_id}")
      nil
    end

    private

    # @!visibility private
    def encode_url(wait, thread_id)
      uri = URI.parse(@url)

      # NOTE: Do not change to symbol keys.
      query = {
        'wait' => wait,
        'thread_id' => thread_id,
        **URI.decode_www_form(uri.query || '').to_h
      }.compact

      query.empty? ? '' : "?#{URI.encode_www_form(query)}"
    end

    # @!visibility private
    def encode64(file)
      unless file.respond_to?(:read)
        raise ArgumentError, 'File or file-like object must respond to {#read}.'
      end

      "data:#{sniff_mime_type(file)};base64,#{Base64.strict_encode64(file.read)}"
    end

    # @!visibility private
    def sniff_mime_type(file)
      bytes = file.read(12).tap { file.rewind }

      if bytes.start_with?("\x89PNG\r\n\x1A\n".b)
        'image/png'
      elsif bytes.start_with?('RIFF'.b) && bytes[8, 4] == 'WEBP'.b
        'image/webp'
      elsif bytes.start_with?("\xFF\xD8\xFF".b) || ['JFIF'.b, 'Exif'.b].include?(bytes[6, 4])
        'image/jpeg'
      else
        raise ArgumentError, 'Unable to determine the exact content type of the provided file.'
      end
    end
  end
end
