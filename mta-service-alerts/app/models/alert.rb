require 'open-uri'
require 'date'
require 'pry'

class Alert < ActiveRecord::Base

  def self.split_alerts line_name, alerts, mta_current_time
    delimiters_class = ["TitlePlannedWork", "TitleDelay", "TitleServiceChange"]
    alerts_type = self.alerts_type alerts, delimiters_class
    alerts_count = alerts_type.count

    alerts_count.times do |idx|
      alert_xpath = self.construct_xpath alerts, delimiters_class, idx, alerts_count
      alert = alerts.xpath(alert_xpath)

      puts "\n#{alert_xpath}:
            \t#{alerts_type[idx]}
            \t#{alerts.xpath(alert_xpath)}"
    end
  end

  def self.alerts_type alerts, delimiters_class
    delimiter_xpath = delimiters_class.map do |delimiter|
      "//span[@class='#{delimiter}']"
    end.join('|')
    alerts.xpath(delimiter_xpath)
  end

  def self.construct_xpath alerts, delimiters_class, idx, alerts_count
    delimiters = delimiters_class.map do |delimiter|
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

  def self.process_time time_str
    DateTime.strptime time_str, "%m/%d/%Y %l:%M:%S %p"
  end


  def initialize

  end




  private
 
    def self.line_data line
      date = line.css('date').inner_text
      time = line.css('time').inner_text

      result = {
        name: line.css('name').inner_text,
        status: line.css('status').inner_text,
        start_time: "#{date} #{time}",
        text: self.clean_html(line)
      }

      unless result[:start_time].blank?
        result[:start_time] = self.convert_time(result[:start_time])
      end

      return result
    end

    def self.update_database data, current_time
      line_active_alert = Alert.find_by active: true, name: data[:name]

      if line_active_alert

        if self.same_alert line_active_alert, data
          # Update the active_until time to current time
          self.update_end_time line_active_alert, current_time
        else
          self.set_alert_inactive line_active_alert
          self.create_data data
        end

      else 
        self.create_data data
      end


    end

    def self.same_alert line_active_alert, data
        line_active_alert[:status] == data[:status] &&
        line_active_alert[:text] == data[:text]
    end

    def self.set_alert_inactive alert
      alert[:active] = false
      alert.save
    end

    def self.create_data data
      alert = Alert.new
      alert[:name] = data[:name]
      alert[:status] = data[:status]
      alert[:start_time] = data[:start_time]
      alert[:end_time] = data[:start_time]
      alert[:text] = data[:text]
      alert[:active] = true

      alert.save
    end

    def self.update_end_time record, current_time
      record[:end_time] = current_time
      record.save
    end

end
