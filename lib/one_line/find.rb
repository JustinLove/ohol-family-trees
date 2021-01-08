class OneLine
  desc 'find [NAME]', 'find a recent life by character name'
  def find(name)
    log.info { "#{from_time} to #{to_time}" }
    LifelogCache::Servers.new.each do |logs|
      next unless logs.server.match('bigserver2') or logs.server.match(/^server1\./)

      lives = History.new
      lives.load_server(logs, time_range)

      lives.select do |life|
        if life.time > from && life.time < to
          if life.name == name.upcase
            puts ""
            log.debug life
            lineage = lives.ancestors(life) if log.info?
            log.info { lineage.take(5).map(&:name).join(', ') }
            log.warn Time.at(life.time)
            log.info { [Time.at(lineage[-1].time), lives.family(life).length] }
            puts "#{life.hash} #{known_players[life.hash]}"
          end
        end
      end
    end
  end
end
