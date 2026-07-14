# frozen_string_literal: true

module Discordrb
  # An embed associated with a message.
  class Embed
    # @return [String] the URL the embed object is based on.
    attr_reader :url

    # @return [String, nil] the title of the embed object. `nil` if there is not a title
    attr_reader :title

    # @return [Integer] the flags of the embed object combined as a bitfield.
    attr_reader :flags

    # @return [String, nil] the description of the embed object. `nil` if there is not a description
    attr_reader :description

    # @return [Symbol] the type of the embed object. Possible types are:
    #
    #   * `:link`
    #   * `:video`
    #   * `:image`
    attr_reader :type

    # @return [Time, nil] the timestamp of the embed object. `nil` if there is not a timestamp
    attr_reader :timestamp

    # @return [ColourRGB, nil] the color of the embed object. `nil` if there is not a color
    attr_reader :color
    alias_method :colour, :color

    # @return [EmbedFooter, nil] the footer of the embed object. `nil` if there is not a footer
    attr_reader :footer

    # @return [EmbedProvider, nil] the provider of the embed object. `nil` if there is not a provider
    attr_reader :provider

    # @return [EmbedImage, nil] the image of the embed object. `nil` if there is not an image
    attr_reader :image

    # @return [EmbedThumbnail, nil] the thumbnail of the embed object. `nil` if there is not a thumbnail
    attr_reader :thumbnail

    # @return [EmbedVideo, nil] the video of the embed object. `nil` if there is not a video
    attr_reader :video

    # @return [EmbedAuthor, nil] the author of the embed object. `nil` if there is not an author
    attr_reader :author

    # @return [Array<EmbedField>] the fields of the embed object.
    attr_reader :fields

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @url = data[:url]
      @title = data[:title]
      @flags = data[:flags] || 0
      @type = data[:type].to_sym
      @description = data[:description]
      @timestamp = Time.iso8601(data[:timestamp]) if data[:timestamp]
      @color = ColourRGB.new(data[:color]) if data[:color]
      @footer = EmbedFooter.new(data[:footer], @bot) if data[:footer]
      @image = EmbedImage.new(data[:image], @bot) if data[:image]
      @video = EmbedVideo.new(data[:video], @bot) if data[:video]
      @provider = EmbedProvider.new(data[:provider], @bot) if data[:provider]
      @thumbnail = EmbedThumbnail.new(data[:thumbnail], @bot) if data[:thumbnail]
      @author = EmbedAuthor.new(data[:author], @bot) if data[:author]
      @fields = data[:fields]&.map { |field| EmbedField.new(field, @bot) } || []
    end

    # @!visibility private
    def to_h
      {
        title: @title,
        description: @description,
        url: @url,
        timestamp: @timestamp&.iso8601,
        color: @color&.to_i,
        image: @image ? { url: @image.url } : nil,
        thumbnail: @thumbnail ? { url: @thumbnail.url } : nil,
        fields: @fields.any? ? @fields.map(&:to_h) : nil,
        footer: @footer&.to_h,
        author: @author&.to_h
      }.compact
    end
  end

  # A footer for an embed.
  class EmbedFooter
    # @return [String] the footer text.
    attr_reader :text

    # @return [String] the URL of the footer icon.
    attr_reader :icon_url

    # @return [String] the proxied URL of the footer icon.
    attr_reader :proxy_icon_url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @text = data[:text]
      @icon_url = data[:icon_url]
      @proxy_icon_url = data[:proxy_icon_url]
    end

    # @!visibility private
    def to_h
      { text: @text, icon_url: @icon_url }.compact
    end
  end

  # An image for an embed.
  class EmbedImage
    # @return [String] the source URL of the image.
    attr_reader :url

    # @return [String] the proxy URL of the image.
    attr_reader :proxy_url

    # @return [Integer] the width of the image, in pixels.
    attr_reader :width

    # @return [Integer] the height of the image, in pixels.
    attr_reader :height

    # @return [Integer] the flags of the image, as a bitfield.
    attr_reader :flags

    # @return [String, nil] the alt text of the image.
    attr_reader :description

    # @return [String, nil] the media type of the image.
    attr_reader :content_type

    # @return [String, nil] the thumbhash of the image.
    attr_reader :placeholder

    # @return [Integer, nil] the version of the image's thumbhash.
    attr_reader :placeholder_version

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @width = data[:width]
      @height = data[:height]
      @flags = data[:flags] || 0
      @description = data[:description]
      @content_type = data[:content_type]
      @placeholder = data[:placeholder]
      @placeholder_version = data[:placeholder_version]
    end
  end

  # A video for an embed.
  class EmbedVideo
    # @return [String] the source URL of the video.
    attr_reader :url

    # @return [String] the proxy URL of the video.
    attr_reader :proxy_url

    # @return [Integer] the width of the video, in pixels.
    attr_reader :width

    # @return [Integer] the height of the video, in pixels.
    attr_reader :height

    # @return [Integer] the flags of the video, as a bitfield.
    attr_reader :flags

    # @return [String, nil] the alt text of the video.
    attr_reader :description

    # @return [String, nil] the media type of the video.
    attr_reader :content_type

    # @return [String, nil] the thumbhash of the video.
    attr_reader :placeholder

    # @return [Integer, nil] the version of the video's thumbhash.
    attr_reader :placeholder_version

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @width = data[:width]
      @height = data[:height]
      @flags = data[:flags] || 0
      @description = data[:description]
      @content_type = data[:content_type]
      @placeholder = data[:placeholder]
      @placeholder_version = data[:placeholder_version]
    end
  end

  # A thumbnail for an embed.
  class EmbedThumbnail
    # @return [String] the CDN URL the thumbnail can be downloaded at.
    attr_reader :url

    # @return [String] the thumbnail's proxy URL.
    attr_reader :proxy_url

    # @return [Integer] the width of the thumbnail's file, in pixels.
    attr_reader :width

    # @return [Integer] the height of the thumbnail's file, in pixels.
    attr_reader :height

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @width = data[:width]
      @height = data[:height]
    end
  end

  # A provider for an embed.
  class EmbedProvider
    # @return [String] the provider's name.
    attr_reader :name

    # @return [String, nil] the URL of the provider, or `nil` if there is no URL.
    attr_reader :url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @name = data[:name]
      @url = data[:url]
    end
  end

  # An author for an embed.
  class EmbedAuthor
    # @return [String] the author's name.
    attr_reader :name

    # @return [String, nil] the URL of the author's website, or `nil` if there is no URL.
    attr_reader :url

    # @return [String, nil] the icon of the author, or `nil` if there is no icon.
    attr_reader :icon_url

    # @return [String, nil] the Discord proxy URL, or `nil` if there is no `icon_url`.
    attr_reader :proxy_icon_url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @name = data[:name]
      @url = data[:url]
      @icon_url = data[:icon_url]
      @proxy_icon_url = data[:proxy_icon_url]
    end

    # @!visibility private
    def to_h
      { name: @name, icon_url: @icon_url }.compact
    end
  end

  # A field for an embed.
  class EmbedField
    # @return [String] the field's name.
    attr_reader :name

    # @return [String] the field's value.
    attr_reader :value

    # @return [true, false] whether the field is displayed inline.
    attr_reader :inline

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @name = data[:name]
      @value = data[:value]
      @inline = data[:inline]
    end

    # @!visibility private
    def to_h
      { name: @name, value: @value, inline: @inline }.compact
    end
  end
end
