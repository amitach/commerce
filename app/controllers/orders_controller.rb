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
