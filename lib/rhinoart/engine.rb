module Rhinoart
  class Engine < ::Rails::Engine
    isolate_namespace Rhinoart

    require "mini_magick"
	require 'carrierwave'
	require 'russian'
	require 'bootstrap-datepicker-rails'
	require 'globalize'

	require "rhinoart/utils"
  end
end
