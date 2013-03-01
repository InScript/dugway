require 'active_support/all'
require 'i18n'

require 'rack/builder'
require 'rack/commonlogger'
require 'better_errors'

require 'dugway/application'
require 'dugway/cart'
require 'dugway/liquifier'
require 'dugway/logger'
require 'dugway/request'
require 'dugway/store'
require 'dugway/template'
require 'dugway/theme'
require 'dugway/theme_font'
require 'dugway/extensions/time'

module Dugway
  class << self
    def application(options={})
      @@store = Store.new(options[:store] || 'dugway')
      @@theme = Theme.new(options[:customization] || {})
      @@cart = Cart.new
      @@source_dir = File.join(Dir.pwd, 'source')
      @@logger = options[:log] ? Logger.new : nil

      I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'data', 'locales', '*.yml').to_s]
      I18n.default_locale = 'en-US'
      I18n.locale = Dugway.store.locale

      Rack::Builder.app do
        use BetterErrors::Middleware
        
        BetterErrors.logger = Dugway.logger
        use Rack::CommonLogger, Dugway.logger
        
        run Application.new
      end
    end

    def store
      @@store
    end

    def theme
      @@theme
    end

    def cart
      @@cart
    end

    def source_dir
      @@source_dir
    end
    
    def logger
      @@logger
    end
  end
end
