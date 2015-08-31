#!/bin/env ruby
require 'optparse'
require 'readline'

$version = "1.0"

# Evaluate the given tokens
def eval_stack(tokens)
  stack = []
  while tokens.length > 0 
    token = tokens.shift
    if token.class == String
      operand = stack.pop()
      begin
        arity = operand.method(token).arity
      rescue Exception => e
        return e.message
      end
      begin
        res = operand.send(token,*stack.slice!(-arity,arity))
      rescue Exception => e
        return e.message
      end
      stack.push(res)
    else
      stack.push(token)
    end
  end
  stack
end

# Change input the looks like numbers into actual numbers
def parse_numbers(stack)
  stack.map { |tok|
    if /[+-]?[0-9]/ =~ tok
      eval(tok)
    else
      tok
    end
  }
end 

def calculate_line(line)

  # tokenize line
  stack = line.split()

  # Parse any numbers in the list (leaving ops as strings)
  #  Exceptions on items that are not quite numbers
  stack = parse_numbers(stack)

  # Evaluate the stack
  eval_stack(stack)

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

  # The main part of the program
  while buf = Readline.readline("> ", true)
    
    # Check if user has asked to quit
    if /^\s*quit/ =~ buf
      break
    end

    begin
      result = calculate_line(buf)
    rescue Exception => e
      puts e.message
      next
    end
    
    if result.length > 1
      puts "Error: Not enough operators"
    end
    puts result
  end
end

