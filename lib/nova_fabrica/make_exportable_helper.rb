module NovaFabrica
  module MakeExportableHelper

    def exportable_table_list
      NovaFabrica::MakeExportable.exportable_tables.sort.map {|tbl| [tbl.titleize, tbl.to_s]}
    end
  
    def exportable_format_list
      NovaFabrica::MakeExportable.exportable_formats.map do |fmt|
        [NovaFabrica::MakeExportable.format_name(fmt), fmt.to_s]
      end
    end

  end
end
