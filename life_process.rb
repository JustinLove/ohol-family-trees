require 'ohol-family-trees/lifelog_cache'
require 'ohol-family-trees/lifelog_server'
require 'ohol-family-trees/lifelog_list'
require 'ohol-family-trees/filesystem_local'
require 'ohol-family-trees/filesystem_s3'
require 'ohol-family-trees/filesystem_group'
require 'set'

include OHOLFamilyTrees

#OutputDir = 'output'
OutputDir = 'd:/dev/ohol-map/public'
OutputBucket = 'wondible-com-ohol-tiles'
LifelogArchive = 'publicLifeLogData'

filesystem = FilesystemGroup.new([
  FilesystemLocal.new(OutputDir),
#  FilesystemS3.new(OutputBucket),
])

LifelogCache::Servers.new.each do |logs|
  #server = logs.server.sub('.onehouronelife.com', '')
  #next unless server == 'bigserver2'

  archive_path = "#{LifelogArchive}/lifeLog_#{logs.server}"
  p archive_path

  list = LifelogList::Logs.new(filesystem, "#{archive_path}/file_list.json", "#{LifelogArchive}/")

  p 'list files', list.files.length
  updated_files = Set.new
  list.update_from(logs) do |logfile|
    updated_files << logfile.path
  end
  p 'updated', updated_files.length
  p 'list files', list.files.length
  #p list.files

  list.each do |logfile|
    if logs.has?(logfile.path)
      logfile = logs.get(logfile.path)
    end

    if true
      if updated_files.member?(logfile.path)
        if logfile.file_probably_complete?
          p 'updated file', logfile.path
          filesystem.write(LifelogArchive + '/' + logfile.path, CacheControl::OneYear.merge(ContentType::Text)) do |archive|
            IO::copy_stream(logfile.open, archive)
          end
        end
      end
    end
  end

  list.checkpoint
end
