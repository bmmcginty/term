require "../src/log"
require "../src/controls/*"

def main
  w = MainWindow.new
  clock = StaticTextControl.new text: "00:00:00", height: 1
  w.add clock, x: 0, y: 0
  key = StaticTextControl.new text: "testing", height: 1
  w.add key, x: 0, y: 2
  w.run
  w.refresh
  while 1
    clock.text = Time.local.to_s("%H:%M:%S")
    w.refresh
    sleep 1
  end
end

main
