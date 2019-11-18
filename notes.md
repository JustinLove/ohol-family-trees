- players ids in maplogs
  - redundant -1s
- diffed keyframes
  - expiring tiles from the keyplace after sufficient time
- batch reprocess ranges
- overdraw missing for large natural objets
  - assume unknown objects are very large
  - http://localhost:8000/public/index.html#x=5&y=2&z=29&t=1570914891
- seed files
- two part seed
- expired objects
- maplog compression
- running on data server
  - failures on heroku

- process multiple servers
- search method to narrow down life for graph
- more user friendly?
- position by time?


# file structure

## current: t/z/x/y.txt
arcs.json
problems:
  - no resumption, or fake giant file reprocess
  - no expiration
  - 404 for missing tiles

## wip keyframes: t/z/x/y.txt
spans.json
problems:
  - keyframe size grows very large, load entire thing
  - track last updated for each tile
  - expiration management
  - 404 for missing tiles

## master keyframe record: t/z/x/y?, large keyframe index file t/z/index.txt
spans?
t/z.json
problems:
  - implement lazy loading of tiles
  - could be large
  - track last updated for each tile
  - expiration management

## individual tile histories: z/x/y/t.txt, z/x/y/index.txt
problems:
  - implement lazy loading of tiles
  - 404 for missing tile
  - multiple fetches: index, keyframe, maybe maplog
  - multiple uploads: index + data
  - can't manage time groups at filesystem level



# done
- "bigserver2.onehouronelife.com/1571995987time_3738527057seed_mapLog.txt"
- 1572240860time_2976543425seed_mapLog.txt
  - possible seed for second part: 1572297324time_3069153003seed_mapLog.txt
- suspect change: 2019-10-23 12:22:28
- suspect golive: 2019-10-26 00:48:51
- fixed: 2019-10-28 16:57
- released: ?
