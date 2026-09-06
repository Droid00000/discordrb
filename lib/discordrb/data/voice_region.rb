# frozen_string_literal: true

module Discordrb
  # The locations of the voice servers on Discord.
  class VoiceRegion
    # @!visibility private
    PREDICATES = %i[
      custom?
      optimal?
      deprecated?
    ].freeze

    # @return [String] the ID of the voice region.
    attr_reader :id
    alias :to_s :id

    # @return [String] the name of the voice region.
    attr_reader :name

    # @!visibility private
    def initialize(data)
      @id = data[:id]
      @name = data[:name]
      @custom = data[:custom]
      @optimal = data[:optimal]
      @deprecated = data[:deprecated]
    end

    # @!attribute [r] custom?
    #   @return [true, false] if the voice region is custom, e.g. for events.
    # @!attribute [r] optimal?
    #   @return [true, false] if the voice region is the closest one to the client.
    # @!attribute [r] deprecated?
    #   @return [true, false] if the voice region is deprecated and should be avoided.
    PREDICATES.each do |name|
      Discordrb.predicate_method(self, name)
    end

    # @!visibility private
    def inspect
      "<VoiceRegion id=\"#{@id}\" name=\"#{@name}\" optimal=#{@optimal}>"
    end
  end
end
