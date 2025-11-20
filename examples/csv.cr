require "csv"
require "../src/term"
require "json"
Log.enable_info


class CsvBrowser < StaticTextControl
@row=0
@col=0
@selected=[] of Int32
@data=Array(Array(String)).new
@colmap=Hash(Int32,Int32).new
@fn : String? = nil
@filter=Array(Tuple(Int32,String)).new

setter col,row
getter data, colmap

def load_data(fn)
@fn=fn
col_count=0
File.open(fn, "r") do |fh|
CSV.each_row(fh) do |row|
@data << row
col_count = col_count > row.size ? col_count : row.size
end # each
end # fh
if File.exists?(fn+".colmap")
JSON.parse(File.read(fn+".colmap")).as_h.each do |k,v|
@colmap[k.to_i]=v.as_i
end # each
else # if no colmap
(0...col_count).each do |i|
@colmap[i]=i
end # each
end # make row map
if File.exists?(fn+".filter")
JSON.parse(File.read(fn+".filter")).as_a.each do |i|
@filter << ({i[0].as_i, i[1].as_s})
end
do_filter
end
if File.exists?(fn+".pos")
@row,@col=JSON.parse(File.read(fn+".pos")).as_a.map(&.as_i)[0..1]
end
end # def

def save_pos
File.write(@fn.not_nil!+".pos", [@row,@col].to_json)
end

action def reverse_sort
sort true
end

action def sort(rev=false)
cols=@data.shift
Log.info { "sorting curval is #{@data[@row][@colmap[@col]]}" }
@data.sort_by! do |i|
i[@colmap[@col]]
#t.to_i? ? t.to_i : -1
end
@data.reverse! if rev
@data.unshift cols
end

action def filter
val=@data[@row][@colmap[@col]]
@filter << ({@colmap[@col],val})
save_filter
do_filter
end

def save_filter
File.write(@fn.not_nil!+".filter",@filter.to_json)
end

def do_filter
@filter.each do |colnum,f|
@data.select! {|i| i[colnum] != f }
end
end

action def save_column
t=@data[1..-1].map {|i| "#{i[0]} #{i[@colmap[@col]].gsub(/\n+/," ")}" }
File.write("#{@fn.not_nil!}.col.#{@colmap[@col]}", t.join("\n"))
end

action def shift_left
if @colmap[@col]<=0
no_change
else
@colmap[@col-1],@colmap[@col]=@colmap[@col],@colmap[@col-1]
@col-=1
save_colmap
end
end

action def shift_right
if @colmap[@col]>=@colmap.size+1
no_change
else
@colmap[@col+1],@colmap[@col]=@colmap[@col],@colmap[@col+1]
@col+=1
save_colmap
end
end

def save_colmap
File.write(@fn.not_nil!+".colmap",@colmap.to_json)
end

def no_change
@dirty=false
end

def text
@data[@row][@colmap[@col]]
end

action def right
if @col>=@data[@row].size
no_change
else
@col+=1
end
end

action def left
if @col<=0
no_change
else
@col-=1
end
end

action def up
if @row<=0
@row=0
no_change
else
@row-=1
save_pos if @row%10==0
end
end

action def down
if @row>=@data.size
@row=@data.size-1
no_change
else
@row+=1
save_pos if @row%10==0
end
end # def

end # class

a = MainWindow.new
tb = CsvBrowser.new text: ""
tb.load_data ARGV[0]
if ARGV[1]? && ARGV[2]?
reg=Regex.literal ARGV[2], i: true
tb.row=tb.col=0
t1=tb.data.shift
tb.data.select! {|i| i[tb.colmap[ARGV[1].to_i]].match reg }
tb.data.unshift t1
end
a.add tb, y: 0
a.run
a.refresh
sleep
