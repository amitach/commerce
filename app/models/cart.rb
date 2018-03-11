class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_products
  has_many :products, through: :cart_products
  has_one :order

  class << self
    def statuses
      %w(active converted)
    end
  end
  validates_presence_of :user, :status
  validates_inclusion_of :status, in: statuses

  include Questionable
  question_for :status, statuses

  delegate :email, to: :user
end
