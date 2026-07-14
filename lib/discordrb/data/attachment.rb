# frozen_string_literal: true

module Discordrb
  # An attachment for a message.
  class Attachment
    include Snowflake

    # Mapping of attachment flags.
    FLAGS = {
      clip: 1 << 0,
      thumbnail: 1 << 1,
      spoiler: 1 << 3,
      animated: 1 << 5
    }.freeze

    # @return [String] the CDN URL the attachment can be downloaded at.
    attr_reader :url

    # @return [String] the attachment's proxy URL.
    attr_reader :proxy_url

    # @return [String] the attachment's filename.
    attr_reader :filename

    # @return [Integer] the attachment's file size in bytes.
    attr_reader :size

    # @return [Integer, nil] the width of an image file, in pixels, or `nil` if the file is not an image.
    attr_reader :width

    # @return [Integer, nil] the height of an image file, in pixels, or `nil` if the file is not an image.
    attr_reader :height

    # @return [String, nil] the attachment's alt text.
    attr_reader :description

    # @return [String, nil] the attachment's mime type.
    attr_reader :content_type

    # @return [true, false] whether the attachment is ephemeral, meaning it will automatically be deleted.
    attr_reader :ephemeral
    alias_method :ephemeral?, :ephemeral

    # @return [Float, nil] the duration of the voice message in seconds.
    attr_reader :duration_seconds

    # @return [String, nil] the base64 encoded bytearray representing a sampled waveform for a voice message.
    attr_reader :waveform

    # @return [Integer] the flags set on the attachment combined as a bitfield.
    attr_reader :flags

    # @return [String, nil] the thumbhash of the attachment, if applicable.
    attr_reader :placeholder

    # @return [Integer, nil] the version of the attachment's thumbhash, if applicable.
    attr_reader :placeholder_version

    # @return [Application, nil] the application that was recognized in the clipped stream.
    attr_reader :clip_application

    # @return [Array<User>] the users who were in the clipped stream.
    attr_reader :clip_participants

    # @return [Time, nil] the time at when the clip was created, if applicable.
    attr_reader :clip_creation_time

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @id = data[:id].to_i
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @filename = data[:filename]
      @size = data[:size]

      @width = data[:width]
      @height = data[:height]
      @description = data[:description]
      @content_type = data[:content_type]

      @ephemeral = data[:ephemeral] || false
      @duration_seconds = data[:duration_secs]&.to_f
      @waveform = data[:waveform]
      @flags = data[:flags] || 0

      @placeholder = data[:placeholder]
      @placeholder_version = data[:placeholder_version]

      @clip_application = Application.new(data[:application], @bot) if data[:application]
      @clip_participants = data[:clip_participants]&.map { |user| @bot.ensure_user(user) } || []
      @clip_creation_time = Time.iso8601(data[:clip_created_at]) if data[:clip_created_at]
    end

    # Check if the attachment is an image.
    # @return [true, false] Whether or not the attachment is an image.
    def image?
      !(@width.nil? || @height.nil?)
    end

    # Get the message associated with the attachment.
    # @return [Message, nil] The message the attachment is associated with.
    def message
      @message if @message.is_a?(Message)
    end

    # Get the message snapshot associated with the attachment.
    # @return [Snapshot, nil] The snapshot the attachment is associated with.
    def snapshot
      @message if @message.is_a?(Snapshot)
    end

    # @!method spoiler?
    #   @return [true, false] whether or not the attachment is marked as a spoiler.
    # @!method clip?
    #   @return [true, false] whether or not the attachment is a clip from a stream.
    # @!method animated?
    #   @return [true, false] whether or not the attachment is considered to be an animated image.
    # @!method thumbnail?
    #   @return [true, false] whether or not the attachment is the thumbnail of a thread in a media channel.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
    end
  end
end
