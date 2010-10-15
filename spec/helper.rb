$:.unshift File.expand_path("../../lib", __FILE__)

def raw_parse(text)
  parser = Marlowe::Parser.new(text)
  parser.parse

  unless parser.successful?
    raise Marlowe::ParseError
  end

  return parser.to_sexp
end

def parse(text)
  parser = Marlowe::Parser.new(text)
  parser.parse

  unless parser.successful?
    puts
    parser.show_fixit
    raise Marlowe::ParseError
  end

  return parser.to_sexp
end

def parse_body(text)
  str = <<-END
class Test
def main
#{text}
end
end
  END

  node = parse(str)
  p node
end
