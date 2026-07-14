# frozen_string_literal: true

module Discordrb
  # Mixin module for user presence.
  module UserPresence
    # @return [Symbol] the current online status of the user.
    #   Can be set to one of (`:online`, `:offline` or `:idle`).
    attr_reader :status

    # @return [ActivitySet] the activities that the user is doing.
    attr_reader :activities

    # @return [Hash<Symbol, Symbol>] the current online status of the user
    #   (`:online`, `:idle` or `:dnd`) of the user on various device types
    #   (`:desktop`, `:mobile`, or `:web`). The value will  be `nil` if the
    #   user is offline or invisible.
    attr_reader :client_status

    # @!method idle?
    #   @return [true, false] whether or not the user is idle.
    # @!method online?
    #   @return [true, false] whether or not the user is online.
    # @!method offline?
    #   @return [true, false] whether or not the user is offline.
    # @!method dnd?
    #   @return [true, false] whether or not the user is on do not disturb.
    %i[idle online offline dnd].each do |name|
      define_method("#{name}?") { @status.to_sym == name }
    end

    # @!visibility private
    def update_presence(data)
      @status = data[:status].to_sym
      @client_status = process_client_status(data[:client_status])

      @activities = ActivitySet.new(data[:activities].map { |item| Activity.new(item, @bot) })
    end
  end

  # An account on Discord.
  class User
    include Snowflake
    include UserPresence

    # Mapping of public flags.
    FLAGS = {
      staff: 1 << 0,
      partner: 1 << 1,
      hypesquad_events: 1 << 2,
      bug_hunter: 1 << 3,
      hypesquad_bravery: 1 << 6,
      hypesquad_brilliance: 1 << 7,
      hypesquad_balance: 1 << 8,
      early_supporter: 1 << 9,
      team_pseudo_user: 1 << 10,
      golden_bug_hunter: 1 << 14,
      verified_bot: 1 << 16,
      early_verified_bot_developer: 1 << 17,
      moderator_programs_alumni: 1 << 18,
      http_interactions: 1 << 19
    }.freeze

    # @return [Integer] the public flags for the user.
    attr_reader :flags

    # @return [String, nil] the CDN hash of the user's avatar.
    attr_reader :avatar

    # @return [String] the user's username, not unique for bots.
    attr_reader :username

    # @return [PrimaryGuild, nil] the guild tag that the user has adopted.
    attr_reader :guild_tag

    # @return [String, nil] the user's non-unique display name.
    attr_reader :global_name

    # @return [true, false] whether or not the user is a bot account.
    attr_reader :bot_account

    # @return [Collectibles] the nameplate and avatar decoration for the user.
    attr_reader :collectibles

    # @return [Integer, nil] the 4-digit tag of the bot account.
    attr_reader :discriminator

    # @return [true, false] whether or not the user is an offical Discord account.
    attr_reader :system_account

    # @return [true, false] whether or not the user is a fake user for a webhook message.
    attr_reader :webhook_account

    alias_method :bot_account?, :bot_account
    alias_method :system_account?, :system_account
    alias_method :webhook_account?, :webhook_account

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data[:id].to_i
      @flags = data[:public_flags] || data[:flags] || 0
      @username = data[:username]
      @avatar = data[:avatar]
      @global_name = data[:global_name]
      @bot_account = data[:bot] || false
      @discriminator = data[:discriminator].to_i if @bot_account
      @system_account = data[:system] || false
      @webhook_account = data[:_webhook] || false
      @collectibles = process_collectibles(data)
      @guild_tag = process_primary_guild(data[:primary_guild])

      @status = :offline
      @activities = Discordrb::ActivitySet.new
      @client_status = process_client_status(data[:client_status])
    end

    # Get the CDN hash of the user's banner.
    # @param bypass_cache [true, false] Whether to ignore the cached banner data and re-fetch it via HTTP.
    # @return [String, nil] The CDN hash of the user's banner, or `nil` if the user doesn't have a banner image set.
    def banner(bypass_cache: true)
      return @banner unless bypass_cache

      @banner = @bot.http.get_user(@id)[:banner]
    end

    # Utility method to get a user's banner URL.
    # @param format [String] The extension to return the URL in. Can be one of `webp`, `jpg`, or `png`.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the user's banner, or `nil` if the user doesn't have a banner set.
    def banner_url(format: 'webp', size: nil)
      asset = banner(bypass_cache: true)

      Assets[:user_banner, asset, format, size:] if asset
    end

    # Utility method to get a user's avatar URL.
    # @param format [String] The extension to return the URL in. Can be one of `webp`, `jpg`, or `png`.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String] The URL to the user's avatar. The URL to the default avatar will be returned if the user doesn't have an avatar set.
    def avatar_url(format: 'webp', size: nil)
      if @avatar
        Assets[:user_avatar, @id, @avatar, format, size:]
      else
        default_hash = if @discriminator
                         @discriminator % 5
                       else
                         (@id.to_i >> 22) % 5
                       end

        Assets[:default_user_avatar, default_hash, 'png']
      end
    end

    # @!method staff?
    #   @return [true, false] whether or not the user is a Discord employee.
    # @!method partner?
    #   @return [true, false] whether or not the user is a partnered guild owner.
    # @!method hypesquad_events?
    #   @return [true, false] whether or not the user has attended a hypesquad event.
    # @!method bug_hunter?
    #   @return [true, false] whether or not the user is a bug hunter (green colour).
    # @!method hypesquad_bravery?
    #   @return [true, false] whether or not the user is in the `bravery` hypesquad house.
    # @!method hypesquad_brilliance?
    #   @return [true, false] whether or not the user is in the `brilliance` hypesquad house.
    # @!method hypesquad_balance?
    #   @return [true, false] whether or not the user is in the `balance` hypesquad house.
    # @!method early_supporter?
    #   @return [true, false] whether or not the user purchased nitro before October 10th, 2018.
    # @!method team_pseudo_user?
    #   @return [true, false] whether or not the user is a developer team.
    # @!method golden_bug_hunter?
    #   @return [true, false] whether or not the user is a bug hunter (golden colour).
    # @!method verified_bot?
    #   @return [true, false] whether or not the user is a bot account that has been verified.
    # @!method early_verified_bot_developer?
    #   @return [true, false] whether or not the user verified a bot they owned before August 2020.
    # @!method moderator_programs_alumni?
    #   @return [true, false] whether or not the user was a part of the moderator community before December 2022.
    # @!method http_interactions?
    #   @return [true, false] whether or not the user is a bot account that only uses HTTP interactions.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
    end

    # Get a string that will mention the user.
    # @return [String] A string that will mention the user.
    def mention
      "<@#{@id}>"
    end

    # Check if the user is the current bot account.
    # @return [true, false] Whether or not the user is the current bot.
    def current_bot?
      @bot.profile == @id
    end

    # Get the private channel between the user and the current bot.
    # @return [Channel] The channel that the current bot can use to DM the user.
    def dm_channel
      @bot.dm_channel(@id)
    end

    # Get the name that's displayed for the user in the Discord client.
    # @return [String] The name that's displayed for the user in the Discord client.
    def display_name
      @global_name || @username
    end

    # Send a direct message to the user. The user must be accepting direct messages
    #   and share a mutual guild with the bot account or have installed the application.
    # @see Channel#send_message!
    def send_message(...)
      dm_channel.send_message(...)
    end

    # Retrieve the member object for the user on a specific guild.
    # @param guild [Integer, String, Guild] The guild where the user should be resolved.
    # @return [Member, nil] The member for the given guild, or `nil` if the user isn't a member.
    def member(guild)
      @bot.member(guild.resolve_id, @id)
    end

    # Add a blocking await for a message from this user. Specifically, this adds am await for
    #   a MessageEvent with this user's ID as a :from attribute.
    # @see Bot#add_await!
    def await!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::MessageEvent, { from: @id }.merge!(attributes), &block)
    end

    # Add an await for a message from this user. Specifically, this adds an await for a MessageEvent
    #   with this user's ID as a :from attribute.
    # @see Bot#add_await
    def await(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::MessageEvent, { from: @id }.merge!(attributes), &block)
    end

    # Modify the properties of the current bot.
    # @param username [String] The new username of the bot.
    # @param avatar [#read, File, nil] The new avatar of the bot, should be a file-like object.
    # @param banner [#read, File, nil] The new banner of the bot, should be a file-like object.
    # @param bio [String, nil] The new bio of the bot. Will only display the first 190 characters when viewed.
    # @raise [Discordrb::Errors::NoPermission] This will happen if you try to modify a user other than the current bot.
    # @return [nil]
    def modify(username: :undef, avatar: :undef, banner: :undef, bio: :undef)
      unless current_bot?
        raise Discordrb::Errors::NoPermission, 'Cannot modify other users'
      end

      data = {
        username: username == :undef ? username : username&.to_s,
        avatar: avatar.respond_to?(:read) ? Discordrb.encode64(avatar) : avatar,
        banner: banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner
      }

      if bio != :undef
        @bot.http.modify_current_application(description: bio)

        return unless data.any? { |_, value| value != :undef }
      end

      update_data(@bot.http.modify_current_user(**data))
      nil
    end

    # @!visibility private
    def update_data(new_data)
      @avatar = new_data[:avatar]
      @username = new_data[:username]
      @global_name = new_data[:global_name]
      @guild_tag = process_primary_guild(new_data[:primary_guild])
      @flags = new_data[:flags] || new_data[:public_flags] || @flags
      @discriminator = new_data[:discriminator]&.to_i if @bot_account

      set_collectibles = new_data.key?(:collectibles)
      set_avatar_decoration = new_data.key?(:avatar_decoration_data)

      return unless set_collectibles || set_avatar_decoration

      collectibles = if set_collectibles
                       new_data[:collectibles] || {}
                     else
                       @collectibles.to_h
                     end

      avatar_decoration_data = if set_avatar_decoration
                                 new_data[:avatar_deocoration_data]
                               else
                                 collectibles[:avatar_decoration_data]
                               end

      process_collectibles({ collectibles:, avatar_decoration_data: })
    end

    # @!visibility private
    def inspect
      "<User id=#{@id} display_name=\"#{display_name}\" flags=#{@flags}>"
    end

    private

    # @!visibility private
    def process_client_status(client_status)
      client_status.to_h { |k, v| [k.to_sym, v.to_sym] }
    end

    # @!visibility private
    def process_collectibles(data)
      items = data[:collectibles] || {}
      items[:avatar_decoration_data] = data[:avatar_decoration_data]
      Collectibles.new(items, @bot)
    end

    # @!visibility private
    def process_primary_guild(identity)
      PrimaryGuild.new(identity, @bot) if identity&.[](:identity_enabled)
    end
  end
end
