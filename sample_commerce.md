# Sample code that looks like this

```ruby
class OrdersController < ApplicationController
  before_action :get_cart

  # process order
  def create
    @order = Order.new(order_params)

    # Add items from cart to order's ordered_items association
    @cart.ordered_items.each do |item|
      @order.ordered_items << item
    end

    # Add shipping and tax to order total
    case params[:order][:shipping_method]
    when 'ground'
      @order.total = (@order.taxed_total).round(2)
    when 'two-day'
      @order.total = @order.taxed_total + (15.75).round(2)
    when "overnight"
      @order.total = @order.taxed_total + (25).round(2)
    end

    # Process credit card
    # Create a connection to ActiveMerchant
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(
      login: ENV["AUTHORIZE_LOGIN"],
      password: ENV["AUTHORIZE_PASSWORD"]
    )

    # Get the card type
    card_type = get_card_type

    # Get credit card object from ActiveMerchant
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      number: params[:card_info][:card_number],
      month: params[:card_info][:card_expiration_month],
      year: params[:card_info][:card_expiration_year],
      verification_value: params[:card_info][:cvv],
      first_name: params[:card_info][:card_first_name],
      last_name: params[:card_info][:card_last_name],
      type: card_type
    )

    # Check if card is valid
    if credit_card.valid?

      billing_address = { name: "#{params[:billing_first_name]} #{params[:billing_last_name]}",
                          address1: params[:billing_address_line_1],
                          city: params[:billing_city], state: params[:billing_state],
                          country: 'US',zip: params[:billing_zip],
                          phone: params[:billing_phone] }

      options = { address: {}, billing_address: billing_address }

      # Make the purchase through ActiveMerchant
      charge_amount = (@order.total.to_f * 100).to_i
      response = gateway.purchase(charge_amount, credit_card, options)

      if !response.success?
        @order.errors.add(:error, "We couldn't process your credit card")
      end
    else
      @order.errors.add(:error, "Your credit card seems to be invalid")
      flash[:error] = "There was a problem processing your order. Please try again."
      render :new && return
    end

    @order.order_status = 'processed'

    if @order.save
      # get rid of cart
      Cart.destroy(session[:cart_id])
      # send order confirmation email
      OrderMailer.order_confirmation(order_params[:billing_email], session[:order_id]).deliver
      flash[:success] = "You successfully ordered!"
      redirect_to confirmation_orders_path
    else
      flash[:error] = "There was a problem processing your order. Please try again."
      render :new
    end
  end

  def order_params
    params.require(:order).permit!
  end

  def get_card_type
    length = params[:card_info][:card_number].size

    if length == 15 && number =~ /^(34|37)/
      "AMEX"
    elsif length == 16 && number =~ /^6011/
      "Discover"
    elsif length == 16 && number =~ /^5[1-5]/
      "MasterCard"
    elsif (length == 13 || length == 16) && number =~ /^4/
      "Visa"
    else
      "Unknown"
    end
  end

  def get_cart
    @cart = Cart.find(session[:cart_id])
  rescue ActiveRecord::RecordNotFound
  end
end


```
The code seems to be doing a lot of work:

> 1. Instantiate a new Order object.

```ruby
  @order = Order.new(order_params)
```

> 2. Add the items from the Cart record to the Order instance.

```ruby
# Add items from cart to order's ordered_items association
    @cart.ordered_items.each do |item|
      @order.ordered_items << item
    end
```
> 3. Add shipping and tax to the total_price of the Order instance.

```ruby
 # Add shipping and tax to order total
    case params[:order][:shipping_method]
    when 'ground'
      @order.total = (@order.taxed_total).round(2)
    when 'two-day'
      @order.total = @order.taxed_total + (15.75).round(2)
    when "overnight"
      @order.total = @order.taxed_total + (25).round(2)
    end
```

> 4. Process the user's credit card

```ruby

    # Get the card type
    card_type = get_card_type
```

> 5. Instantiate an ActiveMerchant client

