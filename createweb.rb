require 'csv'

available = CSV.read('contributors_github_resume.csv', headers: true)
unavailable = CSV.read('unavailable.csv', headers: true)
available_handles = available['GitHub Username'].compact
unavailable_handles = unavailable['GitHub Username'].compact

handles = available_handles - unavailable_handles
groups = handles.sample(4).each_slice(4).to_a

html = <<~HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <title>Rails Mobs</title>
  </head>
  <body>
    <h1><a href="https://mobti.me" target="_blank">Rails Mobs</a></h1>
HTML

groups.each_with_index do |group, i|
  html << "<h2><a href=\"https://mobti.me\" target=\"_blank\">Mob Group #{i + 1}</a></h2>\n<ul>\n"
  group.each do |handle|
    html << "  <li><a href=\"https://github.com/#{handle}\" target=\"_blank\">@#{handle}</a></li>\n"
  end
  html << "</ul>\n"
end

html << "</body></html>"

File.write('rails_mobs.html', html)
puts "Created rails_mobs.html"
