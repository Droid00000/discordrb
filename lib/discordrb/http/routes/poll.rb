# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/poll
  module PollEndpoints
    # @see https://docs.discord.com/developers/resources/poll#get-answer-voters
    def get_poll_answer_voters(channel_id, message_id, answer_id, **params)
      request Route[:GET, "/channels/#{channel_id}/polls/#{message_id}/answers/#{answer_id}"],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/poll#end-poll
    def end_poll(channel_id, message_id, **body)
      request Route[:POST, "/channels/#{channel_id}/polls/#{message_id}/expire"],
              body: filter_undef(body)
    end
  end
end
