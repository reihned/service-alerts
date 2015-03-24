require 'open-uri'
require 'pry'

class Feed

  def initialize
    page = get_page
    doc = parse_page page
    mta_current_time = doc.css('timestamp').inner_text
    lines = select_lines doc

    create_alerts_for_lines lines, mta_current_time

    # Any alerts that have an end_time that is before the current_time, but
    # active: true, are residuals from the last iteration and are set to false.
    Delay.update_active_false_for_ended
  end

  def get_page
    url = "http://web.mta.info/status/serviceStatus.txt"
    open url

    # # for testing
    # open("../research/2015-02-22-08-42-01.xml")
  end

  def parse_page page
    Nokogiri::XML page
  end

  def select_lines doc
    all_lines = doc.xpath('service/subway/line')
    all_lines.select do |line|
      has_alert?(line)
    end
  end

  # Trains with "GOOD SERVICE" don't have alerts
  def has_alert? line
    status = line.css('status').inner_text.strip
    status != "GOOD SERVICE"
  end

  # The HTML in the `text` field of the XML is horrifically invalid, this helps.
  def fix_html line
    # Escaped characters (&gt; etc.) are automatically unescaped by Nokogiri.
    raw_text = line.css('text').inner_text
    regex = /<\/*br\/*>|<\/*b>|<\/*i>|<\/*u>|<\/*strong>|<\/*font.*?>/
    formatted_text = raw_text.gsub(regex, '').gsub('&nbsp;', ' ')
                              .gsub(/\s{2,}/, ' ')
    Nokogiri::HTML formatted_text
  end

  def create_alerts_for_lines lines, mta_current_time
    lines.each do |line|
      Alert.split_alerts(
        line.css('name').inner_text,
        fix_html(line),
        mta_current_time
      )
    end
  end


end