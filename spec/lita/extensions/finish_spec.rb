require "spec_helper"

describe SampleHandler, lita_handler: true, additional_lita_handlers: Lita::Extensions::StepQuestions::Handler do
  before do
    registry.register_hook(:validate_route, Lita::Extensions::StepQuestions)
    LastSelectQuestion.clear_all(user.id)
  end

  context 'finish question' do
    before do
      send_command('order')
      send_message('abort')
    end

    it 'start by say "abort"' do
      expect(replies.last).to eq 'Really?(yes/no)'
    end
  end
end
