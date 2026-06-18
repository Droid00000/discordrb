# frozen_string_literal: true

module Discordrb
  # Generic superclass for discovery.
  module Discovery
    # The discovery settings for a server.
    class Metadata
      # @return [Server] the server the discovery settings are for.
      attr_reader :server

      # @return [Array<String>] the discovery search keywords/tags of the server.
      attr_reader :keywords

      # @return [true, false] whether or not the web page is currently published.
      attr_reader :published

      # @return [String, nil] the server's long description shown on the web page.
      attr_reader :description

      # @return [Array<String>] the server's social media links shown on the web page.
      attr_reader :social_links

      # @return [Array<JoinReason>] the reasons to join the server shown on the web page.
      attr_reader :reasons_to_join

      # @return [true, false] whether clicking on an emoji or sticker will show the server.
      attr_reader :expression_discovery

      alias published? published
      alias expression_discovery? expression_discovery

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @server = server
        update_data(data)
      end

      # Check if the metadata is equal to another server's metadata.
      # @param other [Object, Metadata] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        other.is_a?(Metadata) ? @server == other.server : false
      end

      alias_method :eql?, :==

      # Get the subcategories set for the server.
      # @return [Array<Category>] The subcategories set for the server.
      def subcategories(...)
        @category_ids.map { |category| @bot.discovery_category(category, ...) }
      end

      # Get the primary category set for the server.
      # @return [Category, nil] The primary category set for the server.
      def primary_category(...)
        @bot.discovery_category(@primary_category_id, ...) if @primary_category_id
      end

      # Check if a specific keyword is a valid term.
      # @param keyword [String, Symbol] The keyword that should be checked.
      # @return [true, false] Whether or not the keyword is a valid discovery term.
      def safe_keyword?(keyword)
        JSON.parse(API.validate_discovery_search_term(@bot.token, keyword))['valid']
      end

      # Add one or more discovery subcateogries to the server.
      # @param categories [Category, Integer, Array] The subcategories to add.
      # @return [nil]
      def add_subcategory(categories)
        [*categories].each do |item|
          API::Server.add_discovery_subcategory(@bot.token, @server.id, item.resolve_id)
        end

        update_data(JSON.parse(API::Server.get_discovery_metadata(@bot.token, @server.id)))
        nil
      end

      alias_method :add_subcategories, :add_subcategory

      # Remove one or more discovery subcateogries from the server.
      # @param category [Category, Integer, Array] The subcategories to remove.
      # @return [nil]
      def remove_subcategory(categories)
        [*categories].each do |item|
          API::Server.remove_discovery_subcategory(@bot.token, @server.id, item.resolve_id)
        end

        update_data(JSON.parse(API::Server.get_discovery_metadata(@bot.token, @server.id)))
        nil
      end

      alias_method :remove_subcategories, :remove_subcategory

      # Modify the discovery settings of the server.
      # @param primary_category [Category, Integer, nil] The new primary discovery category.
      # @param keywords [Array<String>, nil] The new discovery search keywords; between 1-10.
      # @param description [String, nil] The long web-page description; between 1-2400 characters.
      # @param reasons_to_join [Array<#to_h>, nil] The new reasons to join the server; between 1-4.
      # @param published [true, false, nil] Whether or not the discovery web page should be published.
      # @param social_links [Array<String>, nil] The new social media links to show on the discovery web page; between 1-9.
      # @param expression_discovery [true, false, nil] Whether clicking on an emoji, sticker, or sound should show the server.
      # @return [nil]
      def modify(
        primary_category: :undef, keywords: :undef, description: :undef, published: :undef,
        reasons_to_join: :undef, social_links: :undef, expression_discovery: :undef
      )
        data = {
          primary_category_id: primary_category == :undef ? @primary_category_id : primary_category&.resolve_id,
          keywords: keywords == :undef ? @keywords : keywords,
          about: description == :undef ? @description : description,
          is_published: published == :undef ? @published : published,
          reasons_to_join: (reasons_to_join == :undef ? @reasons_to_join : reasons_to_join)&.map(&:to_h),
          social_links: social_links == :undef ? @social_links : social_links,
          emoji_discoverability_enabled: expression_discovery == :undef ? @expression_discovery : expression_discovery
        }

        update_data(JSON.parse(API::Server.update_discovery_metadata(@bot.token, @server.id, **data)))
        nil
      end

      # @!visibility private
      def inspect
        "<Discovery::Metadata published=#{@published} expression_discovery=#{@expression_discovery}>"
      end

      private

      # @!visibility private
      def update_data(new_data)
        @description = new_data['about']
        @published = new_data['is_published']
        @keywords = new_data['keywords'] || []
        @social_links = new_data['social_links'] || []
        @category_ids = new_data['category_ids'] || []
        @primary_category_id = new_data['primary_category_id']
        @expression_discovery = new_data['emoji_discoverability_enabled']
        @reasons_to_join = new_data['reasons_to_join']&.map { |item| JoinReason.new(item, self, @bot) } || []
      end
    end

    # A category for a discoverable server.
    class Category
      # @return [Integer] the ID of the category.
      attr_reader :id

      # @return [String] the name of the category.
      attr_reader :name

      # @return [true, false] if the category can be used as a primary category.
      attr_reader :primary

      alias resolve_id id
      alias primary? primary

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @name = data['name']
        @primary = data['is_primary']
      end

      # Check if the category is equal to another category.
      # @param other [Category, Object] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        other.is_a?(Category) ? @id == other.id : false
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        { id: @id, name: @name, primary: @primary }
      end

      # @!visibility private
      def inspect
        "<Discovery::Category id=#{@id} name=\"#{@name}\" primary=#{@primary}>"
      end
    end

    # A reason to join a discoverable server.
    class JoinReason
      # @return [String] the reason to join the server.
      attr_reader :reason

      # @!visibility private
      def initialize(data, meta, bot)
        @bot = bot
        @meta = meta
        @reason = data['reason']
        @emoji_id = data['emoji_id']&.to_i
        @emoji_name = Emoji.new({ 'name' => data['emoji_name'] }, @bot) if data['emoji_name']
      end

      # Get the emoji of the join reason.
      # @return [Emoji, nil] The emoji of the join reason, or `nil`.
      def emoji
        @emoji_id ? @meta.server.emojis[@emoji_id] : @emoji_name
      end

      # Check if the join reason is equal to another join reason.
      # @param other [JoinReason, Object] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        return false unless other.is_a?(JoinReason)

        @reason == other.reason && emoji == other.emoji
      end

      alias_method :eql?, :==

      # @!visibility private
      def inspect
        "<Discovery::JoinReason reason=\"#{@reason}\" emoji=#{emoji.inspect}>"
      end

      # @!visibility private
      def to_h
        { reason: @reason, emoji_id: @emoji_id, emoji_name: @emoji_name&.name }
      end
    end

    # A server's progress towards meeting the discovery requirements.
    class Requirements
      # @return [Server] the server the discovery requirements are for.
      attr_reader :server

      # @return [true, false] whether the server meets the requirements to be listed in discovery.
      attr_reader :sufficient

      # @return [Integer, nil] how old the server must be (in days) before being eligible for discovery.
      attr_reader :minimum_age

      # @return [true, false, nil] whether the server has set a rules channel.
      attr_reader :rules_channel

      # @return [true, false, nil] whether the server is old enough to be listed in discovery.
      attr_reader :minimum_age_met

      # @return [true, false, nil] whether the server has not been flagged by trust & safety.
      attr_reader :safe_environment

      # @return [true, false, nil] whether the server meets the minimum activity requirement.
      attr_reader :healthy_activity

      # @return [true, false, nil] whether the server meets the new member retention requirement.
      attr_reader :healthy_retention

      # @return [true, false, nil] whether the server meets the weekly visitor and communicator requirements.
      attr_reader :healthy_engagement

      # @return [Integer, nil] the minimum amount of members the server must have before being listed in discovery.
      attr_reader :minimum_member_count

      # @return [Time, nil] the time at when the server's grace period ends and the server is de-listed from discovery.
      attr_reader :grace_period_end_time

      # @return [true, false] whether or not the server has required MFA when performing moderator actions.
      attr_reader :moderator_mfa_required

      # @return [true, false, nil] whether the server's activity metrics have yet to be calculated.
      attr_reader :activity_metrics_pending

      # @return [true, false, nil] whether or not the server meets the minimum member count to be listed in discovery.
      attr_reader :minimum_member_count_met

      # @return [true, false] whether or not the grace period can allow the server to remain listed in discovery.
      attr_reader :sufficient_without_grace_period

      # @!group NSFW Properties

      # @return [Array<String>] the disallowed terms found in the server name.
      attr_reader :server_name_keywords

      # @return [Hash<Integer => Array<String>>] a mapping of channel IDs to the disallowed terms found in the channel name.
      attr_reader :channel_name_keywords

      # @return [Array<String>] the disallowed terms found in the server description.
      attr_reader :server_description_keywords

      # @!endgroup

      # @!group Activity Metrics

      # @return [Integer, nil] the average number of users who join the server per-week.
      attr_reader :average_join_count

      # @return [Integer, nil] the average weekly number of users who have viewed the server and have been on Discord for more than 8 weeks.
      attr_reader :average_participant_count

      # @return [Float, nil] the percentage of new members who remain in the server for at least one week.
      attr_reader :week_one_retention_rate

      # @return [Integer, nil] the average weekly number of users who talk in the server and have been on Discord for more than 8 weeks.
      attr_reader :average_communicator_count

      # @!endgroup

      alias sufficient? sufficient
      alias rules_channel? rules_channel
      alias minimum_age_met? minimum_age_met
      alias safe_environment? safe_environment
      alias healthy_activity? healthy_activity
      alias healthy_retention? healthy_retention
      alias healthy_engagement? healthy_engagement
      alias moderator_mfa_required? moderator_mfa_required
      alias activity_metrics_pending? activity_metrics_pending
      alias minimum_member_count_met? minimum_member_count_met
      alias sufficient_without_grace_period? sufficient_without_grace_period

      # @!visibility private
      def initialize(data, server, bot)
        @bot = bot
        @server = server
        @sufficient = data['sufficient']
        @minimum_age = data['minimum_age']
        @rules_channel = data['valid_rules_channel']
        @minimum_age_met = data['age']
        @safe_environment = data['safe_environment']
        @healthy_activity = data['healthy']
        @healthy_retention = data['retention_healthy']
        @healthy_engagement = data['engagement_healthy']
        @minimum_member_count = data['minimum_size']
        @grace_period_end_time = Time.parse(data['grace_period_end_date']) if data['grace_period_end_date']
        @moderator_mfa_required = data['protected']
        @minimum_member_count_met = data['size']
        @activity_metrics_pending = data['health_score_pending']
        @sufficient_without_grace_period = data['sufficient_without_grace_period']
        nsfw_props = data['nsfw_properties'] || {}
        @server_name_keywords = nsfw_props['name_banned_keywords'] || []
        @channel_name_keywords = nsfw_props['channel_banned_keywords']&.transform_keys(&:to_i) || {}
        @server_description_keywords = nsfw_props['description_banned_keywords'] || []
        health_score = data['health_score'] || {}
        @average_join_count = health_score['num_intentful_joiners']&.to_i
        @average_participant_count = health_score['avg_nonnew_participators']&.to_i
        @week_one_retention_rate = health_score['perc_ret_w1_intentful']&.to_f
        @average_communicator_count = health_score['avg_nonnew_communicators']&.to_i
      end

      # @!visibility private
      def inspect
        "<Discovery::Requirements sufficient=#{@sufficient} sufficient_without_grace_period=#{@sufficient_without_grace_period}>"
      end
    end
  end
end
