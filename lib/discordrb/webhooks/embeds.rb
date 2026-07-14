# frozen_string_literal: true

module Discordrb::Webhooks
  # An embed is a multipart-style attachment to a webhook
  #   message that can have a variety of different purposes and appearances.
  class EmbedBuilder
    # @overload title=(value)
    #   @param value [String, nil] The title of the emebd; 1-256 characters.
    #   @return [void]
    # @overload description=(value)
    #   @param value [String, nil] The description of the emebd; 1-4096 characters.
    #   @return [void]
    # @overload url=(value)
    #   @param value [String, nil] The URL of the emebd; 1-2048 characters.
    #   @return [void]
    # @overload timestamp=(value)
    #   @param value [Time, String, nil] The timestamp of the emebd; Time object or ISO8601 string.
    #   @return [void]
    # @overload color=(value)
    #   @param value [Integer, String, ColourRGB, nil] The colour of the embed.
    #   @return [void]
    # @overload image=(value)
    #   @param value [String, nil] The image of the embed; HTTPS URL or `attachment://` reference.
    #   @return [void]
    # @overload thumbnail=(value)
    #   @param value [String, nil] The thumbnail of the embed; HTTPS URL or `attachment://` reference.
    #   @return [void]
    # @overload fields=(value)
    #   @param value [Array<#to_h>, nil] The fields of the embed. Each element must respond to `#to_h`.
    #   @return [void]
    %i[title description url timestamp color image thumbnail fields].each { |item| attr_writer(item) }

    # Add a footer to the embed builder.
    # @param text [String] The text of the footer; 1-2048 characters.
    # @param icon [String, nil] HTTPS URL or `attachment://` reference.
    # @return [void]
    def footer(text:, icon: nil)
      @footer = { text:, icon_url: icon }.tap(&:compact!)
    end

    # Add an author to the embed builder.
    # @param text [String] The name of the author; 1-256 characters.
    # @param url [String, nil] HTTPS URL hyperlink; 1-2048 characters.
    # @param icon [String, nil] HTTPS URL or `attachment://` reference.
    # @return [void]
    def author(text:, url: nil, icon: nil)
      @author = { name: text, url:, icon_url: icon }.tap(&:compact!)
    end

    # Add a field to the embed builder.
    # @param title [String] The title of the field; 1-256 characters.
    # @param value [String] The value of the field; 1-1024 characters.
    # @param inline [true, false, nil] Whether or not the field should be inline.
    # @return [void]
    def field(title:, value:, inline: nil)
      (@fields ||= []) << { name: title, value:, inline: }.tap(&:compact!)
    end

    # @!visibility private
    def to_h
      {
        title: @title,
        description: @description,
        url: @url,
        timestamp: @timestamp.is_a?(Time) ? @timestamp&.iso8601 : @timestamp,
        color: @color.is_a?(String) ? @color.delete('#').to_i(16) : @color&.to_i(16),
        footer: @footer,
        image: @image ? { url: @image } : @image,
        author: @author,
        thumbnail: @thumbnail ? { url: @thumbnail } : @thumbnail,
        fields: @fields&.any? ? @fields.map(&:to_h) : nil
      }.compact
    end

    alias_method :colour=, :color=
  end
end
