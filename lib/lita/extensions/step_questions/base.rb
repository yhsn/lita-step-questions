module Lita
  module Extensions
    class StepQuestions
      class Base
        attr_accessor :index

        class << self
          def step(name, label: name.to_s.gsub('_', ' ').capitalize, validate: false, multi_line: false, example: false, options: false)
            @steps ||= []
            @steps << {
              name:       name,
              label:      label,
              validate:   validate,
              multi_line: multi_line,
              example:    example,
              options:    options,
            }

            def steps
              @steps
            end

            def continue(index, message)
              self.new(index, message)
            end
          end

          def clear_all
            named_redis.del '*'
          end

          def named_redis
            ::Lita::Extensions::StepQuestions::NamedRedis.new
          end
        end

        def initialize(index, message)
          @index = index.to_i
          @message = message
          @user = message.user
        end

        def reply_question(num = false)
          @message.reply "(#{ num || @index + 1 }/#{ self.class.steps.count })#{ current_label }#{ additional_note.size > 0 ? "(#{ additional_note })" : nil }:"
        end

        def start
          @message.reply self.start_message
          reply_question(1)
          named_redis.set([@user.id, 'question_class'].join(':'), self.class.name)
          named_redis.set([@user.id, 'index'].join(':'), -1)
        end

        def wait_abort_confirmation
          @message.reply "Really?(yes/no)"
          named_redis.set([@user.id, 'aborting'].join(':'), true)
        end

        def receive_answer
          return false if named_redis.aborting?(@message.user.id)

          body = @message.body

          if body == 'abort'
            wait_abort_confirmation
            return false
          end

          @current_answer = if current_step[:multi_line] && body == 'done'
                              # "done" is keyword to finish muti-line question. Not append to answer.
                              named_redis.get([@user.id, 'multiline_answer'].join(':'))
                            elsif current_step[:multi_line] && body != 'done'
                              # Multi line answer saved in Redis temporary
                              temp = named_redis.get([@user.id, 'multiline_answer'].join(':'))
                              (temp ? temp + "\n" + body : body)
                            else
                              @message.body
                            end

          if current_step[:validate] && not(current_step[:validate] =~ @current_answer)
            @message.reply "NG. Please answer like this: #{current_step[:example]}"
            return false
          end

          if current_step[:options] && not(current_step[:options].include? @current_answer)
            @message.reply "NG. Please answer in options (#{current_step[:options].join(' ')})"
            return false
          end

          if current_step[:multi_line] && body != 'done'
            named_redis.set([@user.id, 'multiline_answer'].join(':'), @current_answer)
            return true
          end

          @message.reply "OK. #{ self.class.steps[@index][:label] }: #{ "\n" if current_step[:multi_line] }#{ @current_answer }"
          if current_step[:multi_line] && body == 'done'
            named_redis.del([@user.id, 'multiline_answer'].join(':'))
          end
          save(@current_answer)

          if self.class.steps.size == (@index + 1)
            @message.reply self.finish_message
          end
          true
        end

        def next
          @index += 1
          return false if self.class.steps.size <= @index
          named_redis.set([@user.id, 'index'].join(':'), @index)
          reply_question
        end

        def current_label
          return false if self.class.steps.size <= @index
          current_step[:label]
        end

        def current_step
          self.class.steps[(@index < 0 ? 0 : @index)]
        end

        def current_answer
          @current_answer
        end

        def additional_note
          note = ""

          if options = current_step[:options]
            note << 'in ' + options.join(' ')
          end
          if options = current_step[:example]
            note << 'example: ' + current_step[:example]
          end
          if options = current_step[:multi_line]
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
          if @message.body == 'yes'
            @message.reply 'OK. Questions aborted'
          elsif @message.body == 'no'
            @message.reply 'OK. Continue questions'
            named_redis.del([@user.id, 'aborting'].join(':'))
            @message.reply "#{ current_label }#{ additional_note.size > 0 ? "(#{ additional_note })" : nil }:"
          else
            # require yes or no again
            wait_abort_confirmation
            return nil
          end

          named_redis.set([@user.id, 'aborting'].join(':'), false)
        end

        def abort!
          named_redis.del [@user.id, 'index'].join(':')
          named_redis.del [@user.id, 'question_class'].join(':')
        end

        def named_redis
          @named_redis ||= self.class.named_redis
        end

        def aborting?
          named_redis.aborting? @message.user.id
        end
      end
    end
  end
end
