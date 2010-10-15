require 'spec/helper'
require 'marlowe/parser'
require 'marlowe/c'
require 'marlowe/type'

describe Marlowe::C::StackAllocate do
  before do
    @env = Marlowe::C::Env.new
  end

  it "allocates space for a type on the stack" do
    type = mock("a type")
    type.should_receive(:flat_name).and_return("_a_type")
    node = Marlowe::C::StackAllocate.new @env, type, "obj"

    node.value.should == "obj"
    node.generate.should == "_a_type obj"
  end
end

describe Marlowe::C::IntegerLiteral do
  before do
    @env = Marlowe::C::Env.new
  end

  it "emits itself directly" do
    node = Marlowe::C::IntegerLiteral.new(@env, 42)
    node.value.should == "42"
    node.generate.should be_nil
  end
end

describe Marlowe::C::LocalAssignment do
  before do
    @env = Marlowe::C::Env.new
  end

  it "assigns the the local variable a value" do
    lv = mock("local variable")
    lv.should_receive(:name).twice.and_return("foo")

    val = mock("value")
    val.should_receive(:generate).and_return(nil)
    val.should_receive(:value).and_return("42")

    node = Marlowe::C::LocalAssignment.new(@env, lv, val)
    node.value.should == "foo"
    node.generate.should == "foo = 42"
  end
end

describe Marlowe::C::InstanceVariableAssignment do
  before do
    @env = Marlowe::C::Env.new
  end

  it "assigns the named instance variable a value" do
    ivar = mock("instance variable")
    ivar.should_receive(:name).and_return("_foo")
    
    val = mock("value")
    val.should_receive(:generate).and_return(nil)
    val.should_receive(:value).and_return("42")

    node = Marlowe::C::InstanceVariableAssignment.new(@env, ivar, val)
    node.value.should == env.temp(0)
    node.generate.should == "self->_foo = 42"
  end


end
