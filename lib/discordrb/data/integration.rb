# frozen_string_literal: true

module Discordrb
  # An integration for a guild.
  class Integration
    include Snowflake

    # @!visibility private
    PREDICATES = %i[
      enabled
      syncing
      revoked
      emoticons
    ].freeze

    # Mapping of expiry behaviors.
    BEHAVIORS = {
      remove_role: 0,
      kick_member: 1
    }.freeze

    # @return [String] the name of the integration.
    attr_reader :name

    # @return [Symbol] the type of the integration.
    attr_reader :type

    # @return [Guild] the guild that the integration has been added to.
    attr_reader :guild

    # @return [Array<String>] the scopes that the integration was added with.
    attr_reader :scopes

    # @return [User, nil] the user who added the integration. Only present when
    #   the integration was fetched via {Guild#integrations}.
    attr_reader :added_by

    # @return [Time, nil] the time at when the integration was last synced, if any.
    attr_reader :synced_at

    # @return [String] the ID of the integration's account (what this is for is unknown to me).
    attr_reader :account_id

    # @return [Application, nil] the application that the bot integration belongs to.
    attr_reader :application

    # @return [String] the name of the integration's account (what this is for is unknown to me).
    attr_reader :account_name

    # @return [Symbol, nil] the action that the integration will take against expired subscribers.
    #   This can be one of `:remove_role` or `:kick_member`.
    attr_reader :expiry_behavior
    alias expiry_behaviour expiry_behavior

    # @return [Integer] the amount of subscribers that the integration currently has.
    attr_reader :subscriber_count

    # @return [Integer, nil] the ID of the role that the integration uses for subscribers, if any.
    attr_reader :subscriber_role_id

    # @return [Integer] the amount of time (in days) to wait before actioning expiring subscribers.
    attr_reader :expiry_grace_period

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @id = data[:id] == 'twitch-partners' ? data[:id] : data[:id]&.to_i
      @name = data[:name]
      @type = data[:type]&.to_sym
      @scopes = data[:scopes] || []
      @enabled = data[:enabled]
      @syncing = data[:syncing] || false
      @revoked = data[:revoked] || false
      @emoticons = data[:enable_emoticons] || false
      @added_by = @bot.ensure_user(data[:user]) if data[:user]
      @synced_at = Time.iso8601(data[:synced_at]) if data[:synced_at]
      @account_id = data[:account]&.[](:id)
      @account_name = data[:account]&.[](:name)
      @application = Application.new(data[:application], @bot) if data[:application]
      @expiry_behavior = BEHAVIORS.key(data[:expire_behavior]) if data[:expire_behavior]
      @subscriber_count = data[:subscriber_count] || 0
      @subscriber_role_id = data[:role_id]&.to_i
      @expiry_grace_period = data[:expire_grace_period] || 0
    end

    # @!visibility private
    def hash
      @hash ||= (@id == 'twitch-partners' ? @id.hash : @id)
    end

    # Get the role that the integration will use for subscribers.
    # @return [Role, nil] The role that the integration will use for subscribers.
    def subscriber_role
      @guild.role(@subscriber_role_id) if @subscriber_role_id
    end

    # @!attribute [r] enabled?
    #   @return [true, false] whether or not the integration is enabled.
    # @!attribute [r] syncing?
    #   @return [true, false] whether or not the integration is syncing.
    # @!attribute [r] revoked?
    #   @return [true, false] whether or not the integration has been revoked.
    # @!attribute [r] emoticons?
    #   @return [true, false] whether or not the integration is syncing twitch emotes.
    PREDICATES.each do |name|
      define_method("#{name}?") { instance_variable_get(:"@#{name}") }
    end

    # @!visibility private
    def inspect
      "<Integration id=#{@id} guild_id=#{@guild.id} name=\"#{@name}\">"
    end

    # An application for a bot integration.
    class Application
      include Snowflake

      # @return [String] the name of the application.
      attr_reader :name

      # @return [String, nil] the CDN hash for the application's icon.
      attr_reader :icon

      # @return [Integer] the application's flags combined as a bitfied.
      attr_reader :flags

      # @return [User, nil] the bot user the application is for, if any.
      attr_reader :bot_user

      # @return [String, nil] the CDN hash for the application's cover image.
      attr_reader :cover_image

      # @return [String, nil] the description of the application, if one is set.
      attr_reader :description

      # @return [Integer, nil] the ID of the game SKU, if the application is a game.
      attr_reader :primary_sku_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data[:id].to_i
        @name = data[:name]
        @icon = data[:icon]
        @flags = data[:flags_new].to_i
        @cover_image = data[:cover_image]
        @primary_sku_id = data[:primary_sku_id]&.to_i
        @bot_user = @bot.ensure_user(data[:bot]) if data[:bot]
        @description = data[:description] == '' ? nil : data[:description]
      end

      # Utility method to get a application's icon URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
      # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
      # @return [String, nil] The URL to the icon image, or `nil` if the application doesn't have an icon image.
      def icon_url(format: 'webp', size: 4096)
        Assets[:application_icon, @id, @icon, format, size:] if @icon
      end

      # Utility method to get a application's cover image URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
      # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
      # @return [String, nil] The URL to the cover image, or `nil` if the application doesn't have a cover image.
      def cover_image_url(format: 'webp', size: 4096)
        Assets[:application_cover, @id, @cover_image, format, size:] if @cover_image
      end

      # @!visibility private
      def inspect
        "<Application id=#{@id} name=\"#{@name}\" description=\"#{@description}\">"
      end
    end
  end
end
