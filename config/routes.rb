Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Simple welcome page.
  root "home#index"

  # Dashboard with the live gold and silver ticker.
  get "prices" => "prices#index", as: :prices

  # Practice (dummy money) trading desk.
  get "trade" => "trading#show", as: :trading
  get "trade/live" => "trading#live", as: :trading_live       # JSON, polled every second
  post "trade/reset" => "trading#reset", as: :reset_trading
  resources :practice_trades, only: :create, path: "trade/orders" do
    post :close, on: :member                                   # POST /trade/orders/:id/close
  end
end
