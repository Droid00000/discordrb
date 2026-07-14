# frozen_string_literal: true

module Discordrb
  # An instance of a live stage.
  class StageInstance
    include Snowflake

    # @return [String] the topic of the stage instance.
    attr_reader :topic

    # @return [Channel] the channel of the stage instance.
    attr_reader :channel

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @id = data[:id].to_i
      @topic = data[:topic]
      @scheduled_event_id = data[:guild_scheduled_event_id]&.to_i
    end

    # Get the guild of the stage instance.
    # @return [Guild] The assoicated guild of the stage instance.
    def guild
      @channel.guild
    end

    # Get the scheduled event of the stage instance.
    # @return [ScheduledEvent, nil] The scheduled event of the stage instance.
    def scheduled_event
      return unless @scheduled_event_id

      guild.scheduled_event(@scheduled_event_id)
    end

    # Modify the properties of the stage instance.
    # @param topic [String] The 1-120 character topic of the stage instance.
    # @param reason [String, nil] The audit log reason for updating the stage instance.
    # @return [nil]
    def modify(topic:, reason: nil)
      update_data(
        @bot.http.modify_stage_instance(@channel.id, topic:, reason:)
      )
      nil
    end

    # Permanently end the ongoing stage instance.
    # @param reason [String, nil] The audit log reason for deleting the stage instance.
    # @return [nil]
    def delete(reason: nil)
      @bot.http.delete_stage_instance(@channel.id, reason:)
      nil
    end

    # @!visibility private
    def update_data(new_data)
      @topic = new_data[:topic]
      @sscheduled_event_id = new_data[:guild_scheduled_event_id]&.to_i
    end

    # @!visibility private
    def inspect
      "<StageInstance id=#{@id} channel_id=#{@channel.id} topic=\"#{@topic}\">"
    end
  end
end
