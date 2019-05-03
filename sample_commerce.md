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
