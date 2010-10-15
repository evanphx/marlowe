require 'marlowe/interp'

describe Marlowe::Interpreter do
  before :each do
    @scope = Marlowe::Scope.root
  end

  it "can invoke a foreign method" do
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
    m = blah.bind("main")
    call = m.expressions.first

    call.resolve(m).should be_kind_of(Marlowe::CImport::Function)
  end
end
