require 'spec/helper'
require 'marlowe/scope'
require 'marlowe/method'
require 'marlowe/nodes/integer'
require 'marlowe/nodes/local_variable_read'

describe Marlowe::Method do 
  it "contains nodes which are invoked when called" do
    scope = Marlowe::Scope.root
    int = Marlowe::Nodes::Integer.new(10, scope.type("int"))

    sig = Marlowe::TypeSignature.new scope.type("void")
    meth = Marlowe::Method.new "test", int, sig

    meth.run.value == 10
  end

  it "infers it's return type" do
    scope = Marlowe::Scope.root
    int = Marlowe::Nodes::Integer.new(10, scope.type("int"))

    meth = Marlowe::Method.new "test", int

    meth.ret_type.should == scope.type("int")
  end

  it "raises a ArgCountMismatchError when passed args it didn't want" do
    scope = Marlowe::Scope.root
    int = Marlowe::Nodes::Integer.new(10, scope.type("int"))

    sig = Marlowe::TypeSignature.new scope.type("void")

    meth = Marlowe::Method.new "test", int, sig

    lambda {
      meth.run(int)
    }.should raise_error(Marlowe::ArgCountMismatchError)
  end

  it "makes arguments available as locals" do
    scope = Marlowe::Scope.root
    int = Marlowe::Integer.new(10, scope.type("int"))

    sig = Marlowe::TypeSignature.new scope.type("void")
    sig << scope.type("int")

    local = Marlowe::Nodes::LocalVariableRead.new(0)

    meth = Marlowe::Method.new "test", local, sig

    meth.run(int).should == int
  end
end
