require 'open-uri'
require 'nokogiri'

BASE_URL = "https://contributors.rubyonrails.org"

def fetch_contributors(limit = 1000)
  doc = Nokogiri::HTML(URI.open(BASE_URL))
  rows = doc.css("table tr").drop(1)
  rows.first(limit).map do |tr|
    cols = tr.css("td")
    {
      name: cols[1]&.text&.strip,
      url: BASE_URL + cols[1].at_css('a')['href'],
      since: cols[2]&.text&.strip,
      commits: cols[3]&.text&.strip.to_i
    }
  end
end

def create_mob_groups(contributors, group_size = 4)
  contributors.each_slice(group_size).with_index(1).map do |group, i|
    {
      mob_number: i,
      members: group,
      timer: "https://mobti.me/?name=rormob#{i}&time=7"
    }
  end
end

contributors = fetch_contributors(1000)
mobs = create_mob_groups(contributors, 4)

puts "Fetched #{contributors.size} contributors."
puts "Created #{mobs.size} mob groups.\n\n"

mobs.each do |mob|
  puts "Mob ##{mob[:mob_number]} — #{mob[:timer]}"
  mob[:members].each_with_index do |m, idx|
    puts "  #{idx + 1}. #{m[:name]} — #{m[:url]}"
  end
  puts "---"
end
