# frozen_string_literal: true

# This file is licensed under the following license:
#
# Copyright (c) 2021-2026 Matt Carey
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'faraday'
require 'faraday/multipart'
require 'discordrb/http/routes/application_command'
require 'discordrb/http/routes/application_role_connection_metadata'
require 'discordrb/http/routes/application'
require 'discordrb/http/routes/audit_log'
require 'discordrb/http/routes/auto_moderation'
require 'discordrb/http/routes/channel'
require 'discordrb/http/routes/emoji'
require 'discordrb/http/routes/entitlement'
require 'discordrb/http/routes/guild_join_request'
require 'discordrb/http/routes/guild_scheduled_event'
require 'discordrb/http/routes/guild_template'
require 'discordrb/http/routes/guild'
require 'discordrb/http/routes/interaction'
require 'discordrb/http/routes/invite'
require 'discordrb/http/routes/message'
require 'discordrb/http/routes/poll'
require 'discordrb/http/routes/sku'
require 'discordrb/http/routes/soundboard'
require 'discordrb/http/routes/stage_instance'
require 'discordrb/http/routes/sticker'
require 'discordrb/http/routes/subscription'
require 'discordrb/http/routes/user'
require 'discordrb/http/routes/voice'
require 'discordrb/http/routes/webhook'

