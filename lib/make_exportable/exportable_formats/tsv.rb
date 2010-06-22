module MakeExportable #:nodoc:
  class TSV < ExportableFormat #:nodoc:

    self.reference = :tsv
    self.name      = "TSV"
    self.register_format

    attr_accessor :data_set, :data_headers

    def initialize(data_set, data_headers=[])
      self.long      = "Tab-separated (TSV)"
      self.mime_type = "text/tab-separated-values; charset=utf-8;"
      self.data_set = data_set
      self.data_headers = data_headers
    end

    def generate
      generate_header_option(data_headers)
      output = ""
      unless data_headers.blank?
        output << data_headers.map {|h| sanitize(h.humanize.titleize) }.join("\t")
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
