module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class XML < ExportableFormat

      self.reference = :xml
      self.name      = 'XML'
      self.register_format

      attr_accessor :data_set, :data_headers

      def initialize(data_set, data_headers=[])
        self.long      = 'XML'
        self.mime_type = 'application/xml;'
        self.data_set = data_set
        self.data_headers = data_headers
      end

      def generate
        generate_header_option(data_headers)
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
