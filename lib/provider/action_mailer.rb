module UNotifier
  module Provider
    class ActionMailer < ProviderBase
      def initialize(mailer, sending_method: :new_notification, notification_conditions: [])
        super(notification_conditions: notification_conditions)
        @mailer = mailer
        @sending_method = sending_method
      end

      def notify(notification)
        return unless can_notify?(notification)
        sending_method = if @sending_method.kind_of?(Array)
          @sending_method.map { |m| m.call(notification) }&.first
        else
          @sending_method
        end
        @mailer.public_send(sending_method, notification).deliver
      end
    end
  end
end
