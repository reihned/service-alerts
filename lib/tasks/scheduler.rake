desc "Scrapes the MTA feed for alerts"
task :scrape => :environment do
  puts "Updating alerts..."
  Feed.new
  puts "Alerts updated."
end
