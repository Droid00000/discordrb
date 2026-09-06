# frozen_string_literal: true

module Discordrb
  # Namespace for components.
  module Components
    # An entity that can be used to modify components.
    class Tree
      # @!visibility private
      CLASS_TYPES = {
        Components::Button => Components::TYPES[:button],
        Components::Separator => Components::TYPES[:separator],
        Components::Container => Components::TYPES[:container],
        Components::ActionRow => Components::TYPES[:action_row],
        Components::TextDisplay => Components::TYPES[:text_display]
      }.freeze

      # @!visibility private
      def initialize(interaction, bot)
        @bot = bot
        @interaction = interaction
      end

      # Modify a pre-existing button.
      # @param identifier [String] The custom ID of the button to target.
      # @param style [Symbol] The new style of the button.
      # @param label [String, nil] The new label of the button, between 1-100 characters, if applicable.
      # @param url [String, #to_s, nil] The new URL of the button, if the style is `:link`.
      # @param emoji [Emoji, Integer, String, Reaction, Hash, #to_h, nil] The new emoji of the button, if any.
      # @param id [Integer, nil] The new numeric ID of the button, if any.
      # @param custom_id [String] The new custom ID of the button. All non-link buttons must have a custom ID.
      # @param disabled [true, false] Whether or not the button should be disabled (greyed out and un-clickable).
      # @return [nil]
      def modify_button(
        identifier, style: :undef, label: :undef, url: :undef,
        emoji: :undef, id: :undef, custom_id: :undef, disabled: :undef
      )
        data = {
          id: id,
          url: url == :undef ? url : url&.to_s,
          style: Webhooks::View::BUTTON_STYLES[style] || style,
          label: label,
          emoji: emoji == :undef ? emoji : Emoji.build_hash(emoji, prefix: false),
          disabled: disabled,
          custom_id: custom_id
        }

        data.reject! { |_, value| value == :undef }

        set_modified_data(identifier, Webhooks::View::COMPONENT_TYPES[:button], data)
      end

      # @!visibility private
      def to_a
        @interaction.message.components.map(&:to_h)
      end

      # @!visibility private
      def set_modified_data(identifier, type, new_data)
        component = @interaction.get_component(identifier)

        if CLASS_TYPES[component.class] == type
          component.modified_data = new_data
          nil
        else
          name = Webhooks::View::COMPONENT_TYPES.key(type).to_s.tr('_', ' ')
          raise ArgumentError, "A #{name} with the following identifier could not be found: #{identifier}"
        end
      end
    end
  end
end
