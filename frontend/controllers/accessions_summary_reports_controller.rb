class AccessionsSummaryReportsController < ApplicationController

  skip_before_action :unauthorised_access

  def index
#    @accessions_summary_report = JSONModel(:accessions_summary_report).new
    @accessions_summary_report = JSONModel(:accessions_summary_report).new._always_valid!
  end


  def create
    params.permit!
    @accessions_summary_report = JSONModel(:accessions_summary_report).from_hash(params["accessions_summary_report"].to_hash, false)
    if @accessions_summary_report._exceptions.blank?
      begin
        query_hash = {
          :start_date => @accessions_summary_report["start_date"],
          :end_date => @accessions_summary_report["end_date"],
          :report => @accessions_summary_report["report"]
        }
        
        response = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/accessions_summary_reports", query_hash)
        
        @params = params["accessions_summary_report"]
        @data = response
        
      rescue Exception => e
        render action: "index"
      end
    else
      @exceptions = @accessions_summary_report._exceptions
      render action: "index"
    end
  end

end

