module MakeExportable #:nodoc:
  class ExportableFormat #:nodoc:

    class_inheritable_accessor :reference
    class_inheritable_accessor :name
    
    attr_accessor :long
    attr_accessor :mime_type

    class << self
      # Register this format with the mothership
      def register_format
        unless MakeExportable.exportable_formats[self.reference]
          MakeExportable.exportable_formats[self.reference] = self
        end
      end

    end
    
    def generate(data_set, data_headers=nil)
    end

    def sanitize(value)
      value
    end

    def generate_header_option(data_headers=[])
      self.mime_type += (self.data_headers.blank? || data_headers === false) ? " header=absent" : " header=present"
    end

  end

end
