# TODO: am I sure this is requiring the right CSV?
require "csv"
# for compatibility with Rails 2
require 'fastercsv' if CSV.const_defined?(:Reader)

module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class CSV < ExportableFormat

      self.reference = :csv
      self.name      = 'CSV'
      self.long      = 'Comma-separated (CSV)'
      self.data_type = 'text/csv; charset=utf-8; header=present'

      self.register_format
      
      class << self
        
        def generate(data_set, data_headers=[])
          if ::CSV.const_defined? :Reader
            FasterCSV.generate do |csv|
              unless data_headers.blank?
                csv << data_headers.map {|h| sanitize(h.humanize)}
              end
              data_set.each do |row|
                csv << row
              end
            end
          else
            ::CSV.generate do |csv|
              unless data_headers.blank?
                csv << data_headers.map {|f| sanitize(f.humanize)}
              end
              data_set.each do |row|
                csv << row
              end
            end
          end
        end
  
        def sanitize(value)
          value
        end
      end

    end
  end
end
