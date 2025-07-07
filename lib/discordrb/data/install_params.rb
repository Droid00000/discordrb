# frozen_string_literal: true

module Discordrb
  # Default installation parameters for an application.
  class InstallParams
    # @return [Permissions] the default permissions to add an application to a server with.
    attr_reader :permissions

    # @return [Array<String>] the default scopes to add an application to a server with.
    attr_reader :scopes

    # @!visibility private
    def initialize(data, bot, application = nil)
      @bot = bot
      @application = application
      @permissions = Permissions.new(data['permissions'])
      @scopes = data['scopes']
    end

    # @!visibility private
    def to_h
      {
        scopes: @scopes,
        permissions: @permissions.bits.to_s
      }
    end
  end
end
