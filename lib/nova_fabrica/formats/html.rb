module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class HTML < ExportableFormat

      self.reference = :html
      self.name      = 'HTML'
      self.long      = 'HTML'
      self.data_type = 'text/html; charset=utf-8; header=present'

      self.register_format
      
      class << self
        
        def generate(data_set, data_headers=[])
          output = "<table>\n"
          unless data_headers.blank?
            output << "\t<tr>\n"
            output << data_headers.map {|h| "\t\t<th>#{sanitize(h.humanize)}</th>\n" }.join
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
end
