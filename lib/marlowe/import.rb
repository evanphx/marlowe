require 'marlowe/scope'

module Marlowe
  class StaticImporter
    def initialize(code)
      @code = code
    end

    def import(path)
      scope = Marlowe::Scope.new
      scope.import @code
      return scope
    end
  end
end
