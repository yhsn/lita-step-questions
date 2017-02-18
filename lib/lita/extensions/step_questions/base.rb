require 'active_support'
require 'active_support/core_ext/object/blank'

module Lita
  module Extensions
    class StepQuestions
      # Base class of Step questions
      # have multiple steps
      # ex: Pizza order, customer name, pizza name, address, topping ...
      class Base
        attr_reader :index, :current_answer

        class << self
          attr_reader :steps

          def step(name, label: name.to_s.tr('_', ' ').capitalize, validate: nil, multi_line: nil, example: nil, options: nil)
            @steps ||= []
            @steps << {
              name:       name,
              label:      label,
              validate:   validate,
              multi_line: multi_line,
              example:    example,
              options:    options
            }
          end

          def continue(index, message)
            new(index, message)
          end

          def clear_all(user_id)
            # nr = named_redis(user_id)
            # ks = nr.keys '*'

            # ks.each { |k| nr.del k }
            named_redis(user_id).clear_all
          end

          def named_redis(user_id)
            ::Lita::Extensions::StepQuestions::NamedRedis.new(user_id)
          end
        end

        def initialize(index, message)
          @index       = index.to_i
          @message     = message
          @named_redis = self.class.named_redis @message.user.id
        end

        def reply_question(num)
          @message.reply "(#{num + 1}/#{self.class.steps.count})#{current_label}#{!additional_note.blank? ? "(#{additional_note})" : nil}:"
        end

        def start
          @message.reply start_message
          @named_redis.set('question_class', self.class.name)
          @named_redis.set('index', -1)
        end

        def wait_abort_confirmation
          @message.reply 'Really?(yes/no)'
          @named_redis.set('aborting', true)
        end

        def done?
          @message.body == 'done'
        end

        def abort?
          @message.body == 'abort'
        end

        def current_multiline_answer(body)
          stored = @named_redis.get('multi_line')

          if !stored.nil? && stored != ''
            stored + "\n" + body
          else
            body
          end
        end

        # return true: finish one question
        # return false: answer not acceptablle, or continue current question.
        def receive_answer
          return false if @named_redis.aborting?

          body = @message.body

          if abort?
            wait_abort_confirmation
            return false
          end

          is_multi_line = current_step[:multi_line]
          validate = current_step[:validate]
          options  = current_step[:options]

          if is_multi_line && !done?
            merged = current_multiline_answer body

            @named_redis.set('multi_line', merged)

            return false
          end

          current_answer = if is_multi_line && done?
                              @named_redis.get('multi_line')
                            else
                              body
                            end

          if validate && !((validate =~ current_answer))
            @message.reply "NG. Please answer like this: #{current_step[:example]}"
            return false
          end

          if options && !options.include?(current_answer)
            @message.reply "NG. Please answer in options (#{options.join(' ')})"
            return false
          end

          if @index > -1
            @message.reply "OK. #{current_step[:label]}: #{"\n" if is_multi_line}#{current_answer}"
          end

          @named_redis.del('multi_line') if is_multi_line && body == 'done'

          save(current_answer)

          @message.reply finish_message if self.class.steps.size == (@index + 1)

          true
        end

        def next!
          @index += 1
          return false if self.class.steps.size <= @index
          @named_redis.set('index', @index)
          reply_question @index
          true
        end

        def current_label
          return false if self.class.steps.size <= @index
          current_step[:label]
        end

        def current_step
          self.class.steps[(@index < 0 ? 0 : @index)]
        end

        def additional_note
          @options, @example, @multi_line =
            current_step.slice(:options, :example, :multi_line).values

          erb = File.read(File.expand_path('./note.erb', __dir__))
          ERB.new(erb, nil, '-').result(binding).chomp
        end

        def save(data)
          # implement in subclass
        end

        def start_message
          'This is multiple question. If you want to abort, just say "abort".'
        end

        def finish_message
          'OK. Done all questions'
        end

        def confirm_abort
          body = @message.body

          if body == 'yes'
            @message.reply 'OK. Questions aborted'
            @named_redis.del('aborting')
            finish
          elsif body == 'no'
            @message.reply 'OK. Continue questions'
            @named_redis.del('aborting')
            @message.reply "#{current_label}#{!additional_note.empty? ? "(#{additional_note})" : nil}:"
          else
            # require yes or no again
            wait_abort_confirmation
          end

        end

        def aborting?
          @named_redis.aborting?
        end

        def finish
          self.class.clear_all @message.user.id
        end
      end
    end
  end
end
