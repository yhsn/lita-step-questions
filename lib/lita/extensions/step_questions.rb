module Lita
  module Extensions
    class StepQuestions
      def self.call(payload)
        message = payload[:message]
        extensions = payload[:route].extensions
        if extensions.size > 0 && extensions.keys.include?(:multi_question)
          extensions[:multi_question].new(-1, message).start
          Lita.register_handler(Handler)
        end

        true
      end

      def self.current(message)
        klass = named_redis.get [message.user.id, 'question_class'].join(':')
        index = named_redis.get [message.user.id, 'index'].join(':')
        return false if klass.nil?
        Module.const_get(klass).continue(index, message)
      end

      def self.named_redis
        @named_redis = Redis::Namespace.new("#{Lita.redis.namespace}:step-questions", redis: Redis.new)
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
