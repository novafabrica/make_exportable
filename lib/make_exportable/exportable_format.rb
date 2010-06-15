module MakeExportable #:nodoc:
  class ExportableFormat

    class_inheritable_accessor :reference
    class_inheritable_accessor :name
    
    attr_accessor :long
    attr_accessor :mime_type

    class << self
      # Register this format with the mothership
      def register_format
        unless MakeExportable::Core.exportable_formats[self.reference]
          MakeExportable::Core.exportable_formats[self.reference] = self
        end
      end

    end
    
    def generate(data_set, data_headers=nil)
    end

    def sanitize(value)
      value
    end

    def sanitize_and_titleize(value)
      value.humanize.titleize
    end

    def generate_header_option(data_headers=[])
      self.mime_type += self.data_headers.empty? ? " header=absent" : " header=present"
    end

  end

end