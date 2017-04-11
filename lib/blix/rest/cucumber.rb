ENV['RACK_ENV'] = 'test'

require 'cucumber'
require 'blix/rest'
require 'blix/rest/cucumber/world'
require 'blix/rest/cucumber/hooks'
require 'blix/rest/cucumber/request_steps'
require 'blix/rest/cucumber/resource_steps'