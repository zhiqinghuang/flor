
#
# specifying flor
#
# Sun Jul 10 06:48:32 JST 2016
#

require 'spec_helper'


describe 'Flor unit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'u'
    @unit.hook('journal', Flor::Journal)
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe 'a hook' do

    it 'is given the opportunity to see any message' do

      msgs = []
      @unit.hook do |message|
        msgs << Flor.dup(message) if message['consumed']
      end

      @unit.launch(%{
        sequence
          noop _
      }, wait: true)

      expect(msgs).to eq(@unit.journal)
    end

    it 'may alter a message' do

      @unit.hook do |message|
        next if message['consumed']
        next unless message['point'] == 'execute'
        message['tree'][1] = 'blue' if message['tree'][0] == '_sqs'
      end

      @unit.launch(%{
        sequence
          trace 'red'
      }, wait: true)

      expect(
        @unit.traces.collect { |t| "#{t.nid}:#{t.text}" }
      ).to eq(%w[
        0_0:blue
      ])
    end
  end

  describe 'Flor::Scheduler#hook' do

    it 'may filter on consumed:/c:' do

      ncms = []; @unit.hook(consumed: false) { |m| ncms << Flor.dup(m) }
      cms = []; @unit.hook(c: true) { |m| cms << Flor.dup(m) }
      ms = []; @unit.hook { |m| ms << Flor.dup(m) }

      @unit.launch(%{
        sequence
          noop _
      }, wait: true)

      expect([ ms.size, cms.size, ncms.size ]).to eq([ 14, 7, 7 ])
    end

    it 'may filter on point:/p:' do

      ms0 = []
      @unit.hook(point: 'execute') { |m| ms0 << Flor.dup(m) }
      ms1 = []
      @unit.hook(p: %w[ execute terminated ]) { |m| ms1 << Flor.dup(m) }

      @unit.launch(%{
        sequence
          noop _
      }, wait: true)

      expect(
        ms0.collect { |m| m['point'] }.uniq).to eq(%w[ execute ])
      expect(
        ms1.collect { |m| m['point'] }.uniq).to eq(%w[ execute terminated ])
    end

    it 'may filter on domain:/d:' do

      ms0 = []
      @unit.hook(domain: 'test') { |m| ms0 << Flor.dup(m) }
      ms1 = []
      @unit.hook(d: %w[ test nada ]) { |m| ms1 << Flor.dup(m) }
      ms2 = []
      @unit.hook(d: 'tes') { |m| ms2 << Flor.dup(m) }

      r =
        @unit.launch(%{
          sequence
            noop _
        }, wait: true)

      expect(r['point']).to eq('terminated')

      expect(ms0.size).to eq(14)
      expect(ms1.size).to eq(14)
      expect(ms2.size).to eq(0)
    end

    it 'may filter on heap:/hp:' do

      ms0 = []
      @unit.hook(heap: 'sequence') { |m| ms0 << Flor.dup(m) }
      ms1 = []
      @unit.hook(hp: %w[ sequence noop ]) { |m| ms1 << Flor.dup(m) }

      @unit.launch(%{
        sequence
          noop _
      }, wait: true)

      expect(
        ms0.collect { |m| m['point'] }
      ).to eq(%w[ execute ] * 2 + %w[ receive ] * 2)

      expect(
        ms1.collect { |m| m['point'] }
      ).to eq(%w[ execute ] * 4 + %w[ receive ] * 4)
    end

    it 'may filter on heat:/ht:' do

      ms0 = []
      @unit.hook(heat: 'fun0', c: false) do |x, m, o|
        #pp m
        #pp x.node(m['nid'])
        ms0 << Flor.dup(m)
      end

      ms1 = []
      @unit.hook(ht: %w[ fun1 ], c: false) do |x, m, o|
        ms1 << Flor.dup(m)
      end

      r =
        @unit.launch(%{
          define fun0 x; trace "fun0:$(x)"
          define fun1 x; trace "fun1:$(x)"
          sequence
            fun0 'a'
            fun1 'b'
        }, wait: true)

      expect(r['point']).to eq('terminated')

      expect(
        @unit.traces.collect { |t| "#{t.nid}:#{t.text}" }
      ).to eq(%w[
        0_0_2-1:fun0:a
        0_1_2-2:fun1:b
      ])

      expect(
        ms0.collect { |m| m['nid'] }).to eq(%w[ 0_2_0 ] * 3)
      expect(
        ms0.collect { |m| m['point'] }).to eq(%w[ execute receive receive ])

      expect(
        ms1.collect { |m| m['nid'] }).to eq(%w[ 0_2_1 ] * 3)
      expect(
        ms1.collect { |m| m['point'] }).to eq(%w[ execute receive receive ])
    end

    it 'may filter on tag:/t:'
    it 'may filter on tenter:/te:'
    it 'may filter on tleave:/tl:'
  end
end