```ruby
# Process credit card
    # Create a connection to ActiveMerchant
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(
      login: ENV["AUTHORIZE_LOGIN"],
      password: ENV["AUTHORIZE_PASSWORD"]
    )
       # Get credit card object from ActiveMerchant
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      number: params[:card_info][:card_number],
      month: params[:card_info][:card_expiration_month],
      year: params[:card_info][:card_expiration_year],
      verification_value: params[:card_info][:cvv],
      first_name: params[:card_info][:card_first_name],
      last_name: params[:card_info][:card_last_name],
      type: card_type
    )

```
> 6. Using ActiveMerchant check whether the credit card information is valid, if invalid, we stop the transaction and display an error to the user
```ruby
 # Check if card is valid
    if credit_card.valid?
      ...
    else
      @order.errors.add(:error, "Your credit card seems to be invalid")
      flash[:error] = "There was a problem processing your order. Please try again."
      render :new && return
    end
```

> 7. If the credit card is valid, we charge the card via ActiveMerchant, if charge fails, we stop the transaction and display an error to the user

```ruby
if credit_card.valid?
      billing_address = { name: "#{params[:billing_first_name]} #{params[:billing_last_name]}",
                          address1: params[:billing_address_line_1],
                          city: params[:billing_city], state: params[:billing_state],
                          country: 'US',zip: params[:billing_zip],
                          phone: params[:billing_phone] }

      options = { address: {}, billing_address: billing_address }

      # Make the purchase through ActiveMerchant
      charge_amount = (@order.total.to_f * 100).to_i
      response = gateway.purchase(charge_amount, credit_card, options)

      if !response.success?
        @order.errors.add(:error, "We couldn't process your credit card")
      end
  else
      ...
  end
```
> 8. Set the Order's status attribute to processed and save the Order
```ruby
@order.order_status = 'processed'

    if @order.save
      # get rid of cart
      Cart.destroy(session[:cart_id])
      # send order confirmation email
      OrderMailer.order_confirmation(order_params[:billing_email], session[:order_id]).deliver
      flash[:success] = "You successfully ordered!"
      redirect_to confirmation_orders_path
    else
      flash[:error] = "There was a problem processing your order. Please try again."
      render :new
    end

```
> And then there are some helper methods as well

```ruby
def order_params
    params.require(:order).permit!
  end

  def get_card_type
    length = params[:card_info][:card_number].size

    if length == 15 && number =~ /^(34|37)/
      "AMEX"
    elsif length == 16 && number =~ /^6011/
      "Discover"
    elsif length == 16 && number =~ /^5[1-5]/
      "MasterCard"
    elsif (length == 13 || length == 16) && number =~ /^4/
      "Visa"
    else
      "Unknown"
    end
  end

  def get_cart
    @cart = Cart.find(session[:cart_id])
  rescue ActiveRecord::RecordNotFound
  end
```
## Now lets try to follow some coding conventions and techniques to sort of refactor the app and achieve the same thing.

> SOME MAGIC

## This is how the code looks now


```ruby
class OrdersController < ApplicationController
  before_action :load_cart

  def create
    @order = Order.create(
        cart:            @cart,
        shipping_method: params[:order][:shipping_method]
    )
    if @order.valid?
      OrderProcessor.new(@order, params).process!
      flash[:success] = I18n.t("response.order_created")
      redirect_to confirmation_orders_path
    else
      flash[:error] = I18n.t("response.order_failed")
      render :new
    end
  end

  private

    def order_params
      params.require(:order).permit!
    end

    def load_cart
      @cart = current_user.try(:active_cart) || Cart.find_by_id(session[:cart_id])
      raise AppError::CartNotFound if @cart.blank?
    end
end
```


We will go through this step by step

> Use associations / introduce new objects if necessary


The user model looks like this
```ruby
class User < ApplicationRecord
  has_many :carts
  has_one :active_cart, -> { where(status: 'active').order(id: :desc) }, class_name: :Cart
end
```


The order model looks like this

> We use associations, ORM callbacks

```ruby
# Order module implements the core business logic to calculate the price for an order
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

  #including questionable and defining question_for will define the ? methods for all the attributes
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
    sum = 0
    products.map{|product| sum += (product.price * product.quantity) }
    sum
  end

  def calculate_total_price
    self.total_price = shipping_charges + total_product_prices
  end

  def post_order_process!
    cart.deactivate!
    OrderMailer.order_confirmation(cart.email, id).deliver_later!
  end
end
```


The cart model

```ruby
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
```

