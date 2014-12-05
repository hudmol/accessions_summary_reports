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

    if params[:report] == 'received'
      data = run_received_report(params)
    elsif params[:report] == 'processed'
      data = run_processed_report(params)
    end

    json_response(data)

  end

  private

  def run_received_report(params)
    data = {}
    DB.open do |db|
      ds = db[:accession]
        .select(:accession__id, :accession__identifier, :user_defined__boolean_1, :extent__number)
        .left_outer_join(:user_defined, {:accession_id => :accession__id}, :table_alias => :user_defined)
        .left_outer_join(:extent, {:accession_id => :accession__id}, :table_alias => :extent)
        .filter(:repo_id => params[:repo_id])
        .where('accession_date >= ? AND accession_date <= ?', params[:start_date], params[:end_date])

      data[:total_accs] = 0
      data[:new_accs] = 0
      data[:add_accs] = 0
      data[:total_extent] = 0.0
      data[:new_extent] = 0.0
      data[:add_extent] = 0.0
      
      ds.each do |row|
        data[:total_accs] += 1
        data[:total_extent] += row[:number].to_f
        if row[:boolean_1] == 1
          data[:new_accs] += 1
          data[:new_extent] += row[:number].to_f
        else
          data[:add_accs] += 1
          data[:add_extent] += row[:number].to_f
        end
      end

      puts "SSSSSSSSSSSS  #{ds.sql}"
      puts "DDDDDDDDDDDD  #{ds.all}"
    end
    data
  end


  def run_processed_report(params)
    data = {}
    DB.open do |db|
      ds = db[:event_link_rlshp]
        .join(:accession, :accession__id => :accession_id)
        .join(:event, :event__id => :event_id)
        .filter(:repo_id => params[:repo_id])
        .where('event_type = ? AND timestamp >= ? AND timestamp <= ?', 'processed', params[:start_date], params[:end_date])

      data[:total_accs] = 0
      data[:total_extent] = 0

      ds.each do |row|
        data[:total_accs] += 1
#        data[:total_extent] += row[:number].to_f
      end

      puts "SSSSSSSSSSSS  #{ds.sql}"
      puts "DDDDDDDDDDDD  #{ds.all}"
    end
    data
  end

end
