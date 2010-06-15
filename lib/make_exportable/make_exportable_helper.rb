module MakeExportableHelper

  def exportable_class_list
    MakeExportable::Core.exportable_classes.map do |key, klass| 
      [klass.table_name, key]
    end.sort {|item1, item2| item1[0] <=> item2[0] }
  end
  
  def exportable_format_list
    MakeExportable::Core.exportable_formats.map do |key, fmt|
      [fmt.name, key]
    end.sort {|item1, item2| item1[0] <=> item2[0] }
  end

end
