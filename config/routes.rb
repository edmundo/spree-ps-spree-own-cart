# Put your extension routes here.

#map.resources :orders do |order|
#  # we're kind of abusing the notion of a restful collection here but we're in the weird position of 
#  # not being able to create the payment before sending the request to paypal
#  order.resource :pagseguro_payment, :collection => {:successful => :post}
#end  

# http://minharede.redirectme.net:55000/orders/685019152/paypal_payment
# http://minharede.redirectme.net:55000/orders/685019152/paypal_payment/successful

map.resource :pagseguro_payment, :collection => {:successful => :post}

map.namespace :admin do |admin|
  admin.resource :pagseguro_settings
end

