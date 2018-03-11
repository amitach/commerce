module Questionable
  extend ActiveSupport::Concern

  module ClassMethods
    def qs_questionables
      @questionables ||= []
    end

    def question_for(attribute, values)
      qs_questionables << { attribute: attribute, values: values }
      qs_define_methods
    end

    def qs_define_methods
      qs_questionables.each do |config|
        config[:values].each do |s|
          define_method("#{s}?") do
            (self.send(config[:attribute]) == s)
          end
        end
      end
    end
  end
end
