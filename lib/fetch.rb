require 'httpclient'
require 'nokogiri'
require 'fileutils'

BaseUrl = "http://publicdata.onehouronelife.com/publicLifeLogData/"

$http = HTTPClient.new

def fetch_file(path, cache_path, date = Time.at(0))
  if File.exist?(cache_path) && date < File.mtime(cache_path)
    return File.open(cache_path, "r") {|f| f.read}
  else
    p path
    contents = $http.get_content(BaseUrl + path)

    File.open(cache_path, "w") do |f|
      f.write(contents)
    end

    return contents
  end
end

server_directory = fetch_file("", "cache/index.html", Time.now)

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

server_list = extract_path_list(server_directory)

server_list.each do |path,date|
  FileUtils.mkdir_p('cache/' + path)

  index = fetch_file(path, "cache/#{path}/index.html", date)

  log_paths = extract_path_list(index)
  log_paths.each do |log_path,log_date|
    fetch_file("#{path}#{log_path}", "cache/#{path}#{log_path}", log_date)
  end
end
