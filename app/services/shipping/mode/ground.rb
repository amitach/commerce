module Shipping
  module Mode
    class Ground < Base
      def rate
        0
      end
    end
  end
end
