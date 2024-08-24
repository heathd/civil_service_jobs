class CivilServiceJobsScraper::LineBasedStatusDisplay
  attr_reader :num_threads, :counters

  def initialize(num_threads:)
    @num_threads = num_threads
    @mutex = Mutex.new
    @emptying_progress = nil
    @counters = {}
    @per_page_counters = {}
    @page_statuses = {}
  end

  def clear_screen
  end

  def thread_status(thread_num, message)
    @mutex.synchronize do
      puts "#{thread_num}: #{message[0..50]}"
    end
  end

  def increment(counter_name, page_number)
    @mutex.synchronize do
      @counters[counter_name] ||= 0
      @counters[counter_name] += 1

      overall_counter_msg = @counters.map {|name, value| "#{name}: #{value}"}.join(" ")
      puts "                                            all: #{overall_counter_msg}"

      if page_number
        @per_page_counters[page_number] ||= {}
        @per_page_counters[page_number][counter_name] ||= 0
        @per_page_counters[page_number][counter_name] += 1

        # puts "P#{page_number} <#{@page_statuses[page_number]}>: (#{per_page_counters_message(page_number)})"
      end
    end
  end

  def per_page_counters_message(page_number)
    counters = @per_page_counters[page_number] || []
    counters.map do |name, value|
      "#{name}: #{value}"
    end.join(" ")
  end

  def start_waiting_for_empty(total)
    @mutex.synchronize do
      puts "Starting to wait for work queues to empty..."
    end
  end

  def wait_for_empty(current)
    @mutex.synchronize do
      puts "Waiting for work queues to empty..."
    end
  end

  def result_page(page_number, status)
    @mutex.synchronize do
      puts "P#{page_number} <#{status}>: (#{per_page_counters_message(page_number)})"
      @page_statuses[page_number] = status
    end
  end

  def completion_message
    [
      "#{@counters[:complete] || 0} jobs downloaded and added to the database. ",
      "#{@counters[:skip] || 0} jobs skipped because they have already been downloaded. "
    ].join("")
  end

end
