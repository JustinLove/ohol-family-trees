class OneLine
  desc 'defcon', 'check for recent apocalypse towers'
  def defcon
    level = 5
    defcon = {}
    actors = Set.new
    targets = {
      #'839' => [5, "bell"],
      #'2470' => [5, "endblock"],
      '2476' => [5, "nosaj"],
      '2477' => [4, "L1"],
      '2487' => [3, "L2"],
      '2485' => [2, "L3"],
      '2483' => [1, "L4"],
      '2482' => [0, "Apocalypse"],
    }
    levels = [
      "Apocalypse",
      "Defcon 1 imminent destruction",
      "Defcon 2 next step",
      "Defcon 3 increased readiness'",
      "Defcon 4 increased intelligence",
      "Defcon 5 lowest state",
    ]

    MaplogCache::Servers.new.each do |logs|
      log.debug logs

      logs.each do |logfile|
        next unless map_time_range.member?(logfile.approx_log_time)
        log.info logfile.path
        file = logfile.open
        while line = file.gets
          log = Maplog.create(line)
          if log.kind_of?(Maplog::ArcStart)
          elsif log.kind_of?(Maplog::Placement)
            if targets.member?(log.object)
              p [log.object, targets[log.object], log.x, log.y, log.actor]
              defcon[[log.x,log.y]] = log.object
              actors << log.actor
              if targets[log.object][0] < level
                level = targets[log.object][0]
              end
            end
          end
        end
      end
    end

    matching_lives(actors) do |life, lives|
      log.debug life.inspect
      puts "#{life.playerid} #{life.hash} #{life.name} #{known_players[life.hash]}"
    end

    if level < 5
      log.warn headline('-', levels[level])
    else
      log.info headline('-', levels[level])
    end
  end
end
