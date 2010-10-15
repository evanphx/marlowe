require 'spec/helper'
require 'marlowe/scope'
require 'marlowe/import'

describe Marlowe::Scope do

  describe "system scope" do
    before :each do
      @root = Marlowe::Scope.root
    end

    it "contains the system types" do
      @root.type("void").should be_kind_of(Marlowe::Type)

      @root.type("int8").should be_kind_of(Marlowe::Type)
      @root.type("uint8").should be_kind_of(Marlowe::Type)
      @root.type("int16").should be_kind_of(Marlowe::Type)
      @root.type("uint8").should be_kind_of(Marlowe::Type)
      @root.type("int32").should be_kind_of(Marlowe::Type)
      @root.type("uint32").should be_kind_of(Marlowe::Type)
      @root.type("int64").should be_kind_of(Marlowe::Type)
      @root.type("uint64").should be_kind_of(Marlowe::Type)

      @root.type("int").should be_kind_of(Marlowe::Type)
      @root.type("uint").should be_kind_of(Marlowe::Type)
    end
  end

  before :each do
    @scope = Marlowe::Scope.root
  end

  it "can have a parent scope" do
    scope = Marlowe::Scope.new(@scope)
    scope.parent.should == @scope
  end

  it "can look up types in a parent scope" do
    @scope.add_type Marlowe::Type.new("int8")
    scope = Marlowe::Scope.new(@scope)
    scope.type("int8").should == @scope.type("int8")
  end

  it "can contain a class" do
    txt = <<-CODE
package blah
class Foo
end
    CODE

    @scope.import txt
    @scope.package.should == "blah"
    cls = @scope.find_class("Foo")
    cls.name.should == "Foo"
  end

  it "pulls in methods" do
    txt = <<-CODE
package blah
class Foo
  def bar
  end
end
    CODE

    @scope.import txt
    cls = @scope.find_class("Foo")

    meth = cls.declared_methods.first
    meth.name.should == "bar"
  end

  it "imports other scopes" do
    txt = <<-CODE
package blah
import foo
    CODE

    foo_code = <<-CODE
package foo
class Bar
end
    CODE

    @scope.importer = Marlowe::StaticImporter.new(foo_code)
    @scope.import txt

    @scope.identifiers['foo'].should be_kind_of(Marlowe::Scope)
  end

  it "can import elements from C headers" do
    txt = <<-CODE
package blah
from "/usr/include/stdio.h"
  bind puts
end
    CODE

    @scope.import txt
    func = @scope.functions["puts"]
    func.name.should == "puts"

    func.ret_type.should == @scope.type("int")
    func.arguments.size.should == 1
    func.arguments[0].should == @scope.type("int8").pointer_to
  end

  it "is consulted to find a call target" do
    txt = <<-CODE
package blah
from "/usr/include/stdio.h"
  bind puts
end

class Blah
def main
  puts("hello world")
end
end
    CODE
  
    @scope.import txt

    blah = @scope.find_class("Blah")
    blah.name.should == "Blah"

    m = blah.bind("main")
    m.should be_kind_of(Marlowe::BoundMethod)
    call = m.expressions.first

    call.resolve(m).should be_kind_of(Marlowe::CImport::Function)
  end
end
