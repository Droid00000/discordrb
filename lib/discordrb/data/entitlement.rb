# frozen_string_literal: true

module Discordrb
  # A premium offering usable by a server or user.
  class Entitlement
    include IDObject

    # Map of entitlement types.
    TYPES = {
      purchase: 1,
      premium_subscription: 2,
      developer_gift: 3,
      test_purchase: 4,
      free_purchase: 5,
      user_gift: 6,
      premium_purchase: 7,
      application_subscription: 8
    }.freeze

    # @return [Integer] the ID of the associated SKU.
    attr_reader :sku_id

    # @return [Integer] the ID of the associated application.
    attr_reader :application_id

    # @return [Integer] the type of this SKU. See {TYPES}.
    attr_reader :type

    # @return [true, false] if this entitlement is deleted or not.
    attr_reader :deleted
    alias_method :deleted?, :deleted

    # @return [Time, nil] the start date at when the entitlement is valid.
    attr_reader :starts_at

    # @return [Time, nil] the end date at when the entitlement is no longer valid.
    attr_reader :ends_at

    # @return [true, false] if this entitlement has been consumed or not.
    attr_reader :consumed
    alias_method :consumed?, :consumed

    # @return [Integer, nil] The associated user ID for this SKU, or nil.
    attr_reader :user_id

    # @return [Integer, nil] The associated server ID for this SKU, or nil.
    attr_reader :server_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @sku_id = data['sku_id'].to_i
      @application_id = data['application_id'].to_i

      @type = data['type']
      @deleted = data['deleted']
      @consumed = data['consumed']

      @user_id = data['user_id']&.to_i
      @server_id = data['guild_id']&.to_i

      @ends_at = data['ends_at'] ? Time.iso8601(data['ends_at']) : nil
      @starts_at = data['starts_at'] ? Time.iso8601(data['starts_at']) : nil
    end

    # @!method purchase?
    #   @return [true, false] If this entitlement is a purchase.
    # @!method premium_subscription?
    #   @return [true, false] If this entitlement is a premium subscription.
    # @!method developer_gift?
    #   @return [true, false] If this entitlement is a developer gift.
    # @!method test_purchase?
    #   @return [true, false] If this entitlement is a test purchase.
    # @!method free_purchase?
    #   @return [true, false] If this entitlement is a free purchase.
    # @!method user_gift?
    #   @return [true, false] If this entitlement is a user gift.
    # @!method premium_purchase?
    #   @return [true, false] If this entitlement is a premium purchase.
    # @!method application_subscription?
    #   @return [true, false] If this entitlement is a application subscription.
    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end

    # @return [SKU] The associated SKU for this entitlement.
    def sku
      @sku ||= @bot.get_sku(@sku_id)
    end

    # @return [User] The user this entitlement is for.
    def user
      @bot.user(@user_id) if @user_id
    end

    # @return [Server] The server this entitlement is for.
    def server
      @bot.server(@server_id) if @server_id
    end

    # @return [true, false] If this entitlement has expired or not.
    def ended?
      @ends_at ? (Time.now >= @ends_at) : false
    end

    # For One-Time Purchase SKUs, marks a given entitlement as consumed.
    def consume
      API::Monetization.consume_entitlement(@bot.token, @bot.profile.id, @id)
      @consumed = true
    end

    # Deletes a currently-active test entitlement. This entilement must be a test purchase.
    def delete
      raise ArgumentError, 'Type must be of test_purchase!' unless test_purchase?

      API::Monetization.delete_test_entitlement(@bot.token, @bot.profile.id, @id)
      @deleted = true
    end
  end
end
