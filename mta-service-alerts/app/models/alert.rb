require 'open-uri'
require 'date'
require 'pry'

class Alert < ActiveRecord::Base

  def self.split_alerts alerts

  end

  def initialize

  end



  # To be deprecated

  def self.get_data

    puts "get data now"

    # TODO: Add error handling in instances of failure to fetch.
    # TODO: Save page (without nokogiri) to (non-relational?) db.
    page = self.download_page
    doc = Nokogiri::XML page
    lines = self.find_lines doc

    lines.each do |line|
      line_data = self.line_data line
      # TODO: line_data can include multiple alerts. We need to split them.

      # Good service is the the lack of an alert.
      if self.alert_exists? line_data
        puts line_data
        current_time = self.convert_time(doc.css('timestamp').inner_text)
        # self.update_database line_data, current_time
      end
    end
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

    def self.convert_time time_string
      time_string = time_string.gsub(/\s{2,}/, ' ')
                               .gsub(/0(\d\/)/, '\1')
                               .gsub(/\s+(\d:)/, ' 0\1')

      # AM/PM seems to be broken for strptime
      # This is a hack around that
      if time_string.match('AM')
        DateTime.strptime(time_string, "%m/%d/%Y %l:%M")
      elsif time_string.match('PM')
        DateTime.strptime(time_string, "%m/%d/%Y %l:%M") + 12.hours
      end
    end

    def self.update_end_time record, current_time
      record[:end_time] = current_time
      record.save
    end

end
