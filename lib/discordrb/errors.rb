# frozen_string_literal: true

module Discordrb
  # Custom errors raised in various places.
  module Errors
    # Raised for unauthorized HTTP requests.
    class Unauthorized < RuntimeError
      # Default message used for the exception.
      def message
        'The Authorization header was invalid. Ensure your token is correct.'
      end
    end

    # Raised for unauthorized HTTP requests where the associated resource cannot be found.
    class NotFound < RuntimeError; end

    # Raised for HTTP requests that use an invalid HTTP method. Should never raise under normal circumstances.
    class MethodNotAllowed < RuntimeError; end

    # Raised when using a webhook method without an associated token.
    class UnauthorizedWebhook < RuntimeError; end

    # Raised for operations that require an active gateway connection.
    class GatewayRequired < RuntimeError; end

    # Raised for operations that require a gateway intent that was not enabled.
    class MissingGatewayIntent < RuntimeError; end

    # Raised when the bot can't do something because its permissions on the guild are insufficient.
    class NoPermission < RuntimeError
      # @return [Integer, nil] The error code that was encoutered.
      attr_reader :code

      # @return [String, Hash, nil] The error message(s) that was encountered.
      attr_reader :message

      # @!visibility private
      def initialize(data = nil)
        @code = data ? data[:code] : nil
        @message = data ? data[:message] : nil
      end
    end

    # Generic class for errors denoted by API error codes.
    class BadRequest < RuntimeError
      # @return [Hash] the raw errors.
      attr_reader :raw

      # @return [Integer] the error code.
      attr_reader :code

      # @return [Array<String>] the more precise errors.
      attr_reader :errors

      # @return [String, nil] the error's represented message.
      attr_reader :message

      # @!visibility private
      def initialize(data)
        @raw = data
        @code = data[:code] || 0
        @message = data[:message]
        @errors = data[:errors] ? flatten_errors(data[:errors]) : []
      end

      # @return [String] A message including the message and flattened errors.
      def full_message(*)
        error_list = @errors.collect { |err| "\t- #{err}" }

        "#{@message}\n#{error_list.join("\n")}"
      end

      private

      # @!visibility private
      # Flattens errors into a more easily read format.
      # @example Flattening errors of a bad field
      #   flatten_errors(data[:errors])
      #   # => ["embed.fields[0].name: This field is required", "embed.fields[0].value: This field is required"]
      def flatten_errors(err, prev_key = nil)
        err.collect do |key, sub_err|
          if prev_key
            key = /\A\d+\Z/.match?(key) ? "#{prev_key}[#{key}]" : "#{prev_key}.#{key}"
          end

          if (errs = sub_err[:_errors])
            "#{key}: #{errs.map { |e| e[:message] }.join(' ')}"
          elsif sub_err[:message] || sub_err[:code]
            "#{"#{sub_err[:code]}: " if sub_err[:code]}#{err_msg}"
          elsif sub_err.is_a? String
            sub_err
          else
            flatten_errors(sub_err, key)
          end
        end.flatten
      end
    end
  end
end
