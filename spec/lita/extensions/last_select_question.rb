class LastSelectQuestion < Lita::Extensions::StepQuestions::Base
  step :one
  step :two, options: %w(hoge piyo)
end
