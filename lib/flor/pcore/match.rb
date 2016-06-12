#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


class Flor::Pro::Match < Flor::Procedure

  names %w[ match ]

  def pre_execute

    @node['rets'] = []
  end

  def receive_last

    rex, str = arguments

    payload['ret'] =
      if m = rex.match(str)
        m.to_a
      else
        []
      end

    reply
  end

  protected

  def arguments

    fail ArgumentError.new(
      "'match' needs at least 2 arguments"
    ) if @node['rets'].size < 2

    rex = @node['rets']
      .find { |r| r.is_a?(Array) && r[0] == '_rxs' } || @node['rets'].last

    str = (@node['rets'] - [ rex ]).first

    rex = rex.is_a?(String) ? rex : rex[1].to_s
    rex = rex.match(/\A\/[^\/]*\/[a-z]*\z/) ? Kernel.eval(rex) : Regexp.new(rex)

    [ rex, str ]
  end
end

