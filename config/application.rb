require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Csl
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    require 'ext/string'
    require 'ext/hash'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_adapter = :active_elastic_job

    def model_classes
      filenames = Dir[Rails.root.join('app/models/**/*.rb').to_s]
      filenames.select do |filename|
        filename !~ /\/concerns\//
      end.map do |filename|
        klass = filename.gsub(/(^.+models\/|\.rb$)/, '').camelize.constantize
        klass.ancestors.include?(Indexable) ? klass : nil
      end.compact
    end

    config.aws_credentials = {
      access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region:            'us-east-1'
    }

    # Rails.autoloaders.log!
  end
end
