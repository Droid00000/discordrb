# frozen_string_literal: true

# API calls for slash commands.
module Discordrb::API::Application
  module_function

  # Get a list of global application commands.
  # https://discord.com/developers/docs/interactions/slash-commands#get-global-application-commands
  def get_global_commands(token, application_id)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      Authorization: token
    )
  end

  # Get a global application command by ID.
  # https://discord.com/developers/docs/interactions/slash-commands#get-global-application-command
  def get_global_command(token, application_id, command_id)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Create a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#create-global-application-command
  def create_global_command(token, application_id, name, description, options = [], default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil, nsfw = false, integration_types = nil)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts, nsfw: nsfw, integration_types: integration_types }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-global-application-command
  def edit_global_command(token, application_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil, nsfw = nil, integration_types = nil)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts, nsfw: nsfw, integration_types: integration_types }.compact.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Delete a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-global-application-command
  def delete_global_command(token, application_id, command_id)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Set global application commands in bulk.
  # https://discord.com/developers/docs/interactions/slash-commands#bulk-overwrite-global-application-commands
  def bulk_overwrite_global_commands(token, application_id, commands)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      commands.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get a guild's commands for an application.
  # https://discord.com/developers/docs/interactions/slash-commands#get-guild-application-commands
  def get_guild_commands(token, application_id, guild_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      Authorization: token
    )
  end

  # Get a guild command by ID.
  # https://discord.com/developers/docs/interactions/slash-commands#get-guild-application-command
  def get_guild_command(token, application_id, guild_id, command_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Create an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#create-guild-application-command
  def create_guild_command(token, application_id, guild_id, name, description, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil, nsfw = false)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts, nsfw: nsfw }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-guild-application-command
  def edit_guild_command(token, application_id, guild_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil, nsfw = nil)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts, nsfw: nsfw }.compact.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Delete an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-guild-application-command
  def delete_guild_command(token, application_id, guild_id, command_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Set guild commands in bulk.
  # https://discord.com/developers/docs/interactions/slash-commands#bulk-overwrite-guild-application-commands
  def bulk_overwrite_guild_commands(token, application_id, guild_id, commands)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      commands.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get the permissions for a specific guild command.
  # https://discord.com/developers/docs/interactions/slash-commands#get-application-command-permissions
  def get_guild_command_permissions(token, application_id, guild_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_permissions,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/permissions",
      Authorization: token
    )
  end

  # Edit the permissions for a specific guild command.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-application-command-permissions
  def edit_guild_command_permissions(token, application_id, guild_id, command_id, permissions)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid_permissions,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions",
      { permissions: permissions }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit permissions for all commands in a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#batch-edit-application-command-permissions
  def batch_edit_command_permissions(token, application_id, guild_id, permissions)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid_permissions,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/permissions",
      permissions.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get all of the permissions for the commands in a guild.
  # https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
  def get_guild_application_command_permissions(token, application_id, guild_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_permissions,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/permissions",
      Authorization: token
    )
  end

  # Get the permissions for a specific command in a guild.
  # https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
  def get_application_command_permissions(token, application_id, guild_id, command_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid_permissions,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions",
      Authorization: token
    )
  end

  # Get a list of application emojis.
  # https://discord.com/developers/docs/resources/emoji#list-application-emojis
  def list_application_emojis(token, application_id)
    Discordrb::API.request(
      :applications_aid_emojis,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/emojis",
      Authorization: token
    )
  end

  # Get an application emoji by ID.
  # https://discord.com/developers/docs/resources/emoji#get-application-emoji
  def get_application_emoji(token, application_id, emoji_id)
    Discordrb::API.request(
      :applications_aid_emojis_eid,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/emojis/#{emoji_id}",
      Authorization: token
    )
  end

  # Create an application emoji.
  # https://discord.com/developers/docs/resources/emoji#create-application-emoji
  def create_application_emoji(token, application_id, name, image)
    Discordrb::API.request(
      :applications_aid_emojis,
      application_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/emojis",
      { name: name, image: image }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit an application emoji.
  # https://discord.com/developers/docs/resources/emoji#modify-application-emoji
  def edit_application_emoji(token, application_id, emoji_id, name)
    Discordrb::API.request(
      :applications_aid_emojis_eid,
      application_id,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/emojis/#{emoji_id}",
      { name: name }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Delete an application emoji.
  # https://discord.com/developers/docs/resources/emoji#delete-application-emoji
  def delete_application_emoji(token, application_id, emoji_id)
    Discordrb::API.request(
      :applications_aid_emojis_eid,
      application_id,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/emojis/#{emoji_id}",
      Authorization: token
    )
  end

  # Edit the current application for the requesting bot user.
  # https://discord.com/developers/docs/resources/application#edit-current-application
  def update_current_application(token, custom_install_url: :undef, description: :undef, role_connections_verification_url: :undef, install_params: :undef, integration_types_config: :undef, flags: :undef, interactions_endpoint_url: :undef, tags: :undef, event_webhooks_url: :undef, event_webhooks_status: :undef, event_webhooks_types: :undef, icon: :undef, cover_image: :undef)
    Discordrb::API.request(
      :applications_me,
      nil,
      :patch,
      "#{Discordrb::API.api_base}/applications/@me",
      { custom_install_url:, description:, role_connections_verification_url:, install_params:, integration_types_config:, flags:, interactions_endpoint_url:, tags:, event_webhooks_url:, event_webhooks_status:, event_webhooks_types:, icon:, cover_image: }.reject { |_, value| value == :undef }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get a list of role connection metadata records.
  # https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
  def get_application_role_connection_metadata_records(token, application_id)
    Discordrb::API.request(
      :applications_aid_role_connections_metadata,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/role-connections/metadata",
      Authorization: token
    )
  end

  # Get a list of entitlements for the application.
  # https://discord.com/developers/docs/resources/entitlement#list-entitlements
  def list_entitlements(token, application_id, limit: 100, user_id: nil, sku_ids: nil, before: nil, after: nil, server_id: nil, exclude_ended: nil, exclude_deleted: nil)
    query = URI.encode_www_form({ limit: limit, user_id: user_id, sku_ids: sku_ids, before: before, after: after, guild_id: server_id, exclude_ended: exclude_ended, exclude_deleted: exclude_deleted }.compact)

    Discordrb::API.request(
      :applications_aid_entitlements,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements?#{query}",
      Authorization: token
    )
  end

  # Get a single entitlement by its ID.
  # https://discord.com/developers/docs/resources/entitlement#get-entitlement
  def get_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}",
      Authorization: token
    )
  end

  # Create a test entitlement.
  # https://discord.com/developers/docs/resources/entitlement#create-test-entitlement
  def create_test_entitlement(token, application_id, sku_id:, owner_id:, owner_type:)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      nil,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements",
      { sku_id:, owner_id:, owner_type: }.to_json,
      content_type: :json,
      Authorization: token
    )
  end

  # Consume a one-time purchase entitlement.
  # https://discord.com/developers/docs/resources/entitlement#consume-an-entitlement
  def consume_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      nil,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}/consume",
      nil,
      Authorization: token
    )
  end

  # Delete a test entitlement.
  # https://discord.com/developers/docs/resources/entitlement#delete-test-entitlement
  def delete_test_entitlement(token, application_id, entitlement_id)
    Discordrb::API.request(
      :applications_aid_entitlements_eid,
      nil,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/entitlements/#{entitlement_id}",
      Authorization: token
    )
  end

  # Get a list of SKUs for the application.
  # https://discord.com/developers/docs/resources/sku#list-skus
  def list_skus(token, application_id)
    Discordrb::API.request(
      :applications_aid_skus,
      application_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/skus",
      Authorization: token
    )
  end

  # Get a list of subscriptions containing the SKU.
  # https://discord.com/developers/docs/resources/subscription#list-sku-subscriptions
  def list_sku_subscriptions(token, sku_id, limit: 100, before: nil, after: nil, user_id: nil)
    query = URI.encode_www_form({ limit: limit, user_id: user_id, before: before, after: after }.compact)

    Discordrb::API.request(
      :skus_sid_subscriptions,
      nil,
      :get,
      "#{Discordrb::API.api_base}/skus/#{sku_id}/subscriptions?#{query}",
      Authorization: token
    )
  end

  # Get a single subscription for the SKU.
  # https://discord.com/developers/docs/resources/subscription#get-sku-subscription
  def get_sku_subscription(token, sku_id, subscription_id)
    Discordrb::API.request(
      :skus_sid_subscriptions_sid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/skus/#{sku_id}/subscriptions/#{subscription_id}",
      Authorization: token
    )
  end
end
