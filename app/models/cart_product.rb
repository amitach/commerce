class CartProduct < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_presence_of :cart, :product
end
