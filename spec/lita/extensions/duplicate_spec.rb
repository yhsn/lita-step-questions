require 'spec_helper'

describe SampleHandler, lita_handler: true, additional_lita_handlers: Lita::Extensions::StepQuestions::Handler do
  before do
    registry.register_hook(:validate_route, Lita::Extensions::StepQuestions)
    LastSelectQuestion.clear_all(user.id)
  end

  context 'receive command two times' do
    before do
      send_command('order')
      send_command('message')
    end

    it 'not start second session' do
      expect(replies.last).not_to include '(1/2)One:'
    end
  end
end
