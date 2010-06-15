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

    # <tt>make_exportable</tt> is a generic method that when used in a class  it will
    # * include the MakeExporable Module
    # * Extend the class methods by the MakeExportable::ClassMethods
    # * Include the MakeExportable::InstanceMethods on the class Instances
    # * Add a class accessor called exportable_options to hold Find options to be applied to the to_export method
    #
    # Example:
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable
    #   end
    #
    # The method allows for fine controll of how the class will be defaultly exported via a hash
    #
    # These options include
    # * :only and :except - assigns which columns you would like to export.
    # * :scopes - pass in an array of scopes to be attached to the Class before export
    # * :as - specifies the default format to export as
    #
    # For capatibility with Rails 2.3 we allow any option found in the find option at the moment.
    # This will be depricated in future version
    #
    # Examples:
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :order => 'last_name ASC, first_name ASC', :conditions => {:active => true}}
    #   end
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :only => [:id, :username, :full_name]
    #   end
    #
    #   class Customer < ActiveRecord::Base
    #     make_exportable :scopes => [:new_signups, :with_referals]
    #   end
    #
    def make_exportable(options={})
      # register the class as exportable
      MakeExportable.exportable_classes[self.class_name] = self

      valid_options = [:as, :only, :except, :scopes, :conditions, :order, :include,
                       :group, :having, :limit, :offset, :joins]
      options.slice!(*valid_options)

      # Determine the exportable formats, default to all registered formats
      # and remove formats using the :as option
      # TODO: make it impossible to provide no valid formats
      options[:formats] = MakeExportable.exportable_formats.keys
      if format_options = options.delete(:as)
        options[:formats] = MakeExportable.exportable_formats.keys & Array.wrap(format_options)
      end

      # Determine the exportable columns, default to all columns and then
      # remove columns using the :only and :except options
      options[:columns] = self.column_names.map(&:to_sym)
      options = self.process_only_and_except(:columns, options)

      options[:scopes] ||= []

      # exportable options are :formats, :columns, :scopes
      write_inheritable_attribute :exportable_options, options
      class_inheritable_reader :exportable_options

      extend MakeExportable::ClassMethods
      include MakeExportable::InstanceMethods

    end

    def exportable?(format=nil)
      return false
    end

    # TODO: move this out of ActiveRecord::Base
    # MB where should we move this too?
    def process_only_and_except(key, hash)
      #If hash does not contain only or except will return the hash unmodulated.
      if only_options = hash.delete(:only)
        only_array = Array.wrap(only_options).map {|i| i.to_sym}
        hash[key] = only_array
      end
      if except_options = hash.delete(:except)
        only_array = Array.wrap(except_options).map {|i| i.to_sym}
        hash[key] = hash[key] - except_array
      end
      return hash
    end

  end

  module ClassMethods

    # With no argument, returns true if the class has "make_exportable"
    # With a format as an argument, returns true if the format is enabled
    # for this class
    def exportable?(format=nil)
      return exportable_options[:formats].include?(format.to_sym) if format
      return true
    end

    # <tt>to_export</tt> is a generic class method to allow you to simply export all records for an entire class.
    # It takes for it's arguments the format you wish to use, and an option hash.
    #
    # The method allows for fine controll of how the class will be defaultly exported via a hash
    #
    # These options include
    # * :only and :except - assigns which columns you would like to export.
    # * :scopes - pass in an array of scopes to be attached to the Class before export
    # * :headers - override the default headers for the exported attributes. Accepts a empty string
    #
    # For capatibility with Rails 2.3 we allow any option found in the find option at the moment.
    # This will be depricated in future version
    #
    # User.to_export('xml', :columns => [:first_name, :last_name, :username])
    #
    #
    # Finer Controller:
    #
    # User.order_by_username.to_export('csv', :only =>  [:first_name, :last_name, :username])
    def to_export(format, options={})
      options.reverse_merge!(exportable_options.slice([:only, :except]))
      options = self.process_only_and_except(:columns, options)
      data_set = self.get_export_data(options)
      return self.create_report(format, data_set, options)
    end

    # <tt>get_export_data</tt> is a generic class method that finds all objects of a given
    # class fitting the options passed into it and outputs an ordered array of arrays
    # containing the objects data to be used with create_report for
    def get_export_data(options={})
      options.reverse_merge!(exportable_options)
      find_options = options.slice(:conditions, :order, :include, :group, :having,
                                   :limit, :offset, :joins)
      #For rails 2.3 capatibility
      collection = ActiveRecord::VERSION::MAJOR >= 3 ? self.scoped : self
      options[:scopes].each do |scope|
        collection = collection.send(scope)
      end
      #For rails 2.3 capatibility
      if ActiveRecord::VERSION::MAJOR >= 3
        collection = collection.find(:all, find_options)
      else
        collection = collection.all
      end

      rows = collection.map do |item|
        options[:columns].map {|col| item.export_attribute(col) }
      end
      return rows
    end

    # <tt>create_report</tt> is a generic class method to allow you to export data in a easy to describe manner.
    # It takes for it's arguments the format you wish to use, the array headers for each column you wish to export and the exportable rows as described as arrays inside of an array
    def create_report(format, data_set=[], options={})
      validate_export_format(format)
      headers = options[:headers] || options[:columns].map(&:to_s)
      validate_data_lengths(data_set, headers)
      format_class = MakeExportable.exportable_formats[format.to_sym]
      formater = format_class.new(data_set, headers)
      return formater.generate, formater.mime_type
    end


    private

      # method_missing allows the class to accept dynamically named methods
      # such as: SomeClass.create_csv_report(), SomeClass.to_xls_export()
      def method_missing(method_id, *arguments)
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

      def validate_export_format(format)
        unless MakeExportable.exportable_formats.keys.include?(format.to_sym)
          raise MakeExportable::FormatNotFound.new("#{format} is not a supported format.")
        end
        unless exportable_options[:formats].include?(format.to_sym)
          raise MakeExportable::FormatNotFound.new("#{format} format is not allowed on this class.")
        end
      end

      # NoSQL makes this important
      def validate_data_lengths(data_set, data_headers=nil)
        row_length = !data_headers.blank? ? data_headers.size : data_set[0].size
        if data_set.any? {|row| row_length != row.size }
          raise MakeExportable::ExportFault.new("All rows must be the same length. (Are you setting the headers by hand?) (#{row_length} vs. #{data_set.first.size})")
        end
      end

  end

  module InstanceMethods

    # <tt>export_attribute</tt> returns the export value of an attribute.
    # By default, this is simply the value of the attribute itself, but the
    # value can be overridden in the model by defining a method called
    # "#{keyword}_export" where keyword can be either an attribute that
    # needs an alternative export value (for example, returning a formatted
    # date instead of the MySQL value) or can be any keyword that returns
    # any value (such as "last_transaction", "order_total", etc.)
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
