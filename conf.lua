function love.conf(t)
	t.author = "Rokon" 
	t.identity = "LUNO Alpha"
	--t.console = true
	t.accelerometerjoystick = false
	t.modules.physics = false
	t.version = "11.3"
	t.window.width = 640
    t.window.height = 360
	t.window.title = "LUNO Alpha"
	t.window.resizable = true
	t.window.centered = false
	t.externalstorage = false
	
	t.modules.joystick = false
	t.modules.physics = false
end