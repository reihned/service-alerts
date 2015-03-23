class Delay < ActiveRecord::Base
  def self.toggle_active_for_previously_active
    Delay.where(active: true).where.not(end_time: @@mta_current_time)
         .update_all(active: false)
  end
end