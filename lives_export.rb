require 'lifelog'
require 'history'
require 'graph'
require 'date'
require 'csv'

from_time = (Date.today - 1).to_time
to_time = (Date.today - 0).to_time

Dir.foreach("cache/") do |dir|
  next unless dir.match("lifeLog_")

  lives = History.new

  lives.load_dir("cache/"+dir, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1)))

  p lives.length
  next unless lives.length > 0

  from = from_time.to_i
  to = to_time.to_i

  server = dir.sub('lifeLog_', '').sub('.onehouronelife.com', '')

  CSV.open("output/#{server}_#{from_time.to_date}_#{to_time.to_date}.csv", 'wb') do |csv|
    csv << [
      "hash",
      "id",
      "gender",
      "parent",
      "chain",
      "birth_time",
      "birth_x",
      "birth_y",
      "death_time",
      "death_x",
      "death_y",
      "age",
      "cause",
      "name",
      ]
    lives.each do |life|
      if life.time > from && life.time < to
        csv << [
          life.hash,
          life.playerid,
          life.gender,
          life.parent,
          life.chain,
          life.birth_time,
          life.birth_coords[0],
          life.birth_coords[1],
          life.death_time,
          life.death_coords[0],
          life.death_coords[1],
          life.age,
          life.cause,
          life.name_or_blank,
        ]
      end
    end
  end
end
