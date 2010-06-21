require File.expand_path('../../spec_helper', __FILE__)

describe "Exportable Formats" do

  before(:each) do
    class User
      make_exportable
    end
    clean_database!
    User.create(:first_name => "user_1", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.at(0))
    User.create(:first_name => "user_2", :last_name => "Doe", :created_at => Time.at(0), :updated_at => Time.at(0))
  end
  
  context "csv format" do

    it "should export the columns as csv" do
      User.to_export( "csv", :only => [:first_name, "is_admin"]).should ==  ["First Name,Is Admin\nuser_1,false\nuser_2,false\n", "text/csv; charset=utf-8; header=present"]
    end

    it "should export the columns as csv and detect that there is no header" do
      User.to_export( "csv", :only => [:first_name, "is_admin"], :headers => false).should ==  ["user_1,false\nuser_2,false\n", "text/csv; charset=utf-8; header=absent"]
    end

  end
  
  context "excel format" do

    it "should export the columns as xls" do
      User.to_export( "xls", :only =>  [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=present"]
    end

    it "should export the columns as xls and detect no header" do
      User.to_export( "xls", :only =>  [:first_name, "is_admin"], :headers => false).should == ["<table>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "application/vnd.ms-excel; charset=utf-8; header=absent"]
    end

  end

  context "tsv format" do

    it "should export the columns as tsv" do
      User.to_export( "tsv", :only => [:first_name, "is_admin"]).should == ["First Name\tIs Admin\nuser_1\tfalse\nuser_2\tfalse\n", "text/tab-separated-values; charset=utf-8; header=present"]
    end

    it "should export the columns as tsv  and detect no header" do
      User.to_export( "tsv", :only => [:first_name, "is_admin"], :headers => false).should == ["user_1\tfalse\nuser_2\tfalse\n", "text/tab-separated-values; charset=utf-8; header=absent"]
    end

  end

  context "html format" do

    it "should export the columns as html" do
      User.to_export( "html", :only => [:first_name, "is_admin"]).should == ["<table>\n\t<tr>\n\t\t<th>First Name</th>\n\t\t<th>Is Admin</th>\n\t</tr>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=present"]
    end

    it "should export the columns as html and detect no header" do
      User.to_export( "html", :only => [:first_name, "is_admin"], :headers => false).should == ["<table>\n\t<tr>\n\t\t<td>user_1</td>\n\t\t<td>false</td>\n\t</tr>\n\t<tr>\n\t\t<td>user_2</td>\n\t\t<td>false</td>\n\t</tr>\n</table>\n", "text/html; charset=utf-8; header=absent"]
    end

  end

  context "xml format" do

    it "should export the columns as xml" do
      User.to_export( "xml", :only => [:first_name, "is_admin"]).should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records>\n\t<record>\n\t\t<first-name>user_1</first-name>\n\t\t<is-admin>false</is-admin>\n\t</record>\n\t<record>\n\t\t<first-name>user_2</first-name>\n\t\t<is-admin>false</is-admin>\n\t</record>\n</records>\n", "application/xml; header=present"]
    end

    it "should export the columns as xml and detect no header" do
      User.to_export( "xml", :only => [:first_name, "is_admin"], :headers => false).should == ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records>\n\t<record>\n\t\t<attribute_0>user_1</attribute_0>\n\t\t<attribute_1>false</attribute_1>\n\t</record>\n\t<record>\n\t\t<attribute_0>user_2</attribute_0>\n\t\t<attribute_1>false</attribute_1>\n\t</record>\n</records>\n", "application/xml; header=absent"]
    end

  end

  context "json format" do
    it "should export the columns as json" do
      User.to_export( "json", :only => [:first_name]).should ==["[{\"first_name\":\"user_1\"},{\"first_name\":\"user_2\"}]", "application/json; charset=utf-8;"]
    end

  end
  
end
