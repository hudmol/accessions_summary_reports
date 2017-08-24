{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/accessions_summary_reports",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "start_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
      "end_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},

      "report" => {"type" => "string", "enum" => ["received", "processed", "timeliness"], "ifmissing" => "error"},

    },
  },
}
