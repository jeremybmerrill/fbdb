require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AtiDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    # config.active_record.schema_format = :sql

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:3000'
        resource '*', headers: :any, methods: [:get], credentials: true
      end
      allow do
        origins 'http://pol-ad-dashboard.s3-website.us-east-2.amazonaws.com'
        resource '*', headers: :any, methods: [:get]
      end
      allow do
        origins 'http://pol-ads-dashboard.s3-website-us-east-1.amazonaws.com'
        resource '*', headers: :any, methods: [:get]
      end

      allow do
        origins 'https://dashboard.qz.ai'
        resource '*', headers: :any, methods: [:get]
      end
      allow do
        origins 'https://dashboard-frontend.qz.ai'
        resource '*', headers: :any, methods: [:get]
      end

      allow do
        origins 'https://dashboard-frontend.ad-observatory.com'
        resource '*', headers: :any, methods: [:get]
      end
      allow do
        origins 'https://dashboard.ad-observatory.com'
        resource '*', headers: :any, methods: [:get]
      end

      allow do
        origins 'https://projects.propublica.org'
        resource '/pp/*', headers: :any, methods: [:get], credentials: true
      end
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end