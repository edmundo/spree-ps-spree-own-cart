require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module OrdersControllerSpecHelper
  def valid_order_attributes
    {
    }
  end
end

describe OrdersController do
  include OrdersControllerSpecHelper

  describe "handling GET /orders/XXXXXXXXX/confirmation" do

  end

  describe "handling POST /orders/XXXXXXXXX/transmit" do

  end

  describe "handling GET /orders/XXXXXXXXX/finished" do

  end
end