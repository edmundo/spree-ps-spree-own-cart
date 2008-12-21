require File.dirname(__FILE__) + '/../spec_helper'

module OrderSpecHelper
  
  def valid_order_attributes
    {
    }
  end
end


describe Order do
  include OrderSpecHelper

  describe "making transitions" do
  end
 
end
