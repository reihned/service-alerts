require 'open-uri'
require 'date'
require 'pry'

class Alert < ActiveRecord::Base

  def self.split_alerts alerts
    alerts = Nokogiri::HTML(
      '<span class="TitleDelay">Delays</span><P>Foo</P>
       <span class="TitleDelay">Delays</span><P>Bar</P>
       <span class="TitleDelay">Delays</span><P>Bax</P>
       <span class="TitlePlannedWork">Planned Work</span><P>Baz</P>')

    delimiters_class = ["TitlePlannedWork", "TitleDelay", "TitleServiceChange"]

    alerts_count = self.alert_count alerts, delimiters_class

    alerts_count.times do |idx|
      alert_xpath = self.construct_xpath alerts, delimiters_class, idx, alerts_count
      puts "#{alert_xpath}:\n\t#{alerts.xpath(alert_xpath)}\n"
    end


  end

  def self.alert_count alerts, delimiters_class
    delimiter_xpath = delimiters_class.map do |delimiter|
      "//span[@class='#{delimiter}']"
    end.join('|')
    alerts.xpath(delimiter_xpath).count
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
