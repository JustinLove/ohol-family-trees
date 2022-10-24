require 'ohol-family-trees/lifelog_file'
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

      def path_list
        return @path_list if @path_list
        p baseurl + dir
        index = Client.get_content(baseurl + dir)
        #p index
        @path_list = {}
        LifelogServer.extract_path_list(index)
          .map do |path, log_date|
            dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
            next unless dateparts
            cache_path = dir + path
            @path_list[cache_path] = log_date
          end
        @path_list
      end

      def each
        path_list.map do |cache_path, log_date|
          yield Logfile.new(cache_path, log_date, baseurl)
        end
      end

      def has?(cache_path)
        path_list.include?(cache_path)
      end

      def get(cache_path)
        Logfile.new(cache_path, path_list[cache_path], baseurl)
      end
    end

    class Logfile < LifelogFile
      def initialize(path, date, baseurl = BaseUrl)
        super path
        @date = date
        @baseurl = baseurl
      end

      attr_reader :date
      attr_reader :baseurl

      def url
        baseurl + path
      end

      def open
        p url
        contents = Client.get_content(url)
        #p contents
        StringIO.new(contents)
      end
    end
  end
end

