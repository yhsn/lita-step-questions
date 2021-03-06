module Lita
  module Extensions
    class StepQuestions
      # redis wrapper with namespace
      class NamedRedis
        def initialize(user_id)
          @redis = ::Redis::Namespace.new("#{Lita.redis.namespace}:step-questions:#{user_id}", redis: Redis.new)
        end

        def aborting?
          @redis.get('aborting') == 'true'
        end

        def del(args)
          @redis.del args
        end

        def set(key, value)
          @redis.set key, value
        end

        def get(key)
          @redis.get key
        end

        def keys(term)
          @redis.keys term
        end

        def clear_all
          keys('*').each { |key| del(key) }
        end
      end
    end
  end
end
