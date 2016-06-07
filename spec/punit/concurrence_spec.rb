
#
# specifying flor
#
# Fri Jun  3 06:09:21 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('.flor-test.conf')
    @unit.conf['unit'] = 'pu_concurrence'
    @unit.conf['journal'] = true
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe 'concurrence' do

    it 'has no effect when empty' do

      flon = %{
        concurrence _
      }

      msg = @unit.launch(flon, wait: true)

      expect(msg['point']).to eq('terminated')
    end

    it 'has no effect when empty (2)' do

      flon = %{
        concurrence tag: 'z'
      }

      msg = @unit.launch(flon, wait: true)

      expect(msg['point']).to eq('terminated')

      expect(
        @unit.journal
          .collect { |m| [ m['point'][0, 3], m['nid'] ].join(':') }
      ).to eq(%w[
        exe:0 exe:0_0 exe:0_0_1 rec:0_0 ent:0 rec:0 rec: lef:0 ter:
      ])
    end

    it 'executes atts in sequence then children in concurrence' do

      flon = %{
        concurrence tag: 'x', nada: 'y'
          trace 'a'
          trace 'b'
      }

      msg = @unit.launch(flon, wait: true)

      expect(msg['point']).to eq('terminated')

      expect(
        @unit.traces.collect(&:text).join(' ')
      ).to eq(
        'a b'
      )

      expect(
        @unit.journal
          .select { |m| %w[ execute receive ].include?(m['point']) }
          .collect { |m| [ m['point'], m['nid'] ].join(':') }
      ).to comprise(%w[
        execute:0_2 execute:0_3
        execute:0_2_0 execute:0_3_0
        execute:0_2_0_0 execute:0_3_0_0
      ])
    end

    describe 'by default' do

      it 'merges all the payload, first reply wins' do

        flon = %{
          concurrence
            set f.a 0
            set f.a 1
            set f.b 2
        }

        msg = @unit.launch(flon, wait: true)

        expect(msg['point']).to eq('terminated')
        expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0, 'b' => 2 })
      end
    end

    describe 'expect:' do

      it 'accepts an integer > 0' do

        flon = %{
          concurrence expect: 1
            set f.a 0
            set f.b 1
        }

        msg = @unit.launch(flon, wait: true)

        expect(msg['point']).to eq('terminated')
        expect(msg['payload']).to eq({ 'ret' => nil, 'a' => 0 })

        expect(
          @unit.journal
            .select { |m| %w[ execute receive ].include?(m['point']) }
            .collect { |m| [ m['point'], m['nid'] ].join(':') }
        ).to comprise(%w[
          receive:0 receive:0 receive:
        ])
      end
    end
  end
end
