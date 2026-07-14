# frozen_string_literal: true

module Discordrb
  # Collectibles are resources such as nameplates that can be purchased by users.
  class Collectibles
    # @return [Nameplate, nil] the nameplate the user has collected.
    attr_reader :nameplate

    # @return [AvatarDecoration, nil] the avatar decoration the user has collected.
    attr_reader :avatar_decoration

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @nameplate = Nameplate.new(data[:nameplate], bot) if data[:nameplate]
      @avatar_decoration = AvatarDecoration.new(data[:avatar_decoration_data], bot) if data[:avatar_decoration_data]
    end

    # @!visibility private
    def to_h
      {
        nameplate: @nameplate&.to_h,
        avatar_decoration_data: @avatar_decoration&.to_h
      }
    end

    # Background images that are shown on a user's name in the member's list.
    class Nameplate
      # @return [Integer] ID of the nameplate's SKU.
      attr_reader :sku_id

      # @return [String] the path to the nameplate asset.
      attr_reader :asset

      # @return [String] the label of the nameplate.
      attr_reader :label

      # @return [Symbol] the background color of the nameplate.
      attr_reader :palette

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @sku_id = data[:sku_id]&.to_i
        @asset = data[:asset]
        @label = data[:label]
        @palette = data[:palette].to_sym
      end

      # Utility method to get the URL of this nameplate.
      # @param static [true, false] Whether to return the static URL of this
      #   nameplate instead of the animated URL.
      # @return [String] The CDN URL of this nameplate.
      def url(static: false)
        if static
          Assets[:static_nameplate_asset, @asset, 'png']
        else
          Assets[:nameplate_asset, @asset, 'webm']
        end
      end

      # Comparison based off of asset and SKU ID.
      # @param other [Nameplate] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        return false unless other.is_a?(Nameplate)

        (@asset == other.asset) && (@sku_id == other.sku_id)
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        {
          sku_id: @sku_id&.to_s,
          asset: @asset,
          label: @label,
          palette: @palette&.to_s
        }
      end

      # @!visibility private
      def inspect
        "<Nameplate sku_id=#{@sku_id} palette=\"#{@palette}\">"
      end
    end

    # A decoration displayed on a user's avatar.
    class AvatarDecoration
      # @return [String] the avatar decoration's URL asset.
      # @see #url
      attr_reader :asset

      # @return [Integer] the ID of the avatar decoration's SKU.
      attr_reader :sku_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @asset = data[:asset]
        @sku_id = data[:sku_id]&.to_i
      end

      # Utility method to get an avatar decoration URL.
      # @return [String] the URL to the avatar decoration.
      def url
        Assets[:avatar_decoration, @asset]
      end

      # Comparison based off of asset and SKU ID.
      # @param other [AvatarDecoration] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        return false unless other.is_a?(AvatarDecoration)

        (@asset == other.asset) && (@sku_id == other.sku_id)
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        {
          asset: @asset,
          sku_id: @sku_id.to_s
        }
      end

      # @!visibility private
      def inspect
        "<AvatarDecoration sku_id=#{@sku_id}>"
      end
    end
  end
end
