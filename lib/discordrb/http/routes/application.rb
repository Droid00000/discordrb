# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/application
  module ApplicationEndpoints
    # @see https://docs.discord.com/developers/resources/application#get-current-application
    def get_current_application(**params)
      request Route[:GET, '/applications/@me'],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/application#edit-current-application
    def modify_current_application(**body)
      request Route[:PATCH, '/applications/@me'],
              body: filter_undef(body)
    end

    # @see https://docs.discord.com/developers/resources/application#get-application-activity-instance
    def get_application_activity_instance(application_id, instance_id, **params)
      request Route[:GET, "/applications/#{application_id}/activity-instances/#{instance_id}"],
              params: filter_undef(params)
    end
  end
end
