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

            def continue(index, response)
              self.new(index, response)
            end
          end

          def clear_all
            named_redis = Redis::Namespace.new("#{Lita.redis.namespace}:step-questions", redis: Redis.new)
            named_redis.del '*'
          end
        end

        def initialize(index, message)
          @index = index.to_i
          @message = message
          @user = message.user
        end

        def start
          @message.reply 'This is multiple question. If you want to abort, just say "abort".'
          @message.reply self.class.steps.first[:label] + ':'
          named_redis.set([@user.id, 'question_class'].join(':'), self.class.name)
          named_redis.set([@user.id, 'index'].join(':'), -1)
        end

        def add_answer(response)
          body = response.message.body
          @current_answer = if current_step[:multi_line] && body == 'done'
                              # "done" is keyword to finish muti-line question. Not append to answer.
                              named_redis.get([@user.id, 'multiline_answer'].join(':'))
                            elsif current_step[:multi_line] && body != 'done'
                              # Multi line answer saved in Redis temporary
                              temp = named_redis.get([@user.id, 'multiline_answer'].join(':'))
                              (temp ? temp + "\n" + body : body)
                            else
                              response.message.body
                            end

          if current_step[:validate] && not(current_step[:validate] =~ @current_answer)
            response.reply "NG. Please answer like this: #{current_step[:example]}"
            return false
          end

          if current_step[:options] && not(current_step[:options].include? @current_answer)
            response.reply "NG. Please answer in options (#{current_step[:options].join(' ')})"
            return false
          end

          if current_step[:multi_line] && body != 'done'
            named_redis.set([@user.id, 'multiline_answer'].join(':'), @current_answer)
            return true
          end

          response.reply "OK. #{ self.class.steps[@index][:label] }: #{ "\n" if current_step[:multi_line] }#{ @current_answer }"
          if current_step[:multi_line] && body == 'done'
            named_redis.del([@user.id, 'multiline_answer'].join(':'))
          end
          save(@current_answer)

          if self.class.steps.size == (@index + 1)
            response.reply 'OK. Done all questions'
          end
          true
        end

        def next
          @index += 1
          return false if self.class.steps.size <= @index
          named_redis.set([@user.id, 'index'].join(':'), @index)
          @message.reply "#{ current_label }#{ additional_note.size > 0 ? "(#{ additional_note })" : nil }:"
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

        private
          def named_redis
            @named_redis ||= Redis::Namespace.new("#{Lita.redis.namespace}:step-questions", redis: Redis.new)
          end
      end
    end
  end
end
