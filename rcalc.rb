#!/bin/env ruby
require 'optparse'
require 'readline'

$version = "1.3"

# Thow an exception with the troublesome token number attached.
#
# I store the original message and the index of the token that
# generated the error
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
  # Process the tokens in order (with indicies attached), maintining
  # the stack along the way
  tokens.each_with_index.reduce([]) { |stack, (token, index)|
    # If the token is a string, assume an operator
    if token.class == String

      # Look for operands that support the given method and in the
      # right position for the arity given
      operands = stack.each_with_index.select { |o,idx|
        (o.respond_to? token) && (o.method(token).arity.abs == stack.length - idx - 1)
      }

      # If no operands are found for the operator, raise an error
      if operands.empty?
        raise CalcError.new(index, "No suitable arguments for operator: %s" % token)
      else
        # Get the index of the first operand
        oper_index = operands[-1][-1]
        # Get any other operands (arguments can be emtpy)
        arguments = stack.slice!(oper_index+1,stack.length-oper_index)
        # Grab the actual operand (after the modifying slice)
        operand = stack.pop()
      end

      begin
        # Apply the operator (token) to the operand and any arguments
        res = operand.send(token,*arguments)
      rescue StandardError => e
        # Rescue any errors thrown with an error message.  The token
        # index is supplied for better messaging or cursor placement
        raise CalcError.new(index, e.message)
      end
      # Add any result to the stack
      stack.push(res)
    else
      # No operator detected, so push the value onto the stack
      stack.push(token)
    end
  }
 end

# Change input the looks like numbers into actual numbers
def parse_numbers(stack)
  stack.map.each_with_index { |tok, idx|
    # For every item in the stack, if it begins with a digit (and
    # optional sign), try to make it into a number
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
  result = eval_stack(stack)

  # If the result array has multiple elements, then the user supplied
  # too few operators
  if result.length > 1
    raise CalcError.new(result.length+1,"Not enough operators")
  else
    return result
  end
  
end

# Find the position of the nth token in a line
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

# Parse the options
option_parser.parse!

if options[:execute] then
  begin
    # Parse string passed in on the command line
    result = calculate_line( options[:execute] )
    puts result
  rescue CalcError => e
    # Print out a helpful message indicating the issue and where it
    # was found
    puts "Error: %s" % e.message
    puts options[:execute]
    puts "%s ^" % (" " * token_start(options[:execute], e.token_index))
  end
else

  # Print header for interactive use
  puts "RCalc version %s" % $version

  # Position the cursor for any errors
  error = nil # Error'd line
  t_idx = nil # Token index causing the issue
  # Setup the hook to run before asking for input
  Readline.pre_input_hook = Proc.new do
    if error
      # If there is an error, put it on the input line
      Readline.insert_text( error )
      if t_idx
        # If an index is given, position the cursor
        Readline.point = token_start(error,t_idx)+1
        t_idx = nil
      end
      error = nil
      # Display the new line waiting for user input
      Readline.redisplay()
    end
  end
  
  # The main part of the program
  while buf = Readline.readline("> ", true)
    
    # Check if user has asked to quit
    if /^\s*quit/ =~ buf
      break
    end

    # Perform the calculation on the line
    begin
      result = calculate_line(buf)
    rescue CalcError => e
      # On error, print a message, setup the variables used by
      # pre_input_hook and go to next iteration
      puts "Error: %s" % e.message
      error = buf
      t_idx = e.token_index
      next
    end

    # Add the result to history and print it out for the user
    Readline::HISTORY.push(result[0].to_s)
    puts result
    
  end
end

