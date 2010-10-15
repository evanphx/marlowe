require 'spec/helper'
require 'marlowe/nodes/new_object'
require 'marlowe/class'

describe Marlowe::Nodes::NewObject do
  it "takes a type to create" do
    type = Marlowe::Class.new "Test"
    node = Marlowe::Nodes::NewObject.new(type)

    val = node.run(nil)
    val.should be_kind_of(Marlowe::Instance)
    val.type.should == type
  end
end
