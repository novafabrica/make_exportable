module NovaFabrica
  module MakeExportableErrors
    class ExportFormatNotFoundError < StandardError #:nodoc:
    end

    class NoColumnsGivenError < StandardError #:nodoc:
    end
    
    class ExportFault < StandardError #:nodoc:
    end
    
  end
end
