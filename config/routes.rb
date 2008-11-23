# Put your extension routes here.

map.resource :pagseguro_payment, :collection => {:notification => :post}

map.namespace :admin do |admin|
  admin.resource :pagseguro_settings
end

