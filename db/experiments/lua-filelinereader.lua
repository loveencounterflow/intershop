
-- thx to http://www.wellho.net/resources/ex.php4?item=u110/flapper
--[[
This program opens a file and reads and writes
it line by line
]]


path = '/home/flow/Downloads/guoxuedashi-headers.txt'
path = '/home/flow/io/mingkwai-rack/mojikura3-model/test-data/guoxuedashi/guoxuedashi-excerpts-with-yitizi.txt'
path = '/home/flow/io/sqlite-demo/data/guoxuedashi-excerpts-with-yitizi.txt'
-- Open a file for read an test that it worked
input, err = io.open( path )
if err then print("OOps"); return; end

-- -- Open a file for write
-- output, err = io.open( '/tmp/luaflr-output.text', 'w' )


-- x = 0
-- while true do
--   x = x + 1
--   line = input:read()
--   if line == nil then break end
--   end

-- thx to http://lua-users.org/wiki/ForTutorial
input = assert( io.open( path, 'r' ) )
-- print( input:lines() )
x = 0
for line in input:lines() do
  x = x + 1
  -- print( line )
  end

print( x )
input:close()





