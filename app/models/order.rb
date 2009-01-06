class Order < ActiveRecord::Base
  # Modify the transitions in core.
  fsm = Order.state_machines['state']

  # Delete transitions that should not be used.
  fsm.events['next'].transitions.delete_if { |t| t.options[:to] == "creditcard_payment" && t.options[:from] == "shipment" }
  fsm.events['previous'].transitions.delete_if { |t| t.options[:to] == "shipment" && t.options[:from] == "creditcard_payment" }
  fsm.events['next'].transitions.delete_if { |t| t.options[:to] == "authorized" && t.options[:from] == "creditcard_payment" }
  fsm.events['edit'].transitions.delete_if { |t| t.options[:to] == "in_progress" && t.options[:from] == "creditcard_payment" }
  fsm.events['capture'].transitions.delete_if { |t| t.options[:to] == "captured" && t.options[:from] == "authorized" }
  fsm.events['ship'].transitions.delete_if { |t| t.options[:to] == "shipped" && t.options[:from] == "captured" }

  # Delete states that should not be used.
  fsm.states.delete('creditcard_payment')
  fsm.states.delete('authorized')
  fsm.states.delete('captured')

  has_one :pagseguro_payment

  fsm.event :next do
    transition :to => 'ready_to_transmit', :from => 'shipment'
  end

  fsm.event :previous do
    transition :to => 'shipment', :from => 'ready_to_transmit'
  end

  fsm.event :edit do
    transition :to => 'in_progress', :from => 'ready_to_transmit'
  end

  fsm.event :wait_for_payment_response do
    transition :to => 'waiting_for_payment_response', :from => 'ready_to_transmit'
  end
  fsm.after_transition :to => 'waiting_for_payment_response', :do => lambda {|order| order.update_attribute(:checkout_complete, true)}

  fsm.event :approve do
    transition :to => 'ready_to_ship', :from => 'waiting_for_payment_response'
  end
  fsm.after_transition :to => 'ready_to_ship', :do => :complete_order

  fsm.event :cancel do
    transition :to => 'canceled', :from => 'waiting_for_payment_response'
  end

  fsm.event :ship do
    transition :to => 'shipped', :from => 'ready_to_ship'
  end

end
