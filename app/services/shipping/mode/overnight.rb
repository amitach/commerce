module Shipping
  module Mode
    class Overnight < Base
      def rate
        (25).round(2)
      end
    end
  end
end
