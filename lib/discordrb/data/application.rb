# frozen_string_literal: true

module Discordrb
  # OAuth application information.
  class Application
    include IDObject

    # Map of application flags.
    FLAGS = {
      automod_rule_badge: 1 << 6,
      server_presences_intent: 1 << 12,
      limited_server_presences_intent: 1 << 13,
      server_members_intent: 1 << 14,
      limited_server_members_intent: 1 << 15,
      pending_server_limit_verification: 1 << 16,
      embedded: 1 << 17,
      message_content_intent: 1 << 18,
      limited_message_content_intent: 1 << 19,
      application_command_badge: 1 << 23
    }.freeze

    # @return [String] the application name.
    attr_reader :name

    # @return [String] the application description.
    attr_reader :description

    # @return [String] the application origins permitted to use RPC.
    attr_reader :rpc_origins

    # @return [Integer] the applications flags.
    attr_reader :flags

    # @return [true, false] If this appliction can be added by users besides the owner.
    attr_reader :public
    alias_method :public?, :public

    # @return [true, false] If this application requires the full OAuth2 code grant follow in order to join servers.
    attr_reader :requires_code_grant
    alias_method :requires_code_grant?, :requires_code_grant

    # @return [Team, nil] The team that owns this application, or nil if this application isn't part of a team.
    attr_reader :team

    # @return [String, nil] URL of the application's terms of service.
    attr_reader :terms_of_service_url

    # @return [String, nil] URL of the application's privacy policy.
    attr_reader :privacy_policy_url

    # @return [String, nil] Hex encoded key for interaction verification in the GameSDK.
    attr_reader :verify_key

    # @return [String, nil] URL slug to the game store-front if this app is a game sold on Discord.
    attr_reader :slug

    # @return [Integer, nil] If this application is a game sold on Discord, this will be the id of the “Game SKU”.
    attr_reader :primary_sku_id

    # @return [Integer] Approximate count of servers that the bot has been added to.
    attr_reader :server_install_count

    # @return [Integer] Approximate count of users that have installed the application.
    attr_reader :user_install_count

    # @return [Array<String>] Array of redirect URIs for the application.
    attr_reader :redirect_uris
    alias_method :redirect_urls, :redirect_uris

    # @return [String, nil] URL used to reccive interactions via HTTP POST.
    attr_reader :interactions_endpoint

    # @return [String, nil] URL used for role connections verification by the application.
    attr_reader :role_connections_url

    # @return [Integer] The webhook events status. (1) disabled by default, (2) enabled, (3) disabled by Discord.
    attr_reader :webhook_events_status

    # @return [Array<String>] The webhook event types that the application has subscribed to.
    attr_reader :webhook_event_types

    # @return [Array<String>] Array of tags, describing the functionality of the application.
    attr_reader :tags

    # @return [String, nil] Default custom authorization URL for the application if enabled.
    attr_reader :custom_install_url
    alias_method :custom_install_link, :custom_install_url

    # @return [Array<String>] The list of OAuth2 scopes to add the application to a server with.
    attr_reader :install_scopes

    # @return [Permissions, nil] The default set of permissions to give an application when adding it to a server.
    attr_reader :install_permissions

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      update_application_data(data)
    end

    # Utility method to get an application's icon URL.
    # @return [String, nil] The URL of the icon's image (nil if no image is set.)
    def icon_url
      @icon_id ? API.app_icon_url(@id, @icon_id) : nil
    end

    # Utility method to get an application's cover image URL.
    # @return [String, nil] The URL of the cover image (nil if no image is set.)
    def cover_image_url
      @cover_image ? API.cover_image_url(@id, @cover_image) : nil
    end

    # @return [User] The user that owns this application.
    def owner
      @bot.user(@owner_id)
    end

    # @return [Server] The server associated with this application.
    # @raise [Discordrb::Errors::NoPermission] This can happen if the bot doesn't have access to the server.
    def server
      @bot.server(@server_id)
    end

    # Edit the tags used to describe this application.
    # @param tags [Array<String>] New tags to describe the app.
    def tags=(tags)
      edit_application(tags: tags)
    end

    # Edit the public enabled flags for this application.
    # @param flags [Integer] Bitwise value of new public flags.
    def flags=(flags)
      edit_application(flags: flags)
    end

    # Edit the custom installation URL for this application.
    # @param url [String] New default custom install URL for the app.
    def custom_install_url=(url)
      edit_application(custom_install_url: url)
    end

    # Edit the webhook events URL for this application.
    # @param url [String] New webhook events URL for the app.
    def webhook_events_url=(url)
      edit_application(event_webhooks_url: url)
    end

    # Edit the description for this application.
    # @param description [String] New description for the app.
    def description=(description)
      edit_application(description: description)
    end

    # Edit the role connections verification URL for this application.
    # @param url [String] New role connection verification URL for the app.
    def role_connections_url=(url)
      edit_application(role_connections_url: url)
    end

    # Edit the subscribed webhook events for this application.
    # @param types [Array<String>] New events to subscribe to for the app.
    def webhook_event_types=(types)
      edit_application(event_webhooks_types: types)
    end

    # Edit the status of webhook events for this application.
    # @param events [Integer] 1 to enable webhook events, 2 to disable.
    def webhook_events_status=(events)
      edit_application(event_webhooks_status: events)
    end

    # Edit the URL used to reccive interactions via POST.
    # @param url [String] New interactions endpoint URL for the app.
    def interactions_endpoint=(url)
      edit_application(interactions_endpoint_url: url)
    end

    # @!method automod_rule_badge?
    #   @return [Boolean] If the bot has the auto-moderation badge displayed on their profile.
    # @!method server_presences_intent?
    #   @return [Boolean] If the bot is in more than 100 servers and has been granted access to the server presences intent.
    # @!method limited_server_presences_intent?
    #   @return [Boolean] If the bot is in less that 100 servers and has access to the server presences intent.
    # @!method server_members_intent?
    #   @return [Boolean] If the bot is in more than 100 servers and has been granted access to the server members intent.
    # @!method limited_server_members_intent?
    #   @return [Boolean] If the bot is in less that 100 servers and has access to the server members intent.
    # @!method pending_server_limit_verification?
    #   @return [Boolean] If unusal growth of the bot is preventing it from being verified.
    # @!method embedded?
    #   @return [Boolean] If this app is embdedded within the Discord client.
    # @!method message_content_intent?
    #   @return [Boolean] If the bot is in more than 100 servers and has been granted access to the message content intent.
    # @!method limited_message_content_intent?
    #   @return [Boolean] If the bot is in less than 100 servers and has access to the message content intent.
    # @!method application_command_badge?
    #   @return [Boolean] If the bot has the application command badge displayed on their profile.
    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Application name=#{@name} id=#{@id} flags=#{@flags} owner_id=#{@owner_id} server_id=#{@server_id} public=#{@public}>"
    end

    private

    # @!visibility private
    def edit_application(data)
      update_application_data(JSON.parse(API.edit_current_application(@bot.token, **data)))
    end

    # @!visibility private
    def update_application_data(data)
      @name = data['name']
      @description = data['description']
      @icon_id = data['icon']
      @rpc_origins = data['rpc_origins']
      @flags = data['flags']

      @owner_id = data['owner']['id'].to_i
      @server_id = data['guild_id']&.to_i
      @public = data['bot_public']
      @requires_code_grant = data['bot_requires_code_grant']
      @team = data['team'] ? Team.new(data['team'], bot) : nil

      @privacy_policy_url = data['privacy_policy_url']
      @terms_of_service_url = data['terms_of_service_url']
      @verify_key = data['verify_key']
      @primary_sku_id = data['primary_sku_id']&.to_i

      @server_install_count = data['approximate_guild_count'] || 0
      @user_install_count = data['approximate_user_install_count'] || 0

      @cover_image_id = data['cover_image']
      @redirect_uris = data['redirect_uris'] || []
      @interactions_endpoint = data['interactions_endpoint_url']

      @role_connections_url = data['role_connections_verification_url']
      @webhook_events_url = data['event_webhooks_url']
      @webhook_events_status = data['event_webhooks_status']
      @webhook_event_types = data['event_webhooks_types'] || []

      @slug = data['slug']
      @tags = data['tags'] || []
      @custom_installation_url = data['custom_install_url']

      if (params = data['install_params'])
        @install_scopes = params['scopes']
        @install_permissions = Permissions.new(params['permissions'])
      end
    end
  end
end
