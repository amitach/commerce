class Order < ApplicationRecord
  belongs_to :cart
  has_many :cart_products, through: :cart
  has_many :products, through: :cart_products
  before_validation(on: [:create, :update]) { calculate_total_price }
  after_commit :post_order_process!, on: :update

  class << self
    def statuses
      %w(new paid shipped delivered cancelled)
    end

    def shipping_methods
      %w(ground two_day overnight)
    end
  end

  include Questionable
  question_for :status, statuses
  question_for :shipping_method, shipping_methods

  validates_presence_of :cart, :total_price, :status, :shipping_method
  validates_inclusion_of :status, in: statuses
  validates_inclusion_of :shipping_method, in: shipping_methods

  def shipping_charges
    "Shipping::Mode::#{shipping_method.capitalize}".constantize.new.rate
  end

  def total_product_prices
    products.sum(&:price)
  end

  def calculate_total_price
    self.total_price = shipping_charges + total_product_prices
  end

  def post_order_process!
    cart.deactivate!
    OrderMailer.order_confirmation(cart.email, id).deliver_later!
  end
end