The cart product join table
```ruby
class CartProduct < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates_presence_of :cart, :product
end
```


Using service objects

> app/services/order_processor.rb

```ruby
class OrderProcessor
  attr_accessor :order

  def initialize(order, params)
    @order = order
    @params = params
  end

  def process!
    Payment::CreditCard::Context.new(order.total_price, @params).execute!
    begin
      order.update_attributes!(status: Order.statuses[:paid])
      order.post_order_process!
    rescue StandardError => _ex
      raise AppError::OrderCannotBeProcessed
    end
  end
end
```


Payment context class

```ruby
module Payment
  module CreditCard
    class Context
      attr_accessor :amount, :opts, :via

      def initialize(amount, opts, via=Payment::CreditCard::ActiveMerchant)
        @amount = amount
        @opts = opts
        @via = via
      end

      def execute!
        client = via.new(amount, opts)
        client.validate
        client.purchase!
      end
    end
  end
end

```


```ruby
#
# This module implements how a credit card is selected and handled
# Uses strategy pattern to make a purchase
#
# Every derived class should implement the client/validate/purchase! methods
# @params: amount, opts, card
#
# The card type is selected using command pattern
module Payment
  module CreditCard
    class Base
      attr_accessor :amount,
                    :card,
                    :opts,
                    :via

      def initialize(amount, opts)
        @amount = amount.to_f * 100
        @opts = opts
        @card = opts[:card]
      end

      def validate
        raise NotImplementedError
      end

      def purchase!
        raise NotImplementedError
      end

      def client
        raise NotImplementedError
      end

      def commands
        amex = AmexCommand.new
        discover = DiscoverCommand.new
        master_card = MasterCardCommand.new
        visa = VisaCommand.new
        unknown = UnknownCommand.new
        [ amex, discover, master_card, visa, unknown ]
      end

      def commands_for_input(number)
        commands.find{|command| command.match?(number)}
      end

      def card_type
        number = card[:card_number]
        commands_for_input(number).execute
      end
    end

    class ::AmexCommand
      def match?(number)
        number.length == 15 && number =~ /^(34|37)/
      end

      def execute
        'Amex'
      end
    end

    class ::DiscoverCommand
      def match?(number)
        number.length == 16 && number =~ /^6011/
      end

      def execute
        'Discover'
      end
    end

    class ::MasterCardCommand
      def match?(number)
        number.length == 16 && number =~ /^5[1-5]/
      end

      def execute
        'MasterCard'
      end
    end

    class ::VisaCommand
      def match?(number)
        (number.length == 13 || number.length == 16) && number =~ /^4/
      end

      def execute
        'Visa'
      end
    end

    class ::UnknownCommand
      def match?(_number)
        true
      end

      def execute
        'Unkown'
      end
    end
  end
end
```

> Introducing the active merchant class that inherits from the base above

```ruby
module Payment
  module CreditCard
    class ActiveMerchant < Base

      def validate
        raise AppError::CreditCardInvalid unless credit_card.valid?
      end

      def purchase!
        unless client.purchase(amount, credit_card, opts).success?
          raise AppError::CreditCardUnprocessable
        end
        true
      end

      def client
        @client ||= ActiveMerchant::Billing::AuthorizeNetGateway.new(
          login: ENV["AUTHORIZE_LOGIN"],
          password: ENV["AUTHORIZE_PASSWORD"]
        )
      end

      private

      def credit_card
        @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
          number: card[:card_number],
          month: card[:card_expiration_month],
          year: card[:card_expiration_year],
          verification_value: card[:cvv],
          first_name: card[:card_first_name],
          last_name: card[:card_last_name],
          type: card_type
        )
      end
    end
  end
end
```

Now onto the shipping modules

Use of basic inheritance

```ruby
module Shipping
  module Mode
    class Base
      def rate
        raise NotImplementedError, 'Ask the subclass for the rate'
      end
    end
  end
end

module Shipping
  module Mode
    class Ground < Base
      def rate
        0
      end
    end
  end
end

module Shipping
  module Mode
    class Overnight < Base
      def rate
        (25).round(2)
      end
    end
  end
end

module Shipping
  module Mode
    class TwoDay < Base
      def rate
        (15.75).round(2)
      end
    end
  end
end

```
