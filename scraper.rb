require 'scraperwiki'
require 'mechanize'
require 'pry'

# agent = Mechanize.new

# # Read in a page
# page = agent.get("https://www.civilservicejobs.service.gov.uk/csr/index.cgi")

# # Find something on the page using css selectors
# f = page.form('#ID_context_search_form')

# Write out to the sqlite database using scraperwiki library
ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})

# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
