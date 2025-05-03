# frozen_string_literal: true

module Discordrb
  # A reccuring payment for at least one SKU made by a user.
  class Subscription
    include IDObject

    # Map of status types.
    STATUS_TYPES = {
      active: 0,
      ending: 1,
      inactive: 2
    }.freeze

    # @return [Integer] the status of the subscription. See {STATUS_TYPES}.
    attr_reader :status

    # @return [Symbol, nil] the ISO3166-1 country code of the payment source used to buy the subscription.
    attr_reader :country

    # @return [Time] the end of the current subscription period of the subscription.
    attr_reader :end_period

    # @return [Time] the start of the current subscription period of the subscription.
    attr_reader :start_period

    # @return [Time, nil] the time at when the subscription was canceled, or nil.
    attr_reader :canceled_at

    # @return [Array<Integer>] an array of associated subscribed SKUs IDs.
    attr_reader :sku_ids

    # @return [Array<Integer>] an array of granted entitlement IDs for this SKU.
    attr_reader :entitlement_ids

    # @return [Array<Integer>] an array of SKU IDs this user will be subscribed to at renewal.
    attr_reader :renewal_sku_ids

    # @!visibility private
    def initalize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @status = data['status']

      @user_id = data['user_id'].to_i
      @country = data['country'].to_sym

      @sku_ids = data['sku_ids'].map(&:resolve_id)
      @entitlement_ids = data['entitlement_ids'].map(&:resolve_id)
      @renewal_sku_ids = data['renewal_sku_ids'].map(&:resolve_id)

      @end_period = Time.iso8601(data['current_period_end'])
      @start_period = Time.iso8601(data['current_period_start'])
      @canceled_at = data['canceled_at'] ? Time.iso8601(data['canceled_at']) : nil
    end

    # @!method active?
    #   @return [true, false] If this subcription is active.
    # @!method ending?
    #   @return [true, false] If this subcription is ending.
    # @!method inactive?
    #   @return [true, false] If this subcription is inactive.
    STATUS_TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end

    # @return [User] The user who is subscribed to this subscription.
    def user
      @bot.user(@user_id)
    end
  end
end
