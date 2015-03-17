task :get_data => :environment do
  Alert.get_data
end

task :new_feed => :environment do
  Feed.new
end
