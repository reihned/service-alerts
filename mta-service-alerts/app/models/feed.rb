require 'open-uri'

class Feed

  def initialize
    page = get_page
    doc = parse_page page
  end


  def get_page
    url = "http://web.mta.info/status/serviceStatus.txt"
    open url
  end

  def parse_page page
    Nokogiri::XML page
  end



end