module Spree
  module Pagseguro
    # Singleton class to access the Pagseguro configuration object (PagseguroConfiguration.first by default) and it's preferences.
    #
    # Usage:
    #   Spree::Pagseguro::Config[:foo]                  # Returns the foo preference
    #   Spree::Pagseguro::Config[]                      # Returns a Hash with all the tax preferences
    #   Spree::Pagseguro::Config.instance               # Returns the configuration object (PagseguroConfiguration.first)
    #   Spree::Pagseguro::Config.set(preferences_hash)  # Set the tax preferences as especified in +preference_hash+
    class Config
      include Singleton
      include PreferenceAccess
    
      class << self
        def instance
          return nil unless ActiveRecord::Base.connection.tables.include?('configurations')
          PagseguroConfiguration.find_or_create_by_name("Default pagseguro configuration")
        end
      end
    end
  end
end