module MakeExportable #:nodoc:
  class JSON < ExportableFormat

    self.reference = :json
    self.name      = "JSON"
    self.register_format

    attr_accessor :data_set, :data_headers

    def initialize(data_set, data_headers=[])
      self.long      = "JavaScript Object Notation (JSON)"
      self.mime_type = "application/json; charset=utf-8;"
      self.data_set = data_set
      self.data_headers = data_headers
    end

    def generate
      output = []
      unless data_headers.blank?
        data_set.each do |row|
          h = {}
          row.each_with_index do |field, i|
            h[data_headers[i]] = field
          end
          output << h
        end
      else
      end
      return output.to_json
    end

    def sanitize(value)
    end

  end
end
