# frozen_string_literal: true

module Discordrb
  # A Discord poll attatched to a message.
  class Poll
    # @return [String] Question of the poll.
    attr_reader :question

    # @return [Array<Answer>] Selectable poll answers.
    attr_reader :answers

    # @return [Time] How long this poll will last before expiring.
    attr_reader :expiry

    # @return [Boolean] Whether selecting multiple poll answers is enabled.
    attr_reader :allow_multiselect
    alias_method :allow_multiselect?, :allow_multiselect
    alias_method :multiselect?, :allow_multiselect

    # @return [Integer] The layout type of this poll.
    attr_reader :layout_type

    # @return [Boolean] Whether the poll results have been precisely counted.
    attr_reader :finalized
    alias_method :finalized?, :finalized

    # @return [Array] An array of poll answer count objects.
    attr_reader :answer_counts

    # @return [Message] The message this poll originates from.
    attr_reader :message

    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @question = data['poll']['question']['text']
      @answers = data['poll']['answers'].map { |a| Answer.new(a, @bot, self) }
      @expiry = Time.iso8601(data['poll']['expiry']) if data['poll']['expiry']
      @allow_multiselect = data['poll']['allow_multiselect']
      @layout_type = data['poll']['layout_type']
      @finalized = data['poll']['results']['is_finalized']
      @answer_counts = []

      return if data['poll']['results']['answer_counts'].empty?

      @answers_counts = data['poll']['results']['answer_counts'].map { |a| AnswerCount.new(a, @bot) }
    end

    # Immediately ends the poll and returns a new message object.
    # This will fail if the poll wasn't created by the bot.
    # @return [Message] The new message object.
    def end
      response = API::Channel.end_poll(@bot.token, @message.channel.id, @message.id)
      Message.new(JSON.parse(response), @bot)
    end

    alias_method :expire, :end

    # Get a specific answer by its ID.
    # @param id [Integer, String] ID of the answer.
    # @return [Answer, nil]
    def answer(id)
      @answers.find { |a| a.id == id&.resolve_id }
    end

    # Whether or not this poll has ended.
    # @return [Boolean]
    def expired?
      return false if @expiry.nil?

      Time.now >= @expiry
    end

    alias_method :ended?, :expired?

    # Get a specific answer count by its ID.
    # @param id [Integer, String] ID of the answer.
    # @return [AnswerCount, nil]
    def answer_count(id)
      return nil if @answer_counts.empty?

      @answer_counts.find { |a| a.id == id&.to_i }
    end

    # Returns the answer with the highest count.
    # @return [AnswerCount]
    def highest_count
      @answer_counts.max_by(&:count)
    end

    # Represents the count of answers for an answer.
    class AnswerCount
      include IDObject

      # @return [Integer] The number of voters for the answer.
      attr_reader :count

      # @return [Boolean] If the current user voted for this answer.
      attr_reader :voted

      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @count = data['count']
        @voted = data['me_voted']
      end

      # Represents a single answer for a poll.
      class Answer
        include IDObject

        # @return [Poll] Poll this answers originates from.
        attr_reader :poll

        # @return [String] Name of this question.
        attr_reader :name

        # @return [Emoji, nil] Emoji associated with this question.
        attr_reader :emoji

        def initialize(data, bot, poll)
          @bot = bot
          @poll = poll
          @name = data['poll_media']['text']
          @id = data['answer_id']
          @emoji = Emoji.new(data['poll_media']['emoji'], @bot) if data['poll_media']['emoji']
        end

        # Gets an array of user objects that have voted for this poll.
        # @param after [Integer, String] Gets the users after this user ID.
        # @param limit [Integer] The max number of users between 1-100. Defaults to 25.
        def voters(after: nil, limit: 25)
          response = API::Channel.get_answer_voters(@bot.token, @poll.message.channel.id, @poll.message.id, @id, after, limit)
          return nil if response.empty?

          response.map { |user| User.new(user, @bot) }
        end
      end
    end

    # Allows for easy creation of a poll request object.
    class Builder
      # Sets the poll question to something.
      # @param question [String] The question of the poll.
      attr_writer :question

      # Whether multiple answers can be chosen.
      # @param allow_multiselect [Boolean]
      attr_writer :allow_multiselect

      # The layout type. This can currently only be 1.
      # @param layout_type [Integer]
      attr_writer :layout_type

      # How long this poll should last.
      # @param duration [Integer]
      attr_writer :duration

      # @param question [String]
      # @param answers [Array<Hash>]
      # @param allow_multiselect [Boolean] Defaults to false.
      # @param duration [Integer] Defaults to 24 hours.
      # @param layout_type [Integer] Defaults to 1.
      def initialize(question: nil, answers: [], allow_multiselect: false, duration: 24, layout_type: 1)
        @question = question
        @answers = answers
        @allow_multiselect = allow_multiselect
        @duration = duration
        @layout_type = layout_type
        yield self if block_given?
      end

      # Adds an answer to this poll.
      # @param name [String] Name of the answer.
      # @param emoji [String, Integer, Emoji] An emoji for this polls answer.
      def add_answer(name:, emoji: nil)
        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Emoji
                  { id: emoji.id }
                end

        @answers << { poll_media: { text: name, emoji: emoji }.compact }
      end

      # Converts the poll into a hash that can be sent to Discord.
      def to_h
        {
          question: { text: @question },
          answers: @answers,
          allow_multiselect: @allow_multiselect,
          duration: @duration,
          layout_type: @layout_type
        }.to_h
      end
    end
  end
end
