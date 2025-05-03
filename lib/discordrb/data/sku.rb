# frozen_string_literal: true

module Discordrb
  # premium offerings that can be made available to users or servers.
  class SKU
    include IDObject

    # Map of SKU types.
    TYPES = {
      durable: 2,
      consumable: 3,
      subscription: 5,
      subscription_group: 6
    }.freeze

    # Map of SKU flags.
    FLAGS = {
      available: 1 << 2,
      server_subcription: 1 << 7,
      user_subscription: 1 << 8
    }.freeze

    # @return [Integer] the type of this SKU. See {TYPES}.
    attr_reader :type

    # @return [String] the customer facing name of this SKU.
    attr_reader :name

    # @return [String] system generated URL slug based on the name.
    attr_reader :slug

    # @return [Integer] SKU flags combined as a bitfield. See {FLAGS}.
    attr_reader :flags

    # @return [Integer] ID of the associated application for this SKU.
    attr_reader :application_id

    # @!visibility private
    def initalize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @type = data['type']
      @name = data['name']
      @slug = data['slug']
      @flags = data['flags']
      @application_id = data['application_id'].to_i
    end

    # @!method durable?
    #   @return [true, false] If this SKU is durable.
    # @!method consumable?
    #   @return [true, false] If this SKU is consumable.
    # @!method subscription?
    #   @return [true, false] If this SKU is a subcription.
    # @!method subscription_group?
    #   @return [true, false] If this SKU is a subscription group.
    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end

    # @!method available?
    #   @return [true, false] If this SKU is available.
    # @!method server_subcription?
    #   @return [true, false] If this SKU is a server subcription.
    # @!method user_subscription?
    #   @return [true, false] If this SKU is a user subscription.
    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    # Get a subscription by its ID for this SKU.
    # @param id [Integer, String] ID of the subscription to fetch.
    # @return [Subscription] The subscription for the given ID.
    def subcription(id)
      @bot.get_sku_subscription(@id, id.resolve_id)
    end

    # Returns all subscriptions containing the SKU, filterable by user.
    # @param limit [Integer, nil] the limit of how many subscriptions to retrieve. `nil` will return all subscriptions.
    # @param user [User, Integer, nil] A user for which to return subscriptions. Required except for OAuth queries.
    # @return [Array<Subscription>] Array of subscription objects that match the given parameters.
    def subscriptions(limit: nil, user: nil)
      get_subs = proc do |limit, user = nil, after = nil|
        @bot.get_sku_subscriptions(limit: limit, after: after, user: user)
      end

      # Can be done without pagination
      return get_subs.call(limit, user&.resolve_id) if limit && limit <= 100

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_subs.call(100, user&.resolve_id, last_page&.last&.id)
        end
      end

      paginator.to_a
    end
  end
end
