module Payment
  module CreditCard
    class ActiveMerchant < Base

      def validate!
        raise AppError::CreditCardInvalid unless credit_card.valid?
      end

      def purchase!
        unless client!.purchase(amount, credit_card, opts).success?
          raise AppError::CreditCardUnprocessable
        end
        true
      end

      def client!
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
