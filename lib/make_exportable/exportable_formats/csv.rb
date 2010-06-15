require "csv"
# for compatibility with Rails 2
require 'fastercsv' if CSV.const_defined?(:Reader)

module MakeExportable #:nodoc:
  class CSV < ExportableFormat

    cattr_accessor :csv_type

    self.reference = :csv
    self.name      = 'CSV'
    self.register_format
    self.csv_type = ::CSV.const_defined?(:Reader) ? FasterCSV : ::CSV

    attr_accessor :data_set, :data_headers

    def initialize(data_set, data_headers=[])
      self.long      = 'Comma-separated (CSV)'
      self.mime_type = 'text/csv; charset=utf-8;'
      self.data_set = data_set
      self.data_headers = data_headers
    end


    def generate
      generate_header_option(data_headers)
      @@csv_type.generate do |csv|
        csv << data_headers.map {|h| sanitize_and_titleize(h)} unless data_headers.blank?
        data_set.each {|row| csv << row }
      end
    end
  end

end
