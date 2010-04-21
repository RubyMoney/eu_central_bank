$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'eu_central_bank'
require 'spec'
require 'spec/autorun'
require 'shoulda'
require 'rr'

Spec::Runner.configure do |config|
  config.mock_with :rr
end
