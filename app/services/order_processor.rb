class OrderProcessor
  attr_accessor :order

  def initialize(order)
    @order = order
  end

  def process!
    Payment::CreditCard::Context.new(@order.total_price, params).execute!
    begin
      @order.update_attributes!(status: Order.statuses[:paid])
      @order.post_order_process!
    rescue StandardError => ex
      raise AppError::OrderCannotBeProcessed
    end
  end
end
