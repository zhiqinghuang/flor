
#
# specifying flor
#
# Fri May 20 14:29:17 JST 2016
#

require 'spec_helper'


describe 'Flor unit' do

  before :each do

    @unit = Flor::Unit.new('.flor-test.conf')
    @unit.conf['unit'] = 'u'
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe 'trap' do

    it 'traps messages' do

      flon = %{
        sequence
          trap 'execute'
            push f.l 'x'
          trap 'terminated'
            push f.l 'z'
          push f.l 'y'
          push f.l 'y'
      }

      r = @unit.launch(flon, wait: true)

pp r
      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq(%w[ x x x y x y z ])
    end
  end
end

