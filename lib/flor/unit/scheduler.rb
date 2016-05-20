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


module Flor

  class Scheduler

    attr_reader :conf, :env
    attr_reader :logger, :storage

    attr_reader :thread_status

    def initialize(conf={})

      @conf = conf.is_a?(Hash) ? conf : Flor::Conf.read(conf)
      @conf.merge!(Flor::Conf.read_env)

      @env = @conf['env'] ||= 'dev'

      @logger =
        (Flor::Conf.get_class(@conf, 'logger') || Flor::Logger).new(self)
      @storage =
        (Flor::Conf.get_class(@conf, 'storage') || Flor::Storage).new(self)

      @heart_rate = @conf[:sch_heart_rate] || 0.3
      @reload_frequency = @conf[:sch_reload_frequency] || 60
      @max_executors = @conf[:sch_max_executors] || 1

      @mutex = Mutex.new

      @reloaded_at = nil
      @timers = []
      @exids = []

      @executors = []
      @waiters = []
    end

    def shutdown

      @thread_status = :shutdown
      @thread = nil

      @logger.shutdown
      @storage.shutdown
    end

    def start

      # TODO heartbeat, every x minutes, when idle, log something

      @thread_status = :running

      @thread =
        if @thread

          @thread.run

        else

          Thread.new do
            loop do

              begin

                t0 = Time.now

                Thread.stop if @thread_status == :stop
                break if @thread_status == :shutdown

                reload
                trigger_timers
                trigger_executions

                sleep [ @heart_rate - (Time.now - t0), 0 ].max

              rescue => e
# TODO enhance me
puts "-" * 80
p e
puts e.backtrace[0, 7]
puts ("-" * 80) + ' .'
$stdout.flush
              end
            end
          end
        end

      self
    end

    def stop

      @thread_status = :stop
    end

    def running?; @thread_status == :running; end
    def stopped?; ! running?; end

    def join

      @thread.join
    end

    def launch(tree, opts={})

      exid = Flor.generate_exid(
        opts[:domain] || @conf['domain'] || 'domain0',
        opts[:unit] || @conf['unit'] || 'u0')

      queue(Flor.make_launch_msg(exid, tree, opts), opts)
    end

    def queue(message, opts={})

      @storage.put_message(message)

      if to = opts[:wait]
        wait(message['exid'], %w[ failed terminated ], to)
      else
        message['exid']
      end
    end

    def notify(o)

      case o
        when Array # list of exids
          @mutex.synchronize { @exids.concat(o).uniq! } if o.any?
        when Timer
          @mutex.synchronize { @timers.push(o); @timers.sort_by!(&:ntime) }
        when Hash
          if o['consumed']
            notify_waiters(o)
          else
            @logger.notify(o)
          end
        else
          fail ArgumentError.new(
            "don't know what to do with a #{o.class} instance")
      end
    end

    protected

    def notify_waiters(message)

      @mutex.synchronize do

        to_remove = []

        @waiters.each do |w|
          remove = w.notify(message)
          to_remove << w if remove
        end

        @waiters -= to_remove
      end
    end

    def wait(exid, points, timeout)

      w = nil

      @mutex.synchronize do
        @waiters << (w = Waiter.new(exid, points, timeout, false))
          # repeat: false
      end

      w.wait
    end

    def reload

      now = Time.now

      return if @reloaded_at && (now - @reloaded_at < @reload_frequency)

      @mutex.synchronize do

        @reloaded_at = now
        @timers = load_timers
        @exids = load_exids
      end
    end

    def load_timers

      @storage.load_timers.sort_by(&:ntime)
    end

    def load_exids

      @storage.load_exids
    end

    def trigger_timers

      now = Time.now

      loop do

        timer = @timers.first
        break if timer == nil || timer.ntime > now

        @storage.trigger_timer(@timers.shift)
      end
    end

    def trigger_executions

      return if @exids.empty?

      while exid = @mutex.synchronize { @exids.shift }

        @executors = @executors.select { |e| e.alive? }
          # drop done executors

        break if @executors.size > @max_executors
        next if @executors.find { |e| e.exid == exid }

        @executors << UnitExecutor.new(self, exid).run
      end
    end
  end
end

