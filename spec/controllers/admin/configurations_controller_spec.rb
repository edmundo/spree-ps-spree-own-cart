require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::ConfigurationsController do

  it "should get the configuration's index page including this extension's link" do
    get "index"
    response.should be_success
    response.should render_template("index")
    controller.should respond_to("add_ps_spree_own_cart_link")
  end
  
end
