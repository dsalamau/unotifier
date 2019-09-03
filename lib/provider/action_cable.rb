module UNotifier
  module Provider
    class ActionCable < ProviderBase
      attr_reader :server
      attr_accessor :autohide_delay, :channel_name

      def initialize(server, channel_name: nil, autohide_delay: 30, notification_conditions: [])
        super(notification_conditions: notification_conditions)
        @server = server
        @autohide_delay = autohide_delay
        @channel_name =
          channel_name ||
          -> (notification) { "notifications_for_user_#{notification.target.login}" }
      end

      def notify(notification)
        return unless can_notify?(notification)
        if notification.target.online?
          @server.broadcast @channel_name.call(notification), serialize_notification(notification)
        end
      end

      def serialize_notification(notification)
        {
          id: notification.id,
          title: notification.title,
          body: notification.body,
          autohide_delay: notification.autohide_delay || @autohide_delay,
          user_login: notification.target.login,
          link: notification.link,
          urgency: notification.urgency,
        }
      end
    end
  end
end
