# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/entitlement
  module EntitlementEndpoints
    # @see https://docs.discord.com/developers/resources/entitlement#list-entitlements
    def list_entitlements(application_id, **params)
      request Route[:GET, "/applications/#{application_id}/entitlements"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/entitlement#get-entitlement
    def get_entitlement(application_id, entitlement_id, **params)
      request Route[:GET, "/applications/#{application_id}/entitlements/#{entitlement_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/entitlement#consume-an-entitlement
    def consume_an_entitlement(application_id, entitlement_id, **body)
      request Route[:POST, "/applications/#{application_id}/entitlements/#{entitlement_id}/consume"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/entitlement#create-test-entitlement
    def create_test_entitlement(application_id, **body)
      request Route[:POST, "/applications/#{application_id}/entitlements"],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/entitlement#delete-test-entitlement
    def delete_test_entitlement(application_id, **params)
      request Route[:DELETE, "/applications/#{application_id}/entitlements"],
              params: filter_undef(params)
    end
  end
end
