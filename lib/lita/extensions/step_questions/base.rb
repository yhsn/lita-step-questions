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

          def clear_all(user_id)
            raise "user id is required!!" if user_id == nil
            named_redis(user_id).del '*'
          end

          def named_redis(user_id)
            ::Lita::Extensions::StepQuestions::NamedRedis.new(user_id)
          end
        end

        def initialize(index, message)
          @index      = index.to_i
          @message    = message
          @user       = message.user
          @named_redis = self.class.named_redis @user.id
        end

        def reply_question(num = false)
          @message.reply "(#{ num || @index + 1 }/#{ self.class.steps.count })#{ current_label }#{ additional_note.size > 0 ? "(#{ additional_note })" : nil }:"
        end

        def start
          @message.reply self.start_message
          @named_redis.set('question_class', self.class.name)
          @named_redis.set('index', -1)
        end

        def wait_abort_confirmation
          @message.reply "Really?(yes/no)"
          @named_redis.set('aborting', true)
        end

        def receive_answer
          return false if @named_redis.aborting?

          body = @message.body

          if body == 'abort'
            wait_abort_confirmation
            return false
          end

          @current_answer = if current_step[:multi_line] && body == 'done'
                              # "done" is keyword to finish muti-line question. Not append to answer.
                              @named_redis.get('multiline_answer')
                            elsif current_step[:multi_line] && body != 'done'
                              # Multi line answer saved in Redis temporary
                              temp = @named_redis.get('multiline_answer')
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
            @named_redis.set('multiline_answer', @current_answer)
            return true
          end

          if @index > -1
            @message.reply "OK. #{ self.class.steps[@index][:label] }: #{ "\n" if current_step[:multi_line] }#{ @current_answer }"
          end
          if current_step[:multi_line] && body == 'done'
            @named_redis.del('multiline_answer')
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
          @named_redis.set('index', @index)
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
            @named_redis.del('aborting')
            @message.reply "#{ current_label }#{ additional_note.size > 0 ? "(#{ additional_note })" : nil }:"
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
      end
    end
  end
end
