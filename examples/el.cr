require "../src/log"
require "../src/controls/edit"
require "../src/controls/main_window"

a = MainWindow.new
edit = EditControl.new height: 1, text: "abcdefg", width: 3
a.add edit, y: 0
a.run
a.refresh
sleep
