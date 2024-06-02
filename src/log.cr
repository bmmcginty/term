class Log
  @@fh = File.open("#{File.basename(File.realpath("/proc/self/exe"))}.log", "wb")
  @@c = Channel(String).new

  def self.info(&block : (-> String))
    t = block.call
    @@c.send t
    sleep 0
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
    sleep 0
    t.receive
  end # def

end # class
Log.run
