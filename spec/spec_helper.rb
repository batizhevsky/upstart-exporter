require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'fakefs/spec_helpers'

require 'upstart-exporter'

Dir["#{ File.dirname(__FILE__) }/support/**/*.rb"].each do |f|
  require f
end

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers
end
