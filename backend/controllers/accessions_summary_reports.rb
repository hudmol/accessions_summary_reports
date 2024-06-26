require 'date'

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
    elsif params[:report] == 'timeliness'
      data = run_timeliness_report(params)
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
             .where(Sequel.lit('accession_date >= ? AND accession_date <= ?', params[:start_date], params[:end_date]))

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
    end
    data
  end


  def run_processed_report(params)
    data = {}

    data[:total_accs] = 0
    data[:total_extent] = 0
    data[:unprocessed_accs] = 0
    data[:unprocessed_extent] = 0
    data[:bad_date] = []

    # derby freaks out at 'begin'
    if $db_type == :derby
      begin_string = '"BEGIN"'
    elsif $db_type == :mysql
      begin_string = 'begin'
    else
      # warning - only tested on derby and mysql
      begin_string = 'begin'
    end

    DB.open do |db|
      # find accessions processed within the given date range
      ds = db[:event]
             .select(:accession__id, :accession__identifier, :event_type__value, :event_outcome__value, :extent__number, :date__begin)
             .join(:enumeration_value, {:id => :event__event_type_id}, :table_alias => :event_type)
             .join(:enumeration_value, {:id => :event__outcome_id}, :table_alias => :event_outcome)
             .join(:date, {:event_id => :event__id}, :table_alias => :date)
             .join(:event_link_rlshp, {:event_id => :event__id}, :table_alias => :event_link)
             .join(:accession, :id => :event_link__accession_id)
             .left_outer_join(:extent, :accession_id => :accession__id)
             .where(:event__repo_id => params[:repo_id])
             .where(Sequel.lit('event_type.value = ? AND event_outcome.value = ?', 'processed', 'pass'))
             .where(Sequel.lit("(date.#{begin_string} >= ? AND date.#{begin_string} <= ?) OR (date.expression >= ? AND date.expression <= ?)", params[:start_date], params[:end_date], params[:start_date], params[:end_date]))

      ds.each do |row|
        data[:total_accs] += 1
        data[:total_extent] += row[:number].to_f
      end

      # find all unprocessed accessions
      processed_ds = db[:accession]
                       .select(:accession__id)
                       .join(:event_link_rlshp, {:accession_id => :accession__id}, :table_alias => :event_link)
                       .join(:event, {:id => :event_link__event_id}, :table_alias => :event)
                       .join(:enumeration_value, {:id => :event__event_type_id}, :table_alias => :event_type)
                       .where(:accession__repo_id => params[:repo_id])
                       .where(:event_type__value => 'processed')

      unprocessed_ds = db[:accession]
                         .select(:extent__number)
                         .left_outer_join(:extent, :accession_id => :accession__id)
                         .where(Sequel.~(:accession__id=>processed_ds))

      unprocessed_ds.each do |row|
        data[:unprocessed_accs] += 1
        data[:unprocessed_extent] += row[:number].to_f
      end

      # find all processed accessions with bad date formats
      processed_bad_date_ds = db[:accession]
                                .select(:accession__id)
                                .join(:event_link_rlshp, {:accession_id => :accession__id}, :table_alias => :event_link)
                                .join(:event, {:id => :event_link__event_id}, :table_alias => :event)
                                .join(:date, {:event_id => :event__id}, :table_alias => :date)
                                .join(:enumeration_value, {:id => :event__event_type_id}, :table_alias => :event_type)
                                .where(:accession__repo_id => params[:repo_id])
                                .where(:event_type__value => 'processed')
                                .where(Sequel.lit("(date.#{begin_string} like '_%' AND date.#{begin_string} not like '____-__-__') OR (date.expression like '_%' AND date.expression not like '____-__-__')"))

      processed_bad_date_ds.each do |row|
        data[:bad_date] << row[:id]
      end

    end
    data
  end


  def run_timeliness_report(params)
    data = {}

    # derby freaks out at 'begin'
    if $db_type == :derby
      begin_string = '"BEGIN"'
    elsif $db_type == :mysql
      begin_string = 'begin'
    else
      # warning - only tested on derby and mysql
      begin_string = 'begin'
    end

    DB.open do |db|
      ds = db[:accession]
             .select(:accession__id, :accession__accession_date, :user_defined__date_3, :acq_type__value, :date__begin)
             .left_outer_join(:user_defined, {:accession_id => :accession__id}, :table_alias => :user_defined)
             .left_outer_join(:enumeration_value, {:id => :accession__acquisition_type_id}, :table_alias => :acq_type)
             .join(:event_link_rlshp, {:accession_id => :accession__id}, :table_alias => :event_link)
             .join(:event, {:id => :event_link__event_id}, :table_alias => :event)
             .left_outer_join(:date, {:event_id => :event__id}, :table_alias => :date)
             .join(:enumeration_value, {:id => :event__event_type_id}, :table_alias => :event_type)
             .join(:enumeration_value, {:id => :event__outcome_id}, :table_alias => :event_outcome)
             .filter(:accession__repo_id => params[:repo_id])
             .where(:event_type__value => 'cataloged')
             .where(:event_outcome__value => 'pass')
             .where(Sequel.lit('(date.begin >= ? AND date.begin <= ?) OR date.begin IS NULL', params[:start_date], params[:end_date]))

      data[:total_accs] = 0
      data[:timely_accs] = 0
      data[:not_timely_accs] = 0
      data[:unknown_date_accs] = 0
      data[:bad_date_accs] = 0
      data[:bad_date] = []

      ds.each do |row|
        data[:total_accs] += 1

        unless row[:begin]
          data[:bad_date] << row[:id]
          data[:bad_date_accs] += 1
          next
        end

        begin
          cataloged_date = Date.parse(row[:begin])
          compare_date = ['gratis donation', 'nla (dap)'].include?(row[:value]) ? row[:accession_date] : row[:date_3]

          unless compare_date
            data[:unknown_date_accs] += 1
            next
          end

          days_difference = (cataloged_date - compare_date).to_i

          if days_difference <= 90
            data[:timely_accs] += 1
          else
            data[:not_timely_accs] += 1
          end
        rescue ArgumentError
          data[:bad_date] << row[:id]
          data[:bad_date_accs] += 1
        end
      end
    end
    data
  end

end
