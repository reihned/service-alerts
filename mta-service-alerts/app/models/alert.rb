require 'open-uri'
require 'date'
require 'pry'

class Alert

  def self.split_alerts line_name, alerts, mta_current_time
    @@delimiters_class = ["TitlePlannedWork", "TitleDelay", "TitleServiceChange"]
    
    alerts_type = self.alerts_type alerts
    alerts_count = alerts_type.count

    alerts_count.times do |idx|
      alert_xpath = self.construct_xpath alerts, idx, alerts_count
      alert_type = alerts_type[idx]
      alert_html = self.get_alert alerts, alert_xpath

      puts "\n#{alert_xpath}:
            \t#{alert_type}
            \t#{alert_html}"
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

  def self.process_time time_str
    DateTime.strptime time_str, "%m/%d/%Y %l:%M:%S %p"
  end



  def initialize

  end

end
