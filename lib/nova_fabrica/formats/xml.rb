module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class XML < ExportableFormat

      self.reference = :xml
      self.name      = 'XML'
      self.long      = 'XML'
      self.data_type = 'application/xml; header=present'

      self.register_format

      class << self
        def generate(data_set, data_headers=[])
          xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
          xml << "<records>\n"
          data_set.each do |row|
            xml << "\t<record>\n"
            row.each_with_index do |field,i|
              if !data_headers.blank?
                attr_name = sanitize(data_headers[i].dasherize)
              else
                attr_name = "attribute_#{i}"
              end
              xml << "\t\t<#{attr_name}>#{sanitize(field)}</#{attr_name}>\n"
            end
            xml << "\t</record>\n"
          end
          xml << "</records>\n"
          return xml
        end

        def sanitize(value)
          value.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').
            gsub(/"/, '&quot;').gsub(/'/, '&apos;')
        end
      end
      
    end
  end
end
