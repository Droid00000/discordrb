# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/interactions/receiving-and-responding
  module InteractionEndpoints
    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#create-interaction-response
    def create_interaction_response(interaction_id, interaction_token, with_response: :undef, files: :undef, **body)
      request Route[:POST, "/interactions/#{interaction_id}/#{interaction_token}/callback"],
              body: make_attachments(files, body), params: filter_undef({ with_response: })
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#get-original-interaction-response
    def get_original_interaction_response(application_id, interaction_token, **params)
      request Route[:GET, "/webhooks/#{application_id}/#{interaction_token}/messages/@original"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#edit-original-interaction-response
    def edit_original_interaction_response(application_id, interaction_token, files: :undef, **body)
      request Route[:PATCH, "/webhooks/#{application_id}/#{interaction_token}/messages/@original"],
              body: make_attachments(files, body)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#delete-original-interaction-response
    def delete_original_interaction_response(application_id, interaction_token, **params)
      request Route[:DELETE, "/webhooks/#{application_id}/#{interaction_token}/messages/@original"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#create-followup-message
    def create_followup_message(application_id, interaction_token, files: :undef, **body)
      request Route[:POST, "/webhooks/#{application_id}/#{interaction_token}"],
              body: make_attachments(files, body)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#get-followup-message
    def get_followup_message(application_id, interaction_token, message_id, **params)
      request Route[:GET, "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#edit-followup-message
    def edit_followup_message(application_id, interaction_token, message_id, files: :undef, **body)
      request Route[:PATCH, "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}"],
              body: make_attachments(files, body)
    end

    # @see https://docs.discord.com/developers/interactions/receiving-and-responding#edit-followup-message
    def delete_followup_message(application_id, interaction_token, message_id, **params)
      request Route[:DELETE, "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}"],
              params: filter_undef(params)
    end
  end
end
