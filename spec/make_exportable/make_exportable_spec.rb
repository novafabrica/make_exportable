require File.expand_path('../../spec_helper', __FILE__)

describe "Make Exportable" do

  before(:each) do
    clean_database!
  end

  describe MakeExportable do

    # For simply having MakeExportable loaded as a gem/plugin
    describe "mattr_accessor :exportable_classes" do

      it "should be a hash" do
        MakeExportable.exportable_classes.class.should == Hash
      end

      it "should be readable and writable" do
        MakeExportable.exportable_classes[:testkey] = 'testvalue'
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
        MakeExportable.exportable_formats[:testkey].should == 'testvalue'
        MakeExportable.exportable_formats.delete(:testkey)
      end

      it "should contain keys for the supported format types" do
        MakeExportable.exportable_formats.should_not be_nil
        MakeExportable.exportable_formats.key?(:csv ).should be_truthy
        MakeExportable.exportable_formats.key?(:xls ).should be_truthy
        MakeExportable.exportable_formats.key?(:html).should be_truthy
        MakeExportable.exportable_formats.key?(:json).should be_truthy
        MakeExportable.exportable_formats.key?(:tsv ).should be_truthy
        MakeExportable.exportable_formats.key?(:xml ).should be_truthy
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
        if ActiveRecord::VERSION::MAJOR >= 3
          ActiveRecord::Base.methods.include?(:exportable?).should be_truthy
          ActiveRecord::Base.methods.include?(:make_exportable).should be_truthy
        else
          ActiveRecord::Base.methods.include?('exportable?').should be_truthy
          ActiveRecord::Base.methods.include?('make_exportable').should be_truthy
        end
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
        MakeExportable.exportable_classes['User'].should == User
      end

      it "should have MakeExportable's ClassMethods" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.methods.include?(:exportable?).should be_truthy
          User.methods.include?(:to_export).should be_truthy
          User.methods.include?(:get_export_data).should be_truthy
          User.methods.include?(:create_report).should be_truthy
        else
          User.methods.include?("exportable?").should be_truthy
          User.methods.include?("to_export").should be_truthy
          User.methods.include?("get_export_data").should be_truthy
          User.methods.include?("create_report").should be_truthy
        end
      end

      it "should not expose MakeExportable's ClassMethods which are private" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.methods.include?(:find_export_data).should be_falsey
          User.methods.include?(:map_export_data).should be_falsey
          User.methods.include?(:validate_export_format).should be_falsey
          User.methods.include?(:validate_export_data_lengths).should be_falsey
        else
          User.methods.include?("find_export_data").should be_falsey
          User.methods.include?("map_export_data").should be_falsey
          User.methods.include?("validate_export_format").should be_falsey
          User.methods.include?("validate_export_data_lengths").should be_falsey
        end
      end

      it "should have MakeExportable's InstanceMethods" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:export_attribute).should be_truthy
        else
          User.instance_methods.include?("export_attribute").should be_truthy
        end
      end

      it "should have an inheritable class accessor for exportable_options" do
        if ActiveRecord::VERSION::MAJOR >= 3
          User.instance_methods.include?(:exportable_options).should be_truthy
        else
          User.instance_methods.include?("exportable_options").should be_truthy
        end
      end

      describe "dynamically-named methods" do

        describe 'create_#{format}_report' do

          MakeExportable.exportable_formats.map do |format, v|
            it "should define the method create_#{format}_report" do
              User.should_receive(:create_report).with(format.to_s)
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
              User.should_receive(:to_export).with(format.to_s)
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
          User.exportable_options.keys.map(&:to_s).sort.should == ["columns", "formats", "scopes"]
        end

        it "should set :columns to all database columns" do
          User.exportable_options[:columns].should == [:id, :first_name, :last_name, :password, :email, :is_admin, :created_at, :updated_at]
        end

        it "should set :formats to all supported formats" do
          User.exportable_options[:formats].map(&:to_s).sort.should == ["csv", "html", "json", "tsv", "xls", "xml"]
        end

        it "should set :scopes to an empty array" do
          User.exportable_options[:scopes].should == []
        end

      end

      describe "passing in options" do

        it "should toss out invalid options" do

          class Post < ActiveRecord::Base
            make_exportable :nonsense => "this should not be included", :offset => 20
          end

          # valid_options = [:as, :only, :except, :scopes, :conditions, :order, :include,
          #                  :group, :having, :limit, :offset, :joins]
          Post.exportable_options.include?(:nonsense).should be_falsey
          Post.exportable_options.include?(:offset).should be_truthy
        end

        describe ":only/:except options" do

          it "should not appear in exportable_options" do
            # these get removed and converted into :columns
            class Post < ActiveRecord::Base
              make_exportable :only => [:this, :that, :another], :except => [:title]
            end
            Post.exportable_options.include?(:only).should be_falsey
            Post.exportable_options.include?(:except).should be_falsey
          end

          it "should allow column names to be either strings or symbols" do
            class Post < ActiveRecord::Base
              make_exportable :only => ["full_name", :symbol_method]
            end
            Post.exportable_options[:columns].should == [:full_name, :symbol_method]
          end

          it "should allow a single column name or an array of names" do
            class Post < ActiveRecord::Base
              make_exportable :only => "full_name"
            end
            Post.exportable_options[:columns].should == [:full_name]
          end

          # unique for :only option
          it "should allow attributes/methods which are not database columns" do

            class Post < ActiveRecord::Base
              make_exportable :only => ["a_method_name", "another_method"]
            end

            Post.exportable_options[:columns].should == [:a_method_name, :another_method]

          end

          it "should replace the default columns saved in exportable_options[:columns]" do

            class Post < ActiveRecord::Base
              make_exportable :only => ["a_method_name", "another_method"]
            end

            Post.exportable_options[:columns].should == [:a_method_name, :another_method]
          end

          # unless we add a check for this
          it "should not try to catch bogus attribute/method names" do
            class Post < ActiveRecord::Base
              make_exportable :only => ["full_name", "another_method"]
            end
            Post.exportable_options[:columns].should == [:full_name, :another_method]
          end

          # unique for :except option
          it "should subtract from the default columns saved in exportable_options[:columns]" do

            class Post < ActiveRecord::Base
              make_exportable :except => [:created_at, :updated_at]
            end

            Post.exportable_options[:columns].should == [:id, :title, :content, :approved]
          end

          it "should ignore bogus attribute/method names" do
            class Post < ActiveRecord::Base
              make_exportable :except => [:created_at, :updated_at, :bogus]
            end
            Post.exportable_options[:columns].should == [:id, :title, :content, :approved]
          end

        end

        describe ":as option" do

          it "should not appear in exportable_options" do
            class Post < ActiveRecord::Base
              make_exportable :as => [:csv, "xml"]
            end
            Post.exportable_options.include?(:as).should be_falsey
          end

          it "should allow format names to be either strings or symbols" do
            class Post < ActiveRecord::Base
              make_exportable :as => [:csv, "xml"]
            end
            Post.exportable_options[:formats].map(&:to_s).sort.should == ["csv", "xml"]
          end

          it "should allow a single format name or an array of names" do
            class Post < ActiveRecord::Base
              make_exportable :as => :json
            end
            Post.exportable_options[:formats].should == [:json]
          end

          it "should ignore formats not in the supported formats" do
            class Post < ActiveRecord::Base
              make_exportable :as => [:csv, "unsupported"]
            end
            Post.exportable_options[:formats].should == [:csv]
          end

          it "should raise an error if only unsupported formats are passed in" do
            lambda do
              class Post < ActiveRecord::Base
                make_exportable :as => "unsupported"
              end
            end.should raise_error(MakeExportable::FormatNotFound)
          end
        end

        describe ":scopes option" do
          it "should be saved unchanged in exportable_options[:scopes]" do
            Post.class_eval("make_exportable :scopes => [:scope1, :scope2]")
            Post.exportable_options[:scopes].should == [:scope1, :scope2]
          end
        end

        describe "finder options" do
          [:conditions, :order, :include, :group, :having, :limit, :offset, :joins].each do |opt|
            it "should save :#{opt} unchanged in exportable_options[:#{opt}]" do
              Post.class_eval("make_exportable :#{opt} => 'accepts anything trusting the user'")
              Post.exportable_options[opt].should == "accepts anything trusting the user"              
            end
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
          Unexportable.exportable?.should be_falsey
        end

        it "should be true for classes that call make_exportable" do
          User.exportable?.should be_truthy
        end

        it "should be true when the argument value is an allowed format for this class" do
          User.exportable?("csv").should be_truthy
        end

        it "should be false when the argument value is not an allowed format for this class" do
          User.exportable?("unsupported").should be_falsey
        end

      end

      describe "to_export" do

        it "should use default headers if no :header option is sent"
        
        it "should use :headers option for headers if sent"
        
        it "should use no headers if :headers is false"

      end

      describe "get_export_data" do

        context "scopes and find options" do
          # Test how :scopes and find options are merged and applied
          # (testing the private method :find_export_data)
          it "should chainable on named_scopes" do
            User.a_limiter.get_export_data(:only => [:first_name, :last_name]).should == [["first_name", "last_name"],["user_1", "Doe"]]
          end

          it "should allow a scope to be sent" do
            User.get_export_data(:only => [:first_name, :last_name], :scopes => ['a_limiter']).should == [["first_name", "last_name"], ["user_1", "Doe"]]
          end

          it "should allow multiple scopes to be sent" do
            User.get_export_data(:only =>[:first_name, :last_name], :scopes => ['a_limiter', "order_by"]).should == [["first_name", "last_name"], ["user_2", "Doe"]]
          end

          it "should find records using :conditions option" do
            if ActiveRecord::VERSION::MAJOR < 3
              User.get_export_data(:only => [:first_name, :last_name], :conditions => {:first_name => "user_1"} ).should == [["first_name", "last_name"], ["user_1", "Doe"]]
            end
          end

          it "should sort records using :order option" do
            if ActiveRecord::VERSION::MAJOR < 3
              User.get_export_data(:only => [:first_name, :last_name], :order => "id DESC").should == [["first_name", "last_name"], ["user_2", "Doe"], ["user_1", "Doe"]]
            end
          end

          it "should limit records using :limit option" do
            if ActiveRecord::VERSION::MAJOR < 3
              User.get_export_data(:only => [:first_name, :last_name], :limit => 1, :order => "id ASC" ).should == [["first_name", "last_name"], ["user_1", "Doe"]]
            end
          end

          # TODO: Test how :scopes and find options get merged when there are default options
          
        end
        
        context "column selection" do
          # Test how :only/:except are merged and selected
          # (testing the private method :map_export_data)
          it "should export the default columns by default" do
            time = User.first.created_at.to_s
            User.get_export_data().should == [["id", "first_name", "last_name", "password", "email", "is_admin", "created_at", "updated_at"], ["1", "user_1", "Doe", "", "", "false", Time.at(0).to_s, Time.at(0).to_s], ["2", "user_2", "Doe", "", "", "false", Time.at(0).to_s, Time.at(0).to_s]]
          end

          it "should export only the columns given by :only" do
            User.get_export_data(:only => [:first_name, :last_name]).should == [["first_name", "last_name"], ["user_1", "Doe"], ["user_2", "Doe"]]
          end

          it "should export the default columns minus those given by :except" do
            User.get_export_data(:except => [:id, :created_at, :updated_at, :password, :is_admin]).should ==  [["first_name", "last_name", "email"], ["user_1", "Doe", ""], ["user_2", "Doe", ""]]
          end

          it "should raise an error if no columns are passed" do
            lambda do
              User.nothing.get_export_data(:except =>["id", "first_name", "last_name", "password", "email", "is_admin", "created_at", "updated_at"])
            end.should raise_error(MakeExportable::ExportFault)
          end

          # TODO: Test how :only/:except get merged when there are default options

        end
        
      end

      describe "create_report" do

        it "should raise an FormatNotFound if the format is not supported" do
          lambda do
            User.create_report("NONSUPPORTED", "")
          end.should raise_error(MakeExportable::FormatNotFound)
        end

        it 'should export an array of header and array of arrays of rows in the specified format' do
          User.create_report("csv", [[ "data", 'lovely data'],["", "more lovely data"]], :headers => ["Title", "Another Title"]).should == ["Title,Another Title\ndata,lovely data\n\"\",more lovely data\n", "text/csv; charset=utf-8; header=present"]
        end

        it 'should export array of arrays of rows in the specified format if header is set to true with header set as present' do
          User.create_report("csv", [["Title", "Another Title"],[ "data", 'lovely data'],["", "more lovely data"]], :headers => true).should == ["Title,Another Title\ndata,lovely data\n\"\",more lovely data\n", "text/csv; charset=utf-8; header=present"]
        end

        it 'should export array of arrays of rows in the specified format if header is set to false' do
          User.create_report("csv", [[ "data", 'lovely data'],["", "more lovely data"]], :headers => false).should == ["data,lovely data\n\"\",more lovely data\n", "text/csv; charset=utf-8; header=absent"]
        end

        it "should raise an ExportFault if the datasets are not all the same size" do
          lambda do
            User.create_report("xml", [[ "data", 'lovely data'],["more lovely data"]], :headers =>["Title", "Another Title"])
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
          @user.export_attribute('is_admin').should == "false"
        end

        it 'should allow #{method}_export to override the original method'  do
          class User < ActiveRecord::Base
            def is_admin_export
              return "I'm not an Admin I'm a monkey"
            end
          end
          @user.export_attribute('is_admin').should == "I'm not an Admin I'm a monkey"
        end

        # TODO: Would it be better behavior to raise an error?
        it "should return an empty string if the attribute doesn't exist" do
          @user.export_attribute('ful_name').should == ""
        end

        it "should be able to call methods as attributes during exporting" do
          @user.export_attribute('full_name').should == "Carl Joans"
        end

      end

    end

  end

end
