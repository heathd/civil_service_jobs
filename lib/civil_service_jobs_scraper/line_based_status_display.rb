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

      puts @counters.map {|name, value| "#{name}: #{value}"}.join(" ")

      if page_number
        @per_page_counters[page_number] ||= {}
        @per_page_counters[page_number][counter_name] ||= 0
        @per_page_counters[page_number][counter_name] += 1

        puts "#{page_number}: #{@page_statuses[page_number]} "
        puts @per_page_counters[page_number].map {|name, value| "#{name}: #{value}"}.join(" ")
      end
    end
  end

  def start_waiting_for_empty(total)
    @mutex.synchronize do
    end
  end

  def wait_for_empty(current)
    @mutex.synchronize do
    end
  end

  def result_page(page_number, status)
    @mutex.synchronize do
      puts "#{page_number}: #{status}"
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
