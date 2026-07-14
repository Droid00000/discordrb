# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/subscription
  module SubscriptionEndpoints
    # @see https://docs.discord.com/developers/resources/subscription#list-sku-subscriptions
    def list_sku_subscriptions(sku_id, **params)
      request Route[:GET, "/skus/#{sku_id}/subscriptions"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/subscription#get-sku-subscription
    def get_sku_subscriptions(sku_id, subscription_id, **params)
      request Route[:GET, "/skus/#{sku_id}/subscriptions/#{subscription_id}"],
              params: filter_undef(params)
    end
  end
end
