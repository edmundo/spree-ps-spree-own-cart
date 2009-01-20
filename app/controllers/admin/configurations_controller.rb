class Admin::ConfigurationsController < Admin::BaseController
  before_filter :add_ps_spree_own_cart_link, :only => :index

  def add_ps_spree_own_cart_link
    @extension_links << {
      :link => admin_pagseguro_settings_path ,
      :link_text => t('ext.ps_spree_own_cart.extension_name'),
      :description => t('ext.ps_spree_own_cart.extension_description')
    }
  end
end
