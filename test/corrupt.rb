require 'ohol-family-trees/lifelog'

path = "test/corrupt.txt"
file = File.open(path, "r", :external_encoding => 'ASCII-8BIT')
while line = file.gets
  p "-"*20
  p line
  log = OHOLFamilyTrees::Lifelog.create(line, 0, 'server')
  p log
end
