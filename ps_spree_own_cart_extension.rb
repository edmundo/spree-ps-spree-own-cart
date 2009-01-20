# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class PsSpreeOwnCartExtension < Spree::Extension
  version "0.99"
  description "Support for brazilian online payment service PagSeguro using Spree's own cart."
  url "http://github.com/edmundo/spree-ps-spree-own-cart/tree/master"

  def activate
    # Modify the transitions in core.
    fsm = Order.state_machines['state']

    # Delete transitions that should not be used.
    fsm.events['ship'].transitions.delete_if { |t| t.options[:to] == "shipped" && t.options[:from] == "charged" }
    fsm.events['next'].transitions.delete_if { |t| t.options[:to] == "creditcard" && t.options[:from] == "shipping_method" }
    fsm.events['next'].transitions.delete_if { |t| t.options[:to] == "charged" && t.options[:from] == "creditcard" }
    fsm.events['edit'].transitions.delete_if { |t| t.options[:to] == "in_progress" && t.options[:from] == "creditcard" }

    # Delete states that should not be used.
    fsm.states.delete('creditcard')
    fsm.states.delete('charged')
  end

  def self.require_gems(config)
    config.gem 'activerecord-tableless', :lib => 'tableless'
  end
end