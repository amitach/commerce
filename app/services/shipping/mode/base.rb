module Shipping
  module Mode
    class Base
      def rate
        raise NotImplementedError, 'Ask the subclass for the rate'
      end
    end
  end
end
