# Scrapes CIVICA system for Byron Shire council

require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

url = "https://eservices.byron.nsw.gov.au/eservice/daEnquiry/currentlyAdvertised.do?orderBy=suburb&nodeNum=1149"

page = agent.get(url)

page.search("#fullcontent h4.non_table_headers").each do |h4|
  fields = {}
  h4.next_sibling.search("p.rowDataOnly").each do |p|
    key = p.at(".key").inner_text
    value = p.at(".inputField").inner_text
    fields[key] = value
  end

  info_url = (page.uri + h4.at("a")["href"]).to_s
  record = {
    "council_reference" => fields["Application No."],
    "address" => h4.at("a").inner_text.squeeze(" "),
    "description" => fields["Type of Work"],
    "info_url" => info_url,
    "comment_url" => info_url,
    "date_scraped" => Date.today.to_s,
    "date_received" => Date.parse(fields["Date Lodged"]).to_s
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(["council_reference"], record)
  else
    puts "Skipping already saved record " + record["council_reference"]
  end
end
