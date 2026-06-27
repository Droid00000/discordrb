# frozen_string_literal: true

module Discordrb
  # Represent a user making recurring payments for an SKU.
  class Subscription
    include IDObject

    # Mapping of status types.
    STATUSES = {
      active: 0,
      inactive: 1,
      ending: 2
    }.freeze

    # @return [Integer] the status of the subscription.
    attr_reader :status

    # @return [Integer] the user ID of the subscribed user.
    attr_reader :user_id

    # @return [Array<Integer>] the IDs of the subscribed SKUs.
    attr_reader :sku_ids

    # @return [Time, nil] the cancel time of the subscription.
    attr_reader :canceled_at
    alias cancelled_at canceled_at

    # @return [Array<Integer>] the IDs of the granted entitlements.
    attr_reader :entitlement_ids

    # @return [Array<Integer>] the IDs of the SKUs that the user will be
    #   subscribed to upon renewal.
    attr_reader :renewal_sku_ids

    # @return [Time] the time at whenn the current subscription period will end.
    attr_reader :current_period_end

    # @return [Time] the time at whenn the current subscription period will start.
    attr_reader :current_period_start

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @status = data['status']
      @user_id = data['user_id']&.to_i
      @sku_ids = data['sku_ids']&.map(&:to_i) || []
      @canceled_at = Time.parse(data['canceled_at']) if data['canceled_at']
      @entitlement_ids = data['entitlement_ids']&.map(&:to_i) || []
      @renewal_sku_ids = data['renewal_sku_ids']&.map(&:to_i) || []
      @current_period_end = Time.parse(data['current_period_end']) if data['current_period_end']
      @current_period_end = Time.parse(data['current_period_start']) if data['current_period_start']
    end

    # Get the user that the subscription is for.
    # @return [User] The user that the subscription is for.
    def user
      @bot.user(@user_id) if @user_id
    end

    # @!method active?
    #   @return [true, false] if the subscription is active and is scheduled to renew.
    # @!method inactive?
    #   @return [true, false] if the subscription is inactive and no longer being charged.
    # @!method ending?
    #   @return [true, false] if the subscription is active but will no longer renew.
    STATUSES.each do |name, value|
      define_method("#{name}?") { @status == value }
    end
  end
end
