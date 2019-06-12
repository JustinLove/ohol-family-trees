require 'ohol-family-trees/lifelog'

path = "test/ff.txt"
file = File.open(path, "r", :external_encoding => 'ASCII-8BIT')
line = file.gets
p line
line = line.tr("\xff".force_encoding("ASCII-8BIT"), '')
p line.encoding
log = OHOLFamilyTrees::Lifelog.create(line, 0, 'server')
p log
