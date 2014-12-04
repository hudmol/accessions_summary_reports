class FooReport < AbstractReport
  register_report({
                    :uri_suffix => "foo_report",
                    :description => "Report on foo"
                  })

  def initialize(params)
    super
  end

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

  def title
    "Foo Report"
  end

  def headers
    Repository.columns 
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
    }
  end

  def query(db)
    db[:repository].where( :id => @repo_id)
  end

end
