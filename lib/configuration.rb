module UNotifier
  class Configuration
    attr_accessor :site_providers
    attr_accessor :external_providers
    attr_accessor :resource_class
    attr_accessor :notifications_path
    attr_accessor :localization_provider

    def initialize
      @site_providers = []
      @external_providers = []
      @resource_class = nil
      @notifications_path = nil
      @localization_provider = nil
    end
  end
end
