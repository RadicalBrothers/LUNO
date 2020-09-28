local sock = require "sock"
local utf8 = require("utf8")


function love.load()
	lg = love.graphics

    lg.setBackgroundColor(0, 0.1, 0)

	OnlineState = ""
    CornerImages = {}
	FaceImages = {}
	HeartImages = {}
	BackImages = {}
	BorderImages = {}
	FontQuads = {}
	FontChars = {}
	FontSpCha = {}

	GameState = ""
	
	FontImg = lg.newImage('Graphics/Font.png', {mipmaps=true})
	deck = {}
	cardstodraw = {};
	typeboxes = {};
				--preserved for later use
				--
	highlightedTypebox = "";
	myname = "";
	
	colours = {whit={1,1,1,1},blue={41/255,170/255,226/255,1},pink={232/255,74/255,153/255,1},orng={247/255,148/255,29/255,1},gren={60/255,184/255,120/255,1}, gray={0.8,0.8,0.8,1}};
	abfuncs = {col=setCurrentColour}
	
	FChars = {	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4', '5', '6', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '7', '8', '9', '0', "'", '=', '+', '-', '(', ')', '/', '&', '.', ',', '?', '!', ':', " "}
	FSpCha = {	'<ha', 'rt>', '+qt', '-qt', '...', 'spc', 'crd', 'win', '!lu', '!no', 'skp', 'rvs', 'drw', 'sml', 'lcb', 'rcb','tik','crs','not','yes','<st','ar>','lok','lab','rab'}
	CharSet = Set(FChars)
	SpChSet = Set(FSpCha)
	if true then --this is only here so i can fold it up
	--Partition Font Image into Letters
	for i=0,15 do 
		for j=0,15 do
			FontQuads[(16*i)+j+1] = lg.newQuad(150*j, 300*i, 150, 300, FontImg:getDimensions())
		end
	end
	
	--Fetch Card Pieces
	for nameIndex, name in ipairs({
		1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 'Draw', 'Reverse', 'Skip', 'N'
	}) do
		CornerImages[name] = lg.newImage('Graphics/Corner-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'O', 'P', 'W', 'B', 'G', 'K', 'L', 'N'
	}) do
		BackImages[name] = lg.newImage('Graphics/Background-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'CallDitto', 'CallLuno', 'DrawPile', 'Objection', 'JoinTable', 'HostTable', 'N'
	}) do
		FaceImages[name] = lg.newImage('Graphics/Maintext-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'L', 'W', 'N', 'U', 'D'
	}) do
		HeartImages[name] = lg.newImage('Graphics/HeartCircle-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'LH', 'WH', 'NH', 'LU', 'WU', 'NU'
	}) do
		BorderImages[name] = lg.newImage('Graphics/Border-'..name..'.png', {mipmaps=true})
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
	end
	MessageFeed = ""
	MessageFeedTable = {"Welcome to <col:blue>LU<col:pink>NO!{|lf}<col:whit>Game Pending."}
	MessageFeedScrollDex = 1
	PlayerTable = {}
 
 
    -- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
    love.keyboard.setKeyRepeat(true)
