module Lita
  module Extensions
    class StepQuestions
      class Handler < Lita::Handler
        route(/^.*$/, :all)

        def all(response)
          m = response.message
          q = Lita::Extensions::StepQuestions.current m

          return true unless q

          if q.receive_answer
            q.finish unless q.next!
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
