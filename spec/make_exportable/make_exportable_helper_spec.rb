require File.expand_path('../../spec_helper', __FILE__)

describe "Make Exportable Helper" do

  before(:each) do
    clean_database!
  end

  it "it should output an array of exportable classes" do
    MakeExportable.exportable_classes = {}
    User.class_eval("make_exportable")
    Post.class_eval("make_exportable")
    MakeExportableHelper.exportable_class_list.should == ["Post", "User"]
    MakeExportable.exportable_classes = {}
  end

  it "it should output an array of exportable tables" do
    User.class_eval("make_exportable")
    Post.class_eval("make_exportable")
    MakeExportableHelper.exportable_table_list.should ==["posts", "users"]
    MakeExportable.exportable_classes = {}
  end
  
  it "it should output an array of exportable classes and tables to check against" do
    User.class_eval("make_exportable")
    Post.class_eval("make_exportable")
    MakeExportableHelper.exportable_units.should == {User => "users", Post => "posts"}
    MakeExportable.exportable_classes = {}
  end

end
