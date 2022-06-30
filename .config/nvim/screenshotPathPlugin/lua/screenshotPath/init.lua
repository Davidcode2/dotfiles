local function getStringUnderCursor()
  local file = vim.fn.expand("%:p")
  local stringUnderCursor = vim.fn.getline(vim.fn.line("."))
  return stringUnderCursor
end

local function stringIsPath(stringUnderCursor)
  return string.find(stringUnderCursor, '[%w_-/]') ~= nil
end

local function checkIfStringUnderCurosrIsPath()
  local string = getStringUnderCursor()
  if stringIsPath(string) then
    return true
  end
  print("string under cursor is not a path")
  return false
end

local function getParentPathToCurrentFile()
  --print(vim.inspect(vim.fn.cursor(vim.api.nvim_win_get_cursor)))
  local pathToCurrentFile = vim.fn.expand("%:p:h")
  return pathToCurrentFile
end

local function getDirectories(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

local function prependParentDirToPathnames(parentPath, directories)
  local absolutePathToFile = {}
  for i, path in pairs(directories) do
    local completePath = parentPath .. '/' .. path
    absolutePathToFile[i] = completePath
  end
  return absolutePathToFile
end

local function pathStringIsAmongDirectories(pathString, directories)
  for i, dir in pairs(directories) do
    if dir == string.sub(pathString, 1,19) then
      return true
    end
  end
  return false
end

local M = {}

local function getAmountOfLevelsToTargetDir(substringFromEndOfTarget)
  local countLevelsAfterTargetDir = 0
  for match in string.gmatch(substringFromEndOfTarget, '/') do
      countLevelsAfterTargetDir = countLevelsAfterTargetDir + 1
  end
  return countLevelsAfterTargetDir
end

function M.adjustPath()
  if not checkIfStringUnderCurosrIsPath() then return end
  local parentPathToCurrentFile = getParentPathToCurrentFile()
  local directoriesInCurrentDir = getDirectories(parentPathToCurrentFile)
  if pathStringIsAmongDirectories(stringUnderCursor,directoriesInCurrentDir) then
    print("found joplin dir")
    return true
  end
  local startOfWord, endOfTargetDirName = string.find(parentPathToCurrentFile, "JoplinNotesMarkdown")
  local substringFromEndOfTarget = string.sub(parentPathToCurrentFile, 47)
  local dirUpPrefix = ""
  local countLevelsAfterTargetDir = getAmountOfLevelsToTargetDir(substringFromEndOfTarget)
  for i = 1, countLevelsAfterTargetDir+1 do
    dirUpPrefix = "../" .. dirUpPrefix
  end
  local currentRow = vim.api.nvim_win_get_cursor(0)[1]
  local pathUpPrefixTable = {}
  table.insert(pathUpPrefixTable, dirUpPrefix)
  vim.api.nvim_buf_set_text(0, currentRow-1,0, currentRow-1,0, pathUpPrefixTable)
  -- automatically do this when pasting from primary selection (add listener)
  -- print new string into vim buffer
  -- refactor to take stuff out of this function into smaller ones
end

return M
