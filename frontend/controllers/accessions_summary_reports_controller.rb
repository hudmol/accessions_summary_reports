class AccessionsSummaryReportsController < ApplicationController

  skip_before_filter :unauthorised_access

  def index
    @accessions_summary_report = JSONModel(:accessions_summary_report).new._always_valid!
  end
   
  def create

  end

end

