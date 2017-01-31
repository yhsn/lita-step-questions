module Lita
  module Extensions
    # entry point of StepQuestions
    class StepQuestions
      def self.call(payload)
        message    = payload[:message]
        extensions = payload[:route].extensions

        if !current(message) && !extensions.empty? && extensions.keys.include?(:multi_question)
          question_instance = extensions[:multi_question].new(-1, message)
          question_instance.start
        end

        true
      end

      def self.current(message)
        user_id = message.user.id
        klass = named_redis.get [user_id, 'question_class'].join(':')
        index = named_redis.get [user_id, 'index'].join(':')
        return false unless klass
        Module.const_get(klass).continue(index, message)
      end

      def self.named_redis
        @named_redis = Redis::Namespace.new(
          "#{Lita.redis.namespace}:step-questions",
          redis: Redis.new
        )
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
