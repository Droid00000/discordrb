# frozen_string_literal: true

module Discordrb
  # A reaction to a message.
  class Reaction
    # @return [Integer] the total amount of users who have reacted with this reaction
    attr_reader :count

    # @return [true, false] whether the current bot or user used this reaction
    attr_reader :me
    alias_method :me?, :me

    # @return [Integer] the ID of the emoji, if it was custom
    attr_reader :id

    # @return [String] the name or unicode representation of the emoji
    attr_reader :name

    # @return [true, false] whether the current bot super-reacted using this emoji
    attr_reader :me_burst
    alias_method :me_burst?, :me_burst

    # @return [Array<ColourRGB>] an array of colors used for super reactions
    attr_reader :burst_colors

    # @return [Integer] the total count of super reactions
    attr_reader :burst_count

    # @return [Integer] the total count of non super reactions
    attr_reader :normal_count

    # @!visibility private
    def initialize(data)
      @count = data['count']
      @me = data['me']
      @id = data['emoji']['id']&.to_i
      @name = data['emoji']['name']
      @me_burst = data['me_burst']
      @burst_count = data['count_details']['burst']
      @normal_count = data['count_details']['normal']
      @burst_colors = data['burst_colors']&.map { |c| ColourRGB.new(c.delete('#')) } || []
    end

    # Converts this Reaction into a string that can be sent back to Discord in other reaction endpoints.
    # If ID is present, it will be rendered into the form of `name:id`.
    # @return [String] the name of this reaction, including the ID if it is a custom emoji
    def to_s
      id.nil? ? name : "#{name}:#{id}"
    end
  end
end
