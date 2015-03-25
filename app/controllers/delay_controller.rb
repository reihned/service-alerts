class DelayController < ApplicationController
  def index
    delays = Delay.all
    render json: delays
  end

  private

    def delay_params
      params.require(:delay).permit(
        :earliest_start_time,
        :lastest_start_time,
        :min_duration,
        :max_duration,
        :incident_type,
        :incident_location,
        :active
      )
    end
end
