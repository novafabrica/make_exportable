module MakeExportable #:nodoc:

  # Inventory of the exportable classes
  mattr_accessor :exportable_classes
  @@exportable_classes = {}

  # Inventory of the exportable formats
  mattr_accessor :exportable_formats
  @@exportable_formats = {}

  def self.included(target)
    target.extend(ActiveRecordBaseMethods)
  end

  module ActiveRecordBaseMethods

    # <tt>make_exportable</tt> is an ActiveRecord method that, when called, add 
    # methods to a particular class to make exporting data from that class easier.
    #
    # Example:
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable
    #   end
    #   Customer.to_export(:csv)
    #
    # An optional hash of options can be passed as an argument to establish the default 
    # export parameters.
    #
    # These options include:
    # * :only and :except - specify columns or methods to export (defaults to all columns)
    # * :as - specify formats to allow for exporting (defaults to all formats)
    # * :scopes - specify scopes to be called on the class before exporting
    # * find options - for Rails 2.3 and earlier compatibility, standard find options 
    #     are supported (:conditions, :order, :limit, :offset, etc.). These will be deprecated 
    #     and removed in future versions.
    #
    # Examples:
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :only => [:id, :username, :full_name]
    #   end
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :except => [:id, :password], :scopes => [:new_signups, :with_referals], 
    #                     :as => [:csv, :tsv, :xls]
    #   end
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :conditions => {:active => true}, :order => 'last_name ASC, first_name ASC',
    #                     :as => [:json, :html, :xml]
    #   end
    #
    def make_exportable(options={})
      # register the class as exportable
      MakeExportable.exportable_classes[self.class_name] = self

      # remove any invalid options
      valid_options = [:as, :only, :except, :scopes, :conditions, :order, :include,
                       :group, :having, :limit, :offset, :joins]
      options.slice!(*valid_options)

      # Determine the exportable formats, default to all registered formats
      options[:formats] = MakeExportable.exportable_formats.keys
      if format_options = options.delete(:as)
        options[:formats] = options[:formats] & Array.wrap(format_options).map(&:to_sym)
      end
      # Handle case when :as option was sent, but with no valid formats
      if options[:formats].blank?
        valid_formats = MakeExportable.exportable_formats.keys.map {|f| ":#{f}"}
        raise MakeExportable::FormatNotFound.new("No valid export formats. Use: #{valid_formats.join(', ')}") 
      end

      # Determine the exportable columns, default to all columns and then
      # remove columns using the :only and :except options
      options[:columns] = self.column_names.map(&:to_sym)
      if only_options = options.delete(:only)
        options[:columns] = Array.wrap(only_options).map {|i| i.to_sym}
      end
      if except_options = options.delete(:except)
        options[:columns] = options[:columns] - Array.wrap(except_options).map {|i| i.to_sym}
      end


      options[:scopes] ||= []

      # exportable options will be :formats, :columns, :scopes
      write_inheritable_attribute :exportable_options, options
      class_inheritable_reader :exportable_options

      extend MakeExportable::ClassMethods
      include MakeExportable::InstanceMethods

    end

    # <tt>exportable?</tt> returns false for all ActiveRecord classes
    # until <tt>make_exportable</tt> has been called on them.
    def exportable?(format=nil)
      return false
    end

  end

  module ClassMethods

    # <tt>exportable?<?tt> returns true if the class has called "make_exportable".
    # This is overriding the default :exportable? in ActiveRecord::Base which 
    # always returns false.
    # If a format is passed as an argument, returns true only if the format is 
    # allowed for this class.
    def exportable?(format=nil)
      return exportable_options[:formats].include?(format.to_sym) if format
      return true
    end

    # <tt>to_export</tt> is a class method to export all records of a class. It can be called 
    # directly on an ActiveRecord class, but it can also be called on an ActiveRelation scope.
    # It takes two arguments: a format (required) and a hash of options (optional).
    #
    # The options include:
    # * :only and :except - specify columns or methods to export
    # * :scopes - specify scopes to be called on the class before exporting
    # * find options - for Rails 2.3 and earlier compatibility, standard find options 
    #     are supported (:conditions, :order, :limit, :offset, etc.). These will be deprecated 
    #     and removed in future versions.
    # * :headers - supply an array of custom headers for the columns of exported attributes, 
    #     the sizes of the header array and the exported columns must be equal.
    #   
    # Examples:
    #
    #   User.to_export(:xml, :columns => [:first_name, :last_name, :username], 
    #      :order => 'users.last_name ASC')
    #
    #   User.visible.sorted_by_username.to_export('csv', 
    #      :only => [:first_name, :last_name, :username])
    #
    # As a convenience, you can also use "dynamically-named methods" and include the format 
    # in the method name instead of providing it the first argument.
    #
    # Example:  User.to_xml_export(:columns => [:first_name, :last_name, :username])
    #
    def to_export(format, options={})
      data_set = self.get_export_data(options)
      return self.create_report(format, data_set, options)
    end

    # <tt>get_export_data</tt> is a class method that finds all objects of a given
    # class using the options passed in and outputs an ordered array of arrays
    # containing data to be used as columns of data with create_report. Valid options 
    # include :only, :except, :scopes, and standard find options. 
    # See <tt>to_export</tt> for more details on the available options.
    # 
    # Example:
    #
    #   User.get_export_data(:columns => [:first_name, :last_name, :username])
    #   #> [['John', 'Doe', 'johndoe'], ['Joe', 'Smith', 'jsmith']]
    #
    def get_export_data(options={})
      options.reverse_merge!(exportable_options)

      if only_options = options.delete(:only)
        options[:columns] = Array.wrap(only_options).map {|i| i.to_sym}
      end
      if except_options = options.delete(:except)
        options[:columns] = options[:columns] - Array.wrap(except_options).map {|i| i.to_sym}
      end

      # apply scopes and then find options
      collection = self
      options[:scopes].each do |scope|
        collection = collection.send(scope)
      end
      # For Rails 2.3 compatibility
      if ActiveRecord::VERSION::MAJOR < 3
        find_options = options.slice(:conditions, :order, :include, :group, :having, :limit, :offset, :joins)
        collection = collection.find(:all, find_options)
      else
        # they should not be sending find options anymore, so we don't support them
        collection = collection.all
      end

      rows = collection.map do |item|
        options[:columns].map {|col| item.export_attribute(col) }
      end
      return rows
    end

    # <tt>create_report</tt> is a class method to create a report from a set of data.
    # It takes three arguments: a format (required), the data set to use for the report (required),
    # and a hash of options (optional).  The only meaningful options are :columns and :headers either of 
    # which will be used as headers for the columns in the data_set.
    def create_report(format, data_set=[], options={})
      validate_export_format(format)
      options.reverse_merge!(exportable_options)
      if only_options = options.delete(:only)
        options[:columns] = Array.wrap(only_options).map {|i| i.to_sym}
      end
      if except_options = options.delete(:except)
        options[:columns] = options[:columns] - Array.wrap(except_options).map {|i| i.to_sym}
      end
      headers = options[:headers] || options[:columns].map(&:to_s)
      validate_data_lengths(data_set, headers)
      format_class = MakeExportable.exportable_formats[format.to_sym]
      formater = format_class.new(data_set, headers)
      return formater.generate, formater.mime_type
    end


    private

      # <tt>method_missing</tt> allows the class to accept dynamically named methods 
      # such as: SomeClass.to_xls_export(), SomeClass.create_csv_report()
      def method_missing(method_id, *arguments)
        # TODO: Should this use all formats or just the ones in exportable_options?
        possible_formats = exportable_options[:formats].join('|')
        if match = /^create_(#{possible_formats})_report$/.match(method_id.to_s)
          format = match.captures.first
          self.create_report(format, *arguments)
        elsif match = /^to_(#{possible_formats})_export$/.match(method_id.to_s)
          format = match.captures.first
          self.to_export(format, *arguments)
        else
          super
        end
      end

      # <tt>validate_export_format</tt> ensures that the requested export format is valid.
      def validate_export_format(format)
        unless MakeExportable.exportable_formats.keys.include?(format.to_sym)
          raise MakeExportable::FormatNotFound.new("#{format} is not a supported format.")
        end
        unless exportable_options[:formats].include?(format.to_sym)
          raise MakeExportable::FormatNotFound.new("#{format} format is not allowed on this class.")
        end
      end

      # <tt>validate_data_lengths</tt> ensures that the headers and all data rows are of the 
      # same size. (This is an important data integrity check if you are using NoSQL.)
      def validate_data_lengths(data_set, data_headers=nil)
        row_length = !data_headers.blank? ? data_headers.size : data_set[0].size
        if data_set.any? {|row| row_length != row.size }
          raise MakeExportable::ExportFault.new("Headers and all rows in the data set must be the same size.")
        end
      end

  end

  module InstanceMethods

    # <tt>export_attribute</tt> returns the export value of an attribute or method.
    # By default, this is simply the value of the attribute or method itself, 
    # but the value can be permanently overridden with another value by defining 
    # a method called "#{attribute}_export". The alternate method will *always* 
    # be called in place of the original one. At a minimum, this is useful 
    # when a date should be formatted when exporting or when booleans should  
    # always export as "Yes"/"No".  But it can do more, performing any amount of 
    # processing or additional queries, as long as in the end it returns a value 
    # for the export to use.
    # Sending an attribute name that does not exist will return an empty string.
    def export_attribute(attribute)
      begin
        if self.respond_to?("#{attribute}_export")
          return self.send("#{attribute}_export").to_s
        else
          return self.send(attribute).to_s
        end
      rescue
        return ""
      end
    end

  end

end
