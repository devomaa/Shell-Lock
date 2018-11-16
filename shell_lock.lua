

oldEvent = os.pullEvent
os.pullEvent = os.pullEventRaw --no terminate rEEEEEE

if not fs.exists("hash") then
  shell.run("pastebin get 6UV4qfNF hash")
end
os.loadAPI("hash")
local data = {}
local users = {}
local white = {}
local black = {}
local listBlock = {}
local craftOSVersion = 1.8



local function cleanExit(err)
  os.pullEvent = oldEvent
  if err then
    printError(err)
  end
  while true do
    os.queueEvent("exit")
    os.sleep()
  end
end


local function deepCopy(from,to)
  if type(from) == "table" then
    for k,v in pairs(from) do
      if type(v) == "table" then
        to[k] = {}
        deepCopy(from[k],to[k])
      else
        to[k] = v
      end
    end
  end
end

local function saveData()
  fs.delete(".data")
  h = fs.open(".data","w")
  h.write(textutils.serialize(data))
  h.close()
  print("Successfully saved data.  You will need to reboot to utilize the new data.")
end

local function makeDefaultData()
  local def = "print('This is a placeholder program for autocomplete in the lock')"
  local a = fs.open("login","w")
  a.writeLine(def)
  a.close()
  a = fs.open("users","w")
  a.writeLine(def)
  a.close()
  a = fs.open("newUser","w")
  a.writeLine(def)
  a.close()
  local h = fs.open(".data","w")
  h.writeLine("{")
  h.writeLine("  craftOSVersion = \"LOCKED\",")
  h.writeLine("  MOTD = \"Edit .data to change this information...  Use command 'newUser' to create your first account.  User/pass is 'admin'\",")
  h.writeLine("  users = {")
  local hesh = hash.pbkdf2("admin","salty",3)
  for i = 1,#hesh do
    hesh[i] = string.char(hesh[i])
  end
  hesh = table.concat(hesh)
  h.writeLine("    [\"admin\"] = {i = 3, s = \"salty\", o = \"" .. hesh .. "\"},")
  h.writeLine("    --['username'] = {i = iterations, s = salt, o = pbkdf2_Hashed_Password}")
  h.writeLine("  },")
  h.writeLine("  whitelist = {")
  h.writeLine("    \"login\",")
  h.writeLine("    \"help\",")
  h.writeLine("    \"users\",")
  h.writeLine("    \"newUser\",")
  h.writeLine("  },")
  h.writeLine("}")
  h.close()
  printError("System has been setup.  Reboot (ctrl+r) then login with the user AND pass \"admin\".")
  while true do
    os.sleep(10)
  end
end

local function gatherData()
  local h = fs.open(".data","r")
  if h then
    local a = h.readAll()
    h.close()
    data = textutils.unserialize(a)
    if type(data) == "table" then
      if type(data.users) == "table" then
        deepCopy(data.users,users)
      else
        cleanExit("User table empty, add a user to lock.")
      end
      if type(data.whitelist) == "table" then
        deepCopy(data.whitelist,white)
      else
        white = false
      end
      if type(data.blacklist) == "table" then
        deepCopy(data.blacklist,black)
      else
        black = false
      end
      if type(data.noLS) == "table" then
        deepCopy(data.noLS,listBlock)
      else
        noLS = false
      end
      if data.craftOSVersion then
        craftOSVersion = data.craftOSVersion
      end
    else
      cleanExit("Data table is borked")
    end
  else
    makeDefaultData()
  end
end

local function getValidCompletions(buffer)
  buffer = table.concat(buffer)
  local a = shell.complete(buffer)
  if a then
    if white then
      for i = 1,#a do
        local flag = false
        for o = 1,#white do
          if a[i] then
            if (buffer..a[i]):find(white[o]) then
              flag = true
            end
          end
        end
        if not flag then
          a[i] = nil
        end
      end
    end
    if black then
      for i = 1,#a do
        local flag = false
        for o = 1,#black do
          if a[i] then
            if (buffer..a[i]):find(black[o]) == nil then
              flag = true
            end
          end
        end
        if not flag then
          a[i] = nil
        end
      end
    end
  else
    a = {}
  end

  local i = 1
  local b = {}
  for k,v in pairs(a) do
    if type(v) == "string" then
      b[i] = v
      i = i + 1
    end
  end

  return b
end

