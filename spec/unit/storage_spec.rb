
#
# specifying flor
#
# Mon Feb 13 06:21:52 JST 2017
#

require 'spec_helper'


describe Flor::Storage do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'stest'
    @unit.storage.delete_tables
    @unit.storage.migrate
    #@unit.start # no

    @db = @unit.storage.db
  end

  describe '#load_messages' do

    it 'loads only msgs for execution where the messages are all created' do

      d = 'domain0'

      @db[:flor_messages].insert(
        point: 'execute', exid: 'cc', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'execute', exid: 'bb', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'execute', exid: 'aa', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'cancel', exid: 'bb', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'execute', exid: 'aa', status: 'reserved-other', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      #@db[:flor_messages].insert(
      #  point: 'launch', exid: 'dd', status: 'archived', domain: d,
      #  ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'launch', exid: 'ee', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
        #
      @db[:flor_messages].where(exid: 'cc').update(mtime: Flor.tstamp)

      ms = @unit.storage.load_messages(1)

      expect(ms.keys).to eq(%w[ bb cc ])
      expect(ms['bb'].map { |m| m[:status] }.uniq).to eq(%w[ created ])
      expect(ms['cc'].map { |m| m[:status] }.uniq).to eq(%w[ created ])
      expect(ms['bb'].map { |m| m[:point] }).to eq(%w[ execute cancel ])
      expect(ms['cc'].map { |m| m[:point] }).to eq(%w[ execute ])
    end

    it 'does not consider "consumed" messages' do

      d = 'domain1'

      @db[:flor_messages].insert(
        point: 'execute', exid: 'cc', status: 'consumed', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'execute', exid: 'bb', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'cancel', exid: 'cc', status: 'created', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)
      @db[:flor_messages].insert(
        point: 'execute', exid: 'bb', status: 'reserved-other', domain: d,
        ctime: Flor.tstamp, mtime: Flor.tstamp)

      ms = @unit.storage.load_messages(1)

      expect(ms.keys).to eq(%w[ cc ])
      expect(ms['cc'].map { |m| m[:status] }.uniq).to eq(%w[ created ])
      expect(ms['cc'].map { |m| m[:point] }).to eq(%w[ cancel ])
    end
  end
end

