require 'open-uri'
require 'date'
require 'pry'

class Alert
  @@delimiters_class = ["TitlePlannedWork", "TitleDelay", "TitleServiceChange"]

  def self.split_alerts line_name, alerts, mta_current_time
    @@mta_current_time = self.process_mta_current_time mta_current_time

    alerts_type = self.alerts_type alerts
    alerts_count = alerts_type.count

    alerts_count.times do |idx|
      alert_xpath = self.construct_xpath alerts, idx, alerts_count
      alert_type = alerts_type[idx]
      alert_html = self.get_alert(alerts, alert_xpath)

      Alert.new alert_type, alert_html
    end
  end

  def self.alerts_type alerts
    delimiter_xpath = @@delimiters_class.map do |delimiter|
      "//span[@class='#{delimiter}']"
    end.join('|')
    alerts.xpath(delimiter_xpath)
  end

  def self.construct_xpath alerts, idx, alerts_count
    delimiters = @@delimiters_class.map do |delimiter|
      "@class='#{delimiter}'"
    end.join(' or ')

    xpath = "//*[preceding-sibling::span[#{delimiters}][#{idx + 1}]]"

    # If this isn't the last alert, bound with the next alert.
    if idx + 1 != alerts_count
      # The way that `following-siblings` counts *down* from alerts_count seems
      # to run counter to the xpath description from w3 schools, but works.
      xpath += "[following-sibling::span[#{delimiters}][#{alerts_count - idx - 1}]]"
    end
    xpath
  end

  def self.get_alert alerts, alert_xpath
    alerts.xpath alert_xpath
  end

  def self.process_mta_current_time time_str
    DateTime.strptime time_str, "%m/%d/%Y %l:%M:%S %p"
  end

  def self.process_start_time time_str
    DateTime.strptime time_str, "%m/%d/%Y %l:%M%p"
  end



  attr_accessor :alert_type, :alert_html

  def initialize alert_type, alert_html
    alert_type = alert_type
    @alert_html = alert_html

    if alert_type.inner_text == "Delays"
      data = extract_delay_data
      data[:original_html] = alert_type.to_s + @alert_html.to_s
      data[:active] = true
      
      create_or_update_delay data
    end
  end

  def create_or_update_delay data
    alert = Delay.find_by(active: true, original_html: data[:original_html]) ||
            Delay.create(data)

    alert.update end_time: @@mta_current_time
  end

  def extract_delay_data
    alert_text = @alert_html.inner_text.sub("Allow additional travel time.", '')

    standard_delay = /Posted: (.+) Due to (.+) at (.+), (.+) trains are running with delays(.*)\./
    residual_delay = /Posted: (.+) Following an earlier incident at (.+), (.+) trains service has resumed with residual delays(.*)\./

    case alert_text
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
  end

end
