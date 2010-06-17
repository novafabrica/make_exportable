require File.expand_path('../../spec_helper', __FILE__)

describe "Make Exportable" do

  before(:each) do
    clean_database!
  end

  describe MakeExportable do

    before(:each) do
      clean_database!
    end

    # For simply having MakeExportable loaded as a gem/plugin
    describe "mattr_accessor :exportable_classes" do

      it "should begin as an empty hash" do
        MakeExportable.exportable_classes.class.should == Hash
        MakeExportable.exportable_classes.should == {}
      end

      it "should be readable and writable" do
        MakeExportable.exportable_classes[:testkey] = 'testvalue'
        MakeExportable.exportable_classes.should == {:testkey => 'testvalue'}
        MakeExportable.exportable_classes[:testkey].should == 'testvalue'
        MakeExportable.exportable_classes.delete(:testkey)
      end
    end

    describe "mattr_accessor :exportable_formats" do
      
      it "should be a hash" do
        MakeExportable.exportable_classes.class.should == Hash
      end
      
      it "should be readable and writable" do
        MakeExportable.exportable_formats[:testkey] = 'testvalue'
        MakeExportable.exportable_formats.should == {:testkey => 'testvalue'}
        MakeExportable.exportable_formats[:testkey].should == 'testvalue'
        MakeExportable.exportable_formats.delete(:testkey)
      end

      it "should contain keys for the supported format types" do
        MakeExportable.exportable_formats.should_not be_nil
        MakeExportable.exportable_formats.key?(:csv ).should be_true
        MakeExportable.exportable_formats.key?(:xls ).should be_true
        MakeExportable.exportable_formats.key?(:html).should be_true
        MakeExportable.exportable_formats.key?(:json).should be_true
        MakeExportable.exportable_formats.key?(:tsv ).should be_true
        MakeExportable.exportable_formats.key?(:xml ).should be_true
      end
      
      it "should have the correct format class as a value for each key" do
        MakeExportable.exportable_formats[:csv ].should == MakeExportable::CSV
        MakeExportable.exportable_formats[:xls ].should == MakeExportable::Excel
        MakeExportable.exportable_formats[:html].should == MakeExportable::HTML
        MakeExportable.exportable_formats[:json].should == MakeExportable::JSON
        MakeExportable.exportable_formats[:tsv ].should == MakeExportable::TSV
        MakeExportable.exportable_formats[:xml ].should == MakeExportable::XML
      end
      
    end

    describe "extenstions to ActiveRecord's class methods" do
      
      it "should include MakeExportable's ActiveRecordBaseMethods" do
        ActiveRecord.methods.include?(:make_exportable).should be_true
        ActiveRecord.methods.include?(:exportable?).should be_true
      end
      
    end
    
    
    # Once classes add MakeExportable's functionality
    describe "classes declaring make_exportable" do

      before(:each) do
        class User
          make_exportable
        end
      end

      it "should be included in MakeExportable.exportable_tables" do
        MakeExportable.exportable_classes.should == {'User' => User}
      end

      it "should have MakeExportable's ClassMethods" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.methods.include?(:exportable?).should be_true
          User.methods.include?(:to_export).should be_true
          User.methods.include?(:get_export_data).should be_true
          User.methods.include?(:create_report).should be_true
        else
          User.methods.include?("exportable?").should be_true
          User.methods.include?("to_export").should be_true
          User.methods.include?("get_export_data").should be_true
          User.methods.include?("create_report").should be_true
        end
      end
      
      it "should not expose MakeExportable's ClassMethods which are private" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.methods.include?(:find_export_data).should be_false
          User.methods.include?(:map_export_data).should be_false
          User.methods.include?(:validate_export_format).should be_false
          User.methods.include?(:validate_export_data_lengths).should be_false
        else
          User.methods.include?("find_export_data").should be_false
          User.methods.include?("map_export_data").should be_false
          User.methods.include?("validate_export_format").should be_false
          User.methods.include?("validate_export_data_lengths").should be_false
        end
      end

      it "should have MakeExportable's InstanceMethods" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:export_attribute).should be_true
        else
          User.instance_methods.include?("export_attribute").should be_true
        end
      end

      it "should have an inheritable class accessor for exportable_options" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:exportable_options).should be_true
        else
          User.instance_methods.include?("exportable_options").should be_true
        end
      end

      describe "dynamically-named methods" do

        describe 'create_#{format}_report' do

          MakeExportable.exportable_formats.map do |format, v|
            it "should define the method create_#{format}_report" do
              User.should_receive(:create_report).with(format)
              User.send("create_#{format}_report")
            end
          end

          it "should return NoMethodError if the format is not supported" do
            lambda do
              User.create_xyz_report
            end.should raise_error(NoMethodError)
          end

        end

        describe 'to_#{format}_export' do

          MakeExportable.exportable_formats.map do |format, v|
            it "should define the method to_#{format}_export" do
              User.should_receive(:to_export).with(format)
              User.class_eval("to_#{format}_export")
            end
          end

          it "should return NoMethodError if the format is not supported" do
            lambda do
              User.to_xyz_export
            end.should raise_error(NoMethodError)
          end

        end

      end

      describe "not passing in options" do
        
        it "should set default values for key options" do
          User.exportable_options.keys.sort.should == [:columns, :formats, :scopes]
        end
        
        it "should set :columns to all database columns" do
          User.exportable_options[:columns].should == [:first_name, :last_name, :password, :email, :is_admin]
        end
        
        it "should set :formats to all supported formats" do
          User.exportable_options[:formats].should == [:csv, :xls, :html, :json, :tsv, :xml]
        end
        
        it "should set :scopes to an empty array" do
          User.exportable_options[:scopes].should == []
        end
        
      end
      
      # TODO: add tests for calling make_exportable with options
      describe "passing in options" do
        
        it "should toss out invalid options" # i.e. they don't make it to exportable_options
        # valid_options = [:as, :only, :except, :scopes, :conditions, :order, :include,
        #                  :group, :having, :limit, :offset, :joins]
        
        describe ":only/:except options" do
          # same for both :only and :except
          it "should not appear in exportable_options"
          it "should allow attributes/methods which are not database columns"
          it "should allow column names to be either strings or symbols"
          it "should allow a single column name or an array of names" # Array.wrap
          
          # unique for :only option
          it "should replace the default columns saved in exportable_options[:columns]"
          it "should not try to catch bogus attribute/method names" # unless we add a check for this
          
          # unique for :except option
          it "should subtract from the default columns saved in exportable_options[:columns]"
          it "should ignore bogus attribute/method names"
          
        end
        
        describe ":as option" do
          it "should not appear in exportable_options"
          it "should subtract from all supported formats saved in exportable_options[:formats]"
          it "should allow format names to be either strings or symbols"
          it "should allow a single format name or an array of names" # Array.wrap
          it "should ignore formats not in the supported formats"
          it "should raise an error if only unsupported formats are passed in"
        end
        
        describe ":scopes option" do
          it "should be saved unchanged in exportable_options[:scopes]"
        end
        
        describe "finder options" do
          
          [:conditions, :order, :include, :group, :having, :limit, :offset, :joins].each do |opt|
            it "should save :#{opt} unchanged in exportable_options[:#{opt}]"
          end
          
        end
      end

    end
    
    describe "MakeExportable::ClassMethods" do
      
      before(:each) do
        class User
          make_exportable
        end
        clean_database!
        User.create(:first_name => "user_1", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.at(0))
        User.create(:first_name => "user_2", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.at(0))
      end

      describe "exportable?" do
        it "should be false for regular ActiveRecord classes" do
          Post.exportable?.should be_false
        end

        it "should be true for classes that call make_exportable" do
          User.exportable?.should be_true
        end

        it "should be true when the argument value is an allowed format for this class"
        
        it "should be false when the argument value is not an allowed format for this class" 
      
      end
      
      describe "to_export" do
        
        # TODO: Column-specifying tests should move to get_export_data
        context "with explicit columns given" do

          context "csv format" do

            it "should export the columns as csv" do
              User.to_export( "csv", :only => [:first_name, "is_admin"]).should ==  ["First Name,Is Admin\nuser_1,false\nuser_2,false\n", "text/csv; charset=utf-8; header=present"]
            end

            it "should export the columns as csv and detect that there is no header" do
              User.to_export( "csv", :only => [:first_name, "is_admin"], :headers => "").should ==  ["user_1,false\nuser_2,false\n", "text/csv; charset=utf-8; header=absent"]
            end

          end

          context "excel format" do

            it "should export the columns as xls" do
              User.to_export( "xls", :only =>  [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=present"]
            end

            it "should export the columns as xls and detect no header" do
              User.to_export( "xls", :only =>  [:first_name, "is_admin"], :headers => "").should == ["<table>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=absent"]
            end

          end

          context "tsv format" do

            it "should export the columns as tsv" do
              User.to_export( "tsv", :only => [:first_name, "is_admin"]).should == ["First Name\tIs Admin\nuser_1\tfalse\nuser_2\tfalse\n", "text/tab-separated-values; charset=utf-8; header=present"]
            end

            it "should export the columns as tsv  and detect no header" do
              User.to_export( "tsv", :only => [:first_name, "is_admin"], :headers => "").should == ["user_1\tfalse\nuser_2\tfalse\n", "text/tab-separated-values; charset=utf-8; header=absent"]
            end

          end

          context "html format" do

            it "should export the columns as html" do
              User.to_export( "html", :only => [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=present"]
            end

            it "should export the columns as html and detect no header" do
              User.to_export( "html", :only => [:first_name, "is_admin"], :headers => "").should == ["<table>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=absent"]
            end

          end

          context "xml format" do

            it "should export the columns as xml" do
              User.to_export( "xml", :only => [:first_name, "is_admin"]).should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records>\n\t<record>\n\t\t<first-name>user_1</first-name>\n\t\t<is-admin>false</is-admin>\n\t</record>\n\t<record>\n\t\t<first-name>user_2</first-name>\n\t\t<is-admin>false</is-admin>\n\t</record>\n</records>\n", "application/xml; header=present"]
            end

            it "should export the columns as xml and detect no header" do
              User.to_export( "xml", :only => [:first_name, "is_admin"], :headers => "").should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records>\n\t<record>\n\t\t<attribute_0>user_1</attribute_0>\n\t\t<attribute_1>false</attribute_1>\n\t</record>\n\t<record>\n\t\t<attribute_0>user_2</attribute_0>\n\t\t<attribute_1>false</attribute_1>\n\t</record>\n</records>\n", "application/xml; header=absent"]
            end

          end

          context "json format" do

            #TODO figure out a way to test more then one variable. Because it's a hash converted to a string
            it "should export the columns as json" do
              User.to_export( "json", :only => [:first_name]).should ==["[{\"first_name\":\"user_1\"},{\"first_name\":\"user_2\"}]", "application/json; charset=utf-8;"]
            end

          end

          #We really could test this one forever.
          it "should export the columns designated by the options given" do
            User.to_export( "csv", :only => [:first_name, "is_admin"],  :conditions => {:first_name => "user_1"}).should ==["First Name,Is Admin\nuser_1,false\n", "text/csv; charset=utf-8; header=present"]
          end

        end

        context "default columns" do

          it "should export the columns as csv" do
            User.to_export( "csv").should == ["Id,First Name,Last Name,Password,Email,Is Admin,Created At,Updated At\n1,user_1,Doe,\"\",\"\",false,Wednesday December 31 1969 at 07:00PM,Wednesday December 31 1969 at 07:00PM\n2,user_2,Doe,\"\",\"\",false,Wednesday December 31 1969 at 07:00PM,Wednesday December 31 1969 at 07:00PM\n", "text/csv; charset=utf-8; header=present"]
          end

          it "should export the columns as xls" do
            User.to_export( "xls").should == ["<table>\n\t<tr>\n\t\t<th>Id</th>\n\t\t<th>First Name</th>\n\t\t<th>Last Name</th>\n\t\t<th>Password</th>\n\t\t<th>Email</th>\n\t\t<th>Is Admin</th>\n\t\t<th>Created At</th>\n\t\t<th>Updated At</th>\n\t</tr>\n\t<tr>\n\t\t<td>1</td>\n\t\t<td>user_1</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t</tr>\n\t<tr>\n\t\t<td>2</td>\n\t\t<td>user_2</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=present"]
          end

          it "should export the columns as tsv" do
            User.to_export( "tsv").should == ["Id\tFirst Name\tLast Name\tPassword\tEmail\tIs Admin\tCreated At\tUpdated At\n1\tuser_1\tDoe\t\t\tfalse\tWednesday December 31 1969 at 07:00PM\tWednesday December 31 1969 at 07:00PM\n2\tuser_2\tDoe\t\t\tfalse\tWednesday December 31 1969 at 07:00PM\tWednesday December 31 1969 at 07:00PM\n", "text/tab-separated-values; charset=utf-8; header=present"]
          end

          it "should export the columns as html" do
            User.to_export( "html").should == ["<table>\n\t<tr>\n\t\t<th>Id</th>\n\t\t<th>First Name</th>\n\t\t<th>Last Name</th>\n\t\t<th>Password</th>\n\t\t<th>Email</th>\n\t\t<th>Is Admin</th>\n\t\t<th>Created At</th>\n\t\t<th>Updated At</th>\n\t</tr>\n\t<tr>\n\t\t<td>1</td>\n\t\t<td>user_1</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t</tr>\n\t<tr>\n\t\t<td>2</td>\n\t\t<td>user_2</td>\n\t\t<td>Doe</td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td>false</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t\t<td>Wednesday December 31 1969 at 07:00PM</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=present"]
          end

          it "should export the columns as xml" do
            User.to_export( "xml").should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records>\n\t<record>\n\t\t<id>1</id>\n\t\t<first-name>user_1</first-name>\n\t\t<last-name>Doe</last-name>\n\t\t<password></password>\n\t\t<email></email>\n\t\t<is-admin>false</is-admin>\n\t\t<created-at>Wednesday December 31 1969 at 07:00PM</created-at>\n\t\t<updated-at>Wednesday December 31 1969 at 07:00PM</updated-at>\n\t</record>\n\t<record>\n\t\t<id>2</id>\n\t\t<first-name>user_2</first-name>\n\t\t<last-name>Doe</last-name>\n\t\t<password></password>\n\t\t<email></email>\n\t\t<is-admin>false</is-admin>\n\t\t<created-at>Wednesday December 31 1969 at 07:00PM</created-at>\n\t\t<updated-at>Wednesday December 31 1969 at 07:00PM</updated-at>\n\t</record>\n</records>\n", "application/xml; header=present"]
          end

          #We really could test this one forever.
          it "should export the columns designated by the options given" do
            User.to_export( "csv", :conditions => {:first_name => "user_1"}).should == ["Id,First Name,Last Name,Password,Email,Is Admin,Created At,Updated At\n1,user_1,Doe,\"\",\"\",false,Wednesday December 31 1969 at 07:00PM,Wednesday December 31 1969 at 07:00PM\n", "text/csv; charset=utf-8; header=present"]
          end
        end

        # TODO: test :headers => true/false/['x', 'y', 'z']
        # That's it--most everything has been moved out of to_export
      end

      describe "get_export_data" do

        # TODO: test how passed in :scopes and find options are merged and applied
        #   (essentially testing :find_export_data)
        # TODO: test how :only/:except are merged and selected
        #   (essentially testing :map_export_data)
        # Some are already below but just need to be organized into finding / mapping.

        it "should create order array of arrays of ordered column data" do
          User.get_export_data(:only => [:first_name, :last_name]).should == [["user_1", "Doe"], ["user_2", "Doe"]]
        end

        it "should chainable on named_scopes" do
          User.a_limiter.get_export_data(:only => [:first_name, :last_name]).should == [["user_1", "Doe"]]
        end

        it "should allow a scope to be sent" do
          User.get_export_data(:only => [:first_name, :last_name], :scopes => ['a_limiter']).should == [["user_1", "Doe"]]
        end

        it "should allow multiple scopes to be sent" do
          User.get_export_data(:only =>[:first_name, :last_name], :scopes => ['a_limiter', "order_by"]).should == [["user_2", "Doe"]]
        end

        it "should create order array of arrays of ordered column data by the options given" do
          User.get_export_data(:only => [:first_name, :last_name], :order => " ID DESC").should == [["user_2", "Doe"], ["user_1", "Doe"]]

          User.get_export_data(:only => [:first_name, :last_name], :conditions => {:first_name => "user_1"}).should == [["user_1", "Doe"]]
        end

      end

      describe "create_report" do
        
        # TODO: test :headers => true/false/['x', 'y', 'z']
        # TODO: test that different format classes can be selected to return different results
        
        it "should raise an FormatNotFound if the format is not supported" do
          lambda do
            User.create_report("NONSUPPORTED")
          end.should raise_error(MakeExportable::FormatNotFound)
        end

        it 'should export an array of header and array of arrays of rows in the specified format' do
          User.create_report("csv", [[ "data", 'lovely data'],["", "more lovely data"]], :headers => ["Title", "Another Title"]).should == ["Title,Another Title\ndata,lovely data\n\"\",more lovely data\n", "text/csv; charset=utf-8; header=present"]
        end

        it "should raise an ExportFault if the datasets are not all the same size" do
          lambda do
            User.create_report("csv", [[ "data", 'lovely data'],["more lovely data"]], :headers =>["Title", "Another Title"])
          end.should raise_error(MakeExportable::ExportFault)
        end

      end

    end

    describe "MakeExportable::InstanceMethods" do

      describe "#export_attribute" do

        before(:each) do
          class User
            make_exportable
          end
          @user = User.create(:first_name => "Carl", :last_name => "Joans")
        end

        it "should return attribute values" do
          @user.export_attribute('first_name').should == "Carl"
        end

        # FIXME: This test is not quite right--really should use a method name that 
        # exactly matches a DB column or another method.
        it 'should allow #{method}_export to override the original method'  do
          @user.export_attribute('admin').should == "monkey"
        end

        # TODO: Would it be better behaviour to raise an error?
        it "should return an empty string if the attribute doesn't exist" do
          @user.export_attribute('ful_name').should == ""
        end

        it "should be able to call methods as attributes during exporting" do
          @user.export_attribute('full_name').should == "Carl Joans"
        end

      end

    end


  end

  # TODO: each format should have a spec file
  # TODO: MakeExportableHelper should have a spec file
  
end
