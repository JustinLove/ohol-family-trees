## One Hour One Life Family trees

I've been playing around with [GraphViz](http://graphviz.org/) to to make complete family trees from the public lifelog data. Takes a lot more patience to wait until the data is posted, but at least all the descendants should have developed by then

Code is very rough, just using command line invocations of scripts. Basic process is

Update data:

`ruby fetch.rb`

This creates, and later scripts assume, a file structure like

```
cache
  lifeLog_bigserver1.onehouronelife.com
    2018_03March_09_Friday.txt
```

Edit `my_recent_lives.rb` to put in your player hash. This outputs svg wrapped in html to the output directory.

`ruby -Ilib my_recent_lives.rb`

There are a couple other scripts that work similarly, some left from testing. Notably `lives_export.rb` can be used to lives with births, deaths, and names combined for further analysis.


