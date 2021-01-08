require 'httpclient'
require 'nokogiri'
require 'fileutils'

module OHOLFamilyTrees
  class Mirror
    PublicDataUrl = 'http://publicdata.onehouronelife.com'
    MonumentsUrl = "https://onehouronelife.com"

    attr_reader :log
    attr_reader :public_data
    attr_reader :cache
    attr_reader :http

    attr_accessor :monuments_url

    def initialize(log, public_data = PublicDataUrl, cache = 'cache')
      @log = log
      @public_data = public_data
      @cache = cache
      @http = HTTPClient.new

      @monuments_url = MonumentsUrl
    end

    def lives
      mirror('publicLifeLogData')
    end

    def maps
      mirror('publicMapChangeData')
    end

    def mirror(subdir)
      base_url = "#{public_data}/#{subdir}/"
      base_path = "#{cache}/#{subdir}"

      ensure_directory(base_path)

      server_directory = fetch_file(base_url, "", "#{base_path}/index.html", Time.now)

      server_list = extract_path_list(server_directory)

      server_list.each do |path,date|
        FileUtils.mkdir_p("#{base_path}/#{path}")

        index = fetch_file(base_url, path, "#{base_path}/#{path}/index.html", date)

        log_paths = extract_path_list(index)
        log_paths.each do |log_path,log_date|
          fetch_file(base_url, "#{path}#{log_path}", "#{base_path}/#{path}#{log_path}", log_date)
        end
      end
    end

    def ensure_directory(path)
      unless Dir.exist?(path)
        loop do
          puts "Target directory '#{path}' does not exist"
          puts "c Create"
          puts "a Abort"
          case $stdin.gets.chomp.downcase
          when 'c'
            FileUtils.mkdir_p(path)
            break
          when 'a'
            raise "output directory does not exist"
          end
        end
      end

    end

    def fetch_file(base, path, cache_path, date = Time.at(0))
      if File.exist?(cache_path) && date < File.mtime(cache_path)
        return File.open(cache_path, "r") {|f| f.read}
      else
        log.warn path
        contents = http.get_content(base + path)

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

    def extract_monument_path_list(directory)
      paths = []
      Nokogiri::HTML(directory).css('table table table a').each do |node|
        path = node.attr(:href)
        paths << path
      end

      return paths
    end


    def monuments
      base_path = "#{cache}/monuments"

      ensure_directory(base_path)

      known = nil
      if File.exists?("#{base_path}/count.txt")
        known = File.read("#{base_path}/count.txt")
      end
      known = known && known.to_i

      fetch_file(monuments_url, "/monumentStats.php", "#{base_path}/monumentStats.php", Time.now)
      contents = File.read("#{base_path}/monumentStats.php")
      count = nil

      if contents && match = contents.match(/(\d+) monuments completed/)
        count = match[1].to_i
        File.write("#{base_path}/count.txt", count.to_s)
      end

      p "#{count} monuments now, #{known} last time"

      if known.nil? || count.nil? || count > known
        sync_monuments(base_path)
      end
    end

    def sync_monuments(base_path)
      base_url = "#{monuments_url}/monuments/"
      monument_directory = fetch_file(base_url, "", "#{base_path}/index.html", Time.now)

      monument_list = extract_monument_path_list(monument_directory)

      monument_list.each do |path|
        fetch_file(base_url, path, "#{base_path}/#{path}", Time.now)
      end
    end
  end
end
