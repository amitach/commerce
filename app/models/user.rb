class User < ApplicationRecord
  has_many :carts
  has_one :active_cart, -> { where(status: 'active').order(id: :desc) }, class_name: :Cart
end
