module MakeExportable #:nodoc:
  class Excel < ExportableFormat #:nodoc:

    self.reference = :xls
    self.name      = 'Excel'
    self.register_format
    
    attr_accessor :data_set, :data_headers
    

    def initialize(data_set, data_headers=[])
      self.long      = 'Microsoft Excel'
      self.mime_type = 'application/vnd.ms-excel; charset=utf-8;'
      self.data_set = data_set
      self.data_headers = data_headers
    end

    def generate
      generate_header_option(data_headers)
      output = "<?xml version='1.0'?>\n"
      output << "<Workbook xmlns='urn:schemas-microsoft-com:office:spreadsheet'\n"
      output << "\txmlns:o='urn:schemas-microsoft-com:office:office'\n"
      output << "\txmlns:x='urn:schemas-microsoft-com:office:excel'\n"
      output << "\txmlns:ss='urn:schemas-microsoft-com:office:spreadsheet'\n"
      output << "\txmlns:html='http://www.w3.org/TR/REC-html40'>\n"
      output << "\t<Worksheet ss:Name='Sheet1'>\n"
      output << "\t\t<Table>\n"

      unless data_headers.blank?
        output << "\t\t\t<Row>\n"
        output << data_headers.map {|h| "\t\t\t\t<Cell><Data ss:Type='String'>#{sanitize(h.humanize.titleize)}</Data></Cell>\n" }.join
        output << "\t\t\t</Row>\n"
      end

      data_set.each do |row|
        output << "\t\t\t<Row>\n"
        output << row.map {|field| "\t\t\t\t<Cell><Data ss:Type='String'>#{sanitize(field)}</Data></Cell>\n" }.join
        output << "\t\t\t</Row>\n"
      end

      output << "\t\t</Table>\n"
      output << "\t</Worksheet>\n"
      output << "</Workbook>\n"

      return output
    end

    def sanitize(value)
      value.gsub(/</, '&lt;').gsub(/>/, '&gt;')
    end
  end

end
