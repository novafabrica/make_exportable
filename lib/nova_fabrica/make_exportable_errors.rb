module NovaFabrica
  module MakeExportableErrors
    class ExportFormatNotFoundError < StandardError #:nodoc:
    end

    class NoColumnsGivenError < StandardError #:nodoc:
    end
  end
end
