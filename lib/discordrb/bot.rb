# frozen_string_literal: true

require 'websocket/driver'
require 'openssl'
require 'socket'
require 'zlib'

require 'discordrb/events/generic'
require 'discordrb/events/message'
require 'discordrb/events/typing'
require 'discordrb/events/lifetime'
require 'discordrb/events/presence'
require 'discordrb/events/voice_state_update'
require 'discordrb/events/channels'
require 'discordrb/events/members'
require 'discordrb/events/roles'
require 'discordrb/events/guilds'
require 'discordrb/events/await'
require 'discordrb/events/bans'
require 'discordrb/events/raw'
require 'discordrb/events/reactions'
require 'discordrb/events/invites'
require 'discordrb/events/interactions'
require 'discordrb/events/threads'
require 'discordrb/events/integrations'
require 'discordrb/events/scheduled_events'
require 'discordrb/events/polls'
require 'discordrb/events/auto_moderation'
require 'discordrb/events/soundboard_sounds'
require 'discordrb/events/stage_instances'
require 'discordrb/events/join_requests'

require 'discordrb/errors'
require 'discordrb/data'
require 'discordrb/await'
require 'discordrb/container'
require 'discordrb/websocket'
require 'discordrb/cache'
require 'discordrb/gateway'
require 'discordrb/http/client'
require 'discordrb/voice/voice_bot'

