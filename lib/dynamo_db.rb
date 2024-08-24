require 'open3'
require 'socket'

# require File.dirname(__FILE__) + "/../config/dynamoid_local_config"

class DynamoDb
  attr_reader :stdout, :stderr, :pid

  def initialize(in_memory: true)
    @stdout = ""
    @stderr = ""
    @pid = nil
    @stdin, @stdout_io, @stderr_io, @wait_thr = nil
    @in_memory = in_memory
  end

  def find_random_port!
    server = TCPServer.new('127.0.0.1', 0)
    @port = server.addr[1]
    server.close
    @port
  end

  def port
    @port ||= find_random_port!
  end

  def command
    cmd = "java -Djava.library.path=vendor/dynamodb/DynamoDBLocal_lib -jar vendor/dynamodb/DynamoDBLocal.jar -port #{port}"
    if @in_memory
      cmd << " -inMemory"
    else
      cmd << " -sharedDb"
    end
  end

  # Starts the DynamoDB Local process
  def start
    find_random_port!
    @stdin, @stdout_io, @stderr_io, @wait_thr = Open3.popen3(command)

    @pid = @wait_thr.pid

    # Capture stdout and stderr asynchronously
    capture_output
  end

  # Capture stdout and stderr in separate threads
  def capture_output
    Thread.new do
      @stdout_io.each_line { |line| @stdout << line; puts "O: #{line}" }
    end

    Thread.new do
      @stderr_io.each_line { |line| @stderr << line; puts "E: #{line}" }
    end
  end

  # Stops the DynamoDB Local process
  def stop
    if @pid
      Process.kill('TERM', @pid)
      @wait_thr.value # Wait for the process to exit
      cleanup
    end
  end

  # Cleans up the IO streams
  def cleanup
    @stdin.close if @stdin
    @stdout_io.close if @stdout_io
    @stderr_io.close if @stderr_io
  end

  # Checks if the DynamoDB Local process is running
  def running?
    @wait_thr&.alive?
  end
end
