module CacheControl
  NoCache = {:cache_control => "no-cache"}
  OneHour = {:cache_control => "max-age=8600"}
  OneDay = {:cache_control => "max-age=86400"}
  OneWeek = {:cache_control => "max-age=604800"}
  OneMonth = {:cache_control => "max-age=2592000"}
  OneYear = {:cache_control => "max-age=31536000"}
end
