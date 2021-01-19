require 'httpclient'
require 'nokogiri'
require 'fileutils'

$http = HTTPClient.new

def fetch_file(base, path, cache_path, date = Time.at(0))
  if File.exist?(cache_path) && date < File.mtime(cache_path)
    return File.open(cache_path, "r") {|f| f.read}
  else
    p path
    contents = $http.get_content(base + path)

    File.open(cache_path, "w") do |f|
      f.write(contents)
    end

    return contents
  end
end

def extract_path_list(directory)
  paths = []
  Nokogiri::HTML(directory).css('a').each do |node|
    path = node.attr(:href)
    next if path == '../' or path == 'lifeLog/'
    date = DateTime.parse(node.next.content.strip.chop.strip).to_time
    paths << [path, date]
  end

  return paths
end

LifeUrl = "http://publicdata.onehouronelife.com/publicLifeLogData/"
LifePath = "cache/publicLifeLogData"

FileUtils.mkdir_p(LifePath)

server_directory = fetch_file(LifeUrl, "", "#{LifePath}/index.html", Time.now)

server_list = extract_path_list(server_directory)

server_list.each do |path,date|
  FileUtils.mkdir_p("#{LifePath}/#{path}")

  index = fetch_file(LifeUrl, path, "#{LifePath}/#{path}/index.html", date)

  log_paths = extract_path_list(index)
  log_paths.each do |log_path,log_date|
    fetch_file(LifeUrl, "#{path}#{log_path}", "#{LifePath}/#{path}#{log_path}", log_date)
  end
end

MapUrl = "http://publicdata.onehouronelife.com/publicMapChangeData/"
MapPath = "cache/publicMapChangeData"

FileUtils.mkdir_p(MapPath)

server_directory = fetch_file(MapUrl, "", "#{MapPath}/index.html", Time.now)

server_list = extract_path_list(server_directory)

server_list.each do |path,date|
  FileUtils.mkdir_p("#{MapPath}/#{path}")

  index = fetch_file(MapUrl, path, "#{MapPath}/#{path}/index.html", date)

  log_paths = extract_path_list(index)
  log_paths.each do |log_path,log_date|
    fetch_file(MapUrl, "#{path}#{log_path}", "#{MapPath}/#{path}#{log_path}", log_date)
  end
end

def extract_monument_path_list(directory)
  paths = []
  Nokogiri::HTML(directory).css('table table table a').each do |node|
    path = node.attr(:href)
    paths << path
  end

  return paths
end

MonumentsUrl = "http://onehouronelife.com/monuments/"

FileUtils.mkdir_p('cache/monuments')
known = nil
if File.exists?("cache/monuments/count.txt")
  known = File.read("cache/monuments/count.txt")
end
known = known && known.to_i

fetch_file("http://onehouronelife.com/", "monumentStats.php", "cache/monuments/monumentStats.php", Time.now)
contents = File.read("cache/monuments/monumentStats.php")
count = nil

if contents && match = contents.match(/(\d+) monuments completed/)
  count = match[1].to_i
  File.write("cache/monuments/count.txt", count.to_s)
end

p "#{count} monuments now, #{known} last time"

if known.nil? || count.nil? || count > known
  monument_directory = fetch_file(MonumentsUrl, "", "cache/monuments/index.html", Time.now)

  monument_list = extract_monument_path_list(monument_directory)

  monument_list.each do |path|
    fetch_file(MonumentsUrl, path, "cache/monuments/#{path}", Time.now)
  end
end
