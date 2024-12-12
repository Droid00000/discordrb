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
    alias_method :duration, :expiry

    # @return [Boolean] Whether you can select multiple poll answers.
    attr_reader :allow_multiselect
    alias_method :allow_multiselect?, :allow_multiselect
    alias_method :multiselect?, :allow_multiselect

    # @return [Integer] The layout type of this poll.
    attr_reader :layout_type

    # @return [Boolean] Whether the poll results have been precisely counted.
    attr_reader :finalized
    alias_method :finalized?, :finalized

    # @return [Hash<Integer => Integer>] The answer counts by ID.
    attr_reader :answer_counts

    # @return [Message] The message this poll originates from.
    attr_reader :message

    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @question = data['question']['text']
      @answers = data['answers'].map { |a| Answer.new(a, @bot, self) }
      @expiry = Time.iso8601(data['expiry']) if data['expiry']
      @allow_multiselect = data['allow_multiselect']
      @layout_type = data['layout_type']
      @finalized = data['results']['is_finalized'] if data['results']
      @answer_counts = data['results']['answer_counts'].map { |h| h.delete('me_voted') }.reduce({}, :merge) if data.dig('results', 'answer_counts')
    end

    # Ends this poll. Only works if the bot made the poll.
    # @return [Message] The new message object.
    def end
      response = JSON.parse(API::Channel.end_poll(@bot.token, @message.channel.id, @message.id))
      Message.new(response, @bot)
    end

    alias_method :expire, :end

    # Get a specific answer by its ID.
    # @param id [Integer, String] ID of the answer.
    # @return [Answer, nil]
    def answer(id)
      @answers.find { |a| a.id == id.resolve_id }
    end

    # Whether or not this poll has ended.
    # @return [Boolean]
    def expired?
      return false if @expiry.nil?

      Time.now >= @expiry
    end

    alias_method :ended?, :expired?

    # Returns the answer with the highest count.
    # @return [Answer] The answer object.
    def highest_count
      answer(@answer_counts.invert.max&.last)
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

      # Returns how many users have voted for this answer.
      # @return [Integer, nil] Returns the number of votes or nil if they don't exist.
      def count
        return 0 if !@Poll.answer_counts&.key?(@id) && @poll.finalized?

        @poll.answer_counts&.key(@id)
      end

      # Gets an array of user objects that have voted for this poll.
      # @param after [Integer, String] Gets the users after this user ID.
      # @param limit [Integer] The max number of users between 1-100. Defaults to 25.
      def voters(after: nil, limit: 25)
        response = JSON.parse(API::Channel.get_answer_voters(@bot.token, @poll.message.channel.id, @poll.message.id, @id, after, limit))
        return nil if response['users'].empty?

        response['users'].map { |user| User.new(user, @bot) }
      end
    end

    # Allows for easy creation of a poll request object.
    class Builder
      # Sets the poll question.
      # @param question [String]
      attr_writer :question

      # Whether multiple answers can be chosen.
      # @param allow_multiselect [Boolean]
      attr_writer :allow_multiselect
      alias_method :multiselect=, :allow_multiselect=

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
      end

      # Adds an answer to this poll.
      # @param name [String] Name of the answer.
      # @param emoji [String, Integer, Emoji] An emoji for this poll answer.
      def add_answer(name:, emoji: nil)
        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Reaction
                  emoji.id ? { id: emoji.id } : { name: emoji.name }
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
