class PizzaOrderQuestion < Lita::Extensions::StepQuestions::Base
  step :name, label: 'your name'
  step :address
  step :pizza_kind, options: %w(tomato teriyaki ebi-mayo)
  step :phone_number, validate: /^[0-9]{11}$/, example: '00012345678'
  step :comment, multi_line: true
end