-- for later.
	--table.insert(cardstodraw, {card= table.remove(deck, love.math.random(#deck)), x=600, y=500, s=0.1, id="cardthing6", func=Blank})
	--table.insert(cardstodraw, {card={colour = 'L', number = "CallLuno"}, x=400, y=400, s=0.1, id="LunoButton", func=CallLuno})

	ReturnToMainMenu()
end
 
function love.draw()
	local CardSet = IsMouseInCardBounds(love.mouse.getX(), love.mouse.getY(), false)
	local PlayerTableChat = {}
	if PlayerTable then
	for i, t in pairs(PlayerTable) do table.insert(PlayerTableChat, i..": "..t) end
	end
	--Draw Card using Options
	local function drawCard(card, x, y, s, id)
			local highlight = "U"
			local cardstack = {{bg = 'N', hc = 'N', cn = 'N', mt = 'N', bd='N'}}
			if card.colour == 'L' then
				cardstack.bg = 'L'
				cardstack.hc = 'W'
				cardstack.cn = 'N'
				cardstack.mt = card.number
				cardstack.bd = 'W'
			elseif card.number == 'Wild' then
				cardstack.bg = card.colour
				cardstack.hc = 'L'
				cardstack.cn = 'N'
				cardstack.mt = 'N'
				cardstack.bd = 'L'
			elseif card.number == 'HostTable' then
				cardstack.bg = 'W'
				cardstack.hc = 'N'
				cardstack.cn = 'N'
				cardstack.mt = 'HostTable'
				cardstack.bd = 'L'
			elseif card.number == 'JoinTable' then
				cardstack.bg = 'K'
				cardstack.hc = 'N'
				cardstack.cn = 'N'
				cardstack.mt = 'JoinTable'
				cardstack.bd = 'L'
			elseif card.number == 'ScrollUp' then
				cardstack.bg = card.colour
				cardstack.hc = 'U'
				cardstack.cn = 'N'
				cardstack.mt = 'N'
				cardstack.bd = 'L'
			elseif card.number == 'ScrollDown' then
				cardstack.bg = card.colour
				cardstack.hc = 'D'
				cardstack.cn = 'N'
				cardstack.mt = 'N'
				cardstack.bd = 'L'
			else
				cardstack.bg = card.colour
				cardstack.hc = 'W'
				cardstack.cn = card.number
				cardstack.mt = 'N'
				cardstack.bd = 'W'
			end
			
			lg.draw(BackImages[cardstack.bg], x, y, 0, s)
			lg.draw(HeartImages[cardstack.hc], x, y, 0, s)
			lg.draw(CornerImages[cardstack.cn], x, y, 0, s)
			lg.draw(FaceImages[cardstack.mt], x, y, 0, s)
			if CardSet[id] then highlight = "H" end
			lg.draw(BorderImages[cardstack.bd..highlight], x, y, 0, s)
		end

	local function drawText(text, x, y, charWrap, s, ignoreCommands)
		local OnThisLine=0
		local TotalLines=0
		local spacing=150*s
		local ignorei=0
		
		local function drawchar(q)
			lg.draw(FontImg, FontQuads[q], x+(spacing*OnThisLine), y+(2*spacing*TotalLines), 0, s)
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
			elseif j == "{" then
				if text:sub(i+4,i+4) == "}" and not ignoreCommands then
					if text:sub(i+1,i+3) == "|lf" then
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
			elseif j == "<" then
				if text:sub(i+9,i+9) == ">" and not ignoreCommands then
					local ff = text:sub(i+1,i+3)
					if  abfuncs[ff] then
						abfuncs[ff](text:sub(i+5,i+8));
					else
						drawchar(255);
					end
					ignorei=9
				else
					drawchar(FontSpCha["lab"])
				end
			elseif j == ">" then
				drawchar(FontSpCha["rab"])
			else
				drawchar(FontChars[j] or 128)
			end
		end
	
	setCurrentColour("whit")
	return TotalLines
	end

	local function drawTextbox(box)	
		local drawingX = -1
		local drawingY = -1
		local spacing=150*box.scale
		local ignorei=0
		local drawthing=256
		
		local function drawchar(q)
			lg.draw(FontImg, FontQuads[q], box.x+(spacing*drawingX), box.y+(2*spacing*drawingY), 0, box.scale)
			drawingX = drawingX + 1
			if drawingX > box.length then
				drawingX = -1
				drawingY = drawingY + 1
			end
		end
		
		if highlightedTypebox==box.name then setCurrentColour("blue") else setCurrentColour("gray") end
		
		while drawingY<=box.height do		
			if drawingY==-1 then
				if drawingX==-1 then drawthing=220
				elseif drawingX==box.length then drawthing=222
				elseif drawingX==0 and box.badge=="name" then drawthing=223
				elseif drawingX==1 and box.badge=="name" then drawthing=224
				else drawthing=221 
				end
			elseif drawingY==box.height then
				if drawingX==-1 then drawthing=252
				elseif drawingX==box.length then drawthing=254
				elseif drawingX==box.length-2 and box.badge=="send" then drawthing=239
				elseif drawingX==box.length-1 and box.badge=="send" then drawthing=240
				else drawthing=253 
				end				
			elseif drawingX==-1 then drawthing=236
			elseif drawingX==box.length then drawthing=238 
			else drawthing=237 end
			drawchar(drawthing)
		end
		setCurrentColour("whit")
		drawText(box.text, box.x, box.y, box.length, box.scale, box.ignoreCommands)
	end

	local function drawMessageFeed(Table,x,y,charwrap,s, outdex)
		local index = outdex
		local linedex = y
		local Messages = #Table
		
		while index <= Messages do
			linedex = linedex +(drawText(Table[index], x,linedex,charwrap,s,false) + 1.5)*300*s
			index = index + 1
		end
	end

    for index, i in pairs(cardstodraw) do
		drawCard(i.card, i.x, i.y, i.s,i.id)
	end
	
	for index, i in pairs(typeboxes) do
		drawTextbox(i)
	end
	
	drawMessageFeed(MessageFeedTable,650, 30, 29, 0.1,1)
	if PlayerTableChat then drawMessageFeed(PlayerTableChat, 400,30,15,0.1,1) end
end

function setCurrentColour(index)
	lg.setColor(colours[index] or {1,1,1,1}) --colour does not feel like a real word anymore
end

--Find which cards the mouse is inside
function IsMouseInCardBounds(x,y)
	local set = {}
	for _, i in pairs(cardstodraw) do
		if x >= i.x
        and x < i.x + (700*i.s)
        and y >= i.y
        and y < i.y + (1080*i.s) then
		set[i.id] = i.func end
	end
	return set
end

function IsMouseInTextboxBounds(x,y)
	local set = {thing=""}
	for _, i in pairs(typeboxes) do
		if x >=  i.x - (69*i.scale)
        and x <  i.x + (150*(i.length+1)*i.scale) +  (69*i.scale)
        and y >= i.y - (64*i.scale)
        and y <  i.y + (300*(i.height+1)*i.scale) + (64*i.scale) then
		print(i.name)
		set["thing"] = i.name end
	end
	return set
end

function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function ReturnToMainMenu()
	typeboxes = {NameBox={name="NameBox",x=40,y=275,scale=0.2,length=15,height=1,text="",badge="name",ignoreCommands=true, returnfunction=myNameIs},
				IPBox={name="IPBox",x=40,y=400,scale=0.2,length=15,height=1,text="",badge="ip",ignoreCommands=true, returnfunction=Blank},
				PortBox={name="PortBox",x=40,y=525,scale=0.2,length=15,height=1,text="",badge="port",ignoreCommands=true, returnfunction=Blank}}; 
	ClearCardsToDraw()
	table.insert(cardstodraw, {card={colour = 'K', number = "JoinTable"}, x=40, y=40, s=0.2, id="JoinTableButton", func=ClientHost})
	table.insert(cardstodraw, {card={colour = 'W', number = "HostTable"}, x=240, y=40, s=0.2, id="HostTableButton", func=ServerHost})
	PlayerTable = {}
	
	GameState = "MainMenu"
	OnlineState = ""
end

function SettingsMenuLoad()
	typeboxes = {ChatBox={name="ChatBox",x=60,y=500,scale=0.1,length=28,height=3,text="",badge="",ignoreCommands=false, returnfunction=sendChatMessage}}
	ClearCardsToDraw()
	GameState = "SettingsMenu"
end

function ClearCardsToDraw()
	cardstodraw = {}
	table.insert(cardstodraw, {card={colour = 'K', number = "ScrollUp"}, x=550, y=40, s=0.1, id="UpScrollButton", func=ScrollUp})
	table.insert(cardstodraw, {card={colour = 'K', number = "ScrollDown"}, x=550, y=160, s=0.1, id="DownScrollButton", func=ScrollDown})
end	

function love.mousepressed(x,y,b)
	local set = IsMouseInCardBounds(love.mouse.getX(), love.mouse.getY())
	local boxset = IsMouseInTextboxBounds(love.mouse.getX(), love.mouse.getY())
	for id, func in pairs(set) do
		(func or Blank)(b)
	end
	
	for id, func in pairs(boxset) do
		highlightedTypebox=func
	end
end

function ClientHost()
	if OnlineState=="" then
		if typeboxes["NameBox"].text then myname = typeboxes["NameBox"].text end
		local myIP = typeboxes["IPBox"].text or "localhost"
		if myIP == "" then myIP = "localhost" end
		local myPort = tonumber(typeboxes["PortBox"].text) or 22122
		if myname == "" then
			appendChatFeed("<col|orng>Please type a name.<col|whit>")
		else
			appendChatFeed("<col|pink>Looking for Table at "..myIP..":"..myPort)
			love.window.setTitle("LUNO Alpha: Joining as "..myname)
		-- Creating a new client on localhost:22122
		client = sock.newClient(myIP, myPort)

		-- Called when a connection is made to the server
		client:on("connect", function(data)
			print("Client connected to the server.")
		end)
		
		-- Called when the client disconnects from the server
		client:on("disconnect", function(data)
			appendChatFeed("<col|orng>Disconnected from the table.")
			ReturnToMainMenu()
		end)

		-- Custom callback, called whenever you send the event from the server
		client:on("hello", function(msg)
			PlayerTable=msg
			appendChatFeed("<col|pink>Connected to "..msg.host.."'s Table!")
			client:send("playerconnect", {name=myname,index=client:getIndex()})
		end)

		client:connect()
		
		-- Recieved when the server acknowledges a message.
		client:on("ChatMessage", function(data)
			recieveChatMessage(data.text,data.name)
		end)
		
		-- Recieved whenever a new player connects or disconnects to the server.
		client:on("playerconnected", function(data)
			if data.disconnect then recieveChatMessage("A player has left the Table.") else recieveChatMessage(data.name.." has joined the Table!") end
			PlayerTable=data.Table
		end)
		
		OnlineState = "Client"
		SettingsMenuLoad()
		end
	else appendChatFeed("{|lf}<col|orng>You are already online!") end
end

function ServerHost()
	if OnlineState=="" then
		if typeboxes["NameBox"].text then myname = typeboxes["NameBox"].text end
		local myIP = typeboxes["IPBox"].text or "localhost"
		local myPort = tonumber(typeboxes["PortBox"].text) or 22122
		if myname == "" then
			appendChatFeed("{|lf}<col|orng>Please type a name.<col|whit>")
		else
		appendChatFeed("<col|pink>Hosting Table on port "..myPort)
		love.window.setTitle("LUNO Alpha: Hosting as "..myname)
		server = sock.newServer("*", myPort)
		PlayerTable["host"]=myname
		
		-- Called when someone connects to the server
		server:on("connect", function(data, client)
			-- Send a message back to the connected client
			client:send("hello", PlayerTable)
		end)
		
		server:on("playerconnect", function(data, client)
			PlayerTable[client:getConnectId()]=data.name
			server:sendToAll("playerconnected",{Table=PlayerTable,name=data.name, disconnect=false})
			recieveChatMessage(data.name.." has joined the Table!")
		end)
		
		server:on("disconnect", function(data, client)
			UpdatePlayerTable();
			server:sendToAll("playerconnected",{Table=PlayerTable, disconnect=true})
			recieveChatMessage("A player has left the Table.")
		end)
		
		--Called when a client sends a message
		server:on("ClientChatMessage", function(data, client)
			-- Send a message to all clients, and recieve it ourselves
			server:sendToAll("ChatMessage", data)
			recieveChatMessage(data.text,data.name)
		end)
		
		OnlineState = "Server"
		SettingsMenuLoad()
		end
	else appendChatFeed("{|lf}<col|orng>You are already online!<col|whit>") end
end

function UpdatePlayerTable()
	if OnlineState == "Server" then
		local ConnectIDSet = {host=true}
		server:sendToAll("RebuildPlayerTable",true)
		for i,n in pairs(server:getClients()) do ConnectIDSet[n:getConnectId()]=true end
		for i,n in pairs(PlayerTable) do 
		if not ConnectIDSet[i] then PlayerTable[i]=nil end 
		end
	else print("attempted to UpdatePlayerTable as Client") end
end

function CallLuno()
	appendChatFeed("<col|pink>GAME: <col|whit>You Called <col|blue>{!lu}<col|pink>{!no}<col|whit>!")
end

function ScrollUp() end

function ScrollDown() end

function Blank() end

function sendChatMessage(textbox)
	if OnlineState=="Server" then
		recieveChatMessage(textbox.text,myname)
		server:sendToAll("ChatMessage", {text=textbox.text, name=myname})
	elseif OnlineState=="Client" then
		client:send("ClientChatMessage", {text=textbox.text, name=myname})
	else
		recieveChatMessage(textbox.text,myname)
	end
	textbox.text = ""
end

function recieveChatMessage(text,name)
	if name then appendChatFeed(name..": "..text) else appendChatFeed(text) end
end

function myNameIs(textbox)
	myname=textbox.text
	appendChatFeed("<col|blue>Name Set to: "..myname.."<col:whit>")
end

function appendChatFeed(message)
	table.insert(MessageFeedTable, message)
end

function appendTypeBox(message)
	local box = typeboxes[highlightedTypebox] or false
	if box and #box.text<(box.length*box.height) then
		box.text = box.text..message
	end
end

function backspaceTypeBox()
	local box = typeboxes[highlightedTypebox] or false
	if box then
-- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(box.text, -1)
 
        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            box.text = string.sub(box.text, 1, byteoffset - 1)
        end
	end
end

function returnTypeBox()
	local box = typeboxes[highlightedTypebox] or false
	if box then
		box.returnfunction(box)
	end
end

function love.keypressed(key)
	if key == "backspace" then
        backspaceTypeBox()
	elseif key == "return" then 
		returnTypeBox()
    end
	--todo: implement functionality for 'delete','left','right','up','down'
end

function love.textinput(text)
	local brackset = Set({'{','}','<','>'})
	if CharSet[text] or brackset[text] then appendTypeBox(text) end
end

function love.update(dt)
	if OnlineState == "Client" then
		client:update()
	end
	if OnlineState == "Server" then
		server:update()
	end	
end

-- disconnect immediately on exit
function love.quit()
	if OnlineState=="Server" then server:destroy()
	elseif OnlineState=="Client" then client:disconnectNow() end
end