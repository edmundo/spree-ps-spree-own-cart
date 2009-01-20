class Admin::PagseguroPaymentsController < Admin::BaseController
  resource_controller
#  actions :all, :except => [:create, :new, :edit, :update, :destroy]

  belongs_to :order

end