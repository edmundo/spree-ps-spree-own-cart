class Admin::BaseController < Spree::BaseController
  before_filter :add_pagseguro_tab

  private
  def add_pagseguro_tab
    @order_admin_tabs << {
      :name => 'pagseguro',
      :url => "admin_order_pagseguro_payments_url"
    }
  end
end
