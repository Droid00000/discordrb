# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/sku
  module SKUEndpoints
    # @see https://docs.discord.com/developers/resources/sku#list-skus
    def list_skus(application_id, **params)
      request Route[:GET, "/applications/#{application_id}/skus"],
              params: filter_undef(params)
    end
  end
end
