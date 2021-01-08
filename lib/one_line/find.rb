class OneLine
  desc 'find [NAME]', 'find a recent life by chracter name'
  def find(name)
    from_time = (Date.today - 3).to_time
    to_time = (Date.today + 1).to_time

    LifelogCache::Servers.new.each do |logs|
      lives = History.new

      next unless logs.server.match('bigserver2') or logs.server.match(/^server1\./)

      time_range = (from_time - 60*60*24*3)..(to_time + 60*60*24*3)
      lives.load_server(logs, time_range)

      from = from_time.to_i
      to = to_time.to_i

      lives.select do |life|
        if life.time > from && life.time < to
          if life.name == name.upcase
            lineage = lives.ancestors(life)
            puts
            log.debug life
            log.warn { lineage.take(5).map(&:name).join(', ') }
            log.warn Time.at(life.time)
            log.debug { [Time.at(lineage[-1].time), lives.family(life).length] }
            puts life.hash
          end
        end
      end
    end
  end
end
