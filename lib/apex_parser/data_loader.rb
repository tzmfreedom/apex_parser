require 'csv'

module ApexParser
  class DataLoader
    attr_accessor :adapter

    def initialize(adapter = JsonAdapter.new, **options)
      @records = {}
      @adapter = adapter
    end

    def call(soql)
      object_name = soql
      @records[object_name.to_sym] ||= adapter.call(soql)
    end

  end

  class CsvAdapter
    def call(soql)
      object_name = soql
      file = File.expand_path("../../data/#{object_name}.csv", __dir__)
      return unless File.exists?(file)

      CSV.foreach(file, headers: :first_row, skip_blanks: true).map do |row|
        SObject.new(row.to_h)
      end
    end
  end

  class JsonAdapter
    def call(soql)
      object_name = soql
      file = File.expand_path("../../data/#{object_name}.json", __dir__)
      return unless File.exists?(file)

      records = JSON.load(File.open(file))
      records.map { |record| SObject.new(record) }
    end
  end
end
