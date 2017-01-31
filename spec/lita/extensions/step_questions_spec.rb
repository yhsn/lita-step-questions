require 'spec_helper'

describe SampleHandler, lita_handler: true, additional_lita_handlers: Lita::Extensions::StepQuestions::Handler do
  before do
    registry.register_hook(:validate_route, Lita::Extensions::StepQuestions)
    PizzaOrderQuestion.clear_all(user.id)
    OriginalMessageQuestion.clear_all(user.id)
  end

  context 'route not have multi question' do
    it 'not start multi question' do
      send_command('menu')
      expect(replies.last).to eq 'tomato teriyaki ebi-mayo'
    end
  end

  context 'route have multi question' do
    context 'start multi question' do
      before { send_command('order') }

      it 'say default description first' do
        expect(replies.first).to eq 'This is multiple question. If you want to abort, just say "abort".'
      end

      it 'say start message after description' do
        expect(replies.last).to eq '(1/5)your name:'
      end

      it 'do not get answer' do
        expect(replies).not_to include /OK/
      end

      it 'reply question once' do
        expect(replies.select { |r| /your name/ === r }.count).to eq 1
      end
    end
  end

  context 'continue questions' do
    subject { replies.last }
    before { send_command('order') }
    let(:answers) do
      [
        'john doe',
        'kanto, masara town 1-1-2',
        'tomato',
        '12312341234',
        'first line',
        'second lie'
      ]
    end

    context 'recieve answer' do
      before { send_message('john doe', privately: true) }

      it 'do next question by capitalized step name if label not specified' do
        is_expected.to eq '(2/5)Address:'
      end

      it 'say label and recieved answer' do
        expect(replies[-2]).to eq 'OK. your name: john doe'
      end
    end

    context 'do select question' do
      before do
        answers[0..1].each { |a| send_message(a, privately: true) }
      end

      it 'question by label and options' do
        is_expected.to eq '(3/5)Pizza kind(in tomato teriyaki ebi-mayo):'
      end

      it 'accept answer in options and continue' do
        send_message('tomato', privately: true)
        expect(replies[-2]).to eq 'OK. Pizza kind: tomato'
      end

      it 'reject answer not in options' do
        send_message('tacos', privately: true)
        is_expected.to eq 'NG. Please answer in options (tomato teriyaki ebi-mayo)'
      end

      it 'accept answer in options after reject and continue' do
        send_message('tacos', privately: true)
        send_message('teriyaki', privately: true)
        expect(replies[-2]).to eq 'OK. Pizza kind: teriyaki'
      end
    end

    context 'do question with validation' do
      before do
        answers[0..2].each { |a| send_message(a, privately: true) }
      end

      it 'question with answer example' do
        is_expected.to eq '(4/5)Phone number(example: 00012345678):'
      end

      it 'accept valid answer' do
        send_message('12312341234', privately: true)
        expect(replies[-2]).to eq 'OK. Phone number: 12312341234'
      end

      it 'reject invalid answer' do
        send_message('9999999999999999999999', privately: true)
        is_expected.to eq 'NG. Please answer like this: 00012345678'
      end

      it 'accept valid answer after reject' do
        send_message('9999999999999999999999', privately: true)
        send_message('12312341234', privately: true)
        expect(replies[-2]).to eq 'OK. Phone number: 12312341234'
      end
    end

    context 'multi message question' do
      before do
        answers[0..3].each { |a| send_message(a, privately: true) }
      end

      it 'start question with question and description for multi message question' do
        is_expected.to eq '(5/5)Comment(multi message accepted. Finish by say "done"):'
      end

      it 'accept multi message answer' do
        send_message('line one', privately: true)
        send_message('line two', privately: true)
        is_expected.not_to include 'OK. Comment:'
      end

      it 'finish accept answer recieve "done"' do
        send_message('line one', privately: true)
        send_message('line two', privately: true)
        send_message('done', privately: true)
        expect(replies[-2]).to eq "OK. Comment: \nline one\nline two"
      end
    end

    context 'finish questions' do
      before do
        answers.each { |a| send_message(a, privately: true) }
        send_message('done', privately: true)
      end

      it 'finish by all questions done' do
        is_expected.to include 'OK. Done all questions'
      end

      it 'not continue question after questions finished' do
        send_message('hoge', privately: true)
        is_expected.to include 'OK. Done all questions'
      end
    end
  end

  context 'question has original messages' do
    before do
      send_command('message')
    end

    it 'start with original message' do
      expect(replies.first).to eq 'It is start message'
      expect(replies.last).to eq '(1/2)One:'
    end

    it 'finish with original message' do
      send_message('one')
      send_message('two')
      expect(replies.last).to eq 'It is finish message'
    end
  end
end
