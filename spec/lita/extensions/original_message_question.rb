class OriginalMessageQuestion < Lita::Extensions::StepQuestions::Base
  step :one
  step :two

  def start_message
    'It is start message'
  end

  def finish_message
    'It is finish message'
  end
end
