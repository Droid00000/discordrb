# frozen_string_literal: true

module Discordrb
  # Builder for member search.
  class MemberSearch
    # A re-usable query within a filter.
    class Query
      # Mapping of fields to allowed operations.
      TYPES = {
        user_id: %i[any? <= >=],
        display_name: [:any?],
        roles: %i[any? has?],
        joined_at: %i[<= >=],
        pending: [:==],
        rejoined: [:==],
        join_type: [:any?],
        invite_code: [:any?],
        unusual_dm_activity_until: %i[<= >=],
        communication_disabled_until: %i[<= >=],
        unusual_account_activity: [:==],
        automod_quarantined_username: [:==]
      }.freeze

      # Mapping of join methods to their values.
      JOIN_TYPES = {
        unspecified: 0,
        bot: 1,
        application: 1,
        integration: 2,
        discovery: 3,
        hub: 4,
        invite: 5,
        vanity_url: 6,
        manual_verification: 7,
        linked_lobby: 8
      }.freeze

      # @!visibility private
      def initialize(type)
        @data = {}
        @type = type
        @types = TYPES[type]
      end

      # Compare a boolean value for equality.
      # @param other [true, false] The boolean value to append.
      # @raise [TypeError] If the operation is invalid for the type.
      # @return [void]
      def ==(other)
        raise TypeError, 'Invalid type' unless @types.include?(__method__)

        @data[:boolean_query] = other ? true : false
      end

      # Compare a time-based value for "less-than or equal to".
      # @param other [Time, #resolve_id] The time-based value to compare.
      # @raise [TypeError] If the operation is invalid for the type.
      # @return [void]
      def <=(other)
        raise TypeError, 'Invalid type' unless @types.include?(__method__)

        (@data[:range] ||= {})[:lte] = to_range(other)
      end

      alias_method :lte, :<=

      # Compare a time-based value for "greater-than or equal to".
      # @param other [Time, #resolve_id] The time-based value to compare.
      # @raise [TypeError] If the operation is invalid for the type.
      # @return [void]
      def >=(other)
        raise TypeError, 'Invalid type' unless @types.include?(__method__)

        (@data[:range] ||= {})[:gte] = to_range(other)
      end

      alias_method :gte, :>=

      # Compare a value using "or" logic, aka one of the values must match.
      # @param other [Object, Array, Set] The value(s) to match against using "or" logic.
      # @raise [TypeError] If the operation is invalid for the type.
      # @return [void]
      def any?(*other)
        raise TypeError, 'Invalid type' unless @types.include?(__method__)

        @data[:or_query] = other.flat_map { |key| key.is_a?(Set) ? key.to_a : key }
      end

      alias_method :|, :any?

      # Compare a value using "and" logic, aka all of the values must match.
      # @param other [Object, Array, Set] The value(s) to match against using "and" logic.
      # @raise [TypeError] If the operation is invalid for the type.
      # @return [void]
      def has?(*other)
        raise TypeError, 'Invalid type' unless @types.include?(__method__)

        @data[:and_query] = other.flat_map { |key| key.is_a?(Set) ? key.to_a : key }
      end

      alias_method :has, :has?

      # @!visibility private
      def to_h
        case @type
        when :user_id
          @data[:or_query]&.map!(&:resolve_id)
        when :display_name
          @data[:or_query]&.map!(&:to_s)
        when :roles
          (@data[:or_query] || @data[:and_query])&.map!(&:resolve_id)
        when :join_type
          @data[:or_query]&.map! { |value| resolve_join_type(value) }
        when :invite_code
          @data[:or_query]&.map! { |value| resolve_invite_code(value) }
        end

        @data
      end

      private

      # @!visibility private
      def resolve_join_type(value)
        value = value.to_sym if value.is_a?(String)

        if JOIN_TYPES[value] || JOIN_TYPES.key?(value)
          value.is_a?(Symbol) ? JOIN_TYPES[value] : value
        else
          raise ArgumentError, "Invalid join type: '#{value.inspect}'"
        end
      end

      # @!visibility private
      def resolve_invite_code(value)
        return value.code if value.is_a?(Discordrb::Invite)

        value.start_with?('http', 'discord.gg') ? value[(value.rindex('/') + 1)..] : value
      end

      # @!visibility private
      def to_range(value)
        if @type == :user_id
          return value.is_a?(Time) ? Discordrb::IDObject.synthesise(value) : value.resolve_id
        end

        value = Discordrb::IDObject.decompose(value.resolve_id) if value.respond_to?(:resolve_id)

        return (value.to_f * 1000).to_i if value.is_a?(Time)

        raise ArgumentError, "Invalid value for range filter operator ('>=', '<='): '#{value.inspect}'"
      end
    end

    # A re-usable boolean filter.
    class Filter
      # @!method user_id
      #   Filter by a member's user ID. Allowed operations include:
      #
      #   | {Query#<= <=}                                  | {Query#>= >=}                                     | {Query#any? any?}                        |
      #   |------------------------------------------------|---------------------------------------------------|------------------------------------------|
      #   | Match members with user IDs less than this one | Match members with user IDs greater than this one | Match members with any of these user IDs |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method display_name
      #   Filter by a member's global name, username, or nickname. Allowed operations include:
      #
      #   | {Query#any? any?}                              |
      #   |------------------------------------------------|
      #   | Match members that have any of the these names |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method roles
      #   Filter by the roles a member has. Allowed operations include:
      #
      #   | {Query#any? any?}                          | {Query#has? has?}                          |
      #   |--------------------------------------------|--------------------------------------------|
      #   | Match members that have any of these roles | Match members that have all of these roles |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method joined_at
      #   Filter by when a member joined the server. Allowed operations include:
      #
      #   | {Query#<= <=}                                          | {Query#>= >=}                                                   |
      #   |--------------------------------------------------------|-----------------------------------------------------------------|
      #   | Match members with join timestamps less than this time | Match members with join timestamps greater than this time       |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method pending
      #   Filter by whether or not the member has not yet passed the server's verification requirements. Allowed operations include:
      #
      #   | {Query#== ==}                             |
      #   |-------------------------------------------|
      #   | Match members that are, or aren't pending |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method rejoined
      #   Filter by whether or not the member has left and rejoined the server. Allowed operations include:
      #
      #   | {Query#== ==}                                           |
      #   |---------------------------------------------------------|
      #   | Match members that have or have not rejoined the server |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method join_type
      #   Filter by the method a member used to join the server. Allowed operations include:
      #
      #   | {Query#any? any?}                                      |
      #   |--------------------------------------------------------|
      #   | Match members that joined through any of these methods |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method invite_code
      #   Filter by the invite code a member used to join the server. Allowed operations include:
      #
      #   | {Query#any? any?}                                           |
      #   |-------------------------------------------------------------|
      #   | Match members that joined through any of these invite codes |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method unusual_dm_activity_until
      #   Filter by when a member's unusual DM activity flag will expire. Allowed operations include:
      #
      #   | {Query#<= <=}                                              | {Query#>= >=}                                                   |
      #   |------------------------------------------------------------|-----------------------------------------------------------------|
      #   | Match members with unusual dm activity less than this time | Match members with unusual dm activity greater than this time   |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method communication_disabled_until
      #   Filter by when a member's timeout will expire. Allowed operations include:
      #
      #   | {Query#<= <=}                                          | {Query#>= >=}                                             |
      #   |--------------------------------------------------------|-----------------------------------------------------------|
      #   | Match members with a timeout value less than this time | Match members with a timeout value greater than this time |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method unusual_account_activity
      #   Filter by whether or not the member has the `SPAMMER` flag. Allowed operations include:
      #
      #   | {Query#== ==}                                             |
      #   |-----------------------------------------------------------|
      #   | Match members that have, or don't have the `SPAMMER` flag |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      # @!method automod_quarantined_username
      #   Filter by whether or not the member has been indefinitely quarantined by an AutoMod Rule for their username, display name, or nickname. Allowed operations include:
      #
      #   | {Query#== ==}                                                                     |
      #   |-----------------------------------------------------------------------------------|
      #   | Match members that have, or haven't been quarantined by AutoMod due to their name |
      #
      #   @return [Query] The query representing ephemeral member attributes.
      Query::TYPES.each_key do |key|
        define_method(key) do
          if (value = instance_variable_get(:"@#{key}"))
            value
          else
            instance_variable_set(:"@#{key}", Query.new(key))
          end
        end
      end

      # @!visibility private
      def to_h
        signals = {
          unusual_dm_activity_until: @unusual_dm_activity_until&.to_h,
          communication_disabled_until: @communication_disabled_until&.to_h,
          unusual_account_activity: @unusual_account_activity&.to_h&.[](:boolean_query),
          automod_quarantined_username: @automod_quarantined_username&.to_h&.[](:boolean_query)
        }.compact

        { user_id: @user_id&.to_h,
          usernames: @display_name&.to_h,
          role_ids: @roles&.to_h,
          guild_joined_at: @joined_at&.to_h,
          is_pending: @pending&.to_h&.[](:boolean_query),
          did_rejoin: @rejoined&.to_h&.[](:boolean_query),
          join_source_type: @join_type&.to_h,
          invite_code: @invite_code&.to_h,
          safety_signals: signals.empty? ? nil : signals }.compact
      end

      alias_method :id, :user_id
      alias_method :pending?, :pending
      alias_method :rejoined?, :rejoined
      alias_method :join_types, :join_type
      alias_method :invite_codes, :invite_code
      alias_method :display_names, :display_name
      alias_method :timeout, :communication_disabled_until
      alias_method :unusual_account_activity?, :unusual_account_activity
      alias_method :automod_quarantined_username?, :automod_quarantined_username
    end

    # Entry-point for member search.
    class Base
      # Mapping of sort types to values.
      SORT_TYPES = {
        new_guild_members: 1,
        old_guild_members: 2,
        new_discord_users: 3,
        old_discord_users: 4
      }.freeze

      # Mapping of filter types to names.
      TYPES = {
        or_query: %i[or_logic or_filter or_operator],
        and_query: %i[and_logic and_filter and_operator]
      }.freeze

      TYPES.each_key do |name|
        define_method(name) { block_given? ? filter_using(name) : name }
      end

      alias_method :or_logic, :or_query
      alias_method :or_filter, :or_query
      alias_method :and_logic, :and_query
      alias_method :and_filter, :and_query
      alias_method :or_operator, :or_query
      alias_method :and_operator, :and_query

      # Add a top-level filter to the search query. The inner attributes will be combined using `and` or `or` logic.
      # @param name [String, Symbol] The type of filter to add to the search query.
      # @yieldparam filter [Filter] The filter containing the inner attributes that can be matched.
      # @raise [ArgumentError] If the provided `name:` is not a valid value.
      # @return [void]
      def filter_using(name)
        name = name.to_sym

        if (type = TYPES.find { |key, value| (key == name) || value.any?(name) })
          if type[0] == :or_query
            yield((@__or_query__ ||= Filter.new))
          else
            yield((@__and_query__ ||= Filter.new))
          end
        end

        raise ArgumentError, "Invalid value for the 'name' parameter" unless type
      end

      # @!visibility private
      def to_h
        { or_query: @__or_query__&.to_h, and_query: @__and_query__&.to_h }.compact
      end

      # @!visibility private
      def self.sort_by(value)
        value = value.to_sym if value.is_a?(String)

        if SORT_TYPES[value] || SORT_TYPES.key?(value || 1)
          value.is_a?(Symbol) ? SORT_TYPES[value] : (value || 1)
        else
          raise ArgumentError, "Invalid value for the 'sort_by' parameter"
        end
      end

      # @!visibility private
      def self.cursor(value, server)
        return unless value

        if value.is_a?(Member) && (value.server == server)
          return { user_id: value.id, guild_joined_at: value.joined_at.to_f * 1000 }
        end

        if (value = server.member(value.resolve_id))
          return { user_id: value.id, guild_joined_at: value.joined_at.to_f * 1000 }
        else
          raise ArgumentError, "Invalid value for the 'before' or 'after' parameter"
        end
      end
    end
  end
end
