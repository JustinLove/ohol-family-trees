require 'ohol-family-trees/lifelog'

module OHOLFamilyTrees
  class History
    def initialize
      @lives = Hash.new {|h,k| h[k] = Life.new(k)}
      @epoch = 0
    end

    attr_reader :lives,
      :epoch

    def [](key)
      @lives[key]
    end

    def []=(key, value)
      @lives[key] = value
    end

    def length
      @lives.length
    end

    def merge!(other)
      @lives.merge!(other.lives)
    end

    def select(&block)
      @lives.values.select(&block)
    end

    def each(&block)
      @lives.values.each(&block)
    end

    def has_key?(key)
      @lives.has_key?(key)
    end

    def load_log(logfile)
      server = logfile.server
      file = logfile.open
      while line = file.gets
        log = Lifelog.create(line, epoch, server)

        if log.kind_of?(Lifelog::Birth)
          if log.playerid == 2
            @epoch += 1
            log.epoch = epoch
            #p [epoch, path]
          end
          lives[log.key].birth = log
        else
          lives[log.key].death = log
        end
      end
    end

    def load_names(logfile)
      server = logfile.server
      file = logfile.open

      while namelog = Namelog.next_log(file)
        (0..epoch).to_a.reverse.each do |e|
          key = Lifelog.key(namelog.playerid, e, server)
          if lives.has_key?(key)
            lives[key].name = namelog.name
            break
          end
        end
      end
    end

    def load_server(logs, time_range = (Time.at(0)..Time.now))
      logs.each do |logfile|
        next unless logfile.within(time_range)
        #p logfile
        if logfile.names?
          load_names(logfile)
        else
          load_log(logfile)
        end
      end
    end

    def ancestors(target)
      cursor = target
      lineage = [target]
      while cursor && lives.has_key?(cursor.parent) && cursor.parent != Lifelog::NoParent
        cursor = lives[cursor.parent]
        lineage << cursor
      end

      return lineage
    end

    def children(target)
      childs = []
      lives.values.each do |life|
        if life.parent == target.key
          childs << life
        end
      end
      return childs
    end

    def family(target)
      cursor = target
      while cursor && lives.has_key?(cursor.parent) && cursor.parent != Lifelog::NoParent
        cursor = lives[cursor.parent]
      end

      focus = History.new
      focus[cursor.key] = cursor

      count = 0
      while focus.length > count
        count = focus.length
        lives.values.each do |life|
          if focus.has_key?(life.parent)
            focus[life.key] = life
          end
        end
      end

      return focus
    end

    def outsiders(focus)
      count = 0
      while focus.length > count
        count = focus.length
        focus.each do |life|
          if life.killer && !focus.has_key?(life.killer)
            focus.merge!(family(lives[life.killer]))
          end
        end
      end
    end

    def killers(victims)
      focus = History.new
      victims.each do |life|
        if life.killer && !victims.has_key?(life.killer)
          focus[life.killer] = lives[life.killer]
        end
      end
      return focus
    end

    def victims(killer)
      focus = History.new
      lives.values.each do |life|
        if life.killer == killer.key
          focus[life.key] = lives[life.key]
        end
      end
      return focus
    end
  end
end
