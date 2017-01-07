require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'lita/extensions/step_questions'
require 'lita/extensions/step_questions/named_redis'
require 'lita/extensions/step_questions/base'
require 'lita/extensions/step_questions/handler'
