# Put your extension routes here.

map.resources :orders do |order|
  # we're kind of abusing the notion of a restful collection here but we're in the weird position of 
  # not being able to create the payment before sending the request to paypal
  order.resource :pagseguro_payment, :collection => {:successful => :post}
end  
