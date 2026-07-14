# frozen_string_literal: true

module Discordrb
  # Mixin module for caching.
  module Cache
    # @!visibility private
    def reset_cache
      @users = {}
      @guilds = {}
      @channels = {}
      @dm_channels ||= {}
      @default_stickers = {}

      @voice_regions = []
      @sticker_packs = []
      @default_sounds = []
    end

    # ######## ######## ########  ######  ##     ##
    # ##       ##          ##    ##    ## ##     ##
    # ##       ##          ##    ##       ##     ##
    # ######   ######      ##    ##       #########
    # ##       ##          ##    ##       ##     ##
    # ##       ##          ##    ##    ## ##     ##
    # ##       ########    ##     ######  ##     ##

    # @!group Fetch Methods

    # Fetch a user. This will always bypass the cache and make an HTTP request.
    # @param user_id [Integer, String] The ID of the user that should be fetched.
    # @return [User, nil] The user that was fetched, or `nil` if one couldn't be found.
    def fetch_user(user_id)
      user_id = user_id.resolve_id

      begin
        data = @http.get_user(user_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      ensure_user(data, true)
      User.new(data, self)
    end

    # Fetch a guild. This will always bypass the cache and make an HTTP request.
    # @param guild_id [Integer, String] The ID of the guild that should be fetched.
    # @return [Guild, nil] The guild that was fetched, or `nil` if one couldn't be found.
    def fetch_guild(guild_id)
      guild_id = guild_id.resolve_id

      begin
        data = @http.get_guild(guild_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      ensure_guild(data, true)
      Guild.new(data, self)
    end

    # Fetch an invite. This will always make an HTTP request.
    # @param code [String] The code of the invite that should be fetched.
    # @return [Invite, nil] The invite that was fetched, or `nil` if one couldn't be found.
    def fetch_invite(code)
      code = resolve_invite_code(code)

      begin
        data = @http.get_invite(code, with_counts: true)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      Invite.new(data, self)
    end

    # Fetch a sticker. This will always bypass the cache and make an HTTP request.
    # @param sticker_id [Integer, String] The ID of the sticker that should be fetched.
    # @return [Sticker, nil] The sticker that was fetched, or `nil` if one couldn't be found.
    def fetch_sticker(sticker_id)
      sticker_id = sticker_id.resolve_id

      begin
        data = @http.get_sticker(sticker_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      resolved = Sticker.new(data, nil, self)

      if resolved.official?
        @default_stickers[resolved.resolve_id] = resolved
      end

      resolved
    end

    # Fetch a channel. This will always bypass the cache and make an HTTP request.
    # @param channel_id [Integer, String] The ID of the channel that should be fetched.
    # @return [Channel, nil] The channel that was fetched, or `nil` if one couldn't be found.
    def fetch_channel(channel_id)
      channel_id = channel_id.resolve_id

      begin
        data = @http.get_channel(channel_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      ensure_channel(data, nil, false, true)
      Channel.new(data, self)
    end

    # Fetch a DM channel. This will always bypass the cache and make an HTTP request.
    # @param user_id [Integer, String, User, Member] The recipient to retrieve a DM channel for.
    # @return [Channel, nil] The DM channel that was fetched, or `nil` if one couldn't be found.
    def fetch_dm_channel(user_id)
      user_id = user_id.resolve_id

      begin
        data = @http.create_dm_channel(user_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      ensure_channel(data, nil, false, true)
      @dm_channels[user_id] = Channel.new(data, self)
    end

    # Fetch a guild preview. This will always make an HTTP request.
    # @param guild_id [Integer, String] The ID of the guild preview that should be fetched.
    # @return [User, nil] The guild preview that was fetched, or `nil` if one couldn't be found.
    def fetch_guild_preview(guild_id)
      guild_id = guild_id.resolve_id

      begin
        data = @http.get_guild_preview(guild_id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      GuildPreview.new(data, self)
    end

    # Fetch a guild template. This will always make an HTTP request.
    # @param code [String] The code of the guild template that should be fetched.
    # @return [GuildTemplate, nil] The guild template that was fetched, or `nil` if one couldn't be found.
    def fetch_guild_template(code)
      code = resolve_template_code(code)

      begin
        data = @http.get_guild_template(code)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      GuildTemplate.new(data, self)
    end

    # Fetch the voice regions. This will always bypass the cache and make an HTTP request.
    # @return [Array<VoiceRegion>] The voice regions that were fetched.
    def fetch_voice_regions
      data = @http.list_voice_regions

      data.map! { |item| VoiceRegion.new(item) }

      @voice_regions = data
    end

    # Fetch the official sticker packs.. This will always bypass the cache and make an HTTP request.
    # @return [Array<Sticker::Pack>] The official sticker packs that were fetched.
    def fetch_sticker_packs
      data = @http.list_sticker_packs[:sticker_packs]

      data.map! { |item| Sticker::Pack.new(item, self) }

      @sticker_packs = data
    end

    # Fetch the default soundboard sounds. This will always bypass the cache and make an HTTP request.
    # @return [Array<SoundboardSound>] The default soundboard sounds that were fetched.
    def fetch_default_soundboard_sounds
      data = @http.list_default_soundboard_sounds

      data.map! { |item| SoundboardSound.new(item, nil, self) }

      @default_sounds = data
    end

    # Fetch the bot's guilds. This will always bypass the cache and make an HTTP request.
    # @param after [Time, #resolve_id, nil] Get joined guilds starting from after this point.
    # @param before [Time, #resolve_id, nil] Get joined guilds starting from before this point.
    # @param limit [Integer, nil] The maximum number of guilds to return, or `nil` to retrieve
    #   all of the joined guilds. For bots in many guilds, this operation may timeout and fail.
    # @return [Array<JoinedGuild>] A list of joined guilds representing the bot's joined guilds.
    def fetch_guilds(limit: 200, before: nil, after: nil)
      if before && after
        raise ArgumentError, "'before' and 'after' are mutually exclusive"
      end

      options = {
        with_counts: true,
        limit: limit && limit <= 200 ? limit : 200,
        after: after.is_a?(Time) ? Snowflake.synthesise(after) : after&.resolve_id,
        before: before.is_a?(Time) ? Snowflake.synthesise(before) : before&.resolve_id
      }.compact

      get_guilds = lambda do |cursor:|
        data = @http.get_current_user_guilds(**options, after: cursor)
        data.tap { data.map! { |guild| JoinedGuild.new(guild, self) } }
      end

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 200
          []
        else
          get_guilds.call(cursor: last_page&.last&.id || options[:after])
        end
      end

      paginator.to_a
    end

    # @!endgroup

    #   ######      ###      ######   ##     ## ########
    #  ##    ##    ## ##    ##    ##  ##     ## ##
    #  ##         ##   ##   ##        ##     ## ##
    #  ##        ##     ##  ##        ######### ######
    #  ##        #########  ##        ##     ## ##
    #  ##    ##  ##     ##  ##    ##  ##     ## ##
    #   ######   ##     ##   ######   ##     ## ########

    # @!group Cacheable Methods

    # Retrieve the guilds that the bot is a member of.
    # @return [Hash<Integer => Guild>] A mapping of guild IDs to guilds.
    # @raise [Discordrb::Errors::GatewayRequired] If the bot has not connected to the gateway.
    # @raise [Discordrb::Errors::MissingGatewayIntent] If the bot started without the `:guilds` intent.
    def guilds
      unless @gateway.connected?
        raise Discordrb::Errors::GatewayRequired, 'You must connect to the gateway to get guilds'
      end

      if @gateway.intents.nobits?(INTENTS[:guilds])
        raise Discordrb::Errors::MissingGatewayIntent, 'The :guilds intent is required to get guilds'
      end

      @guilds
    end

    # Retrieve an emoji.
    # @param emoji_id [Integer, String] The ID of the emoji that should be retrieved.
    # @return [Emoji, nil] The emoji that was retrieved, or `nil` if one couldn't be found.
    def emoji(emoji_id)
      id = emoji_id.resolve_id

      @guilds.each_value do |guild|
        stored_emoji = guild.emoji(id)

        return stored_emoji if stored_emoji
      end

      nil
    end

    # Retrieve a user.
    # @param user_id [Integer, String] The ID of the user that should be retrieved.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the user if one isn't cached.
    # @return [User, nil] The user that was retrieved, or `nil` if one couldn't be found.
    def user(user_id, fetch: true)
      id = user_id.resolve_id
      cached = @users[id]
      return cached if cached || !fetch

      begin
        data = @http.get_user(id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      resolved = User.new(data, self)
      @users[resolved.resolve_id] = resolved
    end

    # Retrieve a guild.
    # @param guild_id [Integer, String] The ID of the guild that should be retrieved.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the guild if it isn't cached.
    # @return [Guild, nil] The guild that was retrieved, or `nil` if one couldn't be found.
    def guild(guild_id, fetch: true)
      id = guild_id.resolve_id
      cached = @guilds[id]
      return cached if cached || !fetch

      begin
        data = @http.get_guild(id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      resolved = Guild.new(data, self)
      @guilds[resolved.resolve_id] = resolved
    end

    # Retrieve a channel.
    # @param channel_id [Integer, String] The ID of the channel that should be retrieved.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the channel if it isn't cached.
    # @return [Channel, nil] The channel that was retrieved, or `nil` if one couldn't be found.
    def channel(channel_id, fetch: true)
      id = channel_id.resolve_id
      cached = @channels[id]
      return cached if cached || !fetch

      begin
        data = @http.get_channel(id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      resolved = Channel.new(data, self)
      @channels[resolved.resolve_id] = resolved
    end

    # Retrieve a DM channel.
    # @param user_id [Integer, String, User, Member] The recipient to retrieve a DM channel for.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the channel if it isn't cached.
    # @return [Channel, nil] The channel that was retrieved, or `nil` if one couldn't be found.
    def dm_channel(user_id, fetch: true)
      id = user_id.resolve_id
      cached = @dm_channels[id]
      return cached if cached || !fetch

      begin
        data = @http.create_dm_channel(id)
      rescue Discordrb::Errors::NotFound
        return nil
      end

      resolved = Channel.new(data, self)
      @dm_channels[id] = resolved
      @channels[resolved.resolve_id] = resolved
    end

    # Retrieve a sticker.
    # @param sticker_id [Integer, String] The ID of the sticker that should be retrieved.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the sticker if one isn't cached.
    # @return [Sticker, nil] The sticker that was retrieved, or `nil` if one couldn't be found.
    def sticker(sticker_id, fetch: true)
      id = sticker_id.resolve_id
      default_sticker = @default_stickers[id]
      return default_sticker if default_sticker

      @guilds.each_value do |guild|
        cached_sticker = guild.sticker(id)

        return cached_sticker if cached_sticker
      end

      fetch ? fetch_sticker(id) : nil
    end

    # Retrieve the voice regions.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the voice regions if they aren't cached.
    # @return [Array<VoiceRegion>] The voice regions that were retrieved.
    def voice_regions(fetch: true)
      return @voice_regions if @voice_regions.any? || !fetch

      fetch_voice_regions
    end

    # Retrieve the official sticker packs.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the sticker packs if they aren't cached.
    # @return [Array<Sticker::Pack>] The official sticker packs that were retrieved.
    def sticker_packs(fetch: true)
      return @sticker_packs if @sticker_packs.any? || !fetch

      fetch_sticker_packs
    end

    # Retrieve the default soundboard sounds.
    # @param fetch [true, false] Whether to perform an HTTP request to retrieve the soundboard sounds if they aren't cached.
    # @return [Array<SoundboardSound>] The default soundboard sounds that were retrieved.
    def default_soundboard_sounds(fetch: true)
      return @default_sounds if @default_sounds.any? || !fetch

      fetch_default_soundboard_sounds
    end

    # Retrieve an official sticker pack.
    # @param pack_id [Integer, String] The ID of the official sticker pack that should be retrieved.
    # @return [Sticker::Pack, nil] The sticker pack that was retrieved, or `nil` if one couldn't be found.
    def sticker_pack(pack_id)
      id = pack_id.resolve_id

      sticker_packs = sticker_packs(fetch: true)

      sticker_packs.find { |sticker_pack| sticker_pack.id == id }
    end

    # Retrieve a default soundboard sound.
    # @param sound_id [Integer, String] The ID of the default soundboard sound that should be retrieved.
    # @return [SoundboardSound, nil] The soundboard sound that was retrieved, or `nil` if one couldn't be found.
    def default_soundboard_sound(sound_id)
      id = sound_id.resolve_id

      soundboard = fetch default_soundboard_sounds(fetch: true)

      soundboard.find { |soundboard_sound| soundboard_sound.id == id }
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
    # Ensures a given sticker object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a default sticker.
    # @param force_cache [true, false] Whether the object in cache should be updated with the given
    #   data if it already exists.
    # @return [Sticker] the sticker represented by the data hash.
    def ensure_default_sticker(data, force_cache = true)
      id = data[:id].to_i
      if (sticker = @default_stickers[id])
        sticker.from_other(data) if force_cache
        sticker
      else
        @default_stickers[id] = Sticker.new(data, nil, self)
      end
    end

    # @!visibility private
    # Ensures a given user object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a user.
    # @param force_cache [true, false] Whether the object in cache should be updated with the given
    #   data if it already exists.
    # @return [User] the user represented by the data hash.
    def ensure_user(data, force_cache = true)
      id = data[:id].to_i
      if (user = @users[id])
        user.update_data(data) if force_cache
        user
      else
        @users[id] = User.new(data, self)
      end
    end

    # @!visibility private
    # Ensures a given guild object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a guild.
    # @param force_cache [true, false] Whether the object in cache should be updated with the given
    #   data if it already exists.
    # @return [Guild] the guild represented by the data hash.
    def ensure_guild(data, force_cache = false)
      id = data[:id].to_i
      if (guild = @guilds[id])
        guild.update_data(data) if force_cache
        guild
      else
        @guilds[id] = Guild.new(data, self)
      end
    end

    # @!visibility private
    # Ensures a given channel object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a channel.
    # @param guild [Guild, nil] The guild the channel is on, if known.
    # @param interaction [true, false] Whether the channel was sourced from an interaction.
    # @return [Channel] the channel represented by the data hash.
    def ensure_channel(data, guild = nil, interaction = false, force_cache = false)
      id = data[:id].to_i
      if (channel = @channels[id])
        if interaction && channel.obfuscated?
          Channel.new(data, self, guild)
        else
          channel.update_data(data) if force_cache
          channel
        end
      else
        @channels[id] = Channel.new(data, self, guild)
      end
    end

    # @!visibility private
    # Requests member chunks for a given guild ID.
    # @param id [Integer] The guild ID to request chunks for.
    def request_chunks(id)
      id = id.resolve_id

      bucket = (@request_members_rl[id] ||= { mutex: Mutex.new, time: Time.at(0) })

      bucket[:mutex].synchronize do
        last = bucket[:time]
        now = Time.now

        if now < last
          duration = last - now

          LOGGER.info("Preemptively locking REQUEST_GUILD_MEMBERS for #{duration} seconds")
          sleep(duration)
        end

        @gateway.request_guild_members(guild: id, query: '', limit: 0)
        bucket[:time] = (Time.now + 30)
      end
    end

    # @!visibility private
    # Gets the code for an invite.
    # @param invite [String, Invite, VanityInvite] The invite to get the code for. Possible formats are:
    #
    #    * An {Invite} object
    #    * The code for an invite
    #    * A {VanityInvite} object
    #    * A fully qualified invite URL (e.g. `https://discord.com/invite/0A37aN7fasF7n83q`)
    #    * A short invite URL with protocol (e.g. `https://discord.gg/0A37aN7fasF7n83q`)
    #    * A short invite URL without protocol (e.g. `discord.gg/0A37aN7fasF7n83q`)
    # @return [String] Only the code for the invite.
    def resolve_invite_code(invite)
      return invite.code if invite.is_a?(Invite) || invite.is_a?(VanityInvite)

      invite = invite[(invite.rindex('/') + 1)..] if invite.start_with?('http', 'discord.gg')
      invite
    end

    # @!visibility private
    def resolve_template_code(template)
      return template.code if template.is_a?(GuildTemplate)

      template = template[(template.rindex('/') + 1)..] if template.start_with?('https://discord.new/')
      template
    end
  end
end
