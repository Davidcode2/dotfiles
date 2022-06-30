local notesFolderName = "notes"

local function getStringUnderCursor()
  local file = vim.fn.expand("%:p")
  local stringUnderCursor = vim.fn.getline(vim.fn.line("."))
  return stringUnderCursor
end

local function stringIsPath(stringUnderCursor)
  return string.find(stringUnderCursor, '[%w_-/]') ~= nil
end

local function getParentPathToCurrentFile()
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

local function getAmountOfLevelsToTargetDir(substringFromEndOfTarget)
  local countLevelsAfterTargetDir = 0
  for match in string.gmatch(substringFromEndOfTarget, '/') do
      countLevelsAfterTargetDir = countLevelsAfterTargetDir + 1
  end
  return countLevelsAfterTargetDir
end

local function getEndOfParentDirStringPosition(parentPathToCurrentFile)
  local notesFolderNameWithTrailingSlash = notesFolderName .. "/"
  local startOfWord, endOfTargetDirName = string.find(parentPathToCurrentFile, notesFolderNameWithTrailingSlash .."%w*/")
  return endOfTargetDirName
end

local function getDirUpPrefix(substringFromEndOfTarget)
  local dirUpPrefix = ""
  local countLevelsAfterTargetDir = getAmountOfLevelsToTargetDir(substringFromEndOfTarget)
  for i = 1, countLevelsAfterTargetDir+1 do
    dirUpPrefix = "../" .. dirUpPrefix
  end
  return dirUpPrefix
end

local function makeUpDirectoryPrefix(parentPathToCurrentFile)
  local endOfTargetDirNamePos = getEndOfParentDirStringPosition(parentPathToCurrentFile)
  if not endOfTargetDirNamePos then return false end
  local substringFromEndOfTarget = string.sub(parentPathToCurrentFile, endOfTargetDirNamePos)
  if not substringFromEndOfTarget then return false end
  local pathUpPrefixTable = {}
  local dirUpPrefix = getDirUpPrefix(substringFromEndOfTarget)
  table.insert(pathUpPrefixTable, dirUpPrefix)
  return pathUpPrefixTable
end

local function prependPrefixToCurrentLine(pathUpPrefixTable)
  local currentRow = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_text(0, currentRow-1,0, currentRow-1,0, pathUpPrefixTable)
end

local M = {}

function M.adjustPath()
  local stringUnderCursor = getStringUnderCursor()
  if not stringIsPath(stringUnderCursor) then return end
  local pathToParentDirOfCurrentFile = getParentPathToCurrentFile()
  local directoriesInCurrentDir = getDirectories(pathToParentDirOfCurrentFile)
  if pathStringIsAmongDirectories(stringUnderCursor,directoriesInCurrentDir) then
    print("found resources root dir")
    return true
  end
  local pathUpPrefixTable = makeUpDirectoryPrefix(pathToParentDirOfCurrentFile)
  if not pathUpPrefixTable then
    print("path doesn't contain 'notes'")
    return end
  prependPrefixToCurrentLine(pathUpPrefixTable)
  -- automatically do this when pasting from primary selection (add listener)
  -- auto change dir (do this in general, not concerning this plugin)
  -- add ![]()
end

return M
