module Rhinoart
  class Railtie < Rails::Railtie

    initializer "rhinoart_railtie.add_precompile_assets" do |app|

      Rhinoart.stylesheets.each do |path, _|
        app.config.assets.precompile << path
      end

      Rhinoart.javascripts.each do |path|
        app.config.assets.precompile << path
      end

      app.config.assets.precompile += %w[
        jquery.tablesorter.js
        redactor/redactor.css
        redactor/redactor.js
        rhinoart/*.jpg
        rhinoart/*.png
      ]

    end

  end
end
