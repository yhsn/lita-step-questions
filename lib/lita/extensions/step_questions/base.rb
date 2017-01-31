module Lita
  module Extensions
    class StepQuestions
      class Base
        attr_accessor :index

        class << self
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

          attr_reader :steps

          def continue(index, message)
            new(index, message)
          end

          def clear_all(user_id)
            nr = named_redis(user_id)
            ks = nr.keys '*'

            ks.each { |k| nr.del k }
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
          @message.reply "(#{num + 1}/#{self.class.steps.count})#{current_label}#{!additional_note.empty? ? "(#{additional_note})" : nil}:"
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

        # return true: finish one question
        # return false: answer not acceptablle, or continue current question.
        def receive_answer
          return false if @named_redis.aborting?

          body = @message.body

          if abort?
            wait_abort_confirmation
            return false
          end

          multiline_answer = current_step[:multi_line]
          validate = current_step[:validate]
          options  = current_step[:options]

          if multiline_answer && !done?
            stored = @named_redis.get('multi_line')

            merged = if !stored.nil? && stored != ''
                       stored + "\n" + body
                     else
                       body
                     end

            @named_redis.set('multi_line', merged)

            return false
          end

          @current_answer = if multiline_answer && done?
                              @named_redis.get('multi_line')
                            else
                              body
                            end

          if validate && !((validate =~ @current_answer))
            @message.reply "NG. Please answer like this: #{current_step[:example]}"
            return false
          end

          if options && !options.include?(@current_answer)
            @message.reply "NG. Please answer in options (#{options.join(' ')})"
            return false
          end

          if @index > -1
            @message.reply "OK. #{current_step[:label]}: #{"\n" if current_step[:multi_line]}#{@current_answer}"
          end

          @named_redis.del('multi_line') if multiline_answer && body == 'done'

          save(@current_answer)

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

        attr_reader :current_answer

        def additional_note
          note = ''
          step = current_step

          if options = step[:options]
            note << 'in ' + options.join(' ')
          end

          if example = step[:example]
            note << 'example: ' + example
          end

          if step[:multi_line]
            note << 'multi message accepted. Finish by say "done"'
          end

          note
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
          elsif body == 'no'
            @message.reply 'OK. Continue questions'
            @named_redis.del('aborting')
            @message.reply "#{current_label}#{!additional_note.empty? ? "(#{additional_note})" : nil}:"
          else
            # require yes or no again
            wait_abort_confirmation
            return nil
          end

          @named_redis.set('aborting', false)
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
