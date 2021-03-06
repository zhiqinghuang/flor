
#
# specifying flor
#
# Thu Mar 31 16:17:39 JST 2016
#

require 'spec_helper'


describe 'Flor core' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'a variable as head' do

    it 'is derefenced upon application' do

      r = @executor.launch(%{
        set a
          sequence
        a
          1
          2
      })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(2)
    end

    it 'triggers an error when missing' do

      r = @executor.launch(%{
        a
          1
          2
      })

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq("don't know how to apply \"a\"")
    end

    it 'yields the value if not a proc or a func' do

      r = @executor.launch(%{
        set a 1
        a 2
      })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(1)
    end

    it 'yields the value if not a proc or a func (null)'# do
#
#      r = @executor.launch(%{
#        set a null
#        a 2
#      })
#
#      expect(r['point']).to eq('terminated')
#      expect(r['payload']['ret']).to eq(nil)
#    end
  end

  describe 'a variable reference' do

    it 'yields the value' do

      r = @executor.launch(
        %{
          [ key, v.key ]
        },
        vars: { 'key' => 'a major' })

      expect(r['point']).to eq('terminated')
      expect(r['vars']['key']).to eq('a major')
      expect(r['payload']['ret']).to eq([ 'a major' ] * 2)
    end

    it 'fails else' do

      r = @executor.launch(%{
        key
      })

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq("don't know how to apply \"key\"")
    end

      # not super sure about this one
      # regular interpreters fail on this one
      # limiting this behaviour to fields is better, probably
      #
    it 'yields null if referenced with a v. prefix'# do
#
#      flor = %{
#        v.a
#      }
#
#      r = @executor.launch(flor)
#
#      expect(r['point']).to eq('terminated')
#      expect(r['payload']['ret']).to eq(nil)
#    end
  end

  describe 'a variable deep reference' do

    it 'yields the desired value' do

      r = @executor.launch(
        %{
          set c a.0
          a.0.b
        },
        vars: { 'a' => [ { 'b' => 'c' } ] })

      expect(r['point']).to eq('terminated')
      expect(r['vars']['c']).to eq({ 'b' => 'c' })
      expect(r['payload']['ret']).to eq('c')
    end

    it 'yields null when the container exists' do

      r = @executor.launch(
        %{
          [ a.0, h.k0 ]
        },
        vars: { 'a' => [], 'h' => {} })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ nil, nil ])
    end

    it 'fails when the container does not exist' do

      r = @executor.launch(%{ a.0 })

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('variable "a" not found')
    end

    it 'fails when the container does not exist (deeper)' do

      r = @executor.launch(
        %{ h.a.0 },
        vars: { 'h' => {} })

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('no key "a" in variable "h"')
    end
  end

  describe 'the "node" pseudo-variable' do

    it 'gives access to the node' do

      r = @executor.launch(
        %{
          push f.l node.nid
          push f.l "$(node.nid)"
          push f.l node.heat0
          push f.l "$(node.heat0)"
        },
        payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq(%w[ 0_0_1 0_1_1 node.heat0 _dqs ])
    end
  end
end

