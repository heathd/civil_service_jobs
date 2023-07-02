require 'zeitwerk'
loader = Zeitwerk::Loader.new
loader.push_dir(File.dirname(__FILE__) + "/lib")
loader.setup

require 'mechanize'
require 'pry'

NUM_THREADS = 8

STATUS = CivilServiceJobsScraper::StatusDisplay.new(num_threads: NUM_THREADS)
STATUS.clear_screen

agent = Mechanize.new
results_store = CivilServiceJobsScraper::ResultStore.new
worker_pool = CivilServiceJobsScraper::Worker.new(num_threads: NUM_THREADS, status_display: STATUS)
worker_pool.spawn_threads


# First page
# start_page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")
# r = CivilServiceJobsScraper::Page::ResultPage.new(start_page.form_with(id: "ID_context_search_form").submit)
r=nil

n = CivilServiceJobsScraper::ResultNavigator.new(agent: agent, worker_pool: worker_pool, results_store: results_store, status_display: STATUS)
n.mark_complete_and_traverse_from(r)

n.wait_for_completion
sleep(15)