require 'tty-cursor'
require 'tty-progressbar'

class CivilServiceJobsScraper::StatusDisplay
  attr_reader :num_threads

  def initialize(num_threads:)
    @num_threads = num_threads
    @mutex = Mutex.new
    @emptying_progress = nil
    @counters = {}
    @per_page_counters = {}
    @page_statuses = {}
  end

  def clear_screen
    @mutex.synchronize do
      print TTY::Cursor.row(0)
      print TTY::Cursor.column(0)
      print TTY::Cursor.clear_screen
    end
  end

  def thread_status(thread_num, message)
    @mutex.synchronize do
      print TTY::Cursor.row(thread_num)
      print TTY::Cursor.column(0)
      print "#{thread_num}: #{message[0..50]}"
    end
  end

  def increment(counter_name, page_number)
    @mutex.synchronize do
      @counters[counter_name] ||= 0
      @counters[counter_name] += 1

      print TTY::Cursor.row(num_threads + 1)
      print TTY::Cursor.column(0)

      print @counters.map {|name, value| "#{name}: #{value}"}.join(" ")

      if page_number
        @per_page_counters[page_number] ||= {}
        @per_page_counters[page_number][counter_name] ||= 0
        @per_page_counters[page_number][counter_name] += 1

        print TTY::Cursor.row(num_threads + 3 + page_number)
        print TTY::Cursor.column(0)
        print "#{page_number}: #{@page_statuses[page_number]} "
        print @per_page_counters[page_number].map {|name, value| "#{name}: #{value}"}.join(" ")
      end
    end
  end

  def start_waiting_for_empty(total)
    @mutex.synchronize do
      print TTY::Cursor.row(num_threads + 2)
      print TTY::Cursor.column(0)
      @emptying_progress ||= TTY::ProgressBar.new("queue [:bar] :percent :eta", total: total)
      @emptying_progress.current = 0
    end
  end

  def wait_for_empty(current)
    @mutex.synchronize do
      print TTY::Cursor.row(num_threads + 2)
      print TTY::Cursor.column(0)
      @emptying_progress.current = current
    end
  end

  def result_page(page_number, status)
    @mutex.synchronize do
      print TTY::Cursor.row(num_threads + 3 + page_number)
      print TTY::Cursor.column(0)
      print "#{page_number}: #{status}"
      @page_statuses[page_number] = status
    end
  end

end
