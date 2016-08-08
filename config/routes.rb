Rails.application.routes.draw do

  namespace :admin do
    resources :station_infos
  end

  namespace :api do
    resources :guarantes, only: [:index]
  end
end
