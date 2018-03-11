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

      def validate!
        raise NotImplementedError
      end

      def purchase!
        raise NotImplementedError
      end

      def client!
        raise NotImplementedError
      end

      def card_type
        length = card[:card_number].size
        if length == 15 && number =~ /^(34|37)/
          'AMEX'
        elsif length == 16 && number =~ /^6011/
          'Discover'
        elsif length == 16 && number =~ /^5[1-5]/
          'MasterCard'
        elsif (length == 13 || length == 16) && number =~ /^4/
          'Visa'
        else
          'Unknown'
        end
      end
    end
  end
end
