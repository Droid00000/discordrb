# frozen_string_literal: true

module Discordrb
  # A sticker that can be sent in messages.
  class Sticker
    include IDObject

    # Sticker file types.
    # @see https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types
    FORMAT_TYPES = {
      1 => :png,
      2 => :apng,
      3 => :lottie,
      4 => :gif
    }.freeze

    # Sticker types.
    # @see https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types
    TYPES = {
      1 => :standard,
      2 => :server
    }.freeze

    # @return [String] The sticker's name.
    attr_reader :name

    # @return [String] The sticker's description.
    attr_reader :description

    # @return [String] The sticker's tags.
    attr_reader :tags

    # @return [Symbol] The sticker's type, see {TYPE}.
    attr_reader :type

    # @return [Symbol] The file type of this sticker, see {FORMAT_TYPES}.
    attr_reader :format

    # @return [Boolean] If this sticker can be used. May be false due to a lack of server boosts.
    attr_reader :usable
    alias_method :usable?, :usable
    alias_method :available?, :usable

    # @return [User, nil] The user that uploaded this sticker, or nil.
    attr_reader :creator

    # @return [Integer] The sort order of this sticker if it's part of a pack.
    attr_reader :sort_order

    # @return [Integer, nil] The ID of the pack if this sticker belongs to one.
    attr_reader :pack_id

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @name = data['name']
      @id = data['id'].to_i
      @tags = data['tags']

      @description = data['description']

      @usable = data['available']

      @pack_id = data['pack_id']&.to_i
      @sort_order = data['sort_value']

      @server = server || data['guild_id']&.to_i

      @type = TYPES[data['type']]
      @format = FORMAT_TYPES[data['format_type']]

      @creator = data['user'] ? bot.ensure_user(data['user']) : nil
    end

    # @return [Server, Integer, nil] The server this sticker originates from.
    def server
      @server.is_a?(Server) ? @server : @bot.server(@server)
    end

    # @return [String] the file URL of the sticker
    def file_url
      API.sticker_file_url(id, format == :lotte ? :json : format)
    end

    # Set the name of the sticker.
    # @param [String]
    def name=(name)
      update_sticker(name: name)
    end

    # Set the tags of the sticker.
    # @param [String, Array<String>]
    def tags=(tags)
      tags = tags.join(", ") if tags.is_a?(Array)
      update_sticker(tags: tags)
    end

    # Set the description of the sticker.
    # @param [String, nil]
    def description=(description)
      update_sticker(description: description)
    end

    # Delete this sticker from a server.
    # @param reason [String, nil] The reason for deleting this sticker.
    def delete(reason = nil)
      API::Sticker.delete_sticker(@bot.token, server.id, id, reason)
      server.stickers.delete(id)
    end

    # ID based comparison for equality.
    def ==(other)
      return false unless other.is_a?(Sticker)

      return Discordrb.id_compare(@id, other)
    end

    alias_method :eql?, :==

    # @!visibility private
    def update_sticker(data)
      update_data(JSON.parse(API::Sticker.edit_sticker(@bot.token, server.id, id, data[:name],
                                                       data[:description], data[:tags])))
    end
  end
end
