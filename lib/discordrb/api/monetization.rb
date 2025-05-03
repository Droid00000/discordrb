# frozen_string_literal: true

# API calls for monetization.
module Discordrb::API::Monetization
  module_function

  # Get a list of entitlements.
  # https://discord.com/developers/docs/resources/entitlement#list-entitlements
  def list_entitlements(token, application_id, user_id = nil, sku_ids = nil, before = nil, after = nil, limit = nil, server_id = nil, exclude_ended = nil, exclude_deleted = nil)
    query = URI.encode_www_form({ user_id: user_id, sku_ids: sku_ids, before: before, after: after, limit: limit, server_id: server_id, exclude_ended: exclude_ended, exclude_deleted: exclude_deleted }.compact)

    Discordrb::API.request(
      :applications_aid_entitlements,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements#{"?#{query}" unless query.empty?}",
      Authorization: token
    )
  end

  # Get an entitlement by its ID.
  # https://discord.com/developers/docs/resources/entitlement#get-entitlements
  def get_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}",
      Authorization: token
    )
  end

  # Consume a single entitlement.
  # https://discord.com/developers/docs/resources/entitlement#consume-an-entitlement
  def consume_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      application_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}/consume",
      Authorization: token
    )
  end

  # Create a test entitlement.
  # https://discord.com/developers/docs/resources/entitlement#create-test-entitlement
  def create_test_entitlement(token, application_id, sku_id, owner_id, owner_type)
    Discordrb::API.request(
      :applications_aid_entitlements,
      application_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements",
      { sku_id: sku_id, owner_id: owner_id, owner_type: owner_type }.to_json,
      Authorization: token
    )
  end

  # Delete a test entitlement.
  # https://discord.com/developers/docs/resources/entitlement#delete-test-entitlement
  def delete_test_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      application_id,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}",
      Authorization: token
    )
  end

  # Get all SKU subscriptions.
  # https://discord.com/developers/docs/resources/subscription#list-sku-subscriptions
  def list_sku_subscriptions(token, sku_id, before, after, limit, user_id)
    query = URI.encode_www_form({ before: before, after: after, limit: limit, user_id: user_id }.compact)

    Discordrb::API.request(
      :skus,
      sku_id,
      :get,
      "#{Discordrb::API.api_base}/skus/#{sku_id}/subcriptions?#{"?#{query}" unless query.empty?}",
      Authorization: token
    )
  end

  # Get a single SKU subscription.
  # https://discord.com/developers/docs/resources/subscription#get-sku-subscription
  def get_sku_subscription(token, sku_id, subscription_id)
    Discordrb::API.request(
      :skus_sid,
      subscription_id,
      :get,
      "#{Discordrb::API.api_base}/skus/#{sku_id}/subscriptions/#{subscription_id}",
      Authorization: token
    )
  end

  # Get all SKUs.
  # https://discord.com/developers/docs/resources/sku#list-skus
  def list_skus(token, application_id)
    Discordrb::API.request(
      :applications_aid_skus,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/skus",
      Authorization: token
    )
  end
end
