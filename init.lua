function init_mqtt ()
  -- init mqtt client with keepalive timer 120sec
  m = mqtt.Client("NodeMCU", 120, "lfrajpey", "0g0WElp_rPjj")

  -- setup Last Will and Testament (optional)
  -- Broker will publish a message with:
  -- qos = 0, retain = 0, data = "offline"
  -- to topic "/lwt" if client don't send keepalive packet
  m:lwt("/lwt", "offline", 0, 0)

  m:on("connect", function(con) print ("connected") end)
  m:on("offline", function(con) print ("offline") end)

  -- on publish message receive event
  m:on("message", function(conn, topic, data)
    print(topic .. ":" )
    if data ~= nil then
      print(data)
    end
  end)

  -- for secure: m:connect("192.168.11.118", 1880, 1)
  m:connect("m20.cloudmqtt.com", 12267, 0, function(conn)
      print("connected")
  end)

  tmr.delay(1000000)

  -- publish a message with data = hello, QoS = 0, retain = 0
  m:publish("/topic","hello",0,0, function(conn)
      print("sent")
  end)

  m:close();
  -- you can call m:connect againend
  return m
end

function isr ()
  print("ESP8266 AP IP now is: " .. wifi.ap.getip())

  -- print("ESP8266 STATION IP now is: " .. wifi.sta.getip())

  -- now the module is configured and connected to the network so lets start setting things up for the control logic
  gpio.mode(8,gpio.OUTPUT)
  gpio.mode(9,gpio.OUTPUT)

  tmr.delay(10)
  gpio.write(8,gpio.HIGH)
  tmr.delay(10)
  gpio.write(8,gpio.LOW)
end

print("WIFI control")
-- put module in AP mode
wifi.setmode(wifi.SOFTAP)
print("ESP8266 mode is: " .. wifi.getmode())
cfg={}
-- Set the SSID of the module in AP mode and access password
cfg.ssid="NodeMCU"
cfg.pwd="admin1234"

if cfg.ssid and cfg.pwd then
  print("ESP8266 SSID is: " .. cfg.ssid .. " and PASSWORD is: " .. cfg.pwd)
end
-- Now you should see an SSID wireless router named ESP_STATION when you scan for available WIFI networks
-- Lets connect to the module from a computer of mobile device. So, find the SSID and connect using the password selected
wifi.ap.config(cfg)
ap_mac = wifi.ap.getmac()
-- create a server on port 80 and wait for a connection, when a connection is coming in function c will be executed
sv=net.createServer(net.TCP,30)
sv:listen(80,function(c)
  c:on("receive", function(c, pl)

    -- print the payload pl received from the connection
    print(pl)
    print(string.len(pl))

    -- wait until SSID comes back and parse the SSID and the password
    print(string.match(pl,"GET"))
    ssid_start,ssid_end=string.find(pl,"SSID=")
    if ssid_start and ssid_end then
      amper1_start, amper1_end =string.find(pl,"&", ssid_end+1)
      if amper1_start and amper1_end then
        http_start, http_end =string.find(pl,"HTTP/1.1", ssid_end+1)
        if http_start and http_end then
          ssid=string.sub(pl,ssid_end+1, amper1_start-1)
          password=string.sub(pl,amper1_end+10, http_start-2)
          print("ESP8266 connecting to SSID: " .. ssid .. " with PASSWORD: " .. password)
          if ssid and password then
            sv:close()
            -- close the server and set the module to STATION mode
            wifi.setmode(wifi.STATIONAP)
            print("ESP8266 mode now is: " .. wifi.getmode())
            -- configure the module wso it can connect to the network using the received SSID and password
            wifi.sta.config(ssid,password)
            print("Setting up ESP8266 for station mode...Please wait.")
            tmr.alarm(1,1000, 1, function() if wifi.sta.getip()==nil then print(" Wait to IP address!") else print("New IP address is "..wifi.sta.getip()) init_mqtt() isr() tmr.stop(1) end end)
            -- tmr.delay(20000000)

            -- sv=net.createServer(net.TCP, 30)
            -- sv:listen(9999,function(c)
            --   c:on("receive", function(c, pl)
            --     if tonumber(pl) ~= nil then
            --       if tonumber(pl) >= 1 and tonumber(pl) <= 16 then
            --         print(tonumber(pl))
            --         tmr.delay(10)
            --         gpio.write(8,gpio.HIGH)
            --         tmr.delay(10)
            --         gpio.write(8,gpio.LOW)
            --         for count =1,tonumber(pl) do
            --           print(count)
            --           tmr.delay(10)
            --           gpio.write(9,gpio.LOW)
            --           tmr.delay(10)
            --           gpio.write(9,gpio.HIGH)
            --           c:send("Sequence finished")
            --         end
            --       end
            --     end
            --     print("ESP8266 STATION IP now is: " .. new_ip)
            --     c:send("ESP8266 STATION IP now is: " .. new_ip)
            --     c:send("Action completed")
            --   end)
            -- end)
          end
        end
      end
    end
    --c:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 61\r\n\r\n<!DOCTYPE html><html lang='en'><body>helloworld</body></html>")
    c:send("HTTP/1.1 200 OK\r\n")
    c:send("Content-Type: text/html\r\n")
    c:send("Content-Length: 520\r\n")
    c:send("\r\n")
    -- this is the web page that requests the SSID and password from the user
    c:send("<!DOCTYPE html> ")
    c:send("<html lang='en'> ")
    c:send("<body> ")
    c:send("<h1>ESP8266 Wireless control setup</h1> ")
    mac_mess1 = "The module MAC address is: " .. ap_mac
    mac_mess2 = "You will need this MAC address to find the IP address of the module, please take note of it."

    c:send("<h2>" .. mac_mess1 .. "</h2> ")
    c:send("<h2>" .. mac_mess2 .. "</h2> ")
    c:send("<h2>Enter SSID and Password for your WIFI router</h2> ")

    c:send("<form action='' method='get'>")
    c:send("SSID:")
    c:send("<input type='text' name='SSID' value='' maxlength='100' />")
    c:send("<br />")
    c:send("Password:")
    c:send("<input type='text' name='Password' value='' maxlength='100' />")
    c:send("<input type='submit' value='Submit' />")
    c:send("</form> </body> </html>")
  end)
end)
file.close()
