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

    # @return [Integer]
    attr_reader :type

    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :slug

    # @return [Integer]
    attr_reader :flags

    # @return [Integer]
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
  end
end
