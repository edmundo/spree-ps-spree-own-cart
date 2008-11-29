class Admin::PagseguroSettingsController < Admin::BaseController

  def update
    Spree::Pagseguro::Config.set(params[:preferences])
    
    respond_to do |format|
      format.html {
        redirect_to admin_pagseguro_settings_path
      }
    end
  end

end
