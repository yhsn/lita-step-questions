module Lita
  module Extensions
    class StepQuestions
      class Handler < Lita::Handler
        route(/^.*$/, :all)

        def all(response)
          question = Lita::Extensions::StepQuestions.current(response)
          if question && question.add_answer(response)
            question.next
          end
          true
        end

        Lita.register_handler(Handler)
      end
    end
  end
end
