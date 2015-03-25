class Delay < ActiveRecord::Base
  def self.update_active_false_for_ended
    Delay.where(active: true).where.not(end_time: $mta_current_time)
         .update_all(active: false)
  end

  def self.create_or_update alert_type, alert_html
    data = self.extract_data alert_type, alert_html
    alert = Delay.find_by(active: true, original_html: data[:original_html]) ||
            Delay.create(data)

    alert.update end_time: $mta_current_time
    unless alert.start_time.nil?
      duration_seconds = $mta_current_time.to_time - alert.start_time.to_time
      duration_minutes = (duration_seconds / 60).to_i
      alert.update duration: duration_minutes
    end
  end

  def self.extract_data alert_type, alert_html
    alert_text = alert_html.inner_text.sub("Allow additional travel time.", '')

    standard_delay = /Posted: (.+) Due to (.+) at (.+),.(.+).trains are running with delays(.*)\./
    residual_delay = /Posted: (.+) Following an earlier incident at (.+),.(.+).trains service has resumed with residual delays(.*)\./

    data = case alert_text
    when standard_delay
      {
        start_time: Alert.process_start_time("#$1"),
        incident_type: "#$2",
        incident_location: "#$3",
        affected_lines: "#$4#$5"
      }
    when residual_delay
      {
        start_time: Alert.process_start_time("#$1"),
        incident_type: "residual delay",
        incident_location: "#$2",
        affected_lines: "#$3#$4"
      }
    else
      {}
    end

    data[:original_html] = alert_type.to_s + alert_html.to_s
    data[:active] = true
    data
  end
end