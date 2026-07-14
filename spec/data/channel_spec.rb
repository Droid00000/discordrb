# frozen_string_literal: true

require 'discordrb'
require 'mock/api_mock'

using APIMock

describe Discordrb::Channel do
  let(:data) { load_data_file(:text_channel) }
  # Instantiate the doubles here so we can apply mocks in the specs
  let(:bot) { double('bot') }
  let(:guild) { double('guild', id: double) }

  subject(:channel) do
    allow(bot).to receive(:token) { 'fake token' }
    described_class.new(data, bot, guild)
  end

  describe '#update_channel_data' do
    shared_examples('API call') do |property_name|
      it "should call the API with #{property_name}" do
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        data = double(property_name)
        allow(data).to receive(:resolve_id) if property_name == :parent
        expect(Discordrb::API::Channel).to receive(:update!)
        new_data = { property_name => data }
        channel.__send__(:modify, **new_data)
      end
    end

    include_examples('API call', :name, 2)
    include_examples('API call', :topic, 3)
    include_examples('API call', :position, 4)
    include_examples('API call', :bitrate, 5)
    include_examples('API call', :user_limit, 6)
    include_examples('API call', :parent, 9)
    include_examples('API call', :slowmode_rate, 10)

    context 'when permission_overwrite are not set' do
      it 'should not send permission_overwrite' do
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = {}
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:permission_overwrites).and_return(false)
        expect(Discordrb::API::Channel).to receive(:update!)
        channel.__send__(:modify, **new_data)
      end
    end

    context 'when passed a boolean for nsfw' do
      it 'should pass the boolean' do
        nsfw = double('nsfw')
        channel.instance_variable_set(:@nsfw, nsfw)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = {}
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:nsfw).and_return(1)
        expect(Discordrb::API::Channel).to receive(:update!)
        channel.__send__(:modify, **new_data)
      end
    end

    context 'when passed a non-boolean for nsfw' do
      it 'should pass the cached value' do
        nsfw = double('nsfw')
        channel.instance_variable_set(:@nsfw, nsfw)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = {}
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:nsfw).and_return(1)
        expect(Discordrb::API::Channel).to receive(:update!)
        channel.__send__(:modify, **new_data)
      end
    end

    context 'when passed an Integer for slowmode_rate' do
      it 'should pass the new value' do
        slowmode_rate = 5
        channel.instance_variable_set(:@slowmode_rate, slowmode_rate)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = {}
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:rate_limit_per_user).and_return(5)
        expect(Discordrb::API::Channel).to receive(:update!)
        channel.__send__(:modify, **new_data)
      end
    end

    it 'should call #update_data with new data' do
      response_data = {}
      expect(channel).to receive(:update_data).with(response_data)
      allow(JSON).to receive(:parse).and_return(response_data)
      allow(Discordrb::API::Channel).to receive(:update!)
      channel.__send__(:modify)
    end

    context 'when NoPermission is raised' do
      it 'should not call update_data' do
        allow(Discordrb::API::Channel).to receive(:update!).and_raise(Discordrb::Errors::NoPermission)
        expect(channel).not_to receive(:update_data)
        begin
          channel.__send__(:modify)
        rescue Discordrb::Errors::NoPermission
          nil
        end
      end
    end
  end

  describe '#update_data' do
    shared_examples('update property data') do |property_name|
      context 'when we have new data' do
        it 'should assign the property' do
          new_data = double('new data', :[] => nil, :key? => true)
          allow(new_data).to receive(:[]).with(property_name)
        end
      end
    end

    include_examples('update property data', :name)
    include_examples('update property data', :topic)
    include_examples('update property data', :position)
    include_examples('update property data', :bitrate)
    include_examples('update property data', :user_limit)
    include_examples('update property data', :nsfw)
    include_examples('update property data', :parent_id)
  end
end
