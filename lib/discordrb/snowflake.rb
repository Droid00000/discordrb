# frozen_string_literal: true

module Discordrb
  # Mixin module for objects that have snowflake IDs.
  module Snowflake
    # @return [Integer] the unique snowflake ID of the object.
    attr_reader :id
    alias_method :resolve_id, :id
    alias_method :hash, :id

    # Compare the object to another entity using its snowflake ID.
    # @see Discordrb#id_compare?
    def ==(other)
      Discordrb.id_compare?(@id, other)
    end

    alias_method :eql?, :==

    # Creates an artificial snowflake at the given point in time.
    # @param time [Time] The time that the snowflake should represent.
    # @return [Integer] a snowflake with the timestamp component set to the given time.
    def self.synthesise(time)
      ms = (time.to_f * 1000)
      (ms.to_i - DISCORD_EPOCH) << 22
    end

    # Estimates the time at when an object was generated at based on the beginning of the ID.
    # @return [Time] The time at when the object was created at.
    def creation_time
      Discordrb::Snowflake.decompose(@id)
    end

    # Estimates the time at when a snowflake was generated at based on the beginning of the ID.
    # @return [Time] The time at when the snowflake was generated at.
    def self.decompose(snowflake)
      milliseconds = (snowflake.to_i >> 22) + DISCORD_EPOCH
      Time.at(milliseconds / 1000.0)
    end

    class << self
      alias_method :synthesize, :synthesise
    end
  end
end
