require 'open-uri'

class Feed

  def initialize
    page = get_page
    doc = parse_page page
    lines = select_lines doc

    puts_lines lines
  end

  # For debugging purposes
  def puts_lines lines
    lines.each do |line|
      name = line.css('name').inner_text
      status = line.css('status').inner_text

      puts "#{name}: #{status}"
    end
  end

  def get_page
    url = "http://web.mta.info/status/serviceStatus.txt"
    open url
  end

  def parse_page page
    Nokogiri::XML page
  end

  def select_lines doc
    all_lines = doc.css('line')
    all_lines.select do |line|
      is_train?(line) && has_alert?(line)
    end
  end

  # Bus info is currently filtered out for simplicity.
  def is_train? line
    train_names = ["123", "456", "7", "ACE", "BDFM", "G", "JZ", "L", "NQR",
                  "S", "SIR"]
    line_name = line.css('name').inner_text.strip
    train_names.include? line_name
  end

  # Trains with "GOOD SERVICE" don't have alerts
  def has_alert? line
    status = line.css('status').inner_text.strip
    status != "GOOD SERVICE"
  end


end