require 'lita-step-questions'
require 'lita/rspec'
require 'pry'
require 'simplecov'
require 'simplecov-console'

require './spec/lita/extensions/pizza_order_question.rb'
require './spec/lita/extensions/original_message_question.rb'
require './spec/lita/extensions/last_select_question.rb'
require './spec/lita/extensions/sample_handler.rb'

# A compatibility mode is provided for older plugins upgrading from Lita 3. Since this plugin
# was generated with Lita 4, the compatibility mode should be left disabled.
Lita.version_3_compatibility_mode = false

SimpleCov.start do
  add_filter "/vendor/"
end
SimpleCov.formatter = SimpleCov::Formatter::Console
