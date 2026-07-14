# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/application-role-connection-metadata
  module ApplicationRoleConnectionMetadataEndpoints
    # @see https://docs.discord.com/developers/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
    def get_application_role_connection_metadata_records(application_id, **params)
      request Route[:GET, "/applications/#{application_id}/role-connections/metadata"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
    def update_application_role_connection_metadata_records(application_id, metadata)
      request Route[:PUT, "/applications/#{application_id}/role-connections/metadata"],
              body: metadata
    end
  end
end
