# frozen_string_literal: true

module Discordrb
  # A guild member that has joined a thread.
  class ThreadMember
    # @return [Integer] the flags for the thread member.
    attr_reader :flags

    # @return [Channel] the thread that the member is for.
    attr_reader :thread

    # @return [Integer] the ID of the user that the member is for.
    attr_reader :user_id

    # @return [Time] the time at when the member joined the thread.
    attr_reader :joined_at

    alias_method :channel, :thread
    alias_method :resolve_id, :user_id

    # @!visibility private
    def initialize(data, thread, bot)
      @bot = bot
      @thread = thread
      @user_id = data[:user_id]&.to_i
      update_data(data)
    end

    # Remove the thread member from the associated thread channel.
    # @return [nil]
    def remove
      @thread.remove_thread_member(@user_id)
    end

    # Get the guild member that the thread member is for.
    # @return [Member] The guild member that the thread member is for.
    def member
      @member ||= @thread.guild.member(@user_id)
    end

    # Check if two thread member objects are equal to each other.
    # @param other [ThreadMember] The thread member to compare against.
    # @return [true, false] Whether or not the thread members are the same.
    def ==(other)
      return false unless other.is_a?(ThreadMember)

      @thread.id == other.thread.id && @user_id == other.user_id
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<ThreadMember user_id=#{@user_id} thread_id=#{@thread.id}>"
    end

    # @!visibility private
    def update_data(new_data)
      @flags = new_data[:flags].to_i
      @joined_at = Time.iso8601(new_data[:join_timestamp]) if new_data[:join_timestamp]
    end
  end
end
