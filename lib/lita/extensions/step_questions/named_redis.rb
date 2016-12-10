module Lita
  module Extensions
    class StepQuestions
      class NamedRedis < ::Redis::Namespace
        def initialize
          @redis = Redis::Namespace.new("#{Lita.redis.namespace}:step-questions", redis: Redis.new)
        end

        def aborting?(user_id)
          get([user_id, 'aborting'].join(':')) != nil
        end

        def del(args)
          @redis.del args
        end
      end
    end
  end
end
