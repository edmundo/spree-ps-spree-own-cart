# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class PsSpreeOwnCartExtension < Spree::Extension
  version "0.99"
  description "Support for brazilian online payment service PagSeguro using Spree's own cart."
  url "http://github.com/edmundo/spree-ps-spree-own-cart/tree/master"

  def activate

    # Add support for internationalization to this extension.
    Globalite.add_localization_source(File.join(RAILS_ROOT, 'vendor/extensions/ps_spree_own_cart/lang/ui'))

  end

  def self.require_gems(config)
    config.gem 'activerecord-tableless', :lib => 'tableless'
  end
end