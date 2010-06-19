# TODO: These could use improvement
module MakeExportableHelper

  def self.exportable_class_list
    MakeExportable.exportable_classes.keys.sort {|item1, item2| item1[0] <=> item2[0] }
  end

  def self.exportable_table_list
    MakeExportable.exportable_classes.values.map do |klass|
      klass.table_name
    end.sort {|item1, item2| item1[0] <=> item2[0] }
  end

  def self.exportable_format_list
    MakeExportable.exportable_formats.map do |key, fmt|
      [fmt.name, key]
    end.sort {|item1, item2| item1[0] <=> item2[0] }
  end

  def self.exportable_units
    hash = {}
    MakeExportable.exportable_classes.values.map do |klass|
      hash[klass] = klass.table_name
    end
    hash
  end

end
