require "simplecov"
SimpleCov.start

require_relative '../lib/is-enum'

RSpec.configure do |config|
  config.order = :random
  config.disable_monkey_patching!
end

class Alpha < IS::Enum

  define :alpha, 10
  define :beta, 20
  define :bi, 20
  define :Gamma, 30
  define :g_letter, alias: :Gamma

end
