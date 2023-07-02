require 'zeitwerk'
loader = Zeitwerk::Loader.new
loader.push_dir(File.dirname(__FILE__) + "/lib")
loader.setup

require 'mechanize'
require 'pry'

NUM_THREADS = 2

STATUS = CivilServiceJobsScraper::StatusDisplay.new(num_threads: NUM_THREADS)
STATUS.clear_screen

agent = Mechanize.new
start_page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")
first_result_page = CivilServiceJobsScraper::Page::ResultPage.new(
	start_page.form_with(id: "ID_context_search_form").submit)

n = CivilServiceJobsScraper::ResultNavigator.new(
	agent: agent, 
	worker_pool: CivilServiceJobsScraper::Worker.new(num_threads: NUM_THREADS, status_display: STATUS).start!, 
	results_store: CivilServiceJobsScraper::ResultStore.new, 
	status_display: STATUS
)
n.mark_complete_and_traverse_from(first_result_page)

n.wait_for_completion
sleep(15)