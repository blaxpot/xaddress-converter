#######################################################
#
# ruboto/stack.rb
#
# Utility methods for running code in a separate 
# thread with a larger stack.
#
#######################################################

class Object
  def with_large_stack(opts = {}, &block)
    opts = {:size => opts} if opts.is_a? Integer
    opts = {:name => opts} if opts.is_a? String
    opts = {:name => 'Block with large stack'}.update(opts)
    exception = nil
    result = nil
    t = Thread.with_large_stack(opts, &proc{result = block.call rescue exception = $!})
    t.join
    raise exception if exception
    result
  end
end

class Thread
  def self.with_large_stack(opts = {}, &block)
    opts = {:size => opts} if opts.is_a? Integer
    opts = {:name => opts} if opts.is_a? String
    stack_size_kb = opts.delete(:size) || 64
    name = opts.delete(:name) || 'Thread with large stack'
    raise "Unknown option(s): #{opts.inspect}" unless opts.empty?
    block_with_logging = proc do
      begin
        block.call
      rescue Exception => e
        STDERR.puts "Exception in #{name.inspect}: #{e.class} #{e}\n#{e.backtrace.join("\n")}"
        raise
      end
    end
    t = java.lang.Thread.new(nil, block_with_logging, name, stack_size_kb * 1024)
    t.start
    t
  end
end

