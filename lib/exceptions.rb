module UNotifier
  class UNotifierError < StandardError; end

  class NotificationsConfigNotFoundError < UNotifierError
    attr_reader :path, :absolute_path

    def initialize(path)
      @path = path
      @absolute_path = File.expand_path(@path)
      message = "Configuration file not found at #{@absolute_path}"
      super(message)
    end
  end

  class NotificationNotFoundError < UNotifierError
    attr_reader :key

    def initialize(key)
      @key = key
      message = "Notification with key '#{@key}' not found"
      super(message)
    end
  end

  class UnknownTargetError < UNotifierError
    attr_reader :key, :target

    def initialize(key, target)
      @key = key
      @target = target
      message = "Unknown target '#{@target}' for notification '#{@key}'"
      super(message)
    end
  end

  class EmptyLocaleKeyError < UNotifierError
    attr_reader :key

    def initialize(key)
      @key = key
      message = ":locale_key parameter is required for fetching '#{key}' locale"
      super(message)
    end
  end

  class UnknownLocaleKeyError < UNotifierError
    attr_reader :key, :locale_key, :options

    def initialize(key, locale_key, options)
      @key = key
      @locale_key = locale_key
      @options = options
      message = "Unkown locale key '#{@locale_key}' for '#{@key}'. Available options: #{@options}"
      super(message)
    end
  end
end
