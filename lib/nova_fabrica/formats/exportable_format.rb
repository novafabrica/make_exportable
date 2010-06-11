module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:
    class ExportableFormat

      class_inheritable_accessor :reference
      class_inheritable_accessor :name
      class_inheritable_accessor :long
      class_inheritable_accessor :data_type
    
      class << self
        
        def generate(data_set, data_headers=nil)
          # must be specified in each subclass
        end
  
        def sanitize(value)
          value
        end

        # Register this format with the mothership
        def register_format
          unless NovaFabrica::MakeExportable.exportable_formats[self.reference]
            NovaFabrica::MakeExportable.exportable_formats[self.reference] = self
          end
        end
      end
      
    end
    
  end
end
