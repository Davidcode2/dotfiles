local function getStringUnderCursor()
  local file = vim.fn.expand("%:p")
  print("my file is ".. file)
  local stringUnderCursor = vim.fn.getline(vim.fn.line("."))
  return stringUnderCursor
end

local function getParentPathToCurrentFile()
  --print(vim.inspect(vim.fn.cursor(vim.api.nvim_win_get_cursor)))
  local pathToCurrentFile = vim.fn.expand("%:p:h")
  print(pathToCurrentFile)
  return pathToCurrentFile
end

local function stringIsPath(stringUnderCursor)
  return string.find(stringUnderCursor, '[%w_-/]') ~= nil
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

function M.adjustPath()
  local stringUnderCursor = getStringUnderCursor()
  if not stringIsPath(stringUnderCursor) then
    print("string under cursor is not a path")
    return false
  end
  print(stringUnderCursor)
  local parentPathToCurrentFile = getParentPathToCurrentFile()
  local directoriesInCurrentDir = getDirectories(parentPathToCurrentFile)
  local absolutePathsInCurrentDir = prependParentDirToPathnames(parentPathToCurrentFile, directoriesInCurrentDir)
  if pathStringIsAmongDirectories(stringUnderCursor,directoriesInCurrentDir) then
    print("found joplin dir")
    return true
  else
    print("else block")
    local startOfWord, endOfTargetDirName = string.find(parentPathToCurrentFile, "JoplinNotesMarkdown")
    print(endOfTargetDirName)
    local substringFromEndOfTarget = string.sub(parentPathToCurrentFile, 47)
    local countLevelsAfterTargetDir = 0
    for match in string.gmatch(substringFromEndOfTarget, '/') do
        countLevelsAfterTargetDir = countLevelsAfterTargetDir + 1
    end
    print(countLevelsAfterTargetDir)
    local pathToScreenshotDirWithPrependedHops = stringUnderCursor
    for i = 1, countLevelsAfterTargetDir do
      pathToScreenshotDirWithPrependedHops = "../" .. pathToScreenshotDirWithPrependedHops
    end
    print(pathToScreenshotDirWithPrependedHops)
    -- print new string into vim buffer
    -- refactor to take stuff out of this function into smaller ones
   return true
  end
  return "myString"
end

return M
