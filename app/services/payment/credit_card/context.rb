module Payment
  module CreditCard
    class Context

      def initialize(amount, opts, via=Payment::CreditCard::ActiveMerchant)
        @amount = amount
        @opts = opts
        @via = via
      end

      def execute!
        client = via.new(amount, opts)
        client.validate!
        client.purchase!
      end
    end
  end
end
