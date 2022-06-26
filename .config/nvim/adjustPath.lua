local sh = require 'sh'
-- mark entire path (W)
--if Joplin in currentDir
-- searchCurrentPath()
--  return
--else if 
--  while !Joplin found
--    search dir up
--    pfad
--  edit pfad
print("Hello World")

local containerDirWithResourcesFolder = "JoplinNotesMarkdown"

local function getStringUnderCursor()
  local file = vim.fn.expand("%:p")
  print("my file is ".. file)
  local stringUnderCursor = vim.fn.getline(vim.fn.line("."))
  print(stringUnderCursor)
  return stringUnderCursor
end

local function getPathToCurrentFile()
  --print(vim.inspect(vim.fn.cursor(vim.api.nvim_win_get_cursor)))
  local pathToCurrentFile = vim.fn.expand("%:p:h")
  print(pathToCurrentFile)
  return pathToCurrentFile
end

local function stringIsPath(stringUnderCursor)
  local pathRegex = '(([Aa-Zz][0-9]-_)*/?)*'
  return pathRegex.match(stringUnderCursor)
end

local function getDirectories()
  local directoriesWithPrefix = du(awk('{print $2}'))
  return directoriesWithPrefix
end

local function pathStringIsAmongDirectories(pathString, directories)
  for dir in pairs(directories) do
    print(dir)
    if dir == pathString then
      return true
    end
  end
  return false
end

local stringUnderCursor = getStringUnderCursor()
local directoriesInCurrentDir = getDirectories()
if pathStringIsAmongDirectories(stringUnderCursor,directoriesInCurrentDir) then
  print("found joplin dir")
end


return {
  getStringUnderCursor = getStringUnderCursor
}


