# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Overwrite do
  describe '#initialize' do
    it 'Initialize a new permission overwrite' do
      overwrite = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.id).to eq(1_276_342_433_831_190_660)
      expect(overwrite.type).to eq(:role)
      expect(overwrite.denied.bits).to eq(49_152)
      expect(overwrite.allowed.bits).to eq(0)
    end
  end

  describe '#==' do
    it 'Returns true if two permissions overwrites are the same' do
      first = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)
      second = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)

      expect((first == second)).to eq(true)
    end

    it 'Returns false when two permissions overwrites are different types' do
      first = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)
      second = described_class.new({ id: '1268769768920580156', type: 1, deny: '49152', allow: '0' }, nil, nil)

      expect((first == second)).to eq(false)
    end

    it 'Returns false when two permissions overwrites have different bits' do
      first = described_class.new({ id: '1276342433831190660', type: 1, deny: '49152', allow: '0' }, nil, nil)
      second = described_class.new({ id: '1276342433831190660', type: 1, deny: '0', allow: '131072' }, nil, nil)

      expect((first == second)).to eq(false)
    end
  end

  describe '#role?' do
    it 'Returns true if the permission overwrite is for a role' do
      overwrite = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.role?).to eq(true)
    end

    it 'Returns false is the permission overwrite is not for a role' do
      overwrite = described_class.new({ id: '1268769768920580156', type: 1, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.role?).to eq(false)
    end
  end

  describe '#member?' do
    it 'Returns true if the permission overwrite is for a member' do
      overwrite = described_class.new({ id: '1268769768920580156', type: 1, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.member?).to eq(true)
    end

    it 'Returns false is the permission overwrite is not for a role' do
      overwrite = described_class.new({ id: '1276342433831190660', type: 0, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.member?).to eq(false)
    end
  end

  describe '#to_h' do
    it 'serializes the permission overwrite into a hash' do
      overwrite = described_class.new({ id: '1268769768920580156', type: 1, deny: '49152', allow: '0' }, nil, nil)

      expect(overwrite.to_h).to eq({ id: 1_268_769_768_920_580_156, type: 1, deny: '49152', allow: '0' })
    end
  end
end