module Discordrb
  # Represents a Discord bot, including guilds, users, etc.
  class Bot
    include Cache
    include EventContainer

    # The list of currently running threads used to parse and call events.
    #   The threads will have a local variable `:discordrb_name` in the format of `et-1234`, where
    #   "et" stands for "event thread" and the number is a continually incrementing number representing
    #   how many events were executed before.
    # @return [Array<Thread>] The threads.
    attr_reader :event_threads

    # @return [true, false] whether or not the bot should parse its own messages. Off by default.
    attr_accessor :should_parse_self

    # @return [Array(Integer, Integer)] the current shard key
    attr_reader :shard_key

    # @return [Hash<Symbol => Await>] the list of registered {Await}s.
    attr_reader :awaits

    # @return [Hash<Integer => VoiceBot>] a mapping of guild IDs to voice connections.
    attr_reader :voices

    # @return [HTTP::Client] the HTTP client used to make requests to the REST API.
    attr_reader :http

    # The gateway connection is an internal detail that is useless to most people. It is however essential while
    #   debugging or developing discordrb itself, or while writing very custom bots.
    # @return [Gateway] the underlying {Gateway} object.
    attr_reader :gateway

    # @return [String] the bot token used to connect to the {Gateway} and make {#http http} requests.
    attr_reader :token

    # @return [String] the bot token without the `Bot ` prefix.
    attr_reader :raw_token

    # Makes a new bot with the given authentication data. It will be ready to be added event handlers to and can
    # eventually be {#run run}.
    #
    # Simply creating a bot won't be enough to start sending messages etc. with, only a limited set of methods can
    # be used after logging in. If you want to do something when the bot has connected successfully, either do it in the
    # {#ready} event, or use the {#run} method with the `background` parameter and do the processing after that.
    # @param log_mode [Symbol] The mode this bot should use for logging. See {Logger#mode=} for a list of modes.
    # @param token [String] The token that should be used to log in.
    # @param fancy_log [true, false] Whether the output log should be made extra fancy using ANSI escape codes. (Your
    #   terminal may not support this.)
    # @param suppress_ready [true, false] Whether the READY packet should be exempt from being printed to console.
    #   Useful for very large bots running in debug or verbose log_mode.
    # @param parse_self [true, false] Whether the bot should react on its own messages. It's best to turn this off
    #   unless you really need this so you don't inadvertently create infinite loops.
    # @param shard_id [Integer] The number of the shard this bot should handle. See
    #   https://github.com/discord/discord-api-docs/issues/17 for how to do sharding.
    # @param num_shards [Integer] The total number of shards that should be running. See
    #   https://github.com/discord/discord-api-docs/issues/17 for how to do sharding.
    # @param redact_token [true, false] Whether the bot should redact the token in logs. Default is true.
    # @param ignore_bots [true, false] Whether the bot should ignore bot accounts or not. Default is false.
    # @param compression_mode [:none, :large, :stream] Sets which compression mode should be used when connecting
    #   to Discord's gateway. `:none` will request that no payloads are received compressed (not recommended for
    #   production bots). `:large` will request that large payloads are received compressed. `:stream` will request
    #   that all data be received in a continuous compressed stream.
    # @param intents [:all, :unprivileged, Array<Symbol>, :none, Integer] Gateway intents that this bot requires. `:all` will
    #   request all intents. `:unprivileged` will request only intents that are not defined as "Privileged". `:none`
    #   will request no intents. An array of symbols will request only those intents specified. An integer value will request
    #   exactly all the intents specified in the bitwise value.
    # @see Discordrb::INTENTS
    def initialize(
      log_mode: :normal, token: nil, fancy_log: false, suppress_ready: true,
      parse_self: false, shard_id: nil, num_shards: nil, redact_token: true,
      ignore_bots: false, compression_mode: :large, intents: :all
    )
      LOGGER.mode = log_mode
      LOGGER.token = token if redact_token

      @should_parse_self = parse_self

      @shard_key = num_shards ? [shard_id, num_shards] : nil

      LOGGER.fancy = fancy_log
      @prevent_ready = suppress_ready

      raise 'Token string is empty or nil' if token.nil? || token.empty?

      intents = case intents
                when :all
                  ALL_INTENTS
                when :unprivileged
                  UNPRIVILEGED_INTENTS
                when :none
                  NO_INTENTS
                else
                  calculate_intents(intents)
                end

      @raw_token = token.delete_prefix('Bot ')
      @token = "Bot #{@raw_token}"
      @gateway = Gateway.new(self, @shard_key, compression_mode, intents)
      @http = HTTP::Client.new(@token)

      reset_cache

      @voices = {}
      @should_connect_to_voice = {}

      @ignore_bots = ignore_bots

      @event_threads = []
      @current_thread = 0

      @status = :online

      @request_members_rl = {}
      @application_commands = {}
      @queued_application_commands = []
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Creates an OAuth invite URL that can be used to invite the bot to a guild.
    # @param guild [Guild, Integer, String nil] The guild the bot should be invited to, or `nil` if a general invite should be created.
    # @param permission_bits [String, Integer] Permission bits that should be appended to the invite url.
    # @param redirect_uri [String] Redirect URI that should be appended to the invite url.
    # @param scopes [Array<String, Symbol>] The scopes that should be appended to the invite url.
    # @return [String] the OAuth invite URL.
    def invite_url(guild: nil, permission_bits: nil, redirect_uri: nil, scopes: [:bot])
      query = URI.encode_www_form({
        guild_id: guild&.resolve_id,
        permissions: permission_bits,
        redirect_uri: redirect_uri,
        client_id: @client_id ||= application.id,
        scope: scopes&.any? ? scopes.join(' ') : nil
      }.compact)

      "https://discord.com/oauth2/authorize?#{query}"
    end

    # Modify the presence for the bot.
    # @example Change the bot's online indicator to DND.
    #   bot.modify_presence(status: :dnd)
    # @example Change the bot's online indicator to idle.
    #   bot.modify_presence(status: :idle)
    # @example Make the bot say that it is playing Rocket League.
    #   bot.modify_presence(type: :playing, text: "Rocket League")
    # @example Give the bot a custom status that says "I like bees!"
    #   bot.modify_presence(type: :custom_status, text: "I like bees!")
    # @param type [Symbol, Integer] The type of presence to display. See {Activity::TYPES}.
    # @param text [String] The text to display for the presence.
    # @param status [Symbol, String] The current online indicator to set.
    # @return [nil]
    def modify_presence(
      type: :undef, text: :undef, status: :undef
    )
      if type && (type = (Activity::TYPES[type] || type)).nil?
        raise ArgumentError, "Invalid value for the 'type' parameter."
      end

      if status != :undef && %w[online idle dnd invisible].none?(status.to_s)
        raise ArgumentError, "Invalid value for the 'status' parameter."
      end

      presence_data = {
        activities: [],
        status: status == :undef ? @status : status&.to_sym
      }

      (@status = status) if status != :undef

      if type == Activity::TYPES[:streaming]
        url = text
        text = nil
      elsif type == Activity::TYPES[:custom_status]
        state = text
        text = nil
      end

      activity = {
        url: url,
        state: state,
        name: text == :undef ? nil : text,
        type: type == :undef ? nil : type
      }.compact

      unless type.nil?
        if activity.any? { |_, value| value != :undef }
          @activity = activity

          presence_data[:activities] << activity
        elsif activity.all? { |_, value| value == :undef }
          (presence_data[:activities] << @activity) if @activity
        end
      end

      @gateway.modify_presence(afk: false, since: nil, **presence_data)
      nil
    end

    # Get the user account associated with the bot.
    # @return [User] The bot's associated user account.
    def profile
      return self.user(@profile_id) if @profile_id

      me = self.ensure_user(@http.get_current_user)
      me.tap { |current| @profile_id = current.id }
    end

    # Get the application associated with the bot.
    # @return [Application] The bot's associated application.
    def application
      Application.new(@http.get_current_application, self)
    end

    # Get the linked roles records that are associated with the bot.
    # @return [Array<RoleConnectionMetadata>] the role connection records associated with the bot.
    def role_connection_metadata_records
      response = @http.get_application_role_connection_metadata_records(profile.id)
      response.map { |role_connection| RoleConnectionMetadata.new(role_connection, self) }
    end

    # @!endgroup

    #   ######       ###     ########  ########  ##     ##     ###     ##    ##
    #  ##    ##     ## ##       ##     ##        ##     ##    ## ##     ##  ##
    #  ##          ##   ##      ##     ##        ##     ##   ##   ##     ####
    #  ##   ####  ##     ##     ##     ######    ## ### ##  ##     ##     ##
    #  ##    ##   #########     ##     ##        #### ####  #########     ##
    #  ##    ##   ##     ##     ##     ##        ###   ###  ##     ##     ##
    #   ######    ##     ##     ##     ########  ##     ##  ##     ##     ##

    # @!group Gateway

    # Gracefully disconnect the bot from Discord, making it instantly go offline.
    # @return [nil]
    def stop
      @gateway.stop
    end

    # Joins the bot's connection thread with the current thread. This blocks execution
    #   until the websocket stops, which should only happen when manually triggered or
    #   due to an execption being raised. This is needed to have a continuously running bot.
    # @return [nil]
    def join
      @gateway.sync
      nil
    end

    # Make the bot connect to Discord. This will block all further execution unless the
    #  `background:` argument is passed as `true`.
    #
    # @param background [true, false] If this is `true`, then the bot will run in a
    #    seperate thread to allow further execution.  thread to allow further execution.
    #    If it is `false`, this method will block until {#stop} is called. If the bot is run
    #    with `true`, make sure to eventually call {#join} so the script doesn't stop prematurely.
    #
    # @note Running the bot in the background will mean that you can call some methods that require a gateway
    #   connection *before* that connection is established. In most cases an exception will be raised if you try to do
    #   this. If you need a way to safely run code after the bot is fully connected, use a {#ready} event handler instead.
    # @return [nil]
    def run(background: false)
      @gateway.run_async
      return if background

      LOGGER.debug('Oh wait! Not exiting yet as run was run synchronously.')
      @gateway.sync
    end

    alias_method :sync, :join

    # @!endgroup

    #  ######   #######  ##     ## ##     ##    ###    ##    ## ########   ######
    # ##    ## ##     ## ###   ### ###   ###   ## ##   ###   ## ##     ## ##    ##
    # ##       ##     ## #### #### #### ####  ##   ##  ####  ## ##     ## ##
    # ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ## ##     ##  ######
    # ##       ##     ## ##     ## ##     ## ######### ##  #### ##     ##       ##
    # ##    ## ##     ## ##     ## ##     ## ##     ## ##   ### ##     ## ##    ##
    #  ######   #######  ##     ## ##     ## ##     ## ##    ## ########   ######

    # @!group Application Commands

    # Get all of the application commands that the bot has registered.
    # @param guild [Guild, String, Integer, nil] The guild to retrieve commands for.
    #   If this is set to `nil` the global commands for the bot will be retrieved instead.
    # @return [Array<ApplicationCommand>] The application commands that the bot has registered.
    def fetch_application_commands(guild: nil)
      response = if (guild = guild&.resolve_id)
                   @http.get_guild_application_commands(profile.id, guild)
                 else
                   @http.get_global_application_commands(profile.id)
                 end

      response.map { |command| ApplicationCommand.new(command, self) }
    end

    # Retrieve a single application command by its ID.
    # @param command [String, Integer] The ID of the application command to retrieve.
    # @param guild [Guild, String, Integer, nil] The guild to retrieve the command from.
    # @return [ApplicationCommand] The application command for the given ID.
    def fetch_application_command(command, guild: nil)
      response = if (guild = guild&.resolve_id)
                   @http.get_guild_application_command(profile.id, guild, command.resolve_id)
                 else
                   @http.get_global_application_command(profile.id, command.resolve_id)
                 end

      ApplicationCommand.new(response, self)
    end

    # Register a command for the current application.
    # @example
    #   bot.create_application_command(:reddit, 'Reddit Commands') do |command|
    #     command.subcommand_group(:subreddit, 'Subreddit Commands') do |group|
    #       group.subcommand(:hot, "What's trending") do |subcommand|
    #         subcommand.string(:subreddit, 'Subreddit to search')
    #       end
    #
    #       group.subcommand(:new, "What's new") do |subcommand|
    #         subcommand.string(:since, 'How long ago', choices: ['this hour', 'today', 'this week', 'this month', 'this year', 'all time'])
    #         subcommand.string(:subreddit, 'Subreddit to search')
    #       end
    #     end
    #   end
    # @param name [String, Symbol] The 1-32 character name of the command.
    # @param type [Symbol, Integer, nil] The type of application command to create.
    # @param nsfw [true, false, nil] Whether the appplication command should be age-restricted.
    # @param description [String, nil] The 1-100 character description of the chat-input command.
    # @param name_localizations [Hash, #to_h, nil] A mapping of locales to localized command names.
    # @param description_localizations [Hash, #to_h, nil] A mapping of locales to localized command descriptions.
    # @param default_permissions [Permissions, Integer, String, nil] The default permissions required to invoke the command.
    # @param contexts [Array<Symbol, Integer>, nil] The interaction contexts where the command can be invoked from.
    # @param integration_types [Array<Symbol, Integer>, nil] The installation types where the command can be invoked from.
    # @param guild [Guild, Integer, String, nil] The guild where the command should be registed to, or `nil` to create a global command.
    # @param queue [true, false, nil] Whether to avoid instantly registering the command with Discord so it can be {#sync_application_commands synced} later on.
    # @yieldparam builder [OptionBuilder] A builder for application command options, subcommands, and subcommand groups. Only available for chat-input commands.
    # @return [ApplicationCommand, nil] The application command that was upserted, or `nil` if `queue:` argument was set to a value of `true`.
    def create_application_command(
      name, description = nil, name_localizations: nil, description_localizations: nil,
      default_permissions: nil, contexts: nil, integration_types: nil, type: :chat_input,
      nsfw: false, queue: false, guild: nil
    )
      permissions = if default_permissions.respond_to?(:bits)
                      default_permissions.bits
                    elsif default_permissions.is_a?(Enumerable)
                      Permissions.bits(default_permissions)
                    else
                      default_permissions
                    end

      yield((builder = Interactions::OptionBuilder.new)) if block_given?

      data = {
        name: name&.to_s,
        default_permissions: permissions&.to_s,
        description: description == '' ? nil : description,
        name_localizations: name_localizations&.to_h,
        description_localizations: description_localizations&.to_h,
        contexts: contexts&.map { |key| Interaction::CONTEXTS[key] || key },
        integration_types: integration_types&.map { |key| Interaction::INTEGRATION_TYPES[key] || key },
        type: type ? (ApplicationCommand::TYPES[type] || type) : 1,
        nsfw: nsfw || false,
        options: block_given? ? builder.to_a : nil
      }.compact

      if queue && guild
        raise ArgumentError, "The 'queue' and 'guild' arguments are mutually exclusive"
      end

      if data[:options]&.any? && data[:type] != 1
        raise ArgumentError, "'options' can only be provided for `:chat_input` commands"
      end

      if (description.nil? || description == '') && data[:type] != 1
        raise ArgumentError, 'A description must be provided for `:chat_input` commands'
      end

      if guild && (contexts&.any? || integration_types&.any?)
        raise ArgumentError, "'contexts' and 'integration_types' can only be provided for global commands"
      end

      if queue
        @queued_application_commands << data
        return nil
      end

      response = if (guild = guild&.resolve_id)
                   @bot.http.create_guild_application_command(profile.id, guild, **data)
                 else
                   @bot.http.create_global_application_command(profile.id, **data)
                 end

      ApplicationCommand.new(response, self)
    end

    # Modify the properties of an application command.
    # @param command [ApplicationCommand, Integer, String] The command to modify.
    # @param name [String, Symbol] The 1-32 character name of the command.
    # @param nsfw [true, false, nil] Whether the appplication command should be age-restricted.
    # @param description [String, nil] The 1-100 character description of the chat-input command.
    # @param name_localizations [Hash, #to_h, nil] A mapping of locales to localized command names.
    # @param description_localizations [Hash, #to_h, nil] A mapping of locales to localized command descriptions.
    # @param default_permissions [Permissions, Integer, String, nil] The default permissions required to invoke the command.
    # @param contexts [Array<Symbol, Integer>, nil] The interaction contexts where the command can be invoked from.
    # @param integration_types [Array<Symbol, Integer>, nil] The installation types where the command can be invoked from.
    # @param guild [Guild, Integer, String, nil] The guild where the command has been registered, or `nil` if the command is global.
    # @yieldparam builder [OptionBuilder] A builder for application command options, subcommands, and subcommand groups. Only available for chat-input commands.
    # @return [ApplicationCommand] The application command that was modified.
    def modify_application_command(
      command:, name: :undef, description: :undef, name_localizations: :undef, contexts: :undef,
      description_localizations: :undef, default_permissions: :undef, integration_types: :undef,
      nsfw: :undef, guild: nil
    )
      integration = Interaction::INTEGRATION_TYPES

      permissions = if default_permissions.respond_to?(:bits)
                      default_permissions.bits
                    elsif default_permissions.is_a?(Enumerable)
                      Permissions.bits(default_permissions)
                    else
                      default_permissions
                    end

      yield((builder = Interactions::OptionBuilder.new)) if block_given?

      data = {
        name: name,
        default_permissions: permissions == :undef ? :undef : permissions&.to_s,
        description: description == '' ? nil : description,
        name_localizations: name_localizations == :undef ? :undef : name_localizations&.to_h,
        description_localizations: description_localizations == :undef ? :undef : description_localizations&.to_h,
        contexts: contexts == :undef ? :undef : contexts&.map { |key| Interaction::CONTEXTS[key] || key },
        integration_types: integration_types == :undef ? :undef : integration_types&.map { |key| integration[key] || key },
        nsfw: nsfw || false,
        options: block_given? ? builder.to_a : :undef
      }

      response = if (guild = guild&.resolve_id)
                   @bot.http.modify_guild_application_command(profile.id, guild, command.resolve_id, **data)
                 else
                   @bot.http.modify_global_application_command(profile.id, command.resolve_id, **data)
                 end

      command.update_data(response) if command.is_a?(ApplicationCommand)
      ApplicationCommand.new(response, self)
    end

    # Delete an application command.
    # @param command [String, Integer] The ID of the application command to delete.
    # @param guild [Guild, String, Integer, nil] The guild to delete the command from.
    # @return [nil]
    def delete_application_command(command, guild: nil)
      if (guild = guild&.resolve_id)
        @http.delete_guild_application_command(profile.id, guild, command.resolve_id)
      else
        @http.delete_global_application_command(profile.id, command.resolve_id)
      end

      nil
    end

    # Get the permissions for all of the bot's application commands in a specific guild.
    # @param guild [Integer, String, Guild, nil] The guild to fetch the application command permissions for.
    # @return [Array<ApplicationCommand::Permission>] The permissions for all of the application commands in the guild.
    def fetch_application_command_permissions(guild:)
      response = @http.get_guild_application_command_permissions(profile.id, guild.resolve_id)
      response.flat_map { |data| data[:permissions].map { |inner| ApplicationCommand::Permission.new(inner, data, self) } }
    end

    # Sync the queued application commands with Discord.
    # @param guild [Integer, String, Guild, nil] The guild to sync the commands to.
    # @param merge [true, false] Whether to append the queued commands to the ones that
    #   already exist. Setting this to `false` will delete any existing application commands.
    # @return [Array<ApplicationCommand>] The commands that are registered for the application.
    def sync_application_commands(guild: nil, merge: true)
      guild = guild&.resolve_id

      list = if merge
               pending = @queued_application_commands
               current = if guild
                           @http.get_guild_application_commands(profile.id, guild, with_localizations: true)
                         else
                           @http.get_global_application_commands(profile.id, with_localizations: true)
                         end

               current.reject! do |old|
                 type = old[:type]
                 name = old[:name]

                 pending.any? do |command|
                   command[:type] == type && command[:name] == name
                 end
               end

               current.concat(pending)
             else
               @queued_application_commands
             end

      @queued_application_commands = []

      response = if guild
                   @http.bulk_overwrite_guild_application_commands(profile.id, guild, list)
                 else
                   @http.bulk_overwrite_global_application_commands(profile.id, list)
                 end

      response.map! { |app_command| ApplicationCommand.new(app_command, self) } || []
    end

    alias_method :register_application_command, :create_application_command

    # @!endgroup

    #  ######## ##     ##  #######        ## ####  ######
    #  ##       ###   ### ##     ##       ##  ##  ##    ##
    #  ##       #### #### ##     ##       ##  ##  ##
    #  ######   ## ### ## ##     ##       ##  ##   ######
    #  ##       ##     ## ##     ## ##    ##  ##        ##
    #  ##       ##     ## ##     ## ##    ##  ##  ##    ##
    #  ######## ##     ##  #######   ######  ####  ######

    # @!group Application Emojis

    # Get the emojis for the application.
    # @return [Array<Emoji>] The emojis that have been added to the application.
    def fetch_application_emojis
      @http.list_application_emojis(profile.id)[:items].map do |emoji|
        Emoji.new(emoji.tap { |emoji| emoji[:_application] = true }, self, nil)
      end
    end

    # Get a specific emoji for the application.
    # @param emoji [Integer, String, Sound] The ID of the emoji to get.
    # @return [Emoji, nil] The emoji that was identified, or `nil` if there wasn't an emoji with the given ID.
    def fetch_application_emoji(emoji)
      response = @http.get_application_emoji(profile.id, emoji.resolve_id)
      Emoji.new(response.tap { |emoji| emoji[:_application] = true }, self)
    end

    # Create a new emoji.
    # @param name [String] The 2-32 character name of the emoji.
    # @param file [File, #read] A file-like object that responds to `#read`.
    # @return [Emoji] The emoji that was created.
    def create_application_emoji(name:, file:)
      image = file.respond_to?(:read) ? Discordrb.encode64(file) : file

      response = @http.create_application_emoji(profile.id, name:, image:)
      Emoji.new(response.tap { |emoji| emoji[:_application] = true }, self)
    end

    # Modify the properties of an application emoji.
    # @param name [String] The 2-32 character name of the emoji.
    # @return [Emoji] The emoji that was modified.
    def modify_application_emoji(emoji, name:)
      response = @http.modify_application_emoji(profile.id, emoji.resolve_id, name:)
      Emoji.new(response.tap { |emoji| emoji[:_application] = true }, self)
    end

    # Permanently delete an application emoji.
    # @param emoji [Integer, String, Emoji] The emoji to delete.
    # @return [nil]
    def delete_application_emoji(emoji)
      @http.delete_application_emoji(profile.id, emoji.resolve_id)
      nil
    end

    # @!endgroup

    #     ###    ##        ##    ###    #### ########  ######
    #    ## ##   ##        ##   ## ##    ##     ##    ##    ##
    #   ##   ##  ##        ##  ##   ##   ##     ##    ##
    #  ##     ## ##   ##   ## ##     ##  ##     ##     ######
    #  ######### ##  ####  ## #########  ##     ##          ##
    #  ##     ## #### ## #### ##     ##  ##     ##    ##    ##
    #  ##     ##  ##      ##  ##     ## ####    ##     ######

    # @!group Awaits

    # Add an await that the bot should listen to. For information on awaits, see {Await}.
    # @param key [Symbol] The key that uniquely identifies the await for {AwaitEvent}s to listen to (see {#await}).
    # @param type [Class] The event class that should be listened for.
    # @param attributes [Hash] The attributes the event should check for. The block will only be executed if all attributes match.
    # @yield Is executed when the await is triggered.
    # @yieldparam event [Event] The event object that was triggered.
    # @return [Await] The await that was created.
    def add_await(key, type, attributes = {}, &block)
      raise "You can't await an AwaitEvent!" if type == Discordrb::Events::AwaitEvent

      await = Await.new(self, key, type, attributes, block)
      @awaits ||= {}
      @awaits[key] = await
    end

    # Awaits an event, blocking the current thread until a response is received.
    # @param type [Class] The event class that should be listened for.
    # @option attributes [Numeric] :timeout the amount of time (in seconds) to wait for a response before returning `nil`. Waits forever if omitted.
    # @yield Executed when a matching event is received.
    # @yieldparam event [Event] The event object that was triggered.
    # @yieldreturn [true, false] Whether the event matches extra await criteria described by the block.
    # @return [Event, nil] The event object that was triggered, or `nil` if a `timeout` was set and no event was raised in time.
    # @raise [ArgumentError] If the `timeout` attribute was given and was not a positive numeric value.
    def add_await!(type, attributes = {})
      raise "You can't await an AwaitEvent!" if type == Discordrb::Events::AwaitEvent

      timeout = attributes[:timeout]
      raise ArgumentError, 'Timeout must be a number > 0' if timeout.is_a?(Numeric) && !timeout.positive?

      mutex = Mutex.new
      cv = ConditionVariable.new
      response = nil
      block = lambda do |event|
        mutex.synchronize do
          response = event
          if block_given?
            result = yield(event)
            cv.signal if result.is_a?(TrueClass)
          else
            cv.signal
          end
        end
      end

      handler = register_event(type, attributes, block)

      if timeout
        Thread.new do
          sleep timeout
          mutex.synchronize { cv.signal }
        end
      end

      mutex.synchronize { cv.wait(mutex) }

      remove_handler(handler)
      raise 'ConditionVariable was signaled without returning an event!' if response.nil? && timeout.nil?

      response
    end

    # @!endgroup

    #  ##     ## ########  ######   ######     ###     ######   ########  ######
    #  ###   ### ##       ##    ## ##    ##   ## ##   ##    ##  ##       ##    ##
    #  #### #### ##       ##       ##        ##   ##  ##        ##       ##
    #  ## ### ## ######    ######   ######  ##     ## ##   #### ######    ######
    #  ##     ## ##             ##       ## ######### ##    ##  ##             ##
    #  ##     ## ##       ##    ## ##    ## ##     ## ##    ##  ##       ##    ##
    #  ##     ## ########  ######   ######  ##     ##  ######   ########  ######

    # @!group Messages

    # Sends a text message to a channel given its ID and the message's content.
    # @param channel [Channel, String, Integer] The channel, or its ID, to send something to.
    # @param content [String] The text that should be sent as a message. It is limited to 2000 characters (Discord imposed).
    # @param tts [true, false] Whether or not this message should be sent using Discord text-to-speech.
    # @param embeds [Hash, Discordrb::Webhooks::Embed, Array<Hash>, Array<Discordrb::Webhooks::Embed> nil] The rich embed(s) to append to this message.
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, false, nil] Mentions that are allowed to ping on this message. `false` disables all pings
    # @param reference [Message, String, Integer, Hash, nil] The message, or message ID, to reply to if any.
    # @param components [View, Array<Hash>] Interaction components to associate with this message.
    # @param flags [Integer] Flags for this message. Currently only SUPPRESS_EMBEDS (1 << 2), SUPPRESS_NOTIFICATIONS (1 << 12), and IS_COMPONENTS_V2 (1 << 15) can be set.
    # @param nonce [String, nil] A optional nonce in order to verify that a message was sent. Maximum of twenty-five characters.
    # @param enforce_nonce [true, false] Whether the nonce should be enforced and used for message de-duplication.
    # @param poll [Hash, Poll::Builder, Poll, nil] The poll that should be attached to this message.
    # @param stickers [Array<Integer, String, Sticker>, Integer, String, Sticker, nil] The stickers that should be sent with the message.
    # @param client_theme [hash, ClientTheme::Builder, ClientTheme, nil] The client-side theme to share via the message.
    # @return [Message] The message that was sent.
    def send_message(channel, content, tts = false, embeds = nil, attachments = nil, allowed_mentions = nil, reference = nil, components = nil, flags = 0, nonce = nil, enforce_nonce = false, poll = nil, stickers = nil, client_theme = nil)
      components = components&.to_a
      channel_id = channel.resolve_id
      LOGGER.debug("Sending message to #{channel} with content '#{content}'")

      data = {
        content: content == '' ? :undef : (content || :undef),
        tts: tts,
        embeds: embeds && embeds != [] ? [*embeds].map(&:to_h) : :undef,
        files: attachments&.map { |file| file.is_a?(Hash) ? file : { file: file } } || :undef,
        allowed_mentions: allowed_mentions == false ? { parse: [] } : (allowed_mentions || :undef),
        message_reference: reference.respond_to?(:resolve_id) ? { message_id: reference.resolve_id } : (reference || :undef),
        components: components == [] ? :undef : components,
        flags: flags&.zero? ? :undef : (flags || :undef),
        nonce: nonce || :undef,
        enforce_nonce: nonce ? enforce_nonce : :undef,
        poll: poll&.to_h || :undef,
        sticker_ids: stickers && stickers != [] ? [*stickers].map(&:resolve_id) : :undef,
        shared_client_theme: client_theme&.to_h || :undef
      }

      Message.new(@http.create_message(channel_id, **data), self)
    end

    # Sends a text message to a channel given its ID and the message's content, deletes it after the specified timeout in seconds.
    # @param timeout [Integer] The number of seconds after which the message will be deleted.
    # @see #send_message
    def send_temporary_message(timeout, ...)
      message = send_message(...)

      Thread.new do
        Thread.current[:discordrb_name] = "#{@current_thread}-temp-msg"

        sleep(timeout)
        message.delete
      end

      message
    end

    # @!endgroup

    #  ##     ##  #######  ####  ######  ########
    #  ##     ## ##     ##  ##  ##    ## ##
    #  ##     ## ##     ##  ##  ##       ##
    #  ##     ## ##     ##  ##  ##       ######
    #   ##   ##  ##     ##  ##  ##       ##
    #    ## ##   ##     ##  ##  ##    ## ##
    #     ###     #######  ####  ######  ########

    # @!group Voice Connections

    # Gets the voice bot for a particular guild or channel. You can connect to a new channel using the {#voice_connect}
    # method.
    # @param entity [Channel, Guild, Integer] the guild or channel you want to get the voice bot for, or its ID.
    # @return [Voice::VoiceBot, nil] the VoiceBot for the thing you specified, or nil if there is no connection yet.
    def voice(entity)
      id = entity.resolve_id
      return @voices[id] if @voices[id]

      channel = channel(id)
      return nil unless channel

      @voices[channel.guild.id]
    end

    # Connects to a voice channel, initializes network connections and returns the {Voice::VoiceBot} over which audio
    # data can then be sent. After connecting, the bot can also be accessed using {#voice}. If the bot is already
    # connected to voice, the existing connection will be terminated - you don't have to call
    # {Discordrb::Voice::VoiceBot#destroy} before calling this method.
    # @param channel [Channel, String, Integer] The voice channel, or its ID, to connect to.
    # @return [Voice::VoiceBot] the initialized bot over which audio data can then be sent.
    def voice_connect(channel)
      channel = self.channel(channel.resolve_id)
      guild_id = chan.guild.id

      if @voices[channel.id]
        LOGGER.debug('Voice bot exists already! Destroying it')
        @voices[channel.id].destroy
        @voices.delete(channel.id)
      end

      @should_connect_to_voice[guild_id] = channel
      @gateway.modify_voice_state(guild: guild_id, channel: channel.id, mute: false, deaf: false)

      LOGGER.debug('Voice channel init packet sent! Now waiting.')

      sleep(0.02) until @voices[guild_id]
      LOGGER.debug('Voice connect succeeded!')
      @voices[guild_id]
    end

    # Disconnects the client from a specific voice connection given the guild ID. Usually it's more convenient to use
    # {Discordrb::Voice::VoiceBot#destroy} rather than this.
    # @param guild [Guild, String, Integer] The guild, or guild ID, the voice connection is on.
    # @param destroy_vws [true, false] Whether or not the VWS should also be destroyed. If you're calling this method
    #   directly, you should leave it as true.
    def voice_destroy(guild, destroy_vws = true)
      guild = guild.resolve_id
      @gateway.modify_voice_state(guild: guild, channel: nil, mute: false, deaf: false)
      @voices[guild]&.destroy if destroy_vws
      @voices.delete(guild)
    end

    # @!endgroup

    #   ######  ##    ## ##     ##
    #  ##    ## ##   ##  ##     ##
    #  ##       ##  ##   ##     ##
    #   ######  #####    ##     ##
    #        ## ##  ##   ##     ##
    #  ##    ## ##   ##  ##     ##
    #   ######  ##    ##  #######

    # @!group SKUs

    # Get all of the SKUs for the bot.
    # @return [Array<SKU>] All of the SKUs for the bot.
    def skus
      response = @http.list_skus(profile.id)
      response.collect { |data| SKU.new(data, self) }
    end

    # Get a single SKU by its ID.
    # @param sku_id [Integer, String, SKU] The ID of the SKU to get.
    # @return [SKU, nil] The SKU that was identified by its ID, or `nil`.
    def sku(sku_id)
      sku_id = sku_id.resolve_id

      skus.find { |unit| unit.resolve_id == sku_id }
    end

    # @!endgroup

    #  ####  ###   ## ######## ######## ########  ##    ##    ###    ##        ######
    #   ##   ###   ##    ##    ##       ##     ## ###   ##   ## ##   ##       ##    ##
    #   ##   ####  ##    ##    ##       ##     ## ####  ##  ##   ##  ##       ##
    #   ##   ## ## ##    ##    ######   ########  ## ## ## ##     ## ##        ######
    #   ##   ##  ####    ##    ##       ##   ##   ##  #### ######### ##             ##
    #   ##   ##   ###    ##    ##       ##    ##  ##   ### ##     ## ##       ##    ##
    #  ####  ##    ##    ##    ######## ##     ## ##    ## ##     ## ########  ######

    # @!visibility private
    def dispatch(type, data)
      handle_dispatch(type, data)
    end

    # @!visibility private
    # Gets the users, channels, roles and emoji from a string.
    # @param mentions [String] The mentions, which should look like `<@12314873129>`, `<#123456789>`, `<@&123456789>` or `<:name:126328:>`.
    # @param guild [Guild, nil] The guild of the associated mentions (recommended for role parsing, to speed things up).
    # @return [Array<User, Channel, Role, Emoji>] The array of users, channels, roles and emoji identified by the mentions, or `nil` if none exists.
    def parse_mentions(mentions, guild = nil)
      array_to_return = []
      # While possible mentions may be in message
      while mentions.include?('<') && mentions.include?('>')
        # Removing all content before the next possible mention
        mentions = mentions.split('<', 2)[1]
        # Locate the first valid mention enclosed in `<...>`, otherwise advance to the next open `<`
        next unless mentions.split('>', 2).first.length < mentions.split('<', 2).first.length

        # Store the possible mention value to be validated with RegEx
        mention = mentions.split('>', 2).first
        if /@!?(?<id>\d+)/ =~ mention
          array_to_return << self.user(id) unless self.user(id).nil?
        elsif /#(?<id>\d+)/ =~ mention
          array_to_return << self.channel(id, guild) unless self.channel(id, guild).nil?
        elsif /@&(?<id>\d+)/ =~ mention
          if guild
            array_to_return << guild.role(id) unless guild.role(id).nil?
          else
            @guilds.each_value do |element|
              array_to_return << element.role(id) unless element.role(id).nil?
            end
          end
        elsif /(?<animated>^a|^${0}):(?<name>\w+):(?<id>\d+)/ =~ mention
          array_to_return << (emoji(id) || Emoji.new({ id: id, name: name, animated: animated != '' }, self, nil))
        end
      end

      array_to_return
    end

    # @!visibility private
    def inspect
      '<Discordrb::Bot>'
    end

    private

    # Logs a warning if there are guilds which are still unavailable.
    # e.g. due to a Discord outage or because the guilds are large and taking a while to load.
    def unavailable_guilds_check
      # Return unless there are guilds that are unavailable.
      return unless @unavailable_guilds&.positive?

      LOGGER.warn("#{@unavailable_guilds} guilds haven't been cached yet.")
      LOGGER.warn('Guilds may be unavailable due to an outage, or your bot is on very large guilds that are taking a while to load.')
    end

    # Internal handler for PRESENCE_UPDATE
    def update_presence(data)
      # Friends list presences have no guild ID so ignore these to not cause an error
      return unless data[:guild_id]

      user_id = data[:user][:id].to_i
      guild_id = data[:guild_id].to_i
      return unless (guild = self.guild(guild_id))

      if (member = guild.member(user_id, request: false))
        member.user.update_data(data[:user]) if data[:user].any? { |key, _| key != :id }
      else
        # If the member is not cached yet, it means that it just came online from not being cached at all
        # due to large_threshold. Fortunately, Discord sends the entire member object in this case, and
        # not just a part of it - we can just cache this member directly
        member = Member.new(data, guild, self)
        LOGGER.debug("Implicitly adding presence-obtained member #{user_id} to #{guild_id} cache")
        guild.cache_member(member)
      end

      member.user.update_presence(data)
    end

    # Internal handler for VOICE_STATE_UPDATE
    def update_voice_state(data)
      @session_id = data[:session_id]

      guild_id = data[:guild_id].to_i
      guild = self.guild(guild_id)
      return unless guild

      guild&.ensure_member(data[:member]) if data[:member]

      user_id = data[:user_id].to_i
      old_voice_state = guild.voice_states[user_id]
      old_channel_id = old_voice_state&.channel&.id

      guild.update_voice_state(data)

      existing_voice = @voices[guild_id]
      if user_id == profile.id && existing_voice
        new_channel_id = data[:channel_id]
        if new_channel_id
          new_channel = channel(new_channel_id)
          existing_voice.channel = new_channel
        else
          voice_destroy(guild_id)
        end
      end

      old_channel_id
    end

    # Internal handler for VOICE_SERVER_UPDATE
    def update_voice_server(data)
      guild_id = data[:guild_id].to_i
      channel = @should_connect_to_voice[guild_id]

      LOGGER.debug("Voice server update received! chan: #{channel.inspect}")
      return unless channel

      @should_connect_to_voice.delete(guild_id)
      LOGGER.debug('Updating voice server!')

      token = data[:token]
      endpoint = data[:endpoint]

      unless endpoint
        LOGGER.debug('VOICE_SERVER_UPDATE sent with nil endpoint! Ignoring')
        return
      end

      LOGGER.debug('Got data, now creating the bot.')
      @voices[guild_id] = Discordrb::Voice::VoiceBot.new(channel, self, token, @session_id, endpoint)
    end

    # Internal handler for CHANNEL_CREATE
    def create_channel(data)
      channel = Channel.new(data, self)

      # The last message ID of a thread-only channel is the most recent post
      channel.parent.process_last_entity_id(channel.id) if channel.parent&.forum? || channel&.parent&.media?

      # Handle normal and private channels separately
      if (guild = channel.guild)
        guild.cache_channel(channel)
        @channels[channel.id] = channel
      elsif channel.private?
        @dm_channels[channel.recipient.id] = channel
      elsif channel.group?
        @channels[channel.id] = channel
      end
    end

    # Internal handler for CHANNEL_UPDATE
    def update_channel(data)
      id = data[:id].to_i

      if (current = @channels[id])
        current.update_data(data)
      else
        @channels[id] = Channel.new(data, self)
      end
    end

    # Internal handler for CHANNEL_DELETE
    def delete_channel(data)
      guild = @guilds[data[:guild_id].to_i] if data[:guild_id]

      if data[:guild_id]
        id = data[:id].to_i
        @channels.delete(id)
        guild&.delete_channel(id, data[:type])
      else
        @dm_channels.delete(data[:recipients]&.first&.[](:id)&.to_i)
      end
    end

    # Internal handler for GUILD_MEMBER_ADD
    def add_guild_member(data)
      guild = self.guild(data[:guild_id].to_i)

      member = Member.new(data, guild, self)
      guild&.cache_member(member, increment: true)
    end

    # Internal handler for GUILD_MEMBER_UPDATE
    def update_guild_member(data)
      guild_id = data[:guild_id].to_i
      guild = self.guild(guild_id)

      # Only attempt to update members that're already cached
      if (member = guild.member(data[:user][:id].to_i, request: false))
        member.update_data(data)
      else
        self.ensure_user(data[:user])
      end
    end

    # Internal handler for GUILD_CREATE
    def create_guild(data)
      ensure_guild(data, true)
    end

    # Internal handler for GUILD_DELETE
    def delete_guild(data)
      @guilds.delete(data[:id].to_i)
    end

    # Internal handler for GUILD_ROLE_CREATE and GUILD_ROLE_UPDATE
    def update_guild_role(data)
      guild = @guilds[data[:guild_id].to_i]

      if (role = guild&.role(data[:role][:id].to_i))
        role.update_data(data[:role])
      else
        guild&.cache_role(Role.new(data[:role], guild, self))
      end
    end

    # Internal handler for GUILD_SCHEDULED_EVENT_CREATE and GUILD_SCHEDULED_EVENT_UPDATE
    def update_guild_scheduled_event(data)
      guild = @guilds[data[:guild_id].to_i]

      if (event = guild&.scheduled_event(data[:id].to_i, request: false))
        event&.update_data(data)
      else
        guild&.cache_scheduled_event(ScheduledEvent.new(data, guild, self))
      end
    end

    # Internal handler for GUILD_SOUNDBOARD_SOUND_CREATE and GUILD_SOUNDBOARD_SOUND_UPDATE
    def update_soundboard_sound(data)
      guild = @guilds[data[:guild_id].to_i]

      if (sound = guild&.soundboard_sound(data[:sound_id].to_i, request: false))
        sound.update_data(data)
      else
        guild&.cache_soundboard_sound(SoundboardSound.new(data, guild, self))
      end
    end

    # Internal handler for AUTO_MODERATION_RULE_CREATE and AUTO_MODERATION_RULE_UPDATE
    def update_automod_rule(data)
      guild = @guilds[data[:guild_id].to_i]

      if (rule = guild&.automod_rule(data[:id].to_i, request: false))
        rule&.update_data(data)
      else
        guild&.cache_automod_rule(AutoModRule.new(data, guild, self))
      end
    end

    # Internal handler for STAGE_INSTANCE_CREATE and STAGE_INSTANCE_UPDATE
    def update_stage_instance(data)
      channel = @channels[data[:channel_id].to_i]
      instance = channel&.stage_instance(request: false)

      if instance&.id == data[:id].to_i
        instance&.update_data(data)
      else
        channel&.process_stage_instance(StageInstance.new(data, channel, self))
      end
    end

    # @param type [Symbol]
    # @param data [Object]
    def handle_dispatch(type, data)
      # Check whether there are still unavailable guilds and there have been more than 10 seconds since READY
      if @unavailable_guilds&.positive? && (Time.now - @unavailable_timeout_time) > 10 && @gateway&.intents&.anybits?(INTENTS[:guilds])
        # Guild streaming timed out!
        LOGGER.debug("Guild streaming timed out with #{@unavailable_guilds} guilds remaining")
        LOGGER.debug('Calling ready now because guild loading is taking a long time. Guilds may be unavailable due to an outage, or your bot is on very large guilds.')

        # Unset the unavailable guild count so this doesn't get triggered again
        @unavailable_guilds = 0

        notify_ready
      end

      case type
      when :READY
        # As READY may be called multiple times over a single process lifetime, we here need to reset the cache entirely
        # to prevent possible inconsistencies, like objects referencing old versions of other objects which have been
        # replaced.
        reset_cache

        @profile_id = self.ensure_user(data[:user]).resolve_id

        @client_id ||= data[:application][:id]&.to_i

        # Initialize guilds
        @guilds = {}

        if @gateway&.intents&.anybits?(INTENTS[:guilds])
          # Count unavailable guilds
          @unavailable_guilds = data[:guilds].length
        end

        # Don't notify yet if there are unavailable guilds because they need to get available before the bot truly has
        # all the data
        if @unavailable_guilds.zero?
          # No unavailable guilds - we're ready!
          notify_ready
        end

        @ready_time = Time.now
        @unavailable_timeout_time = Time.now
      when :RESUMED
        raise_event(ResumedEvent.new(self))
        LOGGER.out('Resumed')
      when :GUILD_MEMBERS_CHUNK
        id = data[:guild_id].to_i
        self.guild(id)&.process_chunk(data[:members], data[:chunk_index], data[:chunk_count], data[:nonce], data[:not_found], data[:presences])
      when :USER_UPDATE
        updated_user = self.ensure_user(data)
        @profile_id ||= updated_user.resolve_id
      when :INVITE_CREATE
        invite = Invite.new(data, true, self)
        raise_event(InviteCreateEvent.new(data, invite, self))
      when :INVITE_DELETE
        raise_event(InviteDeleteEvent.new(data, self))
      when :MESSAGE_CREATE
        if data[:author][:bot]
          if @ignore_bots
            LOGGER.debug("Ignored bot account (User ID: #{data[:author][:id]}")
            return
          end

          if !should_parse_self && profile.id == data[:author][:id].to_i
            LOGGER.debug('Ignored message from the current bot')
            return
          end
        end

        message = Message.new(data, self)

        if (source_guild = message.guild)
          if (member_data = data[:member])
            member_data[:user] = data[:author]
            source_guild.ensure_member(member_data)
          end

          data[:mentions]&.each do |item|
            next unless (member_item = item[:member])

            member_item[:user] = item
            source_guild.ensure_member(member_item)
          end
        end

        message.channel.process_last_entity_id(message.id)

        event = MessageEvent.new(message, self)
        raise_event(event)

        # Raise a mention event for any direct mentions.
        if message.mentions.any? { |user| user.id == profile.id }
          event = MentionEvent.new(message, self, false)
          raise_event(event)
        end

        bot_role = message.guild&.bot_role

        # Raise a mention event for the current bot's auto-generated role.
        if bot_role && message.role_mentions.any?(bot_role)
          event = MentionEvent.new(message, self, true)
          raise_event(event)
        end

        if message.channel.private?
          event = PrivateMessageEvent.new(message, self)
          raise_event(event)
        end
      when :MESSAGE_UPDATE
        if !should_parse_self && profile.id == data[:author][:id].to_i
          LOGGER.debug('Ignored message from the current bot')
          return
        end

        if @ignore_bots && data[:author][:bot]
          LOGGER.debug("Ignored bot account (User ID: #{data[:author][:id]}")
          return
        end

        message = Message.new(data, self)

        if (source_guild = message.guild)
          if (member_data = data[:member])
            member_data[:user] = data[:author]
            source_guild.ensure_member(member_data)
          end

          data[:mentions]&.each do |item|
            next unless (member_item = item[:member])

            member_item[:user] = item
            source_guild.ensure_member(member_item)
          end
        end

        event = MessageUpdateEvent.new(message, self)
        raise_event(event)
      when :MESSAGE_DELETE
        event = MessageDeleteEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_DELETE_BULK
        LOGGER.debug("MESSAGE_DELETE_BULK will raise #{data[:ids].length} events")

        data[:ids].each do |single_id|
          # Form a data hash for a single ID so the methods get what they want
          single_data = {
            id: single_id,
            channel_id: data[:channel_id]
          }

          event = MessageDeleteEvent.new(single_data, self)
          raise_event(event)
        end
      when :TYPING_START
        event = TypingStartEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_REACTION_ADD
        if data[:member]
          @guilds[data[:guild_id]&.to_i]&.ensure_member(data[:member])
        end

        return if profile.id == data[:user_id].to_i && !should_parse_self

        event = MessageReactionAddEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_REACTION_REMOVE
        return if profile.id == data[:user_id].to_i && !should_parse_self

        event = MessageReactionRemoveEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_REACTION_REMOVE_ALL
        event = MessageReactionRemoveAllEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_REACTION_REMOVE_EMOJI

        event = MessageReactionRemoveEmojiEvent.new(data, self)
        raise_event(event)
      when :PRESENCE_UPDATE
        # Ignore friends list presences
        return unless data[:guild_id]

        new_activities = (data[:activities] || []).map { |act_data| Activity.new(act_data, self) }
        presence_user = @users[data[:user][:id].to_i]
        old_activities = (presence_user&.activities || [])
        update_presence(data)

        # Starting a new game
        playing_change = new_activities.reject do |act|
          old_activities.find { |old| old.name == act.name }
        end

        # Exiting an existing game
        playing_change += old_activities.reject do |old|
          new_activities.find { |act| act.name == old.name }
        end

        if playing_change.any?
          playing_change.each do |act|
            raise_event(PlayingEvent.new(data, act, self))
          end
        else
          raise_event(PresenceEvent.new(data, self))
        end
      when :VOICE_STATE_UPDATE
        old_channel_id = update_voice_state(data)

        event = VoiceStateUpdateEvent.new(data, old_channel_id, self)
        raise_event(event)
      when :VOICE_SERVER_UPDATE
        update_voice_server(data)

        event = VoiceServerUpdateEvent.new(data, self)
        raise_event(event)
      when :CHANNEL_CREATE
        create_channel(data)
        return if data[:flags].to_i.anybits?(Channel::FLAGS[:obfuscated])

        event = ChannelCreateEvent.new(data, self)
        raise_event(event)
      when :CHANNEL_UPDATE
        update_channel(data)
        return if data[:flags].to_i.anybits?(Channel::FLAGS[:obfuscated])

        event = ChannelUpdateEvent.new(data, self)
        raise_event(event)
      when :CHANNEL_DELETE
        delete_channel(data)
        return if data[:flags].to_i.anybits?(Channel::FLAGS[:obfuscated])

        event = ChannelDeleteEvent.new(data, self)
        raise_event(event)
      when :CHANNEL_PINS_UPDATE
        event = ChannelPinsUpdateEvent.new(data, self)

        event.channel.process_last_pin_timestamp(data[:last_pin_timestamp]) if data.key?(:last_pin_timestamp)

        raise_event(event)
      when :GUILD_MEMBER_ADD
        add_guild_member(data)

        event = GuildMemberAddEvent.new(data, self)
        raise_event(event)
      when :GUILD_MEMBER_UPDATE
        update_guild_member(data)

        event = GuildMemberUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_MEMBER_REMOVE
        @guilds[data[:guild_id]&.to_i]&.delete_member(data[:user][:id].to_i)

        event = GuildMemberRemoveEvent.new(data, self)
        raise_event(event)
      when :VOICE_CHANNEL_STATUS_UPDATE
        @channels[data[:id].to_i]&.process_status(data[:status])

        event = VoiceChannelStatusUpdateEvent.new(data, self)
        raise_event(event)
      when :VOICE_CHANNEL_START_TIME_UPDATE
        @channels[data[:id].to_i]&.process_start_time(data[:voice_start_time])

        event = VoiceChannelStartTimeUpdateEvent.new(data, self)
        raise_event(event)
      when :CHANNEL_INFO
        data[:channels].each do |inner|
          next unless (channel = @channels[inner[:id].to_i])

          channel.process_status(inner[:status]) if inner.key?(:status)

          channel.process_start_time(inner[:voice_start_time]) if inner.key?(:voice_start_time)
        end
      when :GUILD_AUDIT_LOG_ENTRY_CREATE
        event = GuildAuditLogEntryCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_BAN_ADD
        event = GuildBanAddEvent.new(data, self)
        raise_event(event)
      when :GUILD_BAN_REMOVE
        event = GuildBanRemoveEvent.new(data, self)
        raise_event(event)
      when :GUILD_ROLE_CREATE
        update_guild_role(data)

        event = GuildRoleCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_ROLE_UPDATE
        update_guild_role(data)

        event = GuildRoleUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_ROLE_DELETE
        @guilds[data[:guild_id].to_i]&.delete_role(data[:role_id].to_i)

        event = GuildRoleDeleteEvent.new(data, self)
        raise_event(event)
      when :INTEGRATION_CREATE
        event = IntegrationCreateEvent.new(data, self)
        raise_event(event)
      when :INTEGRATION_UPDATE
        event = IntegrationUpdateEvent.new(data, self)
        raise_event(event)
      when :INTEGRATION_DELETE
        event = IntegrationDeleteEvent.new(data, self)
        raise_event(event)
      when :GUILD_CREATE
        create_guild(data)

        # Check for false specifically (no data means the guild has never been unavailable)
        if data[:unavailable].is_a? FalseClass
          @unavailable_guilds -= 1 if @unavailable_guilds
          @unavailable_timeout_time = Time.now

          notify_ready if @unavailable_guilds.zero?

          # Return here so the event doesn't get triggered
          return
        end

        event = GuildCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_UPDATE
        @guilds[data[:id].to_i]&.update_data(data)

        event = GuildUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_DELETE
        delete_guild(data)

        if data[:unavailable].is_a? TrueClass
          LOGGER.warn("Guild #{data[:id]} is unavailable due to an outage.")
          return # Don't raise an event
        end

        event = GuildDeleteEvent.new(data, self)
        raise_event(event)
      when :GUILD_EMOJIS_UPDATE
        @guilds[data[:guild_id].to_i]&.__send__(:process_emojis, data[:emojis])

        event = GuildEmojisUpdateEvent.new(data, self)
        raise_event(event)
      when :APPLICATION_COMMAND_PERMISSIONS_UPDATE
        event = ApplicationCommandPermissionsUpdateEvent.new(data, self)

        raise_event(event)
      when :INTERACTION_CREATE
        event = InteractionCreateEvent.new(data, self)
        raise_event(event)

        case data[:type]
        when Interaction::TYPES[:command]
          event = ApplicationCommandEvent.new(data, self)

          Thread.new(event) do |evt|
            Thread.current[:discordrb_name] = "it-#{evt.interaction.id}"

            begin
              LOGGER.debug("Executing application command #{evt.command_name}:#{evt.command_id}")

              @application_commands[evt.command_name]&.call(evt)
            rescue StandardError => e
              LOGGER.log_exception(e)
            end
          end
        when Interaction::TYPES[:component]
          case data[:data][:component_type]
          when Webhooks::View::COMPONENT_TYPES[:button]
            event = ButtonEvent.new(data, self)

            raise_event(event)
          when Webhooks::View::COMPONENT_TYPES[:string_select]
            event = StringSelectEvent.new(data, self)

            raise_event(event)
          when Webhooks::View::COMPONENT_TYPES[:user_select]
            event = UserSelectEvent.new(data, self)

            raise_event(event)
          when Webhooks::View::COMPONENT_TYPES[:role_select]
            event = RoleSelectEvent.new(data, self)

            raise_event(event)
          when Webhooks::View::COMPONENT_TYPES[:mentionable_select]
            event = MentionableSelectEvent.new(data, self)

            raise_event(event)
          when Webhooks::View::COMPONENT_TYPES[:channel_select]
            event = ChannelSelectEvent.new(data, self)

            raise_event(event)
          end
        when Interaction::TYPES[:modal_submit]

          event = ModalSubmitEvent.new(data, self)
          raise_event(event)
        when Interaction::TYPES[:autocomplete]

          event = AutocompleteEvent.new(data, self)
          raise_event(event)
        end
      when :WEBHOOKS_UPDATE
        # This event literally does nothing. Ignore it.
      when :THREAD_CREATE
        create_channel(data)
        return unless data[:newly_created]

        event = ChannelCreateEvent.new(data, self)
        raise_event(event)
      when :THREAD_UPDATE
        update_channel(data)

        event = ChannelUpdateEvent.new(data, self)
        raise_event(event)
      when :THREAD_DELETE
        delete_channel(data)

        event = ChannelDeleteEvent.new(data, self)
        raise_event(event)
      when :THREAD_LIST_SYNC
        guild_id = data[:guild_id].to_i
        guild = @guilds[guild_id]

        # The `channel_ids` field has two meanings:
        #
        # 1. If the field is not present, the thread list is being synced for the whole guild.
        #
        # 2. We are syncing the threads for a specific channel. This can happen when gaining access
        #    to a channel.
        if (ids = data[:channel_ids]&.map(&:to_i))
          @channels.delete_if { |_, channel| channel.thread? && ids.any?(channel.parent&.id) }
          guild&.clear_threads(ids)
        else
          @channels.delete_if { |_, channel| channel.guild.id == guild_id && channel.thread? }
          guild&.clear_threads
        end

        data[:threads].each { |item| ensure_channel(item) }
        data[:members].each { |item| @channels[item[:id].to_i]&.ensure_thread_member(item) }
      when :THREAD_MEMBER_UPDATE
        @channels[data[:id].to_i]&.ensure_thread_member(data)
      when :THREAD_MEMBERS_UPDATE
        channel = self.channel(data[:id].to_i)

        data[:added_members]&.each do |added|
          channel&.ensure_thread_member(added)
          raise_event(ThreadMemberAddEvent.new(added, channel, self))
        end

        data[:removed_member_ids]&.each do |id|
          id = id.to_i
          thread&.pop_thread_member(id)
          raise_event(ThreadMemberRemoveEvent.new(id, channel, self))
        end
      when :GUILD_SOUNDBOARD_SOUND_CREATE
        update_soundboard_sound(data)

        event = SoundboardSoundCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_SOUNDBOARD_SOUND_UPDATE
        update_soundboard_sound(data)

        event = SoundboardSoundUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_SOUNDBOARD_SOUND_DELETE
        @guilds[data[:guild_id].to_i]&.delete_soundboard_sound(data[:sound_id].to_i)

        event = SoundboardSoundDeleteEvent.new(data, self)
        raise_event(event)
      when :VOICE_CHANNEL_EFFECT_SEND
        event = VoiceChannelEffectEvent.new(data, self)
        raise_event(event)
      when :SOUNDBOARD_SOUNDS, :GUILD_SOUNDBOARD_SOUNDS_UPDATE
        @guilds[data[:guild_id].to_i]&.__send__(:process_soundboard_sounds, data[:soundboard_sounds])
      when :AUTO_MODERATION_RULE_CREATE
        update_automod_rule(data)

        event = AutoModRuleCreateEvent.new(data, self)
        raise_event(event)
      when :AUTO_MODERATION_RULE_UPDATE
        update_automod_rule(data)

        event = AutoModRuleUpdateEvent.new(data, self)
        raise_event(event)
      when :AUTO_MODERATION_RULE_DELETE
        @guilds[data[:guild_id].to_i]&.delete_automod_rule(data[:id].to_i)

        event = AutoModRuleDeleteEvent.new(data, self)
        raise_event(event)
      when :AUTO_MODERATION_ACTION_EXECUTION
        event = AutoModActionEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_POLL_VOTE_ADD
        event = PollVoteAddEvent.new(data, self)
        raise_event(event)
      when :MESSAGE_POLL_VOTE_REMOVE
        event = PollVoteRemoveEvent.new(data, self)
        raise_event(event)
      when :STAGE_INSTANCE_CREATE
        update_stage_instance(data)

        event = StageInstanceCreateEvent.new(data, self)
        raise_event(event)
      when :STAGE_INSTANCE_UPDATE
        update_stage_instance(data)

        event = StageInstanceUpdateEvent.new(data, self)
        raise_event(event)
      when :STAGE_INSTANCE_DELETE
        @channels[data[:channel_id].to_i]&.process_stage_instance(nil)

        event = StageInstanceDeleteEvent.new(data, self)
        raise_event(event)
      when :GUILD_SCHEDULED_EVENT_CREATE
        update_guild_scheduled_event(data)

        event = ScheduledEventCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_SCHEDULED_EVENT_UPDATE
        update_guild_scheduled_event(data)

        event = ScheduledEventUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_SCHEDULED_EVENT_DELETE
        @guilds[data[:guild_id].to_i]&.delete_scheduled_event(data[:id].to_i)

        event = ScheduledEventDeleteEvent.new(data, self)
        raise_event(event)
      when :GUILD_SCHEDULED_EVENT_USER_ADD
        guild = @guilds[data[:guild_id].to_i]
        guild&.scheduled_event(data[:guild_scheduled_event_id], request: false)&.increment_user_count

        event = ScheduledEventUserAddEvent.new(data, self)
        raise_event(event)
      when :GUILD_SCHEDULED_EVENT_USER_REMOVE
        guild = @guilds[data[:guild_id].to_i]
        guild&.scheduled_event(data[:guild_scheduled_event_id], request: false)&.deincrement_user_count

        event = ScheduledEventUserRemoveEvent.new(data, self)
        raise_event(event)
      when :GUILD_STICKERS_UPDATE
        @guilds[data[:guild_id].to_i]&.__send__(:process_stickers, data[:stickers])

        event = GuildStickersUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_JOIN_REQUEST_CREATE
        event = GuildJoinRequestCreateEvent.new(data, self)
        raise_event(event)
      when :GUILD_JOIN_REQUEST_UPDATE
        event = GuildJoinRequestUpdateEvent.new(data, self)
        raise_event(event)
      when :GUILD_JOIN_REQUEST_DELETE
        event = GuildJoinRequestDeleteEvent.new(data, self)
        raise_event(event)
      else
        # another event that we don't support yet.
        LOGGER.debug("Event #{type} has been received but is unsupported. Raising UnknownEvent")

        event = UnknownEvent.new(type, data, self)
        raise_event(event)
      end

      # The existence of this array is checked before for performance reasons, since this has to be done for *every*
      # dispatch.
      if @event_handlers && @event_handlers[RawEvent]
        event = RawEvent.new(type, data, self)
        raise_event(event)
      end
    rescue StandardError => e
      LOGGER.error('Gateway message error!')
      LOGGER.log_exception(e)
    end

    # @!visibility private
    def notify_ready
      # Make sure to raise the event
      raise_event(ReadyEvent.new(self))
      LOGGER.good 'Ready'
    end

    # @!visibility private
    def raise_event(event)
      LOGGER.debug("Raised a #{event.class}")
      handle_awaits(event)

      @event_handlers ||= {}
      handlers = @event_handlers[event.class]
      return unless handlers

      handlers.dup.each do |handler|
        call_event(handler, event) if handler.matches?(event)
      end
    end

    # @!visibility private
    def call_event(handler, event)
      t = Thread.new(event) do |evt|
        @event_threads ||= []
        @current_thread ||= 0

        @event_threads << t
        Thread.current[:discordrb_name] = "et-#{@current_thread += 1}"
        begin
          handler.call(evt)
          handler.after_call(evt)
        rescue StandardError => e
          LOGGER.log_exception(e)
        ensure
          @event_threads.delete(t)
        end
      end
    end

    # @!visibility private
    def handle_awaits(event)
      @awaits ||= {}
      @awaits.each_value do |await|
        key, should_delete = await.match(event)
        next unless key

        LOGGER.debug("should_delete: #{should_delete}")
        @awaits.delete(await.key) if should_delete

        await_event = Discordrb::Events::AwaitEvent.new(await, event, self)
        raise_event(await_event)
      end
    end

    # @!visibility private
    def calculate_intents(intents)
      intents = [intents] unless intents.is_a? Array

      intents.reduce(0) do |sum, intent|
        case intent
        when Symbol
          if INTENTS[intent]
            sum | INTENTS[intent]
          else
            LOGGER.warn("Unknown intent: #{intent}")
            sum
          end
        when Integer
          sum | intent
        else
          LOGGER.warn("Invalid intent: #{intent}")
          sum
        end
      end
    end
  end
end
