class LinePercent
  
  def initialize(sentence, ljust, max)
    @sentence = sentence
    @ljust = ljust
    @max = max
    @i = 0
    @prev_percent = -1
    if $stdout.isatty
      print "#{sentence}:".ljust(@ljust)
      print "0%\r"
    else
      print "#{sentence}:".ljust(@ljust)
      print "O%"
    end
  end

  def inc()
    if !$stdout.isatty
      return
    end

    @i += 1
    
    percent = (@i.to_f / @max * 100).to_i
    if percent == @prev_percent
      return
    end

    @prev_percent = percent
    
    print "#{@sentence}:".ljust(@ljust)
    
    print "#{percent}%\r"

  end
  
  def ok()
    if $stdout.isatty
      print "#{@sentence}:".ljust(@ljust)
      puts "OK    "
    else
      puts "OK"
    end
  end
end

def quit(code=1)
  exit(code)
end

# ------------------------------------------------------------------------------

def present(value)
  if value.is_a?(Float)
    value.round(2)
  else
    value.inspect
  end
end

# ------------------------------------------------------------------------------

def print_message(message, silent)
  if silent == false
    print("#{message}:".ljust($LJUST))
    $stdout.flush
  end
end

# ------------------------------------------------------------------------------

def print_failure(message, error_message, silent, &block)
  if silent == true
    print("#{message}:".ljust($LJUST))    
  end
  puts("FAILURE (line #{caller[1].scan(/\d+/).first}): #{error_message}")
  if !block.nil?()
    block.call()
  end
  quit()
end

# ------------------------------------------------------------------------------

def print_ok(silent)
  if silent == false
    puts "OK"
  end
end

# ------------------------------------------------------------------------------

def assert_throw(message, exception_type, silent = false, &code_block)
  print_message(message, silent)
  begin
    code_block.call
  rescue exception_type
    print_ok(silent)
    return
  rescue => e
    print_failure(message, "it throws #{e.class.name}", silent) {
      puts(e.message)
      puts(e.backtrace)
    }
  end
  print_failure(message, "it throws nothing", silent)
end

# ------------------------------------------------------------------------------

def assert_no_throw(message, silent = false, &code_block)
  print_message(message, silent)
  begin
    code_block.call
  rescue => e
    print_failure(message, "it throws #{e.class.name}", silent) {
      puts e.message
      puts e.backtrace
    }
  end
  print_ok(silent)
end

# ------------------------------------------------------------------------------

def assert_eq(message, compared_to, value, silent = false, &block)
  print_message(message, silent)
  if value == compared_to
    print_ok(silent)
  else
    print_failure(message, "#{present(value)} is not equal to #{present(compared_to)}", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_lt(message, compared_to, value, silent = false, &block)
  print_message(message, silent)
  if value < compared_to
    print_ok(silent)
  else
    print_failure(message, "#{present(value)} is not lesser than #{present(compared_to)}", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_le(message, compared_to, value, silent = false, &block)
  print_message(message, silent)
  if value <= compared_to
    print_ok(silent)
  else
    print_failure(message, "#{present(value)} is not lesser than or equal to #{present(compared_to)}", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_gt(message, compared_to, value, silent = false, &block)
  print_message(message, silent)
  if value > compared_to
    print_ok(silent)
  else
    print_failure(message, "#{present(value)} is not greater than #{present(compared_to)}", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_ge(message, compared_to, value, silent = false, &block)
  print_message(message, silent)
  if value >= compared_to
    print_ok(silent)
  else
    print_failure(message, "#{present(value)} is not greater than or equal to #{present(compared_to)}", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_true(message, expr, silent = false, &block)
  print_message(message, silent)
  if expr == true
    print_ok(silent)
  else
    print_failure(message, "boolean expression is false", silent) { block.call if !block.nil? }
  end
end

# ------------------------------------------------------------------------------

def assert_false(message, expr, silent = false, &block)
  print_message(message, silent)
  if expr == false
    print_ok(silent)
  else
    print_failure(message, "boolean expression is true", silent) { block.call if !block.nil? }
  end
end