module Discordrb
  # @!visibility private
  # All of the code from this point onwards was written by Swarley. I take **ZERO** credit for anything
  #   in this file. Huge thanks to them for writing this (https://github.com/shardlab/discordrb/pull/96).
  module HTTP
    # A route for a HTTP request.
    class Route
      # @return [String]
      attr_reader :endpoint

      # @return [Symbol]
      attr_reader :verb

      # @return [Symbol, nil]
      attr_reader :route_key

      # @return [Integer, nil]
      attr_reader :major_param

      # @return [String]
      attr_reader :rate_limit_key

      # @param verb [Symbol]
      # @param endpoint [String]
      # @param major_param [#to_i, nil]
      # @param route_key [String, nil]
      def initialize(verb, endpoint, major_param = nil, route_key = nil, metadata = nil)
        @verb = verb.downcase.to_sym
        @endpoint = endpoint.delete_prefix('/')
        @route_key = route_key || @endpoint.gsub(/\d+/, 'id')
        @major_param = major_param&.to_i
        @rate_limit_key = "#{@verb}:#{@route_key}:#{major_param}#{metadata}"
      end

      # @see #initialize
      def self.[](...)
        new(...)
      end
    end

    # Ratelimit information for a request.
    class RateLimit
      # @return [Integer, nil]
      attr_reader :limit

      # @return [Integer, nil]
      attr_reader :remaining

      # @return [Time, nil]
      attr_reader :reset

      # @return [Time, nil]
      attr_reader :reset_after

      # @return [String, nil]
      attr_reader :bucket

      # @return [Mutex]
      attr_reader :mutex

      def initialize(data = {})
        @mutex = Mutex.new
        update(data)
      end

      # @param data [Hash]
      def update(data)
        @limit = data['x-ratelimit-limit']&.to_i || @limit || Float::INFINITY
        @remaining = data['x-ratelimit-remaining']&.to_i || @remaining || Float::INFINITY
        @reset = data['x-ratelimit-reset'] ? Time.at(data['x-ratelimit-reset'].to_i) : @reset
        @reset_after = (Time.now + data['x-ratelimit-reset-after'].to_f) || @reset_after
        @bucket = data['x-ratelimit-bucket'] || @bucket
      end
    end

    # Client for making HTTP requests to the Discord API. This entire HTTP client was written
    #   by Swarley (https://github.com/shardlab/discordrb/pull/96) so huge thanks to them. I would've
    #   never been able to figure out any of this by myself.
    class Client
      include ApplicationCommandEndpoints
      include ApplicationRoleConnectionMetadataEndpoints
      include ApplicationEndpoints
      include AuditLogEndpoints
      include AutoModerationEndpoints
      include ChannelEndpoints
      include EmojiEndpoints
      include EntitlementEndpoints
      include GuildJoinRequestEndpoints
      include GuildScheduledEventEndpoints
      include GuildTemplateEndpoints
      include GuildEndpoints
      include InteractionEndpoints
      include InviteEndpoints
      include MessageEndpoints
      include PollEndpoints
      include SKUEndpoints
      include SoundboardEndpoints
      include StageInstanceEndpoints
      include StickerEndpoints
      include SubscriptionEndpoints
      include UserEndpoints
      include VoiceEndpoints
      include WebhookEndpoints

      # The user agent used when making requests.
      USER_AGENT = "DiscordBot (https://github.com/shardlab/discordrb, #{Discordrb::VERSION})".freeze

      def initialize(token, version: 10)
        @conn = Faraday.new("https://discord.com/api/v#{version}") do |builder|
          builder.headers[:authorization] = "Bot #{token.delete_prefix('Bot ')}"
          builder.headers[:user_agent] = USER_AGENT

          builder.request :multipart
          builder.request :json

          builder.response :json, parser_options: { symbolize_names: true }

          yield(builder) if block_given?
        end

        @rl_info = Hash.new { |hash, key| hash[key] = RateLimit.new }
      end

      def get_gateway_bot(**params)
        request Route[:GET, '/gateway/bot'],
                params: filter_undef(params)
      end

      private

      # @param route [Route]
      # @param params [Hash, nil]
      # @param body [Hash, nil]
      # @param headers [Hash]
      def raw_request(route, params: nil, body: nil, headers: {})
        trace = SecureRandom.alphanumeric(6)

        endpoint = if params&.tap(&:compact!)&.any?
                     "#{route.endpoint}?#{URI.encode_www_form(params)}"
                   else
                     route.endpoint
                   end

        log_request(route.verb, endpoint, trace, body)
        response = @conn.run_request(route.verb, endpoint, body, headers)
        log_response(response, trace)

        response
      end

      # @param route [Route]
      # @param params [Hash, nil]
      # @param body [Hash, nil]
      # @param headers [Hash, nil]
      # @param reason [String, nil]
      def request(route, params: nil, body: nil, headers: {}, reason: nil)
        headers['X-Audit-Log-Reason'] = uri_quote(reason) if reason && reason != :undef

        synchronize_rl_key(route.rate_limit_key) do
          response = raw_request(route, params: params, body: body, headers: headers)
          handle_response(route, response)
        end
      end

      # @param route [Route]
      # @param response [Faraday::Response]
      def handle_response(route, response)
        update_rate_limits(route, response)

        case response.status
        when 400
          raise Discordrb::Errors::BadRequest, response.body || {}
        when 401
          raise Discordrb::Errors::Unauthorized
        when 403
          raise Discordrb::Errors::NoPermission, response.body || {}
        when 404
          raise Discordrb::Errors::NotFound
        when 405
          raise Discordrb::Errors::MethodNotAllowed
        when 429
          reset_time = response.headers['x-ratelimit-reset-after']
          key = route.rate_limit_key
          Discordrb::LOGGER.ratelimit("Rate limit exceeded for #{key}, resets in #{reset_time} seconds")
        when 204
          nil
        else
          response.body
        end
      end

      # @param route [Route]
      # @param response [Faraday::Response]
      def update_rate_limits(route, response)
        @rl_info[route.rate_limit_key] = @rl_info[response.headers['x-ratelimit-bucket']] if response.headers['x-ratelimit-bucket']
        @rl_info[route.rate_limit_key].update(response.headers)
      end

      # @param key [String]
      def synchronize_rl_key(key)
        rl_info = @rl_info[key].bucket ? @rl_info[@rl_info[key].bucket] : @rl_info[key]

        rl_info.mutex.synchronize do
          if (rl_info.remaining) < 1 && Time.now < rl_info.reset_after
            duration = rl_info.reset_after - Time.now

            LOGGER.ratelimit("Preemptively locking #{key} for #{duration} seconds")
            sleep(duration)
          end

          yield
        end
      end

      # @param verb [Symbol]
      # @param endpoint [String]
      # @param trace [String]
      # @param body [Object, nil]
      def log_request(verb, endpoint, trace, body = nil)
        Discordrb::LOGGER.info  "HTTP OUT [#{trace}] -- #{verb.upcase} /#{endpoint}"
        Discordrb::LOGGER.debug "HTTP OUT [#{trace}] -- Request Body: #{body.inspect}" if body
      end

      # @param response [Faraday::Response]
      # @param trace [String]
      def log_response(response, trace)
        Discordrb::LOGGER.info  "HTTP IN  [#{trace}] -- #{response.status} #{response.reason_phrase}"
        Discordrb::LOGGER.debug "HTTP IN  [#{trace}] -- Response Body: #{response.body.inspect}"
      end

      # Reject any key-value pair from a hash where the value is `:undef`.
      # @param hash [Hash<Object, Object>] The hash to reject the key-value pairs from.
      # @return [Hash] The hash with every key-value pair that had a value of `:undef` removed.
      def filter_undef(hash)
        hash.delete_if { |_, value| value == :undef }
      end

      # URI encode a component.
      # @param string [String] The string that should be URI-encoded.
      # @return [String] The URI encoded string. This will return the original string if it is ASCII only.
      def uri_quote(string)
        string.ascii_only? ? string : URI.encode_uri_component(string)
      end

      # Create a multipart body for Faraday.
      # @param files [Array<Hash>] The attachments and file contents to upload.
      # @param json [Array, Hash, Object] The JSON data to include in the `payload_json` field.
      # @return [Hash] A hash with one payload_json key and the file contents, or the just the hash if no
      #   files were given.
      def make_attachments(files, json)
        json = filter_undef(json)

        if files && files != :undef && files&.any?
          body = {}
          attachments = if json[:data]&.[](:attachments)
                          json[:data][:attachments]
                        else
                          json[:attachments] ||= []
                        end

          files.each_with_index do |hash, index|
            if (file = hash[:file])
              content_type = hash.delete(:content_type) || 'application/octet-stream'
              part = Faraday::Multipart::FilePart.new(file, content_type, hash[:filename])

              body["files[#{index}]"] = part
            end

            attachments << if hash[:id]
                             hash.except(:file)
                           else
                             { id: index, **hash.except(:file) }
                           end
          end
        end

        body&.any? ? { **body, payload_json: JSON.dump(json) } : json
      end
    end
  end
end
