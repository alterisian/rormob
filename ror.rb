require 'open-uri'
require 'nokogiri'
require 'json'
# require 'geocoder'    # if you want to resolve timezone by location

def fetch_contributors(limit = 1_000)
  url = "https://contributors.rubyonrails.org/"
  doc = Nokogiri::HTML(URI.open(url))
  rows = doc.css("table tr").drop(1)  # skip header row
  contributors = rows.map do |tr|
    cols = tr.css("td")
    {
      name: cols[1]&.text&.strip,
      since: cols[2]&.text&.strip,
      commits: cols[3]&.text&.strip.to_i
    }
  end.compact.first(limit)
  contributors
end

def group_into_mobs(contributors, group_size = 4)
  contributors.each_slice(group_size).to_a
end

# Optional: timezone clustering placeholder
def cluster_by_timezone(contributors)
  # If you have contributor location/timezone, you could group by timezone buckets
  # Here we just stub: treat all as “UTC” for now
  contributors.group_by { |c| "UTC" }
end

def output_sessions(groups)
  groups.each_with_index do |grp, idx|
    puts "Session #{idx+1}:"
    grp.each_with_index do |c, j|
      puts "  Member #{j+1}: #{c[:name]} (since #{c[:since]}, commits #{c[:commits]})"
    end
    puts "  → Suggested link to start a mob session: https://mobti.me"
    puts "---"
  end
end

# main flow
contributors = fetch_contributors(1_000)
timezones_buckets = cluster_by_timezone(contributors)
timezones_buckets.each do |tz, list|
  puts "=== Timezone group: #{tz} (#{list.size} contributors) ==="
  groups = group_into_mobs(list, 4)
  output_sessions(groups)
end
