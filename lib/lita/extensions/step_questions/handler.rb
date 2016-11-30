module Lita
  module Extensions
    class StepQuestions
      class Handler < Lita::Handler
        route(/^.*$/, :all)

        def all(response)
          m = response.message
          question = Lita::Extensions::StepQuestions.current m
          return true unless question
          if question.receive_answer
            question.next
          elsif question.aborting?
            question.confirm_abort
            return true
          end
          true
        end

        Lita.register_handler(Handler)
      end
    end
  end
end
