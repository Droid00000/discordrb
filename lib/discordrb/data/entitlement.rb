# frozen_string_literal: true

module Discordrb
  # Represents access to a premium offering.
  class Entitlement
    include IDObject

    # Mapping of entitlement types.
    TYPES = {
      purchase: 1,
      premium_subscription: 2,
      developer_gift: 3,
      test_mode_purchase: 4,
      free_purchase: 5,
      user_gift: 6,
      premium_purchase: 7,
      application_subscription: 8
    }.freeze

    # @return [Integer] the type of the entitlement.
    attr_reader :type

    # @return [Integer] the ID of the SKU that the entitlement belongs to.
    attr_reader :sku_id

    # @return [Integer, nil] the ID of the user that has been granted access
    #   to the entitlement.
    attr_reader :user_id

    # @return [true, false] whether or not the entitlement has been deleted.
    attr_reader :deleted

    # @return [true, false] whether or not the entitlement has been consumed.
    attr_reader :consumed

    # @return [Time, nil] the time at when the entitlement is no longer considered
    #   to be valid.
    attr_reader :end_time

    # @return [Integer, nil] the ID of the server that has been granted access to the
    #   entitlement.
    attr_reader :server_id

    # @return [Time, nil] the time at when the entitlement is considered to be valid.
    attr_reader :start_time

    # @return [Integer, nil] the ID of the application that the entitlement belongs to.
    attr_reader :application_id

    alias deleted? deleted
    alias consumed? consumed

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @type = data['type']
      @sku_id = data['sku_id']&.to_i
      @user_id = data['user_id']&.to_i
      @deleted = data['deleted']
      @consumed = data['consumed'] || false
      @end_time = Time.parse(data['ends_at']) if data['ends_at']
      @server_id = data['guild_id']&.to_i
      @starts_at = Time.parse(data['starts_at']) if data['starts_at']
      @application_id = data['application_id']&.to_i
    end

    # Get the user that the entitlement is for.
    # @return [User, nil] The user that the entitlement is for.
    def user
      @bot.user(@user_id) if @user_id
    end

    # Get the server that the entitlement is for.
    # @return [Server, nil] The server that the entitlement is for.
    def server
      @bot.server(@server_id) if @server_id
    end

    # Check if the entitlement has expired or not.
    # @return [true, false] Whether or not the entitlement has expired.
    def ended?
      !@ends_at.nil? && (Time.now > @ends_at)
    end

    # Mark a one-time purchase entitlement as consumed.
    # @return [nil]
    def consume
      API::Application.consume_entitlement(@bot.token, @application_id, @id)
      nil
    end

    # Delete the entitlement. Only usable for test mode entitlements.
    # @return [nil]
    def delete
      raise 'Can only delete test mode entitlements' unless test_mode_purchase?

      API::Application.delete_test_entitlement(@bot.token, @application_id, @id)
      nil
    end

    # @!method purchase?
    #   @return [true, false] if the entitlement was purchased by a user.
    # @!method premium_subscription?
    #   @return [true, false] if the entitlement is for a nitro subscription.
    # @!method developer_gift?
    #   @return [true, false] if the entitlement was gifted by a developer.
    # @!method test_mode_purchase?
    #   @return [true, false] if the entitlement was created in test-mode by a developer.
    # @!method free_purchase?
    #   @return [true, false] if the entitlement was granted when the associated SKU was free.
    # @!method user_gift?
    #   @return [true, false] if the entitlement was gifted by another user.
    # @!method premium_purchase?
    #   @return [true, false] if the entitlement was claimed by a user for free as a part of nitro.
    # @!method application_subscription?
    #   @return [true, false] if the entitlement was purchased as an application subscription.
    TYPES.each do |name, value|
      define_method("#{name}?") { @type == value }
    end
  end
end
