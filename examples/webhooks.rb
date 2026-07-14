# frozen_string_literal: true

require 'discordrb'
require 'securerandom'

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORDRB_TOKEN'))

SMALL_IMAGE = 'data:image/jpg;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaKtCnYQcchQnSyIijhqFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdHJSdJES/5cUWsR4cNyPd/ced+8Af73MVLNjHFA1y0gl4kImuyoEX9GDfoTRi4DETH1OFJPwHF/38PH1LsazvM/9OcJKzmSATyCeZbphEW8QT29aOud94ggrSgrxOfGYQRckfuS67PIb54LDfp4ZMdKpeeIIsVBoY7mNWdFQiaeIo4qqUb4/47LCeYuzWq6y5j35C0M5bWWZ6zSHkcAiliBCgIwqSijDQoxWjRQTKdqPe/iHHL9ILplcJTByLKACFZLjB/+D392a+ckJNykUBzpfbPtjBAjuAo2abX8f23bjBAg8A1day1+pAzOfpNdaWvQI6NsGLq5bmrwHXO4Ag0+6ZEiOFKDpz+eB9zP6piwwcAt0r7m9Nfdx+gCkqavkDXBwCIwWKHvd491d7b39e6bZ3w/9+3J4GwJBFwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+YLEA0OHzBTh5kAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAK0lEQVRIx+3NQQEAQAQAMC6DjLKJeSX4bQWW1ROXXhwTCAQCgUAgEAgEWz5KaQFiPn2UJwAAAABJRU5ErkJggg=='
CHANNEL_EDIT = ENV.fetch('CHANNEL_EDIT')

bot.message(content: '!CREATE') do |event|
  event.send_message(content: 'Creating a webhook in the channel.')
  hook = event.channel.create_webhook(name: 'Test Webhook')
  hook.send_message(content: 'Successfully created a webhook in the channel.')
end

bot.message(content: '!EDIT_ONE') do |event|
  hook = event.channel.webhooks.first
  hook.modify(name: 'Test One')
  hook.send_message(content: 'Successfully edited a webhook in the channel.')
end

bot.message(content: '!EDIT_TWO') do |event|
  hook = event.channel.webhooks.first
  hook.modify(name: 'Test Two', avatar: SMALL_IMAGE)
  hook.send_message(content: 'Successfully edited the webhook a second time.')
end

bot.message(content: '!EDIT_THREE') do |event|
  hook = event.channel.webhooks.first
  hook.modify(channel: CHANNEL_EDIT || event.channel, avatar: nil)
  hook.send_message(content: 'Successfully edited the webhook a third time.')
end

bot.message(content: '!DELETE') do |event|
  hook = event.channel.webhooks.first
  hook.delete(reason: 'Testing Completed')
  event.send_message(content: 'Successfully deleted the webhook. It can no longer be used.')
end

bot.run
