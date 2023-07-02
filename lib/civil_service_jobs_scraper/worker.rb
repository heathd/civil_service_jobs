
class CivilServiceJobsScraper::Worker
  attr_reader :num_threads, :threads, :queue, :status_display

  def initialize(num_threads:, status_display:)
    @num_threads = num_threads
    @threads = []
    @queue = Queue.new
    @has_reached_last_page=false
    @status_display = status_display
  end
  
  def reached_last_page!
    @has_reached_last_page=true
  end

  def spawn_threads
    num_threads.times do |thread_num|
      threads << Thread.new do
        while running? || actions?
          action_proc = wait_for_action
          action_proc.call(thread_num+1)
        end
      end
    end
  end

  def enqueue(&action)
    queue.push(action)
  end

  def stop
    queue.close
    threads.each(&:exit)
    threads.clear
    true
  end

  def wait_for_empty_and(&index_pages_all_fetched_pred)
    status_display.start_waiting_for_empty(queue.size)
    while actions? || !index_pages_all_fetched_pred.call
      sleep(0.15)
      
      status_display.wait_for_empty(queue.size)
    end
  end

private
  attr_reader :queue, :threads

  def actions?
    !queue.empty?
  end

  def running?
    !queue.closed?
  end

  def dequeue_action
    queue.pop(true)
  end

  def wait_for_action
    queue.pop(false)
  end
end