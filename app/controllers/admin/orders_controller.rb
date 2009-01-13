class Admin::OrdersController < Admin::BaseController
  before_filter :add_ps_own_cart_txns, :only => :show

  def add_ps_own_cart_txns
    @txn_partials << 'ps_own_cart_txns'
  end
end