local sock = require "sock"
local utf8 = require("utf8")


function love.load()
    love.graphics.setBackgroundColor(0, 1, 0)

	OnlineState = ""
    CornerImages = {}
	FaceImages = {}
	HeartImages = {}
	BackImages = {}
	FontQuads = {}
	FontChars = {}
	FontSpCha = {}
	FontImg = love.graphics.newImage('Graphics/Font.png', {mipmaps=true})
	deck = {}
	cardstodraw = {}
	
	FChars = {	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4', '5', '6', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '7', '8', '9', '0', "'", '=', '+', '-', '(', ')', '/', '&', '.', ',', '?', '!', " "}
	FSpCha = {	'hrt', '...', '+qt', '-qt', 'tbd', 'spc', 'crd', 'win', '!lu', '!no', 'skp', 'rvs', 'drw', 'sml', 'lcb', 'rcb'}
	
	--Partition Font Image into Letters
	for i=0,15 do 
		for j=0,15 do
			FontQuads[(16*i)+j+1] = love.graphics.newQuad(150*j, 300*i, 150, 300, FontImg:getDimensions())
		end
	end
	
	--Fetch Card Pieces
	for nameIndex, name in ipairs({
		1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 'Draw', 'Reverse', 'Skip', 'N'
	}) do
		CornerImages[name] = love.graphics.newImage('Graphics/Corner-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'O', 'P', 'W', 'B', 'G', 'K', 'L', 'N'
	}) do
		BackImages[name] = love.graphics.newImage('Graphics/Background-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'CallDitto', 'CallLuno', 'DrawPile', 'Objection', 'JoinTable', 'HostTable', 'N'
	}) do
		FaceImages[name] = love.graphics.newImage('Graphics/Maintext-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'L', 'W', 'N'
	}) do
		HeartImages[name] = love.graphics.newImage('Graphics/HeartCircle-'..name..'.png', {mipmaps=true})
	end
		
	--Populate Deck	
	for suitIndex, suit in ipairs({'O', 'P', 'B', 'G'}) do
		table.insert(deck, {colour = suit, number = 0})
		for rankIndex, rank in ipairs({1, 2, 3, 4, 5, 6, 7, 8, 9, 'Skip', 'Reverse', 'Draw'}) do
			table.insert(deck, {colour = suit, number = rank})
			table.insert(deck, {colour = suit, number = rank})
        end
	end
	for i=1,4 do
		table.insert(deck, {colour = 'W', number = 'Wild'})
			table.insert(deck, {colour = 'K', number = 'Wild'})
	end
	
	--Populate CharList with letters and numbers
	for nameIndex, name in ipairs(FChars) do
		FontChars[name] = nameIndex
	end
	
	--Populate SpChaList with letters and numbers
	for nameIndex, name in ipairs(FSpCha) do
		FontSpCha[name] = nameIndex+128
	end
	
	text = "Type away! -- "
 
    -- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
    love.keyboard.setKeyRepeat(true)
	
	--testing the card click thing with a lot of cards.
	table.insert(cardstodraw, {card={colour = 'W', number = "JoinTable"}, x=40, y=40, s=0.2, id="JoinTableButton", func="ClientHost"})
	table.insert(cardstodraw, {card={colour = 'W', number = "HostTable"}, x=240, y=40, s=0.2, id="HostTableButton", func="ServerHost"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=100, y=400, s=0.1, id="cardthing1", func="nil"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=200, y=400, s=0.1, id="cardthing2", func="nil"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=300, y=400, s=0.1, id="cardthing3", func="nil"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=400, y=400, s=0.1, id="cardthing4", func="nil"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=500, y=400, s=0.1, id="cardthing5", func="nil"})
	table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=600, y=400, s=0.1, id="cardthing6", func="nil"})
	table.insert(cardstodraw, {card={colour = 'L', number = "CallLuno"}, x=400, y=200, s=0.1, id="LunoButton", func="LUNO"})

end
 
