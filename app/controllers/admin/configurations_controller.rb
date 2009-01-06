class Admin::ConfigurationsController < Admin::BaseController
  before_filter :add_ps_spree_own_cart_link, :only => :index

  def add_ps_spree_own_cart_link
    @extension_links << {
      :link => admin_pagseguro_settings_path ,
      :link_text => Globalite.localize(:ext_ps_spree_own_cart),
      :description => Globalite.localize(:ext_ps_spree_own_cart_description)
    }
  end
end
