# frozen_string_literal: true

require 'simplecov'
require 'coveralls'
SimpleCov.start do
  add_filter 'spec'
  add_filter 'lib/punk/commands/auth.rb'
  add_filter 'lib/punk/commands/generate.rb'
  add_filter 'lib/punk/commands/http.rb'
  add_filter 'lib/punk/commands/list.rb'
  add_filter 'lib/punk/core/commands.rb'
  add_filter 'lib/punk/framework/command.rb'
  add_filter 'lib/punk/plugins/cors.rb'
  add_filter 'lib/punk/plugins/ssl.rb'
  add_filter 'lib/punk/startup/logger.rb'
end
Coveralls.wear!

require_relative '../lib/rndb'
