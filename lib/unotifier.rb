require "yaml"

require_relative "hash"
require_relative "unotifier/version"
require_relative "exceptions"
require_relative "provider"
require_relative "configuration"
require_relative "settings"

module UNotifier
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.notifications_config
    @notifications_config ||= if configuration.notifications_path.kind_of?(Array)
                                configuration.notifications_path.each_with_object({}) do |path, config|
                                  config.deep_merge!(YAML.load_file(path))
                                end
                              else
                                YAML.load_file(configuration.notifications_path)
                              end
  rescue Errno::ENOENT
    raise NotificationsConfigNotFoundError.new(configuration.notifications_path)
  end

  def self.reload!
    @configuration = nil
    @notifications_config = nil
  end

  def self.load_notification(key)
    notifications_config.dig(*key.split('.'))
  end

  def self.load_notification!(key)
    notification = load_notification(key)
    raise NotificationNotFoundError.new(key) unless notification
    notification
  end

  def self.urgency_for(key, params = {})
    config = load_notification!(key)

    if config["target"].kind_of?(Hash)
      urgency = config.dig("target", params[:target], "urgency")
      raise UnknownTargetError.new(key, params[:target]) unless urgency
      urgency
    else
      config["urgency"]
    end
  end

  def self.locale_key_for(key, params = {})
    config = load_notification!(key)

    if config["locale_options"].kind_of?(Array)
      raise EmptyLocaleKeyError.new(key) unless params[:locale_key]
      raise UnknownLocaleKeyError.new(
        key, params[:locale_key], config["locale_options"]
      ) unless config["locale_options"].include?(params[:locale_key])
      "notifications.#{key}.#{params[:locale_key]}"
    else
      "notifications.#{key}"
    end
  end

  def self.notify(key, target, params = {})
    user_settings = target.notification_settings[key]
    user_settings ||= Settings::DEFAULT_URGENCY
    locale_key = locale_key_for(key, params)
    urgency = urgency_for(key, params)

    notification = configuration.resource_class.new(
      key: key,
      target: target,
      title: configuration.localization_provider.t("#{locale_key}.title", params.merge(locale: target.locale)),
      body: configuration.localization_provider.t("#{locale_key}.body", params.merge(locale: target.locale, default: "")),
      link: params[:link],
      autohide_delay: params[:autohide_delay],
      urgency: urgency
    )
    notification.save!

    notify_with = []
    notify_with += configuration.site_providers if !params[:external_only] && notify_onsite?(notification, user_settings)
    notify_with += configuration.external_providers if !params[:onsite_only] && notify_external?(notification, user_settings)
    notify_with.each do |provider|
      title_provider_key = "#{locale_key}.#{provider.class.to_s.split("::").last}.title"
      body_provider_key  = "#{locale_key}.#{provider.class.to_s.split("::").last}.body"
      notification.title = configuration.localization_provider.t(title_provider_key, params.merge(locale: target.locale)) if configuration.localization_provider.exists?(title_provider_key)
      notification.body  = configuration.localization_provider.t(body_provider_key, params.merge(locale: target.locale, default: "")) if configuration.localization_provider.exists?(body_provider_key)
      provider.notify(notification)
    end
  end

  def self.notify_onsite(key, target, params)
    notify(key, target, params.merge(onsite_only: true))
  end

  def self.notify_external(key, target, params)
    notify(key, target, params.merge(external_only: true))
  end

  def self.notification_settings_for(target)
    user_settings = target.notification_settings
    Settings
      .grouped_by_urgency_keys_from(notifications_config)
      .each_with_object({}) do |(urgency, keys), settings|
        settings[urgency] = keys.each_with_object({}) do |(key, _), out|
          out[key] = user_settings[key] || Settings::DEFAULT_URGENCY
        end
      end
  end

  private

  def self.notify_onsite?(notification, user_settings)
    return false if notification.urgency == "optional" && user_settings == "off"
    notification.target.online?
  end

  def self.notify_external?(notification, user_settings)
    case notification.urgency
    when "immediate"
      true
    when "regular", "optional"
      user_settings == "external" && !notification.target.online?
    when "onsite"
      false
    else
      false
    end
  end
end
