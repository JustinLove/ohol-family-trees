require 'lifelog'
require 'history'
require 'graph'
require 'date'

from_time = (Date.today - 1).to_time
to_time = (Date.today - 0).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*3)..(to_time + 60*60*24*3)))

  p lives.length

  lines = {}
  from = from_time.to_i
  to = to_time.to_i

  lives.select do |life|
    if life.time > from && life.time < to
      eve = lives.ancestors(life).last
      unless lines[eve.key]
        lines[eve.key] = lives.family(eve)
      end
    end
  end

  lines.each do |key,line|
    eve = line[key]
    filename = "output/#{Time.at(eve.time).strftime('%Y-%m-%d')}_#{line.length}_#{eve.name}"
    p filename
    #Graph.graph(line).output(:dot => filename + ".gv")
    Graph.html(line, filename + ".html")
  end
end
