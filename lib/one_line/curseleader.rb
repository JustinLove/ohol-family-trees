class OneLine
  desc 'curseleader', 'leading recent curse receivers'
  def curseleader
    curses = Hash.new {|h,k| h[k] = 0}
    matching_curses(curselog_time_range) do |curse|
      curses[curse.to_hash] += curse.net
    end
    curses.to_a.sort_by {|h,c| c}.each do |h,c|
      log.debug [h, c]
      puts "#{c.to_s.rjust(4)} #{h[0..7]} #{known_players[h]}"
    end
  end
end
