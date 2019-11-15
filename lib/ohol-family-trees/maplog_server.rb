require 'ohol-family-trees/maplog_file'
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

    class Logfile < MaplogFile
      def initialize(path, date, baseurl = BaseUrl)
        super path
        @date = date
        @baseurl = baseurl
        @contents = nil
      end

      attr_reader :date
      attr_reader :baseurl
      attr_reader :contents

      def url
        baseurl + path
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

