module Shipping
  module Mode
    class TwoDay < Base
      def rate
        (15.75).round(2)
      end
    end
  end
end
