module NovaFabrica
  module MakeExportableHelper

    def exportable_table_list
      NovaFabrica::MakeExportable.exportable_classes.sort.map {|key, value| [value.to_s]}
    end
    
    def exportable_class_list
      NovaFabrica::MakeExportable.exportable_classes.sort.map {|key, value| [key.classify]}
    end
  
    def exportable_format_list
      NovaFabrica::MakeExportable.exportable_formats.map do |fmt|
        [NovaFabrica::MakeExportable.format_name(fmt), fmt.to_s]
      end
    end

  end
end
