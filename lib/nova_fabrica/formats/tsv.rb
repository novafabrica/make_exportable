module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class TSV < ExportableFormat

      self.reference = :tsv
      self.name      = "TSV"
      self.long      = "Tab-separated (TSV)"
      self.data_type = "text/tab-separated-values; charset=utf-8; header=present"

      self.register_format

      class << self
        def generate(data_set, data_headers=[])
          output = ""
          unless data_headers.blank?
            output << data_headers.map {|h| sanitize(h.humanize) }.join("\t")
          end
          output << "\n" unless output.blank?
          data_set.each do |row|
            output << row.map {|field| sanitize(field)}.join("\t") << "\n"
          end
          return output
        end
      
        def sanitize(value)
          value.gsub(/(\t|\\t)/, '  ')
        end
      end
    end
  end
end
