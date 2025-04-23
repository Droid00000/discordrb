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

    # @return [Integer]
    attr_reader :status

    # @return [Symbol, nil]
    attr_reader :country

    # @return [Time]
    attr_reader :end_period

    # @return [Time]
    attr_reader :start_period

    # @return [Time, nil]
    attr_reader :canceled_at

    # @!visibility hidden
    def initalize(data, bot)
      @id = data['id'].to_i
      @status = data['status']

      @user_id = data['user_id'].to_i
      @country = data['country'].to_sym

      @sku_ids = data['sku_ids'].map(&:to_i)
      @entitlement_ids = data['entitlement_ids'].map(&:to_i)
      @renewal_sku_ids = data['renewal_sku_ids'].map(&:to_i)

      @end_period = Time.iso8601(data['current_period_end'])
      @start_period = Time.iso8601(data['current_period_start'])
      @canceled_at = Time.iso8601(data['canceled_at']) if data['canceled_at']
    end

    # @!method active?
    #   @return [true, false] If this subcription is active.
    # @!method ending?
    #   @return [true, false] If this subcription is ending.
    # @!method inactive?
    #   @return [true, false] If this subcription is inactive.
    STATUS_TYPES.each do |key, value|
      define_method("#{key}?") do
        @type == value
      end
    end

    # @return [User] The user who is subscribed to this subscription.
    def user
      @bot.user(@user_id)
    end
  end
end
