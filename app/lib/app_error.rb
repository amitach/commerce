# This is a generic class to raise any kind of custom error
# These errors should be configured in the errors.en.yml file inside of the 'error' section
# After configuration, the error can be raised as follows.

# raise ApplicationError::ImpsTransactionFailed as opposed to raise 'The IMPS transaction failed to process'

# This module should be used as the central point for raising custom errors so that errors
# and their messages as well as integer codes are more easily manageable across the application.

class AppError < StandardError
  attr_accessor :config, :code, :http_code, :message, :name

  def initialize(config)
    @config = config
    @code = config[:code]
    @action = config[:action]
    @message = config[:message]
    @name = config[:name]
  end

  def message_params(params)
    config[:message] = self.class.t(config[:name], params)[:message]
    self.message = config[:message]
    self
  end

  class << self
    def const_missing(name)
      I18n.reload!
      e = t(name)
      if e.is_a? Hash
        e[:name] = name
        return AppError.new(e)
      else
        super
      end
    end

    def t(error_name, message_params=nil)
      err = I18n.t("error.#{error_name.to_s.underscore}")
      if message_params
        err[:message] = I18n.t("error.#{error_name.to_s.underscore}.message", message_params)
      end
      err
    end
  end
end
