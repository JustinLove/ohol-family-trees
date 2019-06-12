require 'ohol-family-tress/lifelog'
require 'ohol-family-tress/history'
require 'ohol-family-trees/lifelog_cache'
require 'ohol-family-tress/graph'
require 'date'
require 'csv'

include OHOLFamilyTrees

from_time = (Date.today - 2).to_time
to_time = (Date.today - 0).to_time

LifelogCache::Servers.new.each do |logs|
  lives = History.new

  lives.load_server(logs, ((from_time - 60*60*24*1)..(to_time + 60*60*24*1)))

  p lives.length
  next unless lives.length > 0

  from = from_time.to_i
  to = to_time.to_i

  server = logs.server

  CSV.open("output/#{server}_#{from_time.to_date}_#{to_time.to_date}.csv", 'wb') do |csv|
    csv << [
      "hash",
      "key",
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
          life.key,
          life.gender,
          life.parent,
          life.chain,
          life.birth_time,
          life.birth_coords && life.birth_coords[0],
          life.birth_coords && life.birth_coords[1],
          life.death_time,
          life.death_coords && life.death_coords[0],
          life.death_coords && life.death_coords[1],
          life.age,
          life.cause,
          life.name_or_blank,
        ]
      end
    end
  end
end
