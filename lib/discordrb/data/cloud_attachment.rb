# frozen_string_literal: true

module Discordrb
  # A message attachment uploaded directly to GCP.
  class CloudAttachment
    # @return [Channel] the channel the uploaded file is for.
    attr_reader :channel

    # @return [String] the display name of the uploaded file.
    attr_reader :filename

    # @return [String] the filename that can be used to upload
    #   the file when sending a new message or modifying an existing one.
    attr_reader :upload_filename

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @filename = data[:filename]
      @unfulfilled = data[:_unfulfilled]
      @upload_filename = data[:upload_filename]
    end

    # Whether the cloud upload failed.
    # @return [true, false] Whether or not the cloud upload has failed.
    def failed?
      @unfulfilled == true
    end

    # Whether the cloud upload succeeded.
    # @return [true, false] Whether or not the cloud upload was successful.
    def succeeded?
      @unfulfilled != true
    end

    # @!visibility private
    def to_h
      failed? ? {} : { filename: @filename, uploaded_filename: @upload_filename }
    end

    # @!visibility private
    def inspect
      "<CloudAttachment channel_id=#{@channel.id} upload_filename=#{@upload_filename}>"
    end
  end
end
