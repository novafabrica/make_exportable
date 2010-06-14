module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class HTML < ExportableFormat

      self.reference = :html
      self.name      = 'HTML'
      self.register_format
      
      attr_accessor :data_set, :data_headers

      def initialize(data_set, data_headers=[])
        self.long      = 'HTML'
        self.mime_type = 'text/html; charset=utf-8;'
        self.data_set = data_set
        self.data_headers = data_headers
      end

      def generate
        generate_header_option(data_headers)
        output = "<table>\n"
        unless data_headers.blank?
          output << "\t<tr>\n"
          output << data_headers.map {|h| "\t\t<th>#{sanitize_and_titleize(h)}</th>\n" }.join
          output << "\t</tr>\n"
        end
        data_set.each do |row|
          output << "\t<tr>\n"
          output << row.map {|field| "\t\t<td>#{sanitize(field)}</td>\n"}.join
          output << "\t</tr>\n"
        end
        output << "</table>\n"
        return output
      end

      def sanitize(value)
        value.gsub(/</, '&lt;').gsub(/>/, '&gt;')
      end
    end

  end
end
