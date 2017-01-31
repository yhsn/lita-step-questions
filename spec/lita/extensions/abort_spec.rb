require 'spec_helper'

describe SampleHandler, lita_handler: true, additional_lita_handlers: Lita::Extensions::StepQuestions::Handler do
  before do
    registry.register_hook(:validate_route, Lita::Extensions::StepQuestions)
    PizzaOrderQuestion.clear_all(user.id)
    OriginalMessageQuestion.clear_all(user.id)
  end

  context 'abort question' do
    before do
      send_command('order')
      send_message('abort')
    end

    it 'start by say "abort"' do
      expect(replies.last).to eq 'Really?(yes/no)'
    end

    context 'finish question by confirm "yes"' do
      before { send_message('yes') }

      it { expect(replies.last).to eq 'OK. Questions aborted' }
    end

    context 'not finish question by answer "no"' do
      before { send_message('no') }

      it 'reply not aborting question' do
        expect(replies[-2]).to eq 'OK. Continue questions'
      end

      it 'repeat current question' do
        expect(replies.last).to eq 'your name:'
      end
    end
  end

  context 'normal response after abort question' do
    before do
      send_command('order')
      send_message('abort')
      send_message('yes')
    end

    it 'not repleat abort confirmation' do
      send_command('order')
      expect(replies.last).not_to eq 'Really?(yes/no)'
    end
  end
end
