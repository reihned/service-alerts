class Delay < ActiveRecord::Migration
  def up
    drop_table :alerts
    create_table :delays do |t|
      t.text :original_html
      t.string :incident_type
      t.string :incident_location
      t.string :affected_lines

      t.boolean :active
      t.datetime :start_time
      t.datetime :end_time
    end
  end

  def down
    drop_table :delays
    create_table :alerts do |t|
      t.string :name
      t.string :status
      
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :active
      t.text :text
    end
  end
end
