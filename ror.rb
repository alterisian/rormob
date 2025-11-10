require 'open-uri'
require 'nokogiri'
require 'csv'

BASE_URL = "https://contributors.rubyonrails.org"

def fetch_contributors(limit = 1000)
  doc = Nokogiri::HTML(URI.open(BASE_URL))
  rows = doc.css("table tr").drop(1)
  rows.first(limit).map do |tr|
    cols = tr.css("td")
    {
      name: cols[1]&.text&.strip,
      url: BASE_URL + cols[1].at_css('a')['href'],
      commits: cols[3]&.text&.strip.to_i
    }
  end
end

def save_contributors_to_csv(contributors, filename = "contributors.csv")
  CSV.open(filename, "w") do |csv|
    csv << ["Name", "Commits", "URL"]
    contributors.each { |c| csv << [c[:name], c[:commits], c[:url]] }
  end
  puts "Saved #{contributors.size} contributors to #{filename}"
end

def create_mob_groups(contributors, group_size = 4)
  contributors.each_slice(group_size).with_index(1).map do |group, i|
    {
      mob_number: i,
      members: group.map { |m| m[:name] },
      timer: "https://mobti.me/?name=rormob#{i}&time=7"
    }
  end
end

contributors = fetch_contributors(1000)
save_contributors_to_csv(contributors)

mobs = create_mob_groups(contributors, 4)

puts "\nCreated #{mobs.size} mob groups.\n\n"

mobs.each do |mob|
  puts "Mob ##{mob[:mob_number]} — #{mob[:timer]}"
  mob[:members].each_with_index { |name, idx| puts "  #{idx + 1}. #{name}" }
  puts "---"
end
