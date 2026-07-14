# frozen_string_literal: true

# This bot shows off DM functionality by sending a DM every time the bot is mentioned.

require 'discordrb'

bot = Discordrb::Bot.new token: 'B0T.T0KEN.here'

# The `mention` event is called if the bot is *directly mentioned*, i.e. not using a role mention or @everyone/@here.
bot.mention do |event|
  # The `send_message` method is used to send a direct message (aka a DM) to the user who sent the initial message.
  event.user.send_message(content: 'You have mentioned me!')
end

bot.run
