#!/bin/env ruby
require 'optparse'
require 'readline'

$version = "1.0"

# Thow an exception with the troublesome token number attached
class CalcError < StandardError
  attr_reader :token_index
  attr_reader :message

  def initialize(token_index, message)
    @token_index = token_index
    @message     = message
  end
end


# Evaluate the given tokens
def eval_stack(tokens)
  tokens.each_with_index.reduce([]) { |stack, (token, index)|
    # If the token is a string, assume an operator
    if token.class == String
      operand = stack.pop()
      begin
        arity = operand.method(token).arity
      rescue NameError => e
        raise CalcError.new(index, e.message)
      end
      begin
        res = operand.send(token,*stack.slice!(-arity,arity))
      rescue ArgumentError => e
        raise CalcError.new(index, e.message)
      end
      stack.push(res)
    else
      stack.push(token)
    end
  }
 end

# Change input the looks like numbers into actual numbers
def parse_numbers(stack)
  stack.map.each_with_index { |tok, idx|
    if /[+-]?[0-9]/ =~ tok
      begin
        eval(tok)
      rescue SyntaxError => e
        raise CalcError.new(idx, e.message)
      end
    else
      tok
    end
  }
end 

# Process a given input line and return the result
def calculate_line(line)

  # tokenize line
  stack = line.split()

  # Parse any numbers in the list (leaving ops as strings)
  #  Exceptions on items that are not quite numbers
  stack = parse_numbers(stack)

  # Evaluate the stack
  eval_stack(stack)

end

# Find the nth token
def token_start(line,idx)
  (0...idx).reduce(0) { |pos, i|
    line.index(" ",pos+1) || 0
  }
end

# Setup some options for the user
options = {}
option_parser = OptionParser.new do |opts|

  # Let the user pass in something to execute on the command line
  options[:execute] = nil
  opts.on('-e STRING', '--execute STRING',
         'Calculate expression in STRING') do |line|
    options[:execute] = line
  end

end

option_parser.parse!

if options[:execute] then
  # Parse string passed in on the command line
  result = calculate_line( options[:execute] )
  puts result
else

  # Print header for interactive use
  puts "RCalc version %s" % $version

  error = nil
  t_idx = nil
  # Proc for handling errors
  Readline.pre_input_hook = Proc.new do
    if error 
      Readline.insert_text( error )
      if t_idx
        Readline.point = token_start(error,t_idx)+1
        t_idx = nil
      end
      error = nil
      Readline.redisplay()
    end
  end
  
  # The main part of the program
  while buf = Readline.readline("> ", true)
    
    # Check if user has asked to quit
    if /^\s*quit/ =~ buf
      break
    end

    begin
      result = calculate_line(buf)
    rescue CalcError => e
      puts e.message
      error = buf
      t_idx = e.token_index
    end
    
    if result and result.length > 1
      puts "Error: Not enough operators"
      error = buf
    else
      puts result
    end
    
  end
end