local function readAThing()
  local sX,sY = term.getCursorPos()
  local mX,mY = term.getSize()
  local buf = {}
  local cComp = 1
  local pos = 0
  local validComps = {}
  while true do
    term.setCursorBlink(true)

    local ev = {os.pullEvent()}
    if ev[1] == "char" then
      table.insert(buf,pos+1,ev[2])
      cComp = 1
      pos = pos + 1
    elseif ev[1] == "key" then
      if ev[2] == keys.backspace then
        if pos > 0 then
          table.remove(buf,pos)
          cComp = 1
          pos = pos - 1
        end
      elseif ev[2] == keys.enter then
        local cX = term.getCursorPos()
        print(string.rep(" ",mX-cX-1))
        term.setCursorBlink(false)
        return table.concat(buf)
      elseif ev[2] == keys.up then
        cComp = cComp + 1
        if cComp > #validComps then cComp = 1 end
      elseif ev[2] == keys.down then
        cComp = cComp - 1
        if cComp < 1 then
          cComp = #validComps
          if cComp == 0 then
            cComp = 1
          end
        end
      elseif ev[2] == keys.right then
        if pos == #buf then
          local completion = validComps[cComp]
          if completion then
            for i = 1,completion:len() do
              buf[#buf+1] = string.sub(completion,i,i)
              pos = pos + 1
            end
          end
        else
          pos = pos + 1
          if pos > #buf then pos = #buf end
        end
      end
    elseif ev[2] == keys.left then
      pos = pos - 1
      if pos < 0 then pos = 0 end
    elseif ev[2] == keys.tab then
      if pos == #buf then
        local completion = validComps[cComp]
        if completion then
          for i = 1,completion:len() do
            buf[#buf+1] = string.sub(completion,i,i)
            pos = pos + 1
          end
        end
      end
    end
    term.setCursorPos(sX,sY)
    term.write(string.rep(" ",mX-sX))
    term.setCursorPos(sX,sY)
    local st = #buf + sX - (mX-1)
    if st > 0 then
      term.write(table.concat(buf,"",st))
    else
      term.write(table.concat(buf))
    end
    if #buf > 0 then
      validComps = getValidCompletions(buf)
    else
      validComps = {}
    end
    local a = validComps[cComp]
    if a then
      term.setBackgroundColor(colors.gray)
      term.write(a)
      term.setBackgroundColor(colors.black)
    end
    term.setCursorPos(sX+pos,sY)
  end
end

local function doRead()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.yellow)
  term.write("> ")
  term.setTextColor(colors.white)
  return readAThing()
end


local function printStartup()
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setTextColor(colors.yellow)
  term.setCursorPos(1,1)
  print("CraftOS "..tostring(craftOSVersion))
  if data.MOTD then
    term.setTextColor(colors.white)
    print(data.MOTD)
  end
end

local function login()
  term.write("User: ")
  local usr = read()
  if users[usr] then
    term.write("Pass: ")
    local pass = read("*")
    pass = hash.pbkdf2(pass,users[usr].s,users[usr].i)
    for i = 1,#pass do
      pass[i] = string.char(pass[i])
    end
    pass = table.concat(pass)
    if users[usr].o == pass then
      return true
    else
      printError("User and pass do not match.")
      return false
    end
  else
    printError("No user: "..tostring(usr))
    return false
  end
end

local function runAThing(thing)
  if thing then
    if thing == "login" then
      if login() then
        cleanExit()
      end
      return
    elseif thing == "newUser" then
      print("Log in first.")
      if login() then
        print("Input username: ")
        local username = read()
        print("Input password: ")
        local password = read("*")
        print("Reinput password: ")
        local p2 = read("*")
        if password == p2 then
          print("Input password salt: ")
          local salt = read()
          local iter = math.random(2,5)
          if data.users["admin"] then
            data.users["admin"] = nil
            print("Initial 'admin' user deleted.")
          end
          password = hash.pbkdf2(password,salt,iter)
          for i = 1,#password do
            password[i] = string.char(password[i])
          end
          password = table.concat(password)
          data.users[username] = {
            s = salt,
            i = iter,
            o = password,
          }
          saveData()
        else
          printError("The passwords do not match.")
        end
      end
      return
    elseif thing == "help" then
      if white then
        print("Allowed commands/programs:")
        for i = 1,#white do
          print(" ",white[i])
        end
      elseif black then
        print("Blacklisted commands/programs:")
        for i = 1,#black do
          print(" ",black[i])
        end
      end
      return
    elseif thing == "users" then
      for k,v in pairs(users) do
        print(k)
      end
      return
    end
    parallel.waitForAny(
    function ()
      local canRun = false
      if white then
        for i = 1,#white do
          if thing:find(white[i]) then
            canRun = true
          end
        end
      end
      if black then
        for i = 1,#black do
          if thing:find(black[i]) then
            canRun = false
          end
        end
      end
      if canRun then
        shell.run(thing)
      else
        printError("Access denied.  Try 'help'.")
      end
    end,
    function ()
      while true do
        local ev = os.pullEvent()
        if ev == "terminate" then
          printError("Terminated")
          break
        end
      end
    end
    )
  else
    printError("Shell.lua:666:Cannot handle")
  end
end

local function main()
  gatherData()
  printStartup()
  while true do
    runAThing(doRead())
  end
end

local function watch()
  while true do
    local ev = os.pullEvent()
    if ev == "exit" then
      return
    end
  end
end




parallel.waitForAny(main,watch)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.yellow)
term.clear()
term.setCursorPos(1,1)
print("CraftOS 1.8")
