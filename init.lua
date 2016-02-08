-- use pin 0 as the input pulse width counter
pulse1 = 0
du = 0
gpio.mode(1,gpio.INT,gpio.PULLUP)
blink_state = gpio.HIGH

function connect_mqtt()
  -- for secure: m:connect("192.168.11.118", 1880, 1)
  m:connect("m20.cloudmqtt.com", 12267, 0, function(conn)
    print("connected")
    m:publish("/topic","isr",0,0, function(client) print("sent") m:close() end)
  end)
end

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

  -- publish a message with data = hello, QoS = 0, retain = 0
  m:publish("/topic","hello", 1, 0, function(client) print("sent") m:close() end)

  -- you can call m:connect again
  return m
end

gpio.mode(0,gpio.OUTPUT)
gpio.write(0, gpio.HIGH)

function pin1cb(level)
 du = tmr.now() - pulse1
 print(du)
 pulse1 = tmr.now()
 if du > 2000000 then
   connect_mqtt()
 end

 --if level == 1 then gpio.trig(1, "down") else gpio.trig(1, "up") end
end


enduser_setup.start(
  function()
    print("Connected to wifi as:" .. wifi.sta.getip())
    tmr.delay(2000000)
    print("MQTT")
    m = init_mqtt()

    gpio.trig(1, "down", pin1cb)

  end,
  function(err, str)
    print("enduser_setup: Err #" .. err .. ": " .. str)
  end
);

--file.close()
