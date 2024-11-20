# frozen_string_literal: true

module Discordrb
  # Stickers: https://discord.com/developers/docs/resources/sticker
  class Sticker
    include IDObject

    FORMAT = {
      1 => :png,
      2 => :apng,
      3 => :lottie,
      4 => :gif
    }.freeze

    TYPE = {
      1 => :standard,
      2 => :server
    }.freeze

    # @return [String] The sticker's name.
    attr_reader :name

    # @return [String] The sticker's description.
    attr_reader :description

    # @return [String] The sticker's tags.
    attr_reader :tags

    # @return [String] The sticker type.
    attr_reader :type

    # @return [String] The file type of this sticker.
    attr_reader :format

    # @return [Boolean] If this sticker can be used.
    attr_reader :usable

    # @return [Object, nil] The server this sticker originates from.
    attr_reader :server

    # @return [Object, nil] The user that uploaded this sticker.
    attr_reader :member

    # @return [Integer] Sort order of a sticker if it belongs to a pack.
    attr_reader :sort_order

    # @return [Integer] Pack ID of a sticker if it belongs to one.
    attr_reader :pack_id

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = @bot.server(data['guild_id']) if data['guild_id']
      @name = data['name']
      @id = data['id']&.to_i
      @tags = data['tags']
      @type = TYPE[data['type']]
      @format = FORMAT[data['format_type']]
      @description = data['description']
      @pack_id = data['pack_id']&.to_i
      @sort_order = data['sort_value']&.to_i
      @usable = data['available']
      @member = @bot.user(data['user']) if data['user']
    end

    # @return [String] the file URL of the sticker
    def url
      mime = @format == :lottie ? :json : @format
      API.sticker_file_url(id, format: mime.to_s)
    end

    # Returns if this sticker can be added to a guild.
    def premium?
      !(@format == :lottie || @type == :standard)
    end

    # Returns a tempfile object for this sticker.
    # @return [File] a file.
    def file
      file = Tempfile.new(Time.now.to_s)
      file.binmode
      file.write(Faraday.get(url).body)
      file.rewind
      file
    end
  end
end
