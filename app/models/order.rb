class Order < ActiveRecord::Base
  has_many :pagseguro_payments

  # Modify the transitions in core.
  fsm = Order.state_machines['state']

  fsm.event :next do
    transition :to => 'ready_to_transmit', :from => 'shipping_method'
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
