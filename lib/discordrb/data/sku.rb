# frozen_string_literal: true

module Discordrb
  # A premium offering that can be made available to an entity.
  class SKU
    include IDObject

    # Mapping of SKU flags.
    FLAGS = {
      available: 1 << 2,
      server_subscription: 1 << 7,
      user_subscription: 1 << 8
    }.freeze

    # Mapping of SKU types.
    TYPES = {
      durable: 2,
      consumable: 3,
      subscription: 5,
      subscription_group: 6
    }.freeze

    # @return [String] the name of the SKU.
    attr_reader :name

    # @return [String] the slug of the SKU.
    attr_reader :slug

    # @return [Integer] the type of the SKU.
    attr_reader :type

    # @return [Integer] the flags of the SKU.
    attr_reader :flags

    # @return [Integer] the ID of the parent application for the SKU.
    attr_reader :application_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @slug = data['slug']
      @type = data['type']
      @flags = data['flags']
      @application_id = data['application_id']&.to_i
    end

    # Get a single subscription that contains the SKU by its ID.
    # @param id [Integer, String] The ID of the subscription to resolve.
    # @return [Subscription, nil] The subscription that was retrieved, or `nil` if not found.
    def subscription(id)
      data = API::Application.get_sku_subscription(@bot.token, @id, id.resolve_id)
      Subscription.new(JSON.parse(data), @bot)
    rescue StandardError
      nil
    end

    # Get the subscriptions that contain the SKU.
    # @param limit [Integer, nil] The maximum number of subscriptions to fetch, or `nil`
    #   to get all of the subscriptions.
    # @param user [User, Member, Integer, String, nil] The user to get subscriptions for.
    # @param after [Time, #resolve_id, nil] Get subscriptions that come after this snowflake.
    # @param before [Time, #resolve_id, nil] Get subscriptions that come before this snowflake.
    # @return [Array<Subscription>] The subscriptions that matched the provided arguments.
    # @raise [ArgumentError] If `before:` and `after:` are provided in conjunction.
    def subscriptions(user:, limit: 100, before: nil, after: nil)
      raise ArgumentError, "'before' and 'after' are mutually exclusive" if before && after

      rest = {
        user_id: user&.resolve_id,
        limit: limit && limit <= 100 ? limit : 100,
        after: after.is_a?(Time) ? IDObject.synthesise(after) : after&.resolve_id,
        before: before.is_a?(Time) ? IDObject.synthesise(before) : before&.resolve_id
      }.compact

      get_subscriptions = lambda do |query|
        data = API::Application.list_sku_subscriptions(@bot.token, @id, **rest, **query.compact)
        JSON.parse(data).collect { |subscription_data| Subscription.new(subscription_data, @bot) }
      end

      # Can be done without pagination.
      return get_subscriptions.call({}) if limit && limit <= 100

      paginator = Paginator.new(limit, before ? :up : :down) do |page|
        if last_page && last_page.count < 100
          []
        elsif before
          get_subscriptions.call(before: page&.first&.id)
        else
          get_subscriptions.call(after: page&.last&.id)
        end
      end

      paginator.to_a
    end

    # @!method durable?
    #   @return [true, false] whether or not the SKU is a durable one-time purchase.
    # @!method consumable?
    #   @return [true, false] whether or not the SKU is a consumable one-time purchase.
    # @!method subscription?
    #   @return [true, false] whether or not the SKU is for a recurring subscription.
    # @!method subscription_group?
    #   @return [true, false] whether or not the SKU is part of a system-generated group.
    TYPES.each do |name, value|
      define_method("#{name}?") { @type == value }
    end

    # @!method available?
    #   @return [true, false] whether or not the SKU is available for purchase.
    # @!method server_subscription?
    #   @return [true, false] whether or not the SKU can be purchased by a user and applied to a server.
    # @!method user_subscription?
    #   @return [true, false] whether or not the SKU can be purchased by a user for themselves.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
    end
  end
end
