module Lita
  module Extensions
    class StepQuestions
      class Handler < Lita::Handler
        route(/^.*$/, :all)

        def all(response)
          question = Lita::Extensions::StepQuestions.current(response)
          return true unless question
          if question.receive_answer(response)
            question.next
          elsif question.aborting?
            question.confirm_abort(response)
            return true
          end
          true
        end

        Lita.register_handler(Handler)
      end
    end
  end
end
