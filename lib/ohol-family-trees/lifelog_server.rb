require 'httpclient'
require 'nokogiri'

module OHOLFamilyTrees
  module LifelogServer
    def self.extract_path_list(directory)
      paths = []
      Nokogiri::HTML(directory).css('a').each do |node|
        path = node.attr(:href)
        next if path == '../' or path == 'lifeLog/'
        date = DateTime.parse(node.next.content.strip.chop.strip).to_time
        paths << [path, date]
      end

      return paths
    end

    BaseUrl = "http://publicdata.onehouronelife.com/publicLifeLogData/"

    Client = HTTPClient.new

    class Servers
      include Enumerable

      def initialize(baseurl = BaseUrl)
        @baseurl = baseurl
      end

      attr_reader :baseurl

      def each(&block)
        p baseurl
        index = Client.get_content(baseurl)
        #p index
        iter = LifelogServer.extract_path_list(index)
          .map(&:first)
          .select {|dir| dir.match("lifeLog_")}
          .map {|dir| Logs.new(dir, baseurl) }
        if block_given?
          iter.each(&block)
        end
      end
    end

    class Logs
      include Enumerable

      def initialize(dir, baseurl = BaseUrl)
        @dir = dir
        @baseurl = baseurl
      end

      attr_reader :dir
      attr_reader :baseurl

      def server
        dir.match(/lifeLog_(.*)\//)[1]
      end

      def each
        p baseurl + dir
        index = Client.get_content(baseurl + dir)
        #p index
        LifelogServer.extract_path_list(index)
          .map do |path, log_date|
            dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
            next unless dateparts
            cache_path = dir + path
            yield Logfile.new(cache_path, log_date, baseurl)
          end
      end
    end

    class Logfile
      def initialize(path, date, baseurl = BaseUrl)
        @path = path
        @date = date
        @baseurl = baseurl
      end

      attr_reader :path
      attr_reader :date
      attr_reader :baseurl

      def url
        baseurl + path
      end

      def approx_log_time
        dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
        return date unless dateparts

        Time.gm(dateparts[1], dateparts[2], dateparts[3])
      end

      def within(time_range = (Time.at(0)..Time.now))
        time_range.cover?(approx_log_time)
      end

      def server
        path.match(/lifeLog_(.*)\//)[1]
      end

      def names?
        path.match('_names.txt')
      end

      def open
        p baseurl + path
        contents = Client.get_content(baseurl + path)
        #p contents
        StringIO.new(contents)
        #File.open(file_path, "r", :external_encoding => 'ASCII-8BIT')
      end
    end
  end
end