function love.draw()
	local function drawCard(card, x, y, s)
			local cardstack = {{bg = 'N', hc = 'N', cn = 'N', mt = 'N'}}
			if card.colour == 'L' then
				cardstack.bg = 'L'
				cardstack.hc = 'W'
				cardstack.cn = 'N'
				cardstack.mt = card.number
			elseif card.number == 'Wild' then
				cardstack.bg = card.colour
				cardstack.hc = 'L'
				cardstack.cn = 'N'
				cardstack.mt = 'N'
			elseif card.number == 'HostTable' then
				cardstack.bg = 'W'
				cardstack.hc = 'N'
				cardstack.cn = 'N'
				cardstack.mt = 'HostTable'
			elseif card.number == 'JoinTable' then
				cardstack.bg = 'K'
				cardstack.hc = 'N'
				cardstack.cn = 'N'
				cardstack.mt = 'JoinTable'
			else
				cardstack.bg = card.colour
				cardstack.hc = 'W'
				cardstack.cn = card.number
				cardstack.mt = 'N'
			end
			
			love.graphics.draw(BackImages[cardstack.bg], x, y, 0, s)
			love.graphics.draw(HeartImages[cardstack.hc], x, y, 0, s)
			love.graphics.draw(CornerImages[cardstack.cn], x, y, 0, s)
			love.graphics.draw(FaceImages[cardstack.mt], x, y, 0, s)
		end

	local function drawText(text, x, y, charWrap, s)
		local CharSet = Set(FChars)
		local SpChSet = Set(FSpCha)
		local OnThisLine=0
		local TotalLines=0
		local spacing=150*s
		local ignorei=0
		
		local function drawchar(q)
			love.graphics.draw(FontImg, FontQuads[q], x+(spacing*OnThisLine), y+(2*spacing*TotalLines), 0, s)
			OnThisLine = OnThisLine + 1
			if OnThisLine >= charWrap then
				OnThisLine = 0
				TotalLines = TotalLines + 1
			end
		end
		
		for i = 1, string.len(text) do
			local j = text:sub(i,i)
			if ignorei >= 1 then
				ignorei = ignorei - 1
			elseif CharSet[j] then
				drawchar(FontChars[j])
			elseif j == "{" then
				if text:sub(i+4,i+4) == "}" then
					if text:sub(i+1,i+3) == "!lf" then
						OnThisLine = 0
						TotalLines = TotalLines + 1
					elseif SpChSet[text:sub(i+1,i+3)] then
						drawchar(FontSpCha[text:sub(i+1,i+3)])
					else
						drawchar(256)
					end
					ignorei=4
				else
					drawchar(FontSpCha["lcb"])
				end
			elseif j == "}" then
				drawchar(FontSpCha["rcb"])
			else
				drawchar(128)
			end
		end
	
	
	end

    for index, i in ipairs(cardstodraw) do
		drawCard(i.card, i.x, i.y, i.s)
	end
	
	drawText("These pixels are looking{!lf}SO MUCH BETTER", 650, 30, 28, 0.1)
end

function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function love.keypressed(key)
    if key == 's' then
        ServerHost()
    end
	if key == 'c' then
        ClientHost()
    end
	if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(text, -1)
 
        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            text = string.sub(text, 1, byteoffset - 1)
        end
    end
end

function ClientHost()
	print("client is now on!")
    -- Creating a new client on localhost:14941
    client = sock.newClient("localhost", 14941)

    -- Called when a connection is made to the server
    client:on("connect", function(data)
        print("Client connected to the server.")
    end)
    
    -- Called when the client disconnects from the server
    client:on("disconnect", function(data)
        print("Client disconnected from the server.")
    end)

    -- Custom callback, called whenever you send the event from the server
    client:on("hello", function(msg)
        print("The server replied: " .. msg)
    end)

    client:connect()
    
    --  You can send different types of data
    client:send("greeting", "Hello, my name is Inigo Montoya.")
    client:send("isShooting", true)
    client:send("bulletsLeft", 1)
    client:send("position", {
        x = 465.3,
        y = 50,
    })	
	
	OnlineState = "Client"
end

function ServerHost()
    print("Server Start!")
	server = sock.newServer("*", 14941)
    
    -- Called when someone connects to the server
    server:on("connect", function(data, client)
        -- Send a message back to the connected client
        local msg = "Hello from the server!"
        client:send("hello", msg)
    end)
	
	OnlineState = "Server"
end

function love.update(dt)
	if OnlineState == "Client" then
		client:update()
	end
	if OnlineState == "Server" then
		server:update()
	end
		
end