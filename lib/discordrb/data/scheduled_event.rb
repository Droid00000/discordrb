# frozen_string_literal: true

module Discordrb
  # A scheduled event for an occurrence on a server.
  class ScheduledEvent
    include IDObject

    # Map of status types.
    STATUSES = {
      scheduled: 1,
      active: 2,
      completed: 3,
      canceled: 4
    }.freeze

    # Map of entity types.
    ENTITY_TYPES = {
      stage: 1,
      voice: 2,
      external: 3
    }.freeze

    # @return [String] the name of the scheduled event.
    attr_reader :name

    # @return [Integer] the current status of the scheduled event.
    attr_reader :status

    # @return [Time, nil] the time at when the scheduled event will end.
    attr_reader :end_time

    # @return [String, nil] the external location of the scheduled event.
    attr_reader :location

    # @return [String, nil] the image hash of the scheduled event's cover image.
    attr_reader :cover_id

    # @return [Integer, nil] the ID of the entity associated with the scheduled event.
    attr_reader :entity_id

    # @return [Time] the time at when the scheduled event has been scheduled to start.
    attr_reader :start_time

    # @return [Integer] the type of the entity that is assoicated with the scheduled event.
    attr_reader :entity_type

    # @return [String, nil] the description of the scheduled event. Between 1-1000 characters.
    attr_reader :description

    # @return [RecurrenceRule, nil] the definition for how often this scheduled event should repeat.
    attr_reader :recurrence_rule

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @server_id = data['guild_id']&.to_i
      @user_count = data['user_count']
      @creator_id = data['creator_id']&.to_i
      bot.ensure_user(data['creator']) if data['creator']

      # Set the rest of the mutable attributes in the method.
      update_data(data)
    end

    # Get the exceptions for the scheduled event's recurrence rule.
    # @return [Array<Exception>] The exceptions to the recurrence rule.
    def exceptions
      @exceptions.values
    end

    # Get an exception for the scheduled event's recurrence rule by ID.
    # @param id [#resolve_id, Time, nil] The ID of the exception to get.
    # @return [Exception, nil] The exception for the given ID, or `nil`.
    def exception(id)
      id = if id.is_a?(Time)
             IDObject.synthesise(id)
           else
             id&.resolve_id
           end

      @exceptions[id]
    end

    # Get the server that the scheduled event originates from.
    # @return [Server] The server that the scheduled event originates from.
    def server
      @server ||= @bot.server(@server_id)
    end

    # Get the user who was responsible for the creation of the scheduled event.
    # @return [User, nil] The user who was responsible for the creation of the scheduled event.
    def creator
      @bot.user(@creator_id) if @creator_id
    end

    # Get the channel in which the scheduled event will be hosted. This can be `nil` if the type is external.
    # @return [Channel, nil] The channel where the scheduled event will take place, or `nil` if there isn't one.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # Get a URL that will display an embed in the Discord client containing information about the scheduled event.
    # @return [String] A URL that will display an embed containing a brief overview about the scheduled event's information.
    def url
      "https://discord.com/events/#{@server_id}/#{@id}"
    end

    # Utility method to get a scheduled event's cover image URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
    # @return [String, nil] The URL to the scheduled event's cover image, or `nil` if the scheduled event doesn't have a cover image set.
    def cover_url(format: 'webp', size: 4096)
      API.scheduled_event_cover_url(@id, @cover_id, format, size) if @cover_id
    end

    # @!method scheduled?
    #   @return [true, false] whether the scheduled event has been scheduled to take place.
    # @!method active?
    #   @return [true, false] whether the scheduled event is currently taking place.
    # @!method completed?
    #   @return [true, false] whether the scheduled event has finished taking place.
    # @!method canceled?
    #   @return [true, false] whether the scheduled event has been canceled.
    STATUSES.each do |name, value|
      define_method("#{name}?") do
        @status == value
      end
    end

    alias_method :cancelled?, :canceled?

    # @!method stage?
    #   @return [true, false] whether the scheduled event will take place in a stage channel.
    # @!method voice?
    #   @return [true, false] whether the scheduled event will take place in a voice channel.
    # @!method external?
    #   @return [true, false] whether the scheduled event will take place in an external location.
    ENTITY_TYPES.each do |name, value|
      define_method("#{name}?") do
        @entity_type == value
      end
    end

    # Start the scheduled event.
    # @param reason [String, nil] The reason for starting the event.
    # @return [nil]
    def start(reason: nil)
      raise 'Cannot start this event' unless scheduled?

      modify(status: STATUSES[:active], reason: reason)
    end

    # Cancel the scheduled event. This cannot be undone.
    # @param reason [String, nil] The reason for cancelling the event.
    # @return [nil]
    def cancel(reason: nil)
      raise 'Cannot cancel this event' unless scheduled?

      modify(status: STATUSES[:canceled], reason: reason)
    end

    # End the scheduled event. This cannot be undone.
    # @param reason [String, nil] The reason for ending the event.
    # @return [nil]
    def end(reason: nil)
      raise 'Cannot end this event' unless active?

      modify(status: STATUSES[:completed], reason: reason)
    end

    # Edit the properties of the scheduled event.
    # @param name [String] The new 1-100 character name of the scheduled event.
    # @param channel [Integer, Channel, String, nil] The new channel of the scheduled event.
    # @param location [String, nil] The new location of the scheduled event.
    # @param start_time [Time] The new start time of the scheduled event.
    # @param end_time [Time] The new end time of the scheduled event.
    # @param description [String, nil] The new 1-100 character description of the scheduled event.
    # @param status [Integer, Symbol] The new status of the scheduled event.
    # @param cover [File, #read] The new cover image of the scheduled event.
    # @param entity_type [Integer, Symbol] The new entity type of the scheduled event.
    # @param recurrence_rule [#to_h, nil] The new recurrence rule of the scheduled event.
    # @param reason [String, nil] The audit log reason for modifying the scheduled event.
    # @yieldparam builder [RecurrenceRule::Builder] An optional reccurence rule builder.
    # @return [nil]
    def modify(
      name: :undef, channel: :undef, location: :undef, start_time: :undef,
      end_time: :undef, description: :undef, status: :undef, cover: :undef,
      entity_type: :undef, recurrence_rule: :undef, reason: nil
    )
      data = {
        name: name,
        channel_id: channel == :undef ? channel : channel&.resolve_id,
        entity_metadata: location == :undef ? location : { location: },
        scheduled_end_time: end_time == :undef ? end_time : end_time&.iso8601,
        scheduled_start_time: start_time == :undef ? start_time : start_time&.iso8601,
        description: description,
        entity_type: entity_type == :undef ? entity_type : ENTITY_TYPES[entity_type] || entity_type,
        status: status == :undef ? status : STATUSES[status] || status,
        image: cover.respond_to?(:read) ? Discordrb.encode64(cover) : cover,
        recurrence_rule: recurrence_rule == :undef ? recurrence_rule : recurrence_rule&.to_h,
        reason: reason
      }

      if block_given?
        yield((builder = RecurrenceRule::Builder.new))
        raise 'An `interval` must be provided' unless builder.interval?
        raise 'A `frequency` must be provided' unless builder.frequency?
        raise 'A `start_time` must be provided' unless builder.start_time?

        data[:recurrence_rule] = builder.to_h
      end

      update_data(JSON.parse(API::Server.update_scheduled_event(@bot.token, @server_id, @id, **data)))
      nil
    end

    # Delete the scheduled event. Use this with caution, as it cannot be undone.
    # @param reason [String, nil] The reason to show in the audit log for deleting the scheduled event.
    # @return [nil]
    def delete(reason: nil)
      API::Server.delete_scheduled_event(@bot.token, @server_id, @id, reason: reason)
      @server&.delete_scheduled_event(@id)
      nil
    end

    # Get the total amount of users who are subscribed to the scheduled event.
    # @param request [true, false] Whether to request the user count from Discord if it isn't cached.
    # @return [Integer, nil] The total amount of users who are currently subscribed to the scheduled event.
    def user_count(request: true)
      return @user_count if (@user_count && @bot.gateway.intents.anybits?(INTENTS[:server_scheduled_events])) || (request == false)

      @user_count = JSON.parse(API::Server.get_scheduled_event_user_counts(@bot.token, @server_id, @id))['guild_scheduled_event_count']
    end

    alias_method :subscriber_count, :user_count

    # Get the users who are subscribed to the scheduled event.
    # @param limit [Integer, nil] The limit (`nil` for no limit) of how many subscribers to return.
    # @param member [true, false] Whether to return subscribers as server members, when applicable.
    # @param recurrence [Time, #resolve_id, nil] The specific reccurence to retrieve subscribers for.
    # @return [Array<User, Member>] The users or members that have subscribed to the scheduled event.
    def users(limit: 100, recurrence: nil, member: false)
      get_users = proc do |fetch_limit, after = nil|
        response = if recurrence
                     API::Server.get_scheduled_event_exception_users(@bot.token, @server_id, @id, recurrence, limit: fetch_limit, with_member: member, after: after)
                   else
                     API::Server.get_scheduled_event_users(@bot.token, @server_id, @id, limit: fetch_limit, with_member: member, after: after)
                   end

        JSON.parse(response).map { |data| data['member'] ? Member.new(data['member'], server, @bot).tap { |member| server&.cache_member(member) } : User.new(data['user'], @bot) }
      end

      # Convert the specific recurrence to a snowflake.
      recurrence = recurrence.is_a?(Time) ? IDObject.synthesise(recurrence) : recurrence&.resolve_id

      # Can be done without pagination.
      return get_users.call(limit) if limit && limit <= 100

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_users.call(100, last_page&.last&.id)
        end
      end

      paginator.to_a
    end

    alias_method :subscribers, :users

    # Cancel or re-schedule a specific recurrence for the scheduled event's recurrence rule.
    # @param original_start_time [Time] The original start time of the scheduled event recurrence.
    # @param cancelled [true, false, nil] Whether the scheduled event should be skipped on the recurrence.
    # @param end_time [Time, nil] The new modified time at when the scheduled event recurrence should end.
    # @param start_time [Time, nil] The new modified time at when the scheduled event recurrence should start.
    # @param reason [String, nil] The reason to show in the audit log for creating the scheduled event exception.
    # @note If an exception with the same original start time already exists, this will overwrite the existing one.
    # @return [Exception] The scheduled event exception that was created.
    def create_exception(
      original_start_time:, start_time: nil, end_time: nil, cancelled: nil,
      canceled: nil, reason: nil
    )
      data = {
        reason: reason,
        is_canceled: cancelled || canceled || :undef,
        scheduled_end_time: end_time ? end_time&.iso8601 : :undef,
        original_scheduled_start_time: original_start_time.iso8601,
        scheduled_start_time: start_time ? start_time&.iso8601 : :undef
      }

      response = API::Server.create_scheduled_event_exception(@bot.token, @server_id, @id, **data)
      Exception.new(JSON.parse(response), self, @bot).tap { |exception| cache_exception(exception) }
    end

    # Get a mapping of recurrence IDs to the amount of users who are subscribed to the recurrence.
    # @param ids [Array<#resolve_id, Time>] The IDs of the recurrences to retrieve counts for; between 1-10.
    # @return [Hash<Integer => Integer>] A hash mapping recurrence IDs to their respective subscriber counts.
    def recurrence_user_counts(ids)
      ids = [*ids].map { |value| value.is_a?(Time) ? IDObject.synthesise(value) : value&.resolve_id }
      raise ArgumentError, "The 'ids' parameter must have 1-10 elements" unless ids.length.between?(1, 10)

      response = API::Server.get_scheduled_event_user_counts(@bot.token, @server_id, @id, exception_ids: ids)
      JSON.parse(response)['guild_scheduled_event_exception_counts'].tap { |hash| hash.transform_keys!(&:to_i) }
    end

    alias_method :recurrence_subscriber_counts, :recurrence_user_counts

    # @!visibility private
    def increment_user_count
      @user_count += 1 if @user_count
    end

    # @!visibility private
    def deincrement_user_count
      @user_count -= 1 if @user_count
    end

    # @!visibility private
    def cache_exception(exception)
      @exceptions[exception.id] = exception
    end

    # @!visibility private
    def delete_exception(exception)
      @exceptions.delete(exception.resolve_id)
    end

    # @!visibility private
    def inspect
      "<ScheduledEvent id=#{@id} name=\"#{@name}\" start_time=#{@start_time.inspect} end_time=#{@end_time.inspect}>"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @status = new_data['status']
      @cover_id = new_data['image']
      @entity_type = new_data['entity_type']
      @description = new_data['description']
      @entity_id = new_data['entity_id']&.to_i
      @channel_id = new_data['channel_id']&.to_i
      @start_time = Time.iso8601(new_data['scheduled_start_time'])
      @location = new_data['entity_metadata'] ? new_data['entity_metadata']['location'] : nil
      @end_time = new_data['scheduled_end_time'] ? Time.iso8601(new_data['scheduled_end_time']) : nil
      @recurrence_rule = new_data['recurrence_rule'] ? RecurrenceRule.new(new_data['recurrence_rule'], @bot) : nil
      @exceptions = (new_data['guild_scheduled_event_exceptions'] || []).to_h do |scheduled_event_exception|
        [scheduled_event_exception['event_exception_id'].to_i, Exception.new(scheduled_event_exception, self, @bot)]
      end
    end

    # Represents how frequently a scheduled event will repeat.
    class RecurrenceRule
      # Map of weekdays.
      WEEKDAYS = {
        monday: 0,
        tuesday: 1,
        wednesday: 2,
        thursday: 3,
        friday: 4,
        saturday: 5,
        sunday: 6
      }.freeze

      # Map of frequencies.
      FREQUENCIES = {
        yearly: 0,
        monthly: 1,
        weekly: 2,
        daily: 3
      }.freeze

      # Map of months.
      MONTHS = {
        january: 1,
        february: 2,
        march: 3,
        april: 4,
        may: 5,
        june: 6,
        july: 7,
        august: 8,
        september: 9,
        october: 10,
        november: 11,
        december: 12
      }.freeze

      # @return [Integer, nil] the amount of times that the event can recur before stopping.
      attr_reader :count

      # @return [Array<Integer>] the specific months the event can recur on.
      attr_reader :by_month

      # @return [Time, nil] the time at when the reccurence interval will end.
      attr_reader :end_time

      # @return [Time] the time at when the reccurence interval will start.
      attr_reader :start_time

      # @return [Array<Integer>] the specific days of the week the event can recur on.
      attr_reader :by_weekday

      # @return [Integer] The spacing between the events, defined by the frequency.
      attr_reader :interval

      # @return [Integer] how often the reccurence interval will occur, e.g. yearly, monthly, etc.
      attr_reader :frequency

      # @return [Array<Integer>] the specific days within the year (1-364) to recur on.
      attr_reader :by_year_day

      # @return [Array<WeeklyDay>] the specific days within a specific week to recur on.
      attr_reader :by_n_weekday

      # @return [Array<Integer>] the specific dates within a month to recur on.
      attr_reader :by_month_day

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @count = data['count']
        @by_month = data['by_month'] || []
        @end_time = Time.iso8601(data['end']) if data['end']
        @start_time = Time.iso8601(data['start']) if data['start']
        @by_weekday = data['by_weekday'] || []
        @interval = data['interval']
        @frequency = data['frequency']
        @by_year_day = data['by_year_day'] || []
        @by_n_weekday = data['by_n_weekday']&.map { |day| WeeklyDay.new(day, @bot) } || []
        @by_month_day = data['by_month_day'] || []
      end

      # @!method yearly?
      #   @return [true, false] whether the event repeat on a yearly basis.
      # @!method monthly?
      #   @return [true, false] whether the event repeat on a monthly basis.
      # @!method weekly?
      #   @return [true, false] whether the event repeat on a weekly basis.
      # @!method daily?
      #   @return [true, false] whether the event repeat on a daily basis.
      FREQUENCIES.each do |name, value|
        define_method("#{name}?") do
          @frequency == value
        end
      end

      # Convert the recurrence rule into an RFC-5545 string.
      # @param start_time [true, false] Whether to include the `DTSTART` value in the string.
      # @return [String] An RFC-5545 compliant string that can represent the recurrence rule.
      def to_s(start_time: false)
        parts = []
        parts << "FREQ=#{FREQUENCIES.key(@frequency).upcase}"
        parts << "COUNT=#{@count}" if @count
        parts << "INTERVAL=#{@interval}" if @interval
        parts << "BYMONTH=#{@by_month.join(',')}" if @by_month.any?
        parts << "BYYEARDAY=#{@by_year_day.join(',')}" if @by_year_day.any?
        parts << "BYMONTHDAY=#{@by_month_day.join(',')}" if @by_month_day.any?
        parts << "UNTIL=#{@end_time.utc.strftime('%Y%m%dT%H%M%SZ')}" if @end_time

        if @by_n_weekday.any? || @by_weekday.any?
          list = @by_n_weekday.map { |n| "+#{n.week}#{WEEKDAYS.key(n.day)[..1].upcase}" }
          @by_weekday.each { |weekday| list << WEEKDAYS.key(weekday)[..1].upcase }
          parts << "BYDAY=#{list.join(',')}"
        end

        return "RRULE:#{parts.join(';')}" unless start_time

        "DTSTART:#{@start_time.utc.strftime('%Y%m%dT%H%M%SZ')}\nRRULE:#{parts.join(';')}"
      end

      # @!visibility private
      def inspect
        "<RecurrenceRule interval=#{@interval} frequency=#{@frequency}>"
      end

      # @!visibility private
      def to_h
        {
          count: @count,
          interval: @interval,
          frequency: @frequency,
          end: @end_time&.iso8601,
          start: @start_time&.iso8601,
          by_month: @by_month.any? ? @by_month : nil,
          by_weekday: @by_weekday.any? ? @by_weekday : nil,
          by_year_day: @by_year_day.any? ? @by_year_day : nil,
          by_month_day: @by_month_day.any? ? @by_month_day : nil,
          by_n_weekday: @by_n_weekday.any? ? @by_n_weekday.map(&:to_h) : nil
        }
      end

      # The specific day within a specific week to recur on.
      class WeeklyDay
        # @return [Integer] the day (0-6) of the week to recur on.
        attr_reader :day

        # @return [Integer] the week (1-5) to recur on in the month.
        attr_reader :week

        # @!visibility private
        def initialize(data, bot)
          @bot = bot
          @week = data['n']
          @day = data['day']
        end

        # @!visibility private
        def to_h
          { n: @week, day: @day }
        end

        # @!method monday?
        #   @return [true, false] whether the day within the week is a monday.
        # @!method tuesday?
        #   @return [true, false] whether the day within the week is a tuesday.
        # @!method wednesday?
        #   @return [true, false] whether the day within the week is a wednesday.
        # @!method thursday?
        #   @return [true, false] whether the day within the week is a thursday.
        # @!method friday?
        #   @return [true, false] whether the day within the week is a friday.
        # @!method saturday?
        #   @return [true, false] whether the day within the week is a saturday.
        # @!method sunday?
        #   @return [true, false] whether the day within the week is a sunday.
        WEEKDAYS.each do |name, value|
          define_method("#{name}?") do
            @day == value
          end
        end
      end

      # Builder for the reccurence rule.
      class Builder
        # @overload interval=(value)
        #   @param value [Integer] the spacing between the events, defined by the frequency.
        #   @return [void]
        attr_writer :interval

        # @overload frequency=(value)
        #   @param value [Integer, String] how frequently the scheduled event should occur.
        #   @return [void]
        attr_writer :frequency

        # @overload start_time=(value)
        #   @param value [Time, #iso8601] the time at when the reccurence interval will begin.
        #   @return [void]
        attr_writer :start_time

        # Set the the specific days within the month to recur on.
        # @param monthly_days [Array<Integer>] The speific days within
        #   the month to recur on.
        # @return [void]
        def by_month_day=(monthly_days)
          @by_month_day = Array(monthly_days).map(&:to_i)
        end

        # Set the the specific months of the year to recur on.
        # @param months [Array<Integer, Symbol>, Integer, Symbol] The specific months
        #   of the year to recur on,  e.g. `:april`, `:july`, `:june`, etc.
        # @return [void]
        def by_month=(months)
          @by_month = Array(months).map { |month| MONTHS[month] || month }
        end

        # Set the specific days of the week to recur on.
        # @param weekdays [Array<Symbol, Integer>, Symbol, Integer] The specific days
        #   of the week to recur on, e.g. `:tuesday`, `:saturday`, etc.
        # @return [void]
        def by_weekday=(weekdays)
          @by_weekday = Array(weekdays).map { |day| WEEKDAYS[day] || day }
        end

        # Set the specific days for a specific week to recur on.
        # @param week [Integer] The week of the month (1-5) to recur on.
        # @param day [Integer, Symbol] The specific day to recur on, e.g. `:friday`.
        # @return [void]
        def by_n_weekday(week:, day:)
          (@by_n_weekday ||= []) << { n: week, day: WEEKDAYS[day] || day }
        end

        # @!visibility private
        def interval?
          !@interval.nil?
        end

        # @!visibility private
        def frequency?
          !@frequency.nil?
        end

        # @!visibility private
        def start_time?
          !@start_time.nil?
        end

        # @!visibility private
        def to_h
          {
            by_month: @by_month,
            by_weekday: @by_weekday,
            interval: @interval.to_i,
            by_n_weekday: @by_n_weekday,
            by_month_day: @by_month_day,
            start: @start_time.utc.iso8601,
            frequency: FREQUENCIES[@frequency] || @frequency
          }
        end
      end
    end

    # A skipped or re-scheduled recurrence for a recurring scheduled event.
    class Exception
      include IDObject

      # @return [Time, nil] the new modified end time of the scheduled event recurrence.
      attr_reader :end_time

      # @return [true, false] if the scheduled event should be skipped on the recurrence.
      attr_reader :cancelled

      # @return [Time, nil] the new modified start time of the scheduled event recurrence.
      attr_reader :start_time

      alias_method :recurrence_id, :id
      alias_method :canceled?, :cancelled
      alias_method :cancelled?, :cancelled
      alias_method :original_start_time, :creation_time

      # @!visibility private
      def initialize(data, event, bot)
        @bot = bot
        @event = event
        @id = data['event_exception_id'].to_i
        update_data(data)
      end

      # Edit the properties of the scheduled event exception.
      # @param cancelled [true, false] Whether the scheduled event should be skipped on the recurrence.
      # @param end_time [Time, nil] The new modified time at when the scheduled event recurrence should end.
      # @param start_time [Time, nil] The new modified time at when the scheduled event recurrence should start.
      # @param reason [String, nil] The reason to show in the audit log for modifying the scheduled event exception.
      # @return [nil]
      def modify(cancelled: :undef, canceled: :undef, start_time: :undef, end_time: :undef, reason: nil)
        data = {
          reason: reason,
          is_canceled: cancelled == :undef ? canceled : cancelled,
          scheduled_end_time: (end_time == :undef ? @end_time : end_time)&.iso8601,
          scheduled_start_time: (start_time == :undef ? @start_time : start_time)&.iso8601
        }

        (data[:is_canceled] = @cancelled) if data[:is_canceled] == :undef

        update_data(JSON.parse(API::Server.update_scheduled_event_exception(@bot.token, @event.server.id, @event.id, @id, **data)))
        nil
      end

      # Delete the scheduled event exception.
      # @param reason [String, nil] The reason to show in the audit log for deleting the scheduled event exception.
      # @return [nil]
      def delete(reason: nil)
        API::Server.delete_scheduled_event_exception(@bot.token, @event.server.id, @event.id, @id, reason: reason)
        @event.delete_exception(@id)
        nil
      end

      # Get the total amount of users who are specifically subscribed to the scheduled event exception.
      # @return [Integer] The total amount of users who are currently subscribed to the scheduled event exception.
      def user_count
        @event.recurrence_user_counts(@id)[@id] || 0
      end

      alias_method :subscriber_count, :user_count

      # Get the users who are specifically subscribed to the scheduled event exception.
      # @param limit [Integer, nil] The limit (`nil` for no limit) of how many subscribers to return.
      # @param member [true, false] Whether to return subscribers as server members, when applicable.
      # @return [Array<User, Member>] The users or members that have subscribed to the scheduled event exception.
      def users(limit: 100, member: false)
        @event.users(limit:, member:, recurrence: @id)
      end

      alias_method :subscribers, :users

      # @!visibility private
      def to_h
        {
          event_id: @event.id,
          event_exception_id: @id,
          is_canceled: @cancelled,
          scheduled_end_time: @end_time&.utc&.iso8601,
          scheduled_start_time: @start_time&.utc&.iso8601
        }
      end

      # @!visibility private
      def inspect
        "<Exception id=#{@id} original_start_time=\"#{original_start_time.utc.iso8601}\">"
      end

      # @!visibility private
      def update_data(new_data)
        @cancelled = new_data['is_canceled']
        @end_time = new_data['scheduled_end_time'] ? Time.parse(new_data['scheduled_end_time']) : nil
        @start_time = new_data['scheduled_start_time'] ? Time.parse(new_data['scheduled_start_time']) : nil
      end
    end
  end
end
