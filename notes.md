- x not check every lifelog file on every update
- x copying files to map dir
- server date ranges - server?
  - local task?
- xxxlogList be combined?
- x tranfer to server tasks
- long term caching of partial files
  - cloudfront
    - invalidations
    - multiple paths
    - parameters
    - * not copy partial file
      - x not copy
      - copy somewhere else?
      - remove old files - s3 policy?
      - have frontend find somewhere else?
  - browser
    - multiple paths
    - parameters
    - * alternate location
- lineage processing


- time difference between lives and map placments: https://onemap.wondible.com/#x=-28185&y=-597&z=29&s=17&t=1621748525&preset=daily-review
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
