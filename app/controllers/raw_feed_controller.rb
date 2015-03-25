class RawFeedController < ApplicationController
  def index
    search_query = construct_query params
    feeds = RawFeed.where search_query
    render json: feeds
  end

  private

    def construct_query params
      earliest = params[:earliest].nil? ?
                  DateTime.iso8601('2015-01-01T00:00:00-05:00') :
                  DateTime.iso8601(params[:earliest])
      latest = params[:latest].nil? ?
                  DateTime.now :
                  DateTime.iso8601(params[:latest])

      { mta_current_time: earliest..latest }
    end
end