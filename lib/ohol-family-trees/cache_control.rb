module CacheControl
  NoCache = {'Cache-Control' => "no-cache"}
  OneHour = {'Cache-Control' => "max-age=8600"}
  OneDay = {'Cache-Control' => "max-age=86400"}
  OneWeek = {'Cache-Control' => "max-age=604800"}
  OneMonth = {'Cache-Control' => "max-age=2592000"}
  OneYear = {'Cache-Control' => "max-age=31536000"}
end
