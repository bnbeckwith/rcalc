#!/bin/env ruby

require 'readline'

$version = "0.0"

puts "RCalc version %s" % $version

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

# The main part of the program
while buf = Readline.readline("> ", true)
  # tokenize buf
  stack = buf.split()
  
  # Check if user has asked to quit
  if /^\s*quit/ =~ stack[0]
    break
  end

  # Parse any numbers in the list (leaving ops as strings)
  #  Exceptions on items that are not quite numbers
  begin
    stack = parse_numbers(stack)
  rescue Exception => e
    puts e.message
    next
  end
  # Evaluate the stack
  result = eval_stack(stack)
  if result.length > 1
    puts "Error: Not enough operators"
  end
  puts result
end

