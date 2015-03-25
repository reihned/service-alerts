class CreateRawFeeds < ActiveRecord::Migration
  def change
    create_table :raw_feeds do |t|
      t.datetime :mta_current_time
      t.text :feed
      t.timestamps null: false
    end
  end
end
