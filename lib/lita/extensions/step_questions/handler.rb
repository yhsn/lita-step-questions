module Lita
  module Extensions
    class StepQuestions
      # Handling message from user
      # Process message body and control question flow
      class Handler < Lita::Handler
        on :message_dispatched, :all
        on :unhandled_message, :all

        def all(payload)
          q = Lita::Extensions::StepQuestions.current payload[:message]

          return true unless q

          if q.receive_answer
            q.finish unless q.next!
          elsif !q.abort? && q.aborting?
            q.confirm_abort
          end

          true
        end

        Lita.register_handler(Handler)
      end
    end
  end
end
