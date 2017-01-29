module Lita
  module Extensions
    class StepQuestions
      class Handler < Lita::Handler
        on :message_dispatched, :all
        on :unhandled_message, :all

        def all(payload)
          m = payload[:message]
          q = Lita::Extensions::StepQuestions.current m

          return true unless q

          if q.receive_answer
            q.finish unless q.next!
            return
          elsif q.aborting?
            q.confirm_abort
          end

          true
        end

        Lita.register_handler(Handler)
      end
    end
  end
end
