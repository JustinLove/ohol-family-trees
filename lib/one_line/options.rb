class OneLine
  LogLevels = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]
  class_option :verbose, :default => 'WARN', :desc => 'DEBUG, INFO, WARN'
  class_option :i, :type => :boolean, :desc => 'verbose=INFO'
  class_option :d, :type => :boolean, :desc => 'verbose=DEBUG'

  private
  def verbose
    d = options[:d] && 'DEBUG'
    i = options[:i] && 'INFO'
    v = options[:verbose].to_s.upcase
    ([d, i, v, "WARN"] & LogLevels).compact.first
  end
end
