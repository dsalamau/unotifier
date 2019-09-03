module UNotifier
  module Provider
    class ProviderBase
      def initialize(notification_conditions: [])
        @notification_conditions = notification_conditions
      end

      def can_notify?(target)
        return true if @notification_conditions.empty?
        @notification_conditions.all? { |c| c.call(target) }
      end
    end
  end
end
