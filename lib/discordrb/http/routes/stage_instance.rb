# frozen_string_literal: true

module Discordrb::HTTP
  # @see https://docs.discord.com/developers/resources/stage-instance
  module StageInstanceEndpoints
    # @see https://docs.discord.com/developers/resources/stage-instance#get-stage-instance
    def get_stage_instance(channel_id, **params)
      request Route[:GET, "/stage-instances/#{channel_id}", channel_id],
              params: filter_undef(params)
    end

    # @see https://docs.discord.com/developers/resources/stage-instance#create-stage-instance
    def create_stage_instance(reason: :undef, **body)
      request Route[:POST, '/stage-instances'],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/stage-instance#modify-stage-instance
    def modify_stage_instance(channel_id, reason: :undef, **body)
      request Route[:PATCH, "/stage-instances/#{channel_id}", channel_id],
              body: filter_undef(body), reason: reason
    end

    # @see https://docs.discord.com/developers/resources/soundboard#delete-guild-soundboard-sound
    def delete_stage_instance(channel_id, reason: :undef, **params)
      request Route[:DELETE, "/stage-instances/#{channel_id}", channel_id],
              params: filter_undef(params), reason: reason
    end
  end
end
