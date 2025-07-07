# frozen_string_literal: true

module Discordrb
  # OAuth Application information
  class Application
    include IDObject

    # Map of application flags.
    FLAGS = {
      automod_rule_badge: 1 << 6,
      presence_intent: 1 << 12,
      limited_presence_intent: 1 << 13,
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

    # @return [Array<String>] the application's origins permitted to use RPC.
    attr_reader :rpc_origins

    # @return [Integer] the application's public flags.
    attr_reader :flags

    # @return [User] the user that owns this application.
    attr_reader :owner

    # @return [String, nil] the ID of the application's icon. Can be used to generate an icon URL.
    # @see #icon_url
    attr_reader :icon_id

    # @return [true, false] if users other than the bot owner can add the bot to servers.
    attr_reader :public
    alias_method :public?, :public

    # @return [Profile] the user object of the associated bot for this application.
    attr_reader :bot_profile

    # @return [true, false] whether the bot requires the full OAuth2 code grant in order to join servers.
    attr_reader :requires_code_grant
    alias_method :requires_code_grant?, :requires_code_grant

    # @return [String, nil] the URL to the application's terms of service.
    attr_reader :terms_of_service_url

    # @return [String, nil] the URL to the application's privacy policy.
    attr_reader :privacy_policy_url

    # @return [String] Hex encoded key for verification in interactions and the GameSDK.
    attr_reader :verify_key

    # @return [Team, nil] the team that owns this application, or nil if the application isn't owned by a team.
    attr_reader :team

    # @return [Integer, nil] the ID of the server that is associated with this application.
    attr_reader :server_id

    # @return [String, nil] the ID of the application's default rich presence invite cover image hash.
    #   Can be used to generate a cover image URL.
    # @see #cover_image_url
    attr_reader :cover_image_id

    # @return [Integer] the approximate count of server's the application has been added to.
    attr_reader :approximate_server_count

    # @return [Integer] the approximate count of users that have installed the application with the `application.commands` scope.
    attr_reader :approximate_user_install_count

    # @return [Integer] the approximate count of users that have OAuth2 authorizations for the application.
    attr_reader :approximate_user_authorization_count

    # @return [Array<String>] array of redirect URIs for the application.
    attr_reader :redirect_uris
    alias_method :redirect_urls, :redirect_uris

    # @return [String, nil] the interactions endpoint URL for the application.
    attr_reader :interaction_endpoint_url

    # @return [String, nil] the role connections URL for the application.
    attr_reader :role_connections_verification_url

    # @return [String, nil] the webhook events URL used by the application to receive webhook events.
    attr_reader :webhook_events_url

    # @return [Integer] the status of the application's webhook events.
    attr_reader :webhook_events_status

    # @return [Array<String>] the webhook event types that the application is subscribed to.
    attr_reader :webhook_event_types

    # @return [Array<String>] an array of tags describing the content and functionality of the application.
    attr_reader :tags

    # @return [InstallParams, nil] the settings for the application's default in-app authorization link.
    attr_reader :install_params

    # @return [Hash<Integer => InstallParams>] the default scopes and permissions for each supported installation context.
    attr_reader :integration_types_config

    # @return [String, nil] the default custom authorization URL for the app.
    attr_reader :custom_install_url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      update_data(data)
    end

    # Get the server associated with this application.
    # @return [Server, nil] This will be nil if the bot does not have an associated server set.
    # @raise [Errors::NoPermission] This can happen when the bot is not in the associated server.
    def server
      @bot.server(@server_id) if @server_id
    end

    # Utility method to get a application's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
    # @return [String, nil] the URL of the icon image (nil if no image is set).
    def icon_url(format = 'webp')
      API.app_icon_url(@id, @icon_id, format) if @icon_id
    end

    # Utility method to get a application's cover image URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
    # @return [String, nil] the URL of the icon image (nil if no image is set).
    def cover_image_url(format = 'webp')
      API.app_cover_url(@id, @cover_image_id, format) if @cover_image_id
    end

    # The inspect method is overwritten to give more useful output.
    def inspect
      "<Application name=#{@name} id=#{@id} public=#{@public} owner=#{@owner&.id} server_id=#{@server_id} tags=#{@tags}>"
    end

    # @!method automod_rule_badge?
    #   @return [true, false] if the application has at least 100 automod rules across all of its servers.
    # @!method presence_intent?
    #   @return [true, false] if the application is in less than 100 servers and has access to the server presences intent.
    # @!method limited_presence_intent?
    #   @return [true, false] if the application is in more than 100 servers and has access to the server presences intent.
    # @!method server_members_intent?
    #   @return [true, false] if the application is in more than 100 servers and has access to the server members intent.
    # @!method limited_server_members_intent?
    #   @return [true, false] if the application is in less than 100 servers and has access to the server members intent.
    # @!method pending_server_limit_verification?
    #   @return [true, false] if the application has underwent unusual growth that is preventing it from being verified.
    # @!method embedded?
    #   @return [true, false] if the application is embedded within the Discord client (currently unavailable publicly).
    # @!method message_content_intent?
    #   @return [true, false] if the application is in more than 100 servers and has access to the message content intent.
    # @!method limited_message_content_intent?
    #   @return [true, false] if the application is in less than 100 servers and has access to the message content intent.
    # @!method application_command_badge?
    #   @return [true, false] if the application has registered at least one global application command.
    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    private

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @description = new_data['description']
      @icon_id = new_data['icon']
      @rpc_origins = new_data['rpc_origins']
      @flags = new_data['flags']
      @owner = new_data['owner'] ? @bot.ensure_user(new_data['owner']) : nil

      @public = new_data['bot_public']
      @bot_profile = new_data['bot'] ? Profile.new(new_data['bot'], @bot) : nil
      @requires_code_grant = new_data['bot_require_code_grant']
      @terms_of_service_url = new_data['terms_of_service_url']
      @privacy_policy_url = new_data['privacy_policy_url']
      @verify_key = new_data['verify_key']
      @team = new_data['team'] ? Team.new(new_data['team'], @bot) : nil

      @server_id = new_data['guild_id']&.to_i
      @cover_image_id = new_data['cover_image']
      @approximate_server_count = new_data['approximate_guild_count'] || 0
      @approximate_user_install_count = new_data['approximate_user_install_count'] || 0
      @approximate_user_authorization_count = new_data['approximate_user_authorization_count'] || 0
      @redirect_uris = new_data['redirect_uris'] || []
      @interaction_endpoint_url = new_data['interactions_endpoint_url']

      @role_connections_verification_url = new_data['role_connections_verification_url']
      @webhook_events_url = new_data['event_webhooks_url']
      @webhook_events_status = new_data['event_webhooks_status']
      @webhook_event_types = new_data['event_webhooks_types'] || []
      @tags = new_data['tags'] || []
      @install_params = new_data['install_params'] ? InstallParams.new(new_data['install_params'], @bot, self) : nil
      @custom_install_url = new_data['custom_install_url']

      @integration_types_config = process_integration_types(new_data['integration_types_config'] || {}).compact
    end

    # @!visibility private
    # @note For internal use only.
    def process_integration_types(integration_types)
      integration_types.transform_values do |value|
        InstallParams.new(value, @bot) if value != {}
      end
    end

    # @!visibility private
    def update_application(new_data)
      from_other(JSON.parse(API::Application.update_current_applicaton(@bot.token,
                                                                       new_data[:custom_install_url] || :undef,
                                                                       new_data[:description] || :undef,
                                                                       new_data[:role_connections_verification_url] || :undef,
                                                                       new_data[:install_params] || :undef,
                                                                       new_data[:integration_types_config] || :undef,
                                                                       new_data[:flags] || :undef,
                                                                       new_data[:interactions_endpoint_url] || :undef,
                                                                       new_data[:tags] || :undef,
                                                                       new_data[:webhook_events_url] || :undef,
                                                                       new_data[:webhook_events_status] || :undef,
                                                                       new_data[:webhook_event_types] || :undef,
                                                                       new_data.key?(:icon) ? new_data[:icon] : :undef,
                                                                       new_data.key?(:cover_image) ? new_data[:cover_image] : :undef)))
    end
  end
end
