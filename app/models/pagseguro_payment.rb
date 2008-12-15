class PagseguroPayment < ActiveRecord::Base
  has_many :pagseguro_txns
  belongs_to :order
  
  validates_presence_of :order
  alias :txns :pagseguro_txns

  # attr_accessible is a nightmare with attachment_fu, so use attr_protected instead.
  attr_protected :state
  
  # order state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => 'waiting_for_status_definition' do
    after_transition :to => 'payment_approved', :do => :mark_order_ready_to_ship
    after_transition :to => 'payment_canceled', :do => :cancel_order
    after_transition :to => 'status_definition_expired', :do => :cancel_order
    
    event :analyze_payment do
      transition :to => 'payment_being_analyzed', :from => 'waiting_for_status_definition'
    end
    event :wait_for_payment do
      transition :to => 'waiting_for_payment', :from => 'waiting_for_status_definition'
    end
    event :expire do
      transition :to => 'status_definition_expired', :from => 'waiting_for_status_definition'
    end
    event :cancel_payment do
      transition :to => 'payment_canceled', :from => ['payment_being_analyzed', 'waiting_for_payment']
    end
    event :approve_payment do
      transition :to => 'payment_approved', :from => ['payment_being_analyzed', 'waiting_for_payment']
    end
    event :complete_payment do
      transition :to => 'payment_completed', :from => 'payment_approved'
    end
  end

  private
  def mark_order_ready_to_ship
    self.order.approve!
  end

  def cancel_order
    self.order.cancel!
  end
end
