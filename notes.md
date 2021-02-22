- s3 cache headers
  - update code
  - generate file lists for batch operations
    printf 'wondible-com-ohol-tiles,%s\n' tiles/24/*/*.png > tiles24.csv
    - x original tiles 24+ - one year
    - job running - activity map tiles - one month
    - job ready - activity map tiles indexes - one month
    - list generated static tiles - one week
    - job ready static index - one week
    - list generating - static objects - one week - static objects index - one week
    - list generating - log tiles - one month
    - list generating - log objects - one month - log object index - one month
    - job ready - notable objects - one week
- pavers
- batch reprocess ranges
- x manual tagging of previous seed ends?
  - helper script
- expired objects??
- running on data server
  - failures on heroku
  - split by tiles to temp and then process each tile?

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


- x microspan at 1572968386 startTime at end of file
  bigserver2.onehouronelife.com/1572783606time_2085226784seed_mapLog.txt
  - looks like nosaj locations, in a couple files
  - data overwrites previous tile, then next log overwrites span in spans


- overdraw missing for large natural objets
  - maplogs may skip small objects, should always write 0 if possibly unknown
  - assume unknown objects are very large
  - x http://localhost:8000/public/index.html#x=5&y=2&z=29&t=1570914891

- seed change without wipe circa 2019-11-16 03:14
