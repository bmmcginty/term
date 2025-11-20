class Log
  @@fh = File.open("#{File.basename(File.realpath("/proc/self/exe"))}.log", "wb")
  @@c = Channel(String).new
  @@log_info = false

  def self.enable_info
    @@log_info = true
  end

  def self.info(&block : (-> String))
    return if !@@log_info
    t = block.call
    @@c.send t
    sleep 0.seconds
  end

  def self.error(&block : (-> String))
    t = block.call
    @@c.send t
    sleep 0.seconds
  end

  def self.run
    t = Channel(Int32).new
    spawn do
      t.send 0
      while 1
        @@fh.puts @@c.receive
        @@fh.flush
      end
    end
    sleep 0.seconds
    t.receive
  end # def

end # class

Log.run
