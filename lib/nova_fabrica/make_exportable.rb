# Copyright (c) 2010 Kevin Skoglund
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module NovaFabrica #:nodoc:
  module MakeExportable #:nodoc:



    # Constant that contains the supported formats, human readable names, and the mime-type
    # Supported formats at the moment are csv, tsv, xls, xml and html
    SUPPORTED_FORMATS = {
      :csv => {:name => 'Comma-separated (CSV)', :data_type => "text/csv; charset=utf-8; header=present"},
      :tsv => {:name => 'Tab-separated (TSV)', :data_type => "text/tab-separated-values; charset=utf-8; header=present"},
      :xls => {:name => 'Excel', :data_type => "application/vnd.ms-excel; charset=utf-8; header=present"},
      :xml => {:name => 'XML', :data_type => "application/xml; header=present"},
      :html => {:name => 'HTML', :data_type => "text/html; charset=utf-8; header=present"}
    }

    mattr_accessor :exportable_tables
    # Contains an array of exportable tables
    @@exportable_tables = []

    mattr_accessor :exportable_formats
    # Contains the exportable formats for the included class, is initiated with all supported formats
    @@exportable_formats = SUPPORTED_FORMATS.inject([])  { |result, hash| result << hash[0] }

    def self.included(target)
      remove_any_unsupported_formats
      # We do this for capatibility with Rails 2
      if CSV.const_defined? :Reader
        require 'fastercsv' if self.exportable_formats.include?(:csv)
      else
      end
      target.extend(BaseMethods)
    end

    # TODO: Reconsider the location of these 3 export methods.
    # exportable_format_supported: used by Model
    # format_name: used by the Controller & View
    # format_data_type_for: used by Model, but could be Controller
    def self.exportable_format_supported?(format)
      return false unless NovaFabrica::MakeExportable::SUPPORTED_FORMATS.has_key?(format.to_sym)
      return false unless NovaFabrica::MakeExportable.exportable_formats.include?(format.to_sym)
      return true
    end

    def self.format_name(format)
      raise NovaFabrica::MakeExportableErrors::ExportFormatNotFoundError.new("#{format} not supported") unless exportable_format_supported?(format)
      return SUPPORTED_FORMATS[format.to_sym][:name]
    end

    def self.format_data_type_for(format)
      raise NovaFabrica::MakeExportableErrors::ExportFormatNotFoundError.new("#{format} not supported") unless exportable_format_supported?(format)
      return SUPPORTED_FORMATS[format.to_sym][:data_type]
    end

    private

      def self.remove_any_unsupported_formats
        desired   = self.exportable_formats
        supported = SUPPORTED_FORMATS.keys
        allowed   = desired & supported   # '&' is Set Intersection
        self.exportable_formats = allowed
      end


      module BaseMethods

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
        # For finer controll you can include any options you would normally apply to a find method
        #
        # Example:
        #
        # class Customer < ActiveRecord::Base
        #  make_exportable :order => 'last_name ASC, first_name ASC', :conditions => {:active => true}
        # end
        #

        def make_exportable(options={})
          unless NovaFabrica::MakeExportable.exportable_tables.include?(self.table_name)
            NovaFabrica::MakeExportable.exportable_tables << self.table_name
          end
          extend NovaFabrica::MakeExportable::ClassMethods
          include NovaFabrica::MakeExportable::InstanceMethods
          write_inheritable_attribute :exportable_options, options
          class_inheritable_reader :exportable_options
        end

      end

      module ClassMethods

        # <tt>to_export</tt> is a generic class method to allow you to simply export all records for an entire class.
        # It takes for it's arguments the format you wish to use, the columns or method calls you wish to export and the options to be used in your find operation. It also will use any options designated when make_exportable was initialized for the class unless overwritten.
        #
        # Basic Example:
        #
        # User.to_export('xml', [:first_name, :last_name, :username])
        #
        #
        # Finer Controller:

        # User.to_export('csv', [:first_name, :last_name, :username], :limit => 5, :order => :username)
        def to_export(format, columns=[], options={})
          # I feel it's inefficient for this method to run if no columns are given MB
          raise NovaFabrica::MakeExportableErrors::NoColumnsGivenError.new("You must include the columns or methods that you want to export") if columns.empty?
          data_rows = self.get_export_data(columns, options)
          return self.create_report(format, columns, data_rows)
        end

        # <tt>get_export_data</tt> is a generic class method that finds all objects of a given class fitting the options passed into it and outputs an ordered array of arrays containing the objects data to be used with create_report for
        def get_export_data(columns, options={})
          if !options.is_a?(Hash)
            collection = self.send(options)
          elsif options.empty? &&  !exportable_options.is_a?(Hash)
            collection = self.send(options)
          else
            options.reverse_merge!(exportable_options)
            collection = self.find(:all, options)
          end
          rows = collection.inject([]) {|memo, item| memo << item.export_columns(columns) }
          return rows
        end

        # <tt>create_report</tt> is a generic class method to allow you to export data in a easy to describe manner.
        # It takes for it's arguments the format you wish to use, the array headers for each column you wish to export and the exportable rows as described as arrays inside of an array
        #
        # TODO should we check to make sure that the rows are all the same size. I understand this might slow the plugin down to much. But the export will be useless unless row size is kept correct. Barring of course XML.
        def create_report( format, headers=[], rows=[] )
          raise NovaFabrica::MakeExportableErrors::ExportFormatNotFoundError.new("#{format} not supported by MakeExportable") unless NovaFabrica::MakeExportable.exportable_format_supported?(format)
          data_type = NovaFabrica::MakeExportable.format_data_type_for(format)
          data_string = eval("generate_#{format.to_s}(headers, rows)")
          return data_string, data_type
        end


        private #-----------

        # Overwriting method_missing allows the class to accept dynamicly named methods
        # such as: Class.create_csv_for(), Class.create_xml_report_for, or Class.to_xls_report()
        def method_missing(method_id, *arguments)
          if match = /^create_(#{NovaFabrica::MakeExportable.exportable_formats.join('|')})(_report)?_for$/.match(method_id.to_s)
            format = match.captures.first
            self.create_report(format, *arguments)
          elsif match = /^to_(#{NovaFabrica::MakeExportable.exportable_formats.join('|')})_report$/.match(method_id.to_s)
            format = match.captures.first
            self.to_export(format, *arguments)
          else
            super
          end
        end

        def generate_csv( field_names, data_rows )
          if CSV.const_defined? :Reader
            FasterCSV.generate do |csv|
              csv << field_names.map {|fn| fn.to_s.gsub(/_/, " ").titleize }
              data_rows.each do |row|
                csv << row
              end
            end
          else
            CSV.generate do |csv|
              csv << field_names.map {|fn| fn.to_s.gsub(/_/, " ").titleize }
              data_rows.each do |row|
                csv << row
              end
            end
          end
        end

        def generate_tsv( field_names, data_rows )
          tsv = field_names.map {|fn| fn.to_s.gsub(/_/, " ").titleize }.join("\t") << "\n"
          data_rows.each do |row|
            tsv << row.map {|field| clean_for_tsv(field)}.join("\t") << "\n"
          end
          return tsv
        end

        def generate_html( field_names, data_rows)
          html = "<table>\n"
          html << "\t<tr>\n#{field_names.map {|fn| "\t\t<th>#{fn.to_s.gsub(/_/, " ").titleize}</th>\n" }.join}\t</tr>\n"
          data_rows.each do |row|
            html << "\t<tr>\n#{row.map {|field| "\t\t<td>#{clean_for_html(field)}</td>\n"}.join}\t</tr>\n"
          end
          html << "</table>\n"
          return html
        end
        alias :generate_xls :generate_html

        def generate_xml( field_names, data_rows )
          cname = self.class_name.downcase.dasherize
          xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
          xml << "<#{cname.pluralize}>\n"
          data_rows.each do |row|
            xml << "\t<#{cname}>\n"
            row.each_with_index do |field,i|
              fn = field_names[i].to_s.dasherize
              xml << "\t\t<#{fn}>#{clean_for_xml(field)}</#{fn}>\n"
            end
            xml << "\t</#{cname}>\n"
          end
          xml << "</#{cname.pluralize}>\n"
          return xml
        end

        def clean_for_tsv( string )
          return string.gsub(/(\t|\\t)/, '  ')
        end

        # <tt>clean_for_html</tt> sanitizes < and > for output in html.
        def clean_for_html(string)
          string.gsub!(/</, '&lt;')
          string.gsub!(/>/, '&gt;')
          return string
        end

        # <tt>clean_for_xml</tt> sanitizes &, <, >, ", and ' for output in xml.
        def clean_for_xml( string )
          string.gsub!(/&/, '&amp;')
          string.gsub!(/</, '&lt;')
          string.gsub!(/>/, '&gt;')
          string.gsub!(/"/, '&quot;')
          string.gsub!(/'/, '&apos;')
          return string
        end

      end

      module InstanceMethods

        # <tt>export_columns</tt> returns an array of the data returned by
        # exporting each column in turn.
        def export_columns(columns)
          columns.collect {|column| export_attribute(column) }
        end

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

end
