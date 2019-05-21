require 'monument'
require 'json'

Dir.foreach("cache/monuments") do |dir|
  next unless dir.match("onehouronelife.com.php")
  p dir

  server = dir.sub('.php','')

  monuments = Monument.load_file("cache/monuments/"+dir, dir)
  #p monuments

  json = []

  monuments.each do |monument|
    json << [monument.x, monument.y, monument.date]
  end

  File.open("output/#{server}_monuments.json", 'wb') do |file|
    file << JSON.generate(json)
  end
end
