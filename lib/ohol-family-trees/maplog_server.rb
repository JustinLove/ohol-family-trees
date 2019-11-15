require 'httpclient'
require 'nokogiri'

module OHOLFamilyTrees
  module MaplogServer
    def self.extract_path_list(directory)
      paths = []
      Nokogiri::HTML(directory).css('a').each do |node|
        path = node.attr(:href)
        next if path == '../'
        date = DateTime.parse(node.next.content.strip.chop.strip).to_time
        paths << [path, date]
      end

      return paths
    end

    BaseUrl = "http://publicdata.onehouronelife.com/publicMapChangeData/"

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
        iter = MaplogServer.extract_path_list(index)
          .map(&:first)
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
        dir
      end

      def each
        p baseurl + dir
        index = Client.get_content(baseurl + dir)
        #p index
        MaplogServer.extract_path_list(index)
          .map do |path, log_date|
            next unless path.match('_mapLog.txt')
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
        @contents = nil
      end

      attr_reader :path
      attr_reader :date
      attr_reader :baseurl
      attr_reader :contents

      def url
        baseurl + path
      end

      def approx_log_time
        return date unless timestamp

        Time.at(timestamp)
      end

      def within(time_range = (Time.at(0)..Time.now))
        time_range.cover?(approx_log_time)
      end

      def server
        path.match(/(.*onehouronelife.com)\//)[1]
      end

      def timestamp
        path.match(/(\d{10})time_/)[1].to_i
      end

      def cache_valid_at?(at_time)
        date.to_i <= at_time && (at_time < 1571853427 || 1572325200 < at_time)
      end

      def seed
        if timestamp == 1571995987
          return nil
        elsif timestamp == 1572240860
          return 30691433003
        elsif timestamp == 1572297324
          return nil
        end
        match = path.match(/_(\d+)seed/)
        match && match[1].to_i
      end

      def merges_with?(file)
        seed && file.seed && seed == file.seed
      end

      def open
        p baseurl + path
        @contents ||= Client.get_content(baseurl + path)
        #p contents
        StringIO.new(contents)
      end
    end
  end
end

