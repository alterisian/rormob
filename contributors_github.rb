require 'nokogiri'
require 'open-uri'
require 'csv'
require 'net/http'
require 'json'
require 'uri'

INPUT_FILE = "contributors.csv"
OUTPUT_FILE = "contributors_github_resume.csv"
BATCH_SIZE = 5

def first_commit_sha(contributor_commits_url)
  doc = Nokogiri::HTML(URI.open(contributor_commits_url))
  link = doc.at_css("table tr td a[href*='/commit/']")&.[]("href")
  return nil unless link
  link.split('/').last
rescue
  nil
end

def github_username_from_commit_sha(repo, sha, token=nil)
  return nil unless sha
  url = URI("https://api.github.com/repos/#{repo}/commits/#{sha}")
  req = Net::HTTP::Get.new(url)
  req['Authorization'] = "token #{token}" if token
  res = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.request(req) }
  return nil unless res.is_a?(Net::HTTPSuccess)
  data = JSON.parse(res.body)
  data.dig("author", "login")
rescue
  nil
end

# Load all contributors
all_contributors = CSV.read(INPUT_FILE, headers: true)

# Check existing output CSV to see how far we got
processed_count = 0
if File.exist?(OUTPUT_FILE)
  CSV.foreach(OUTPUT_FILE, headers: true) do |row|
    processed_count += 1 if row['GitHub Username'] && !row['GitHub Username'].empty?
  end
end

contributors_to_process = all_contributors[processed_count..-1] || []
puts "Resuming from contributor ##{processed_count + 1}"

# Open CSV in append mode if file exists, else create
CSV.open(OUTPUT_FILE, processed_count > 0 ? "a" : "w") do |csv|
  if processed_count == 0
    csv << ["GitHub Username", "Name", "Commits", "Contributor URL"]
  end

  contributors_to_process.each_slice(BATCH_SIZE) do |batch|
    any_found = false

    batch.each_with_index do |row, i|
      puts "Processing #{processed_count + i + 1}/#{all_contributors.size}: #{row['Name']}"
      commits_page = row['URL']

      sha = first_commit_sha(commits_page)
      github_username = github_username_from_commit_sha("rails/rails", sha)

      any_found ||= !github_username.nil?

      csv << [github_username, row['Name'], row['Commits'], commits_page]
      sleep 1
    end

    unless any_found
      puts "No GitHub usernames found in this batch. Stopping."
      break
    end

    processed_count += batch.size
  end
end

puts "Finished processing. Output saved to #{OUTPUT_FILE}"
