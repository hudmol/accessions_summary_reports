class AccessionsSummaryReportsController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    @accessions_summary_report = JSONModel(:accessions_summary_report).new._always_valid!
  end
   
  def create
    begin
      post_data = {
        :start_date => params["accessions_summary_report"]["start_date"],
        :end_date => params["accessions_summary_report"]["end_date"],
        :report => params["accessions_summary_report"]["report"]
      }

      response = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/accessions_summary_reports", post_data)

      @params = params["accessions_summary_report"]
      @response = response

    rescue Exception => e
    end
  end

end

