# frozen_string_literal: true

module Discordrb
  # A request to join a guild.
  class JoinRequest
    include Snowflake

    # @return [Symbol] the status of the join request.
    attr_reader :status

    # @return [Array<Response>] the responses to the join request questions.
    attr_reader :responses

    # @return [Time, nil] the time at when the join request's status was changed.
    attr_reader :reviewed_at

    # @return [User, nil] the user who last updated the status of the join request.
    attr_reader :reviewed_by

    # @return [String, nil] the reason for rejecting the join request. Only applicable
    #   if the status of the join request is `:rejected`.
    attr_reader :rejection_reason

    # @!visibility private
    def initialize(data, guild, bot)
      @bot = bot
      @guild = guild
      @id = data[:id].to_i
      @guild_id = @guild&.id || data[:guild_id]&.to_i
      @user = @bot.ensure_user(data[:user]) if data[:user]
      @status = data[:application_status]&.downcase&.to_sym
      @user_id = @user&.id || data[:user_id]&.to_i
      @responses = data[:form_responses]&.map { |item| Response.new(item, @bot) } || []
      @reviewed_at = Time.parse(data[:reviewed_at]) if data[:reviewed_at]
      @rejection_reason = data[:rejection_reason] == '' ? nil : data[:rejection_reason]
      @reviewed_by = @bot.ensure_user(data[:actioned_by_user]) if data[:actioned_by_user]
    end

    # Get the user that the join request is for.
    # @return [User] The user that the join request is for.
    def user
      @user ||= (@bot.user(@user_id) if @user_id)
    end

    # Get the guild that the join request is for.
    # @return [Guild] The guild that the join request is for.
    def guild
      @guild ||= (@bot.guild(@guild_id) if @guild_id)
    end

    # Check if the join request's status has been finalized.
    # @return [true, false] Whether or not the join request has been finalized.
    def finalized?
      approved? || rejected?
    end

    alias_method :finalised?, :finalized?

    # @!attribute [r] approved?
    #   @return [true, false] whether or not the join request has been approved.
    # @!attribute [r] rejected?
    #   @return [true, false] whether or not the join request has been rejected.
    # @!attribute [r] submitted?
    #   @return [true, false] whether or not the join request is waiting for a review.
    %i[approved rejected submitted].each do |name|
      define_method(:"#{name}?") { @status == name }
    end

    # Approve the join request.
    # @return [nil]
    def approve
      data = { status: 'APPROVED' }

      raise "The join request has already been #{@status}" if finalized?

      update_data(@bot.http.action_guild_join_request(@guild_id, @id, **data))
      nil
    end

    # Reject the join request.
    # @param reason [String, nil] The reason for rejecting the join request.
    # @return [nil]
    def reject(reason: nil)
      data = { status: 'REJECTED', rejection_reason: reason }

      raise "The join request has already been #{@status}" if finalized?

      update_data(@bot.http.action_guild_join_request(@guild_id, @id, **data))
      nil
    end

    # @!visibility private
    def inspect
      "<JoinRequest id=#{@id} guild_id=#{@guild_id} user_id=#{@user_id} status=\"#{@status}\">"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @status = new_data[:application_status]&.downcase&.to_sym
      @user = @bot.ensure_user(new_data[:user]) if new_data[:user]
      @reviewed_at = Time.iso8601(new_data[:reviewed_at]) if new_data[:reviewed_at]
      @rejection_reason = new_data[:rejection_reason] == '' ? nil : new_data[:rejection_reason]
      @reviewed_by = @bot.ensure_user(new_data[:actioned_by_user]) if new_data[:actioned_by_user]
    end

    # A response for a guild's join question.
    class Response
      # @return [Symbol] the type of the question.
      attr_reader :type

      # @return [String] the title of the question.
      attr_reader :title

      # @return [Array<String>] the rules that the user must agree to.
      attr_reader :rules

      # @return [Array<String>] the multiple-choice options of the question.
      attr_reader :choices

      # @return [true, false, String, nil] the user's response to the question.
      attr_reader :response

      # @return [true, false] whether or not the user had to provide a response.
      attr_reader :required
      alias required? required

      # @return [String, nil] the subtext for the question, or `nil` if none is set.
      attr_reader :description

      # @return [String, nil] the placeholder text for the question's response area.
      attr_reader :placeholder

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @type = data[:field_type]&.downcase&.to_sym
        @title = data[:label]
        @rules = data[:terms] || []
        @choices = data[:choices] || []
        @required = data[:required] || false
        @description = data[:description]
        @placeholder = data[:placeholder]
        raw = data[:response]
        @response = raw.is_a?(Numeric) ? @choices&.[](raw) : raw
      end
    end
  end
end
