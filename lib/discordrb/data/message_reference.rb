# frozen_string_literal: true

module Discordrb
  # Data about a reference to another message.
  class MessageReference
    # Mapping of types.
    TYPES = {
      default: 0,
      forward: 1
    }.freeze

    # @return [Integer] the type of the reference.
    attr_reader :type

    # @return [Integer, nil] the ID of the guild that the
    #   referenced message originates from. Only guaranteed
    #   to be present for replies and forwards from a guild.
    attr_reader :guild_id

    # @return [Integer, nil] the ID of the referenced message.
    attr_reader :message_id

    # @return [Integer] the ID of the channel that the referenced
    #   message originates from.
    attr_reader :channel_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @type = data[:type]
      @guild_id = data[:guild_id]&.to_i
      @message_id = data[:message_id]&.to_i
      @channel_id = data[:channel_id]&.to_i
      @deleted = data.key?(:message) && data[:message].nil?
      @message = Message.new(data[:message], @bot) if data[:message]
    end

    # Get the guild the referenced message originates from.
    # @return [Guild, nil] The guild the referenced message originates from.
    def guild
      channel.guild
    end

    # Get the channel the referenced message originates from.
    # @return [Channel] The channel that the referenced message originates from.
    def channel
      @bot.channel(@channel_id)
    end

    # Get the status of the referenced message.
    # @return [Symbol] The status of the referenced message. Will be one of the
    #   following: `:available`, `:unknown`, or `:deleted`.
    def state
      return :available if @message

      @deleted ? :deleted : :unknown
    end

    # Get the message that the message reference is a pointer to.
    # @return [Message, nil] The message that was referenced or `nil` if not found.
    def message
      return @message if @message || @deleted

      @message = channel&.load_message(@message_id)
      @message.tap { @deleted = true unless @message }
    end

    alias_method :resolve, :message

    # @!method reply?
    #   @return [true, false] whether the message is a reply to another message.
    # @!method forward?
    #   @return [true, false] whether the message is a snapshot of another message.
    TYPES.each do |name, value|
      define_method("#{name}?") { @type == value }
    end

    # @!visibility private
    def inspect
      "<MessageReference type=#{@type} state=#{@state}>"
    end
  end
end
