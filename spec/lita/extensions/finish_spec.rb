require "spec_helper"

describe SampleHandler, lita_handler: true, additional_lita_handlers: Lita::Extensions::StepQuestions::Handler do
  before do
    registry.register_hook(:validate_route, Lita::Extensions::StepQuestions)
    LastSelectQuestion.clear_all(user.id)
  end

  context 'finish questions has select question at last' do
    before do
      send_command('last_select')
      send_message('a')
      send_message('hoge')
    end

    it 'finish by all questions done' do
      expect(replies.last).to include 'OK. Done all questions'
    end

    it 'not continue question after questions finished' do
      count_at_finished = replies.size
      send_message('hoge')
      expect(count_at_finished).to eq replies.size
    end
  end
end
