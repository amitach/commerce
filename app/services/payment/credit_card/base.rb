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
