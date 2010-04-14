require 'rbgccxml'

module Marlowe
  class CFunction
    def initialize(func)
      @func = func
    end

    def return_type
      @func.return_type.to_cpp
    end
  end

  class CResolver
    def initialize
      @files = []
    end

    def add_file(file)
      @files << file
    end

    def resolve!
      @root ||= RbGCCXML.parse(*@files)
    end

    def find_function(name)
      resolve!

      if func = @root.functions(name)
        return CFunction.new(func)
      end

      return nil
    end
  end
end
