# frozen_string_literal: true

module Discordrb
  # A user that joined a guild.
  class Member
    include PermissionCalculator

    # Mapping of member flags.
    FLAGS = {
      rejoined: 1 << 0,
      completed_onboarding: 1 << 1,
      bypassed_verification: 1 << 2,
      started_onboarding: 1 << 3,
      guest: 1 << 4,
      started_home_actions: 1 << 5,
      completed_home_actions: 1 << 6,
      automod_quarantined_username: 1 << 7,
      dm_settings_upsell_acknowledged: 1 << 9,
      automod_quarantined_guild_tag: 1 << 10
    }.freeze

    # @return [User] the user the guild member represents.
    attr_reader :user

    # @return [Integer] the member flags for the guild member.
    attr_reader :flags

    # @return [String, nil] the member's guild specific avatar.
    attr_reader :avatar

    # @return [String, nil] the member's guild specific banner.
    attr_reader :banner

    # @return [true, false] whether the member has yet to pass the
    #   member verification requirements.
    attr_reader :pending

    # @return [String, nil] the member's guild specifc display name.
    attr_reader :nickname

    # @return [Time, nil] The time at when the member joined the guild.
    # @note This is only `nil` for "members" that joined via a guest invite.
    attr_reader :joined_at

    # @return [Collectibles] the guild specific avatar-decoration and nameplate
    #   that the member has equipped.
    attr_reader :collectibles

    # @return [Time, nil] the time at when the member starting "boosting" the guild.
    attr_reader :premium_since

    alias_method :pending?, :pending
    alias_method :boosting_since, :premium_since

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @guild_id = @guild&.id || data[:guild_id]&.to_i
      @user = @bot.ensure_user(data[:user], true)
      @flags = data[:flags]
      @avatar = data[:avatar]
      @banner = data[:banner]
      @pending = data[:pending] || false
      @nickname = data[:nick] == '' ? nil : data[:nick]
      @joined_at = Time.iso8601(data[:joined_at]) if data[:joined_at]
      @collectibles = process_collectibles(data)
      @role_ids = data[:roles]&.map(&:to_i) || []
      @premium_since = Time.iso8601(data[:premium_since]) if data[:premium_since]
      timeout_timestamp = data[:communication_disabled_until]
      @timeout_until = Time.iso8601(timeout_timestamp) if timeout_timestamp
      @permissions = Permissions.new(data[:permissions].to_i) if data[:permissions]
      interaction_channel_id = data[:_interaction_channel_id]
      @interaction_channel_id = interaction_channel_id&.to_i if interaction_channel_id
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Get the color of the member.
    # @return [ColourRGB, nil] The color of the member.
    def color
      color_role&.color
    end

    # Check if the member is a booster.
    # @return [true, false] If the member is boosting the guild.
    def premium?
      !@premium_since.nil?
    end

    # Get the display name of the member.
    # @return [String] The member's nickname or the user's name.
    def display_name
      @nickname || @user.display_name
    end

    # Check if the member is the guild owner.
    # @return [true, false] Whether or not the member is the owner.
    def owner?
      @user.resolve_id == guild.owner&.resolve_id
    end

    # Get the guild the member is a part of.
    # @return [Guild] The guild that the member is associated with.
    def guild
      @guild ||= (@bot.guild(@guild_id) if @guild_id)
    end

    # Modify the properties of the member.
    # @param nickname [String, nil] The 1-32 character nickname of the member.
    # @param flags [Integer, nil] The new guild member flags to set for the member.
    # @param roles [Array<Role, Integer, String>, nil] The new roles to set for the member.
    # @param muted [true, false, nil] Whether the member shoule be muted in the voice channel.
    # @param voice_channel [Channel, Integer, String, nil] The voice channel to move the member to.
    # @param deafened [true, false, nil] Whether the member should be deafened in the voice channel.
    # @param timeout_until [Time, nil] The time at when the the member's timeout should expire, or `nil` to clear it.
    # @param avatar [#read, File, nil] The new guild avatar to set for the current bot. Should be a file-like object.
    # @param banner [#read, File, nil] The new guild banner to set for the current bot. Should be a file-like object.
    # @param bio [String, nil] The new 1-300 character guild specific bio to set for the current bot.
    # @param suppressed [true, false] Whether or not the member should be suppressed in the stage channel.
    # @param request_to_speak [true, false] Whether or not the current bot is requesting to speak in the stage channel.
    # @param reason [String, nil] The reason to show in the guild's audit log for modifying the member.
    # @return [nil]
    def modify(
      nickname: :undef, flags: :undef, roles: :undef, muted: :undef, voice_channel: :undef,
      deafened: :undef, timeout_until: :undef, avatar: :undef, banner: :undef, bio: :undef,
      suppressed: :undef, request_to_speak: :undef, reason: nil
    )
      if timeout_until && timeout_until != :undef && timeout_until > (Time.now + 2_419_200)
        raise ArgumentError, 'The timeout duration cannot be greater than 28 days in the future'
      end

      data = {
        nick: nickname,
        roles: roles == :undef ? roles : roles&.map(&:resolve_id),
        mute: muted,
        deaf: deafened,
        channel_id: voice_channel == :undef ? voice_channel : voice_channel&.resolve_id,
        flags: flags,
        communication_disabled_until: timeout_until == :undef ? timeout_until : timeout_until&.iso8601
      }

      if @user.current_bot? && (nickname != :undef || avatar != :undef || banner != :undef || bio != :undef)
        me = {
          bio: bio,
          nick: data.delete(:nick),
          avatar: avatar.respond_to?(:read) ? Discordrb.encode64(avatar) : avatar,
          banner: banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner
        }

        update_data(@bot.http.modify_current_guild_member(@guild_id, **me, reason: reason))
      end

      if suppressed != :undef || request_to_speak != :undef
        unless self.voice_channel&.stage?
          raise ArgumentError, 'The member must be connected to a stage channel'
        end

        stage_data = {
          suppress: suppressed,
          channel_id: self.voice_channel.resolve_id
        }

        if @user.current_bot?
          stage_data[:request_to_speak_timestamp] = if request_to_speak == true
                                                      Time.now.iso8601
                                                    elsif request_to_speak == false
                                                      nil
                                                    else
                                                      :undef
                                                    end

          @bot.http.modify_current_user_voice_state(@guild_id, **stage_data)
        elsif suppressed != :undef
          @bot.http.modify_user_voice_state(@guild_id, @user.id, **stage_data)
        end
      end

      return unless data.any? { |_, value| value != :undef }

      update_data(@bot.http.modify_guild_member(@guild_id, @user.id, **data, reason: reason))
      nil
    end

    alias_method :colour, :color
    alias_method :boosting?, :premium?

    # @!endgroup

    #  ######   #######  ##       ########  ######
    #  ##   ## ##     ## ##       ##       ##
    #  ##   ## ##     ## ##       ##       ##
    #  ######  ##     ## ##       ######    ######
    #  ## ##   ##     ## ##       ##             ##
    #  ##  ##  ##     ## ##       ##             ##
    #  ##   ##  #######  ######## ######## ######

    # @!group Roles

    # Get the roles that the member has.
    # @return [Array<Role>] The roles that the member has.
    def roles
      return @roles if @roles

      process_roles(@role_ids)
    end

    # Check if the member has a specific role.
    # @param role [Role, Integer, String] The role to check.
    # @return [true, false] Whether or not the member has the role.
    def role?(role)
      roles.any?(role.resolve_id)
    end

    # Get the member's highest role.
    # @return [Role] The highest role (by hierarchy) that the member has.
    def top_role
      roles.max
    end

    # Get the role that hoists the member.
    # @return [Role, nil] The role that hoists the member in the member list.
    def hoist_role
      roles.select(&:hoisted?).max
    end

    # Get the role that determines the member's color.
    # @return [Role, nil] The role that determines what the member's color is.
    def color_role
      roles.select { |role| role.color.to_i.nonzero? }.max
    end

    # Add one or more roles to the member.
    # @param roles [Array<Role, Integer, String>, Role, Integer, String] The roles to add.
    # @param atomic [true, false, nil] Whether to add the roles without using the cached roles.
    # @param reason [String, nil] The reason to show in the guild's audit log for adding the roles.
    # @return [nil]
    def add_roles(roles, atomic: nil, reason: nil)
      roles = roles.is_a?(Enumerable) ? roles.map(&:resolve_id) : [roles.resolve_id]

      if atomic == false || (atomic.nil? && roles.length > 1)
        modify(roles: roles.concat(self.roles.map(&:resolve_id)).tap(&:uniq!), reason:)
      else
        roles.each { |id| @bot.http.add_guild_member_role(@guild_id, @user.id, id, reason:) }
      end

      nil
    end

    # Remove one or more roles from the member.
    # @param roles [Array<Role, Integer, String>, Role, Integer, String] The roles to remove.
    # @param atomic [true, false, nil] Whether to remove the roles without using the cached roles.
    # @param reason [String, nil] The reason to show in the guild's audit log for remove the roles.
    # @return [nil]
    def remove_roles(roles, atomic: nil, reason: nil)
      roles = roles.is_a?(Enumerable) ? roles.map(&:resolve_id) : [roles.resolve_id]

      if atomic == false || (atomic.nil? && roles.length > 1)
        modify(roles: self.roles.reject { |role| roles.include?(role.resolve_id) }, reason:)
      else
        roles.each { |id| @bot.http.remove_guild_member_role(@guild_id, @user.id, id, reason:) }
      end

      nil
    end

    alias_method :add_role, :add_roles
    alias_method :highest_role, :top_role
    alias_method :colour_role, :color_role
    alias_method :remove_role, :remove_roles

    # @!endgroup

    #     ###     ######   ######  ######## ########  ######
    #    ## ##   ##    ## ##    ## ##          ##    ##    ##
    #   ##   ##  ##       ##       ##          ##    ##
    #  ##     ##  ######   ######  ######      ##     ######
    #  #########       ##       ## ##          ##          ##
    #  ##     ## ##    ## ##    ## ##          ##    ##    ##
    #  ##     ##  ######   ######  ########    ##     ######

    # @!group Assets

    # Get the avatar that the member is displaying.
    # @return [String] The member's guild avatar if one is set, or their global avatar.
    def display_avatar_url(format: 'webp', size: nil)
      avatar_url(format:, size:) || @user.avatar_url(format:, size:)
    end

    # Get the banner that the member is displaying.
    # @return [String, nil] The member's guild banner if one is set, or their global banner.
    def display_banner_url(format: 'webp', size: nil)
      banner_url(format:, size:) || @user.banner_url(format:, size:)
    end

    # Get the URL to the member's guild avatar.
    # @param format [String] The format of the avatar. Can be one of `webp`, `jpg`, `png`, or `gif`.
    # @param size [Integer, nil] The size of the banner. Can be any real power of two between 0-4096.
    # @return [String, nil] The URL to the member's guild specific avatar, or `nil` if thay have not set one.
    def avatar_url(format: 'webp', size: nil)
      Assets[:guild_member_avatar, @guild_id, @user.id, @avatar, format, size:] if @avatar
    end

    # Get the URL to the member's guild banner.
    # @param format [String] The format of the banner. Can be one of `webp`, `jpg`, `png`, or `gif`.
    # @param size [Integer, nil] The size of the banner. Can be any real power of two between 0-4096.
    # @return [String, nil] The URL to the member's guild specific banner, or `nil` if thay have not set one.
    def banner_url(format: 'webp', size: nil)
      Assets[:guild_member_banner, @guild_id, @user.id, @banner, format, size:] if @banner
    end

    # @!endgroup

    #  ##     ##  #######  ####  ######  ########
    #  ##     ## ##     ##  ##  ##    ## ##
    #  ##     ## ##     ##  ##  ##       ##
    #  ##     ## ##     ##  ##  ##       ######
    #   ##   ##  ##     ##  ##  ##       ##
    #    ## ##   ##     ##  ##  ##    ## ##
    #     ###     #######  ####  ######  ########

    # @!group Voice

    # Check if the member has requested to speak in the stage.
    # @return [true, false] Whether the member requested to speak in the stage.
    def requested_to_speak?
      !requested_to_speak_at.nil?
    end

    # Get the voice or stage channel that the member is connected to.
    # @return [Channel, nil] The voice or stage channel the member is connected to.
    def voice_channel
      guild.voice_states[@user.id]&.channel
    end

    # Get the time at when the member requested to speak in the stage channel.
    # @return [Time, nil] The time at when the member requested to speak in the stage.
    def requested_to_speak_at
      guild.voice_states[@user.id]&.requested_to_speak_at
    end

    # @!method muted?
    #   @return [true, false] whether the member has been muted by the guild.
    # @!method camera?
    #   @return [true, false] whether the member has enabled their camera/webcam.
    # @!method deafened?
    #   @return [true, false] whether the member has been deafened by the guild.
    # @!method streaming?
    #   @return [true, false] whether the member is streaming using "Go Live".
    # @!method suppressed?
    #   @return [true, false] whether the member cannot talk in the stage channel.
    # @!method self_muted?
    #   @return [true, false] whether the member has locally muted themselves.
    # @!method self_deafened?
    #   @return [true, false] whether the member has locally deafened themselves.
    VoiceState::PREDICATES.each do |name|
      define_method(name) { guild.voice_states[@user.id]&.public_send(name) || false }
    end

    # @!endgroup

    #  ######## ##          ###     ######    ######
    #  ##       ##         ## ##   ##    ##  ##    ##
    #  ##       ##        ##   ##  ##        ##
    #  ######   ##       ##     ## ##   ####  ######
    #  ##       ##       ######### ##    ##        ##
    #  ##       ##       ##     ## ##    ##  ##    ##
    #  ##       ######## ##     ##  ######    ######

    # @!group Flags

    # @!method rejoined?
    #   @return [true, false] whether or not the member left the guild and rejoined within 13 days.
    # @!method completed_onboarding?
    #   @return [true, false] whether or not the member has completed the onboarding process.
    # @!method bypassed_verification?
    #   @return [true, false] whether or not the member has bypassed the membership requirements.
    # @!method started_onboarding?
    #   @return [true, false] whether or not the member has started the onboarding process.
    # @!method guest?
    #   @return [true, false] whether or not the member is a guest and can only access one voice channel.
    # @!method started_home_actions?
    #   @return [true, false] whether or not the member has started the new-member tasks in the server guide.
    # @!method completed_home_actions?
    #   @return [true, false] whether or not the member has completed the new-member tasks in the server guide.
    # @!method automod_quarantined_username?
    #   @return [true, false] whether or not the member has been quarantined by AutoMod due to their name.
    # @!method automod_quarantined_guild_tag?
    #   @return [true, false] whether or not the member has been quarantined by AutoMod due to their guild tag.
    # @!method dm_settings_upsell_acknowledged?
    #   @return [true, false] whether or not the member has dismissed the DM settings upsell.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) }
    end

    # @!endgroup

    #  ##     ##  #######  ########  ######## ########     ###    ######## ####  #######  ##    ##
    #  ###   ### ##     ## ##     ## ##       ##     ##   ## ##      ##     ##  ##     ## ###   ##
    #  #### #### ##     ## ##     ## ##       ##     ##  ##   ##     ##     ##  ##     ## ####  ##
    #  ## ### ## ##     ## ##     ## ######   ########  ##     ##    ##     ##  ##     ## ## ## ##
    #  ##     ## ##     ## ##     ## ##       ##   ##   #########    ##     ##  ##     ## ##  ####
    #  ##     ## ##     ## ##     ## ##       ##    ##  ##     ##    ##     ##  ##     ## ##   ###
    #  ##     ##  #######  ########  ######## ##     ## ##     ##    ##    ####  #######  ##    ##

    # @!group Moderation

    # Ban the member from the guild.
    # @return [nil]
    # @see Guild#ban
    def ban(**)
      guild.ban(@user.id, **)
    end

    # Kick the member from the guild.
    # @return [nil]
    # @see Guild#kick
    def kick(**)
      guild.kick(@user.id, **)
    end

    # Unban the member from the guild.
    # @return [nil]
    # @see Guild#unban
    def unban(**)
      guild.unban(@user.id, **)
    end

    # Get the time at when the member's timeout expires.
    # @return [Time, nil] When the member's timeout will expire.
    def timeout_until
      timeout? ? @timeout_until : nil
    end

    # Check if the guild member is in timeout.
    # @return [true, false] Whether or not the member is in timeout.
    def timeout?
      !@timeout_until.nil? && @timeout_until > Time.now
    end

    # Check if the guild member has been quarantined by AutoMod.
    # @return [true, false] Whether or not the member has been quarantined.
    def quarantined?
      automod_quarantined_guild_tag? || automod_quarantined_username?
    end

    # @!endgroup

    #  ##     ##  ######  ######## ########
    #  ##     ## ##    ## ##       ##     ##
    #  ##     ## ##       ##       ##     ##
    #  ##     ##  ######  ######   ########
    #  ##     ##       ## ##       ##   ##
    #  ##     ## ##    ## ##       ##    ##
    #   #######   ######  ######## ##     ##

    # @!group User Methods

    # @!visibility private
    names = %i[
      id
      hash
      dnd?
      idle?
      mention
      online?
      offline?
      resolve_id
      dm_channel
      current_bot?
      bot_account?
      creation_time
      verified_bot?
      webhook_account?
    ]

    # @!visibility private
    def ==(other)
      @user == other
    end

    alias_method :eql?, :==

    # Send a message to the current member in the DM channel.
    # @return [Message] The message that was sent to the current member.
    # @see User#send_message
    def send_message(...)
      @user.send_message(...)
    end

    # @!method id
    #   Get the User ID of the member.
    #   @return [Integer] The user ID of the member.
    #   @see Snowflake#id
    #
    # @!method mention
    #   Get a string that will mention the member.
    #   @return [String] A string that will mention the member.
    #   @see User#mention
    #
    # @!method dm_channel
    #   Get the DM channel between the member and current bot.
    #   @return [Channel] The DM channel between the member and bot.
    #   @see User#dm_channel
    #
    # @!method current_bot?
    #   Check if the member is for the current bot account.
    #   @return [true, false] Whether the member is the current bot.
    #   @see User#current_bot?
    #
    # @!method bot_account?
    #   Check if the member is a bot account for an application.
    #   @return [true, false] Whether or not the member is a bot account.
    #   @see User#bot_account?
    #
    # @!method creation_time
    #   Get the time at when the current member joined Discord.
    #   @return [Time] The time at when the member made their Discord account.
    #   @see Snowflake#creation_time
    #
    # @!method verified_bot?
    #   Check if the member is a bot account that has been verified.
    #   # @return [true, false] Whethero nor the bot account has been verified.
    #   # @see User#verified_bot
    names.each do |name|
      define_method(name) { @user.public_send(name) }
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
    def update_data(new_data)
      process_roles(new_data[:roles]) if new_data[:roles]
      @user&.update_data(new_data[:user]) if new_data[:user]
      @flags = new_data[:flags] if new_data[:flags]
      @nickname = new_data[:nick] if new_data.key?(:nick)
      @avatar = new_data[:avatar] if new_data.key?(:avatar)
      @banner = new_data[:banner] if new_data.key?(:banner)
      @pending = new_data[:pending] if new_data.key?(:pending)

      set_collectibles = new_data.key?(:collectibles)
      set_avatar_decoration = new_data.key?(:avatar_decoration_data)

      if set_collectibles || set_avatar_decoration
        collectibles = if set_collectibles
                         new_data[:collectibles] || {}
                       else
                         @collectibles.to_h
                       end

        avatar_decoration_data = if set_avatar_decoration
                                   new_data[:avatar_decoration_data]
                                 else
                                   collectibles[:avatar_decoration_data]
                                 end

        process_collectibles({ collectibles:, avatar_decoration_data: })
      end

      if new_data.key?(:premium_since)
        premium_timestamp = new_data[:premium_since]
        @premium_since = premium_timestamp ? Time.iso8601(premium_timestamp) : nil
      end

      return unless new_data.key?(:communication_disabled_until)

      timeout_timestamp = new_data[:communication_disabled_until]
      @timeout_until = timeout_timestamp ? Time.iso8601(timeout_timestamp) : nil
    end

    # @!visibility private
    def pop_role(id)
      @roles&.reject! { |role| role.id == id }
      @role_ids&.reject! { |role_id| role_id == id }
    end

    # @!visibility private
    def inspect
      "<Member user_id=#{@user.id} guild_id=#{@guild_id}>"
    end

    private

    # @!visibility private
    def process_roles(role_ids)
      items = role_ids.filter_map { |role| guild.role(role) }

      (items << guild.everyone_role) unless items.include?(@guild_id)

      @roles = items
    end

    # @!visibility private
    def process_collectibles(data)
      items = data[:collectibles] || {}
      items[:avatar_decoration_data] = data[:avatar_decoration_data]
      Collectibles.new(items, @bot)
    end
  end
end
