class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/accessions_summary_reports')
    .description("Provides summary reports on accessions")
    .params(["start_date", String, "Accession date range start"],
            ["end_date", String, "Accession date range end"],
            ["report", String, "Report type"],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "Report data"]) \
  do
    data = {}

    DB.open do |db|
      ds = db[:accession].filter(:repo_id => params[:repo_id]).
        where('accession_date >= ? AND accession_date <= ?', params[:start_date], params[:end_date])

      data["count"] = ds.count
    end

    json_response(data)
  end

end
