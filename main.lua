local sock = require "sock"
local utf8 = require("utf8")

function love.load()
	lg = love.graphics

    lg.setBackgroundColor(0, 0.1, 0)
	
	debugbuild=true --SET TO FALSE AT SOME POINT
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
	discard = {}
	discardTop = {}
	cardstodraw = {};
	typeboxes = {};
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
		'CallDitto', 'CallLuno', 'DrawPile', 'Objection', 'JoinTable', 'HostTable', 'PlayGame', 'Blank', 'N'
	}) do
		FaceImages[name] = lg.newImage('Graphics/Maintext-'..name..'.png', {mipmaps=true})
	end
	for nameIndex, name in ipairs({
		'L', 'O', 'P', 'W', 'B', 'G', 'N', 'U', 'D'
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
		table.insert(deck, {colour = 'L', number = 'WildW'})
			table.insert(deck, {colour = 'L', number = 'WildK'})
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
	MessageFeedTable = {"Welcome to <col:blue>LU<col:pink>NO!<col:whit> Game Development has FINALLY begun!"}
	MessageFeedScrollDex = 1
	PlayerTable = {}
	TurnTable = {}
	MyHand = {}
	HandIndex = 1
	TurnIndex = 1
	TurnsAreGoingBackward = false
 
	ReturnToMainMenu()
end
 
function love.draw()
	local CardSet = IsMouseInCardBounds(love.mouse.getX(), love.mouse.getY(), false)
	local PlayerTableChat = {}
	
	if TurnTable[1] then
		for i, t in pairs(TurnTable) do 
			local colour=""
			if i==TurnIndex then colour="<col:pink>" end
			table.insert(PlayerTableChat, colour..PlayerTable[t].handcount.."{crd}: "..PlayerTable[t].name) 
		end --it'll do for now
	elseif PlayerTable then
		for i, t in pairs(PlayerTable) do 
			table.insert(PlayerTableChat, t.name)	
		end
	end
	--Draw Card using Options
	local function drawCard(card, x, y, s, id)
			local highlight = "U"
			local cardstack = {{bg = 'N', hc = 'N', cn = 'N', mt = 'N', bd='N'}}
			if card.number == 'N' then
				cardstack.bg = 'N'
				cardstack.hc = 'N'
				cardstack.cn = 'N'
				cardstack.mt = 'N'
				cardstack.bd = 'N'
			elseif card.number == 'WildW' then
				cardstack.bg = 'W'
				cardstack.hc = card.colour
				cardstack.cn = 'N'
				cardstack.mt = 'N'
				cardstack.bd = 'L'
			elseif card.number == 'WildK' then
				cardstack.bg = 'K'
				cardstack.hc = card.colour
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
			elseif card.colour == 'L' then
				cardstack.bg = 'L'
				cardstack.hc = 'W'
				cardstack.cn = 'N'
				cardstack.mt = card.number
				cardstack.bd = 'W'
			else
				cardstack.bg = card.colour
				cardstack.hc = 'W'
				cardstack.cn = card.number
				cardstack.mt = 'N'
				cardstack.bd = 'W'
			end
			
			lg.draw(BackImages[cardstack.bg] or BackImages['N'], x, y, 0, s)
			lg.draw(HeartImages[cardstack.hc] or BackImages['N'], x, y, 0, s)
			lg.draw(CornerImages[cardstack.cn] or BackImages['N'], x, y, 0, s)
			lg.draw(FaceImages[cardstack.mt] or BackImages['N'], x, y, 0, s)
			if CardSet[id] then highlight = "H" end
			lg.draw(BorderImages[cardstack.bd..highlight] or BackImages['N'], x, y, 0, s)
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
				elseif drawingX==0 and box.badge=="ip" then drawthing=239
				elseif drawingX==1 and box.badge=="ip" then drawthing=240
				elseif drawingX==0 and box.badge=="chat" then drawthing=234
				elseif drawingX==1 and box.badge=="chat" then drawthing=235
				elseif drawingX==0 and box.badge=="port" then drawthing=250
				elseif drawingX==1 and box.badge=="port" then drawthing=251
				else drawthing=221 
				end
			elseif drawingY==box.height then
				if drawingX==-1 then drawthing=252
				elseif drawingX==box.length then drawthing=254
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
		drawCard(i.card, i.x, i.y, i.s, i.id)
	end
	
	for index, i in pairs(typeboxes) do
		drawTextbox(i)
	end
	
	drawMessageFeed(MessageFeedTable,740, 30, 35, 0.1,MessageFeedScrollDex)
	if PlayerTableChat then drawMessageFeed(PlayerTableChat, 40,30,15,0.1,1) end
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
        and x <  i.x + (150*(i.length)*i.scale) +  (69*i.scale)
        and y >= i.y - (64*i.scale)
        and y <  i.y + (300*(i.height)*i.scale) + (64*i.scale) then
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
	createCButton({colour = 'K', number = "JoinTable"}, 40, 40, 0.2, "JoinTableButton", ClientHost)
	createCButton({colour = 'W', number = "HostTable"}, 240, 40, 0.2,"HostTableButton", ServerHost)
	PlayerTable = {}
	TurnTable = {}
	GameState = "MainMenu"
	OnlineState = ""
end

function SettingsMenuLoad()
	typeboxes = {ChatBox={name="ChatBox",x=60,y=500,scale=0.1,length=35,height=4,text="",badge="chat",ignoreCommands=false, returnfunction=sendChatMessage}}
	ClearCardsToDraw()
	createCButton({colour = 'L', number = "PlayGame"}, 240, 40, 0.2, "StartTableButton", PlayGame)
	TurnTable = {}
	GameState = "SettingsMenu"
end

function StartGame()
	local TempTurnTable = {}
	typeboxes = {ChatBox={name="ChatBox",x=70,y=450,scale=0.08,length=35,height=4,text="",badge="chat",ignoreCommands=false, returnfunction=sendChatMessage}}
	ClearCardsToDraw()
	recieveChatMessage("<col|blue>The game has started!")
	createCButton({colour = 'B', number = "WildK"}, 40, 570, 0.1, "PlayerCard1", PlayCard1)
	createCButton({colour = 'O', number = "WildW"}, 120, 570, 0.1, "PlayerCard2", PlayCard2)
	createCButton({colour = 'N', number = "N"}, 200, 570, 0.1, "PlayerCard3", PlayCard3)
	createCButton({colour = 'N', number = "N"}, 280, 570, 0.1, "PlayerCard4", PlayCard4)
	createCButton({colour = 'N', number = "N"}, 360, 570, 0.1, "PlayerCard5", PlayCard5)
	createCButton({colour = 'N', number = "N"}, 440, 570, 0.1, "PlayerCard6", PlayCard6)
	createCButton({colour = 'N', number = "N"}, 520, 570, 0.1, "PlayerCard7", PlayCard7)
	createCButton({colour = 'N', number = "N"}, 600, 570, 0.1, "PlayerCard8", PlayCard8)
	createCButton({colour = 'L', number = "CallLuno"}, 680, 570, 0.1, "PlayerCard9", PlayCard9)
	createCButton({colour = 'P', number = "ScrollUp"}, 760, 570, 0.05, "HandScrollUp", HandScrollU)
	createCButton({colour = 'B', number = "ScrollDown"}, 760, 624, 0.05, "HandScrollDown", HandScrollD)
	
	HandIndex=1
	
	if OnlineState=="Server" then 
		for i,n in pairs(PlayerTable) do 
			for f = 1,7 do
			table.insert(PlayerTable[i].hand, DrawCardFromDeck())
			end
			PlayerTable[i].handcount = 7
			table.insert(TempTurnTable, i)
		end
		while #TempTurnTable>0 do table.insert(TurnTable, table.remove(TempTurnTable, math.random(#TempTurnTable))) end
		discardTop = DrawCardFromDeck()
		server:sendToAll("GAMESTART", {PT=PlayerTable, TT=TurnTable, DT=discardTop})
	end
	
	createCButton(discardTop, 170, 280, 0.15, "DiscardPile", nil)
	createCButton({colour = 'L', number = "DrawPile"}, 60, 280, 0.15, "DrawPile", DrawCardButton)
	createCButton({colour = 'L', number = "CallLuno"}, 280, 280, 0.15, "CallLuno", CallLunoButton)
	createCButton({colour = 'L', number = "Blank"}, 390, 280, 0.15, "ContextSensitiveButton", ContextSensitiveButton)
	
	GameState = "Gameplay"
	UpdateHandLook()
end

function DrawCardButton() DoPlayerAction('Draw') end
function CallLunoButton() DoPlayerAction('Luno') end
function ContextSensitiveButton() DoPlayerAction('CSB') end
function PlayCard1() PlayACard(0) end
function PlayCard2() PlayACard(1) end
function PlayCard3() PlayACard(2) end
function PlayCard4() PlayACard(3) end
function PlayCard5() PlayACard(4) end
function PlayCard6() PlayACard(5) end
function PlayCard7() PlayACard(6) end
function PlayCard8() PlayACard(7) end
function PlayCard9() PlayACard(8) end
function PlayACard(n) DoPlayerAction('Play',HandIndex+n) end

function DoPlayerAction(act,n)
	if GameState ~= "Gameplay" then print("what?"); return end
	
	n=n or 0
	
	if OnlineState=="Server" then
		if PlayerAction(act, n, "host") then
		IterateTurnIndex()
		server:sendToAll("GameplayUpdate", {PT=PlayerTable,TT=TurnTable,DT=discardTop,TI=TurnIndex})
		UpdateHandLook()
		end
	elseif OnlineState=="Client" then
	client:send("PlayerDidSomething", {action=act,card=n,id=WhoAmI()})
	end
end

function PlayerAction(action,card,id,theClient) 
	if TurnTable[TurnIndex]==id then --update later to account for Ditto and Luno
		if action=="Draw" then return PlayerDrawsCard(id,theClient)
		elseif action=="Play" then return PlayerPlaysCard(id, card, theClient)
		end
	else 
		return PlayerError("<col:gren>It is not your turn.")
	end
end

function IterateTurnIndex()
	if TurnsAreGoingBackward then
		TurnIndex = TurnIndex - 1
		if TurnIndex<1 then TurnIndex = #TurnTable end
	else
		TurnIndex = TurnIndex + 1
		if TurnIndex>#TurnTable then TurnIndex = 1 end
	end
end

function PlayerDrawsCard(ID,theClient)
	table.insert(PlayerTable[ID].hand, DrawCardFromDeck())
	PlayerTable[ID].handcount = PlayerTable[ID].handcount + 1
	UpdateHandLook()
	return true --update later for draw cards
end

function PlayerPlaysCard(ID,NO,theClient)
	local DT = discardTop
	local PlayedCard = PlayerTable[ID] and PlayerTable[ID].hand and PlayerTable[ID].hand[NO] or "asdf"
		if PlayedCard == "asdf" then 
			return PlayerError(ID,theClient,"<col:gren>That card does not exist.");
		end
		
		if PlayedCard.colour == DT.colour or PlayedCard.number == DT.number then --update later for special cards and wilds
			table.insert(discard,DT)
			discardTop=PlayedCard
			table.remove(PlayerTable[ID].hand, NO)
			PlayerTable[ID].handcount = PlayerTable[ID].handcount - 1
			return true
		else
			return PlayerError(ID,theClient,"<col:gren>Card cannot be played.")
		end
end

function PlayerError(ID,CLI,TXT)
if ID=="host" then recieveChatMessage(TXT)
			else
			if CLI then CLI:send("PlayError", TXT); end  end
			return false
end

function UpdateGameplay(PT,TT,DT,TI)
			PlayerTable=PT
			TurnTable=TT
			discardTop=DT
			TurnIndex=TI
			UpdateHandLook()
end

function DrawCardFromDeck()
	if #deck < 1 then deck=discard; discard = {} end
	return table.remove(deck, love.math.random(#deck))
end

function UpdateHandLook()
	local myID = WhoAmI()
	local myHand = PlayerTable[myID] and PlayerTable[myID].hand or {{colour = 'B', number = "WildK"},{colour = 'B', number = "WildK"}}
	local theHandCount = PlayerTable[myID] and PlayerTable[myID].handcount or 9
	if theHandCount<HandIndex+8 then if theHandCount<9 then HandIndex=1 else HandIndex=theHandCount-8 end end
	
	print(myID.." UpdateHandLookHas Run")
	for i=HandIndex,HandIndex+8 do
		cardstodraw[("PlayerCard%d"):format(i+1-HandIndex)].card = myHand[i] or {colour = 'N', number = "N"}
	end
	if theHandCount>9 then 
		cardstodraw["HandScrollUp"].card = {colour = 'N', number = "ScrollUp"}
		cardstodraw["HandScrollDown"].card = {colour = 'N', number = "ScrollDown"}
	else
		cardstodraw["HandScrollUp"].card = {colour = 'N', number = "N"}
		cardstodraw["HandScrollDown"].card = {colour = 'N', number = "N"}	
	end
	
	cardstodraw["DiscardPile"].card=discardTop
end

function WhoAmI()
		if OnlineState == "Server" then return "host"
	elseif OnlineState == "Client" then return client:getConnectId()
	else recieveChatMessage("You have no identity right now."); return end
end

function setCurrentColour(index)
	lg.setColor(colours[index] or {1,1,1,1}) --colour does not feel like a real word anymore
end


function ClearCardsToDraw()
	cardstodraw = {}
	createCButton({colour = 'K', number = "ScrollUp"}, 670, 40, 0.1, "UpScrollButton", ScrollUp)
	createCButton({colour = 'K', number = "ScrollDown"}, 670, 160, 0.1, "DownScrollButton", ScrollDown)
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
			appendChatFeed("<col|pink>Connected to "..msg.host.name.."'s Table!")
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
			if GameState=="Gameplay" then TurnTable=data.TT; TurnIndex=data.TI end
		end)
		
		client:on("GAMESTART", function(data) 
			PlayerTable=data.PT
			TurnTable=data.TT
			discardTop=data.DT
			StartGame()
		end)
		
		client:on("GameplayUpdate", function(data) 
			UpdateGameplay(data.PT,data.TT,data.DT,data.TI)
		end)
		
		client:on("notyourturn", function(data)
			recieveChatMessage(data)
		end)
		
		OnlineState = "Client"
		SettingsMenuLoad()
		end
	else appendChatFeed("<col|orng>You are already online!") end
end

function ServerHost()
	if OnlineState=="" then
		if typeboxes["NameBox"].text then myname = typeboxes["NameBox"].text end
		local myIP = typeboxes["IPBox"].text or "localhost"
		local myPort = tonumber(typeboxes["PortBox"].text) or 22122
		if myname == "" then
			appendChatFeed("<col|orng>Please type a name.<col|whit>")
		else
		appendChatFeed("<col|pink>Hosting Table on port "..myPort)
		love.window.setTitle("LUNO Alpha: Hosting as "..myname)
		server = sock.newServer("*", myPort)
		CreatePlayerTableEntry("host",myname)
		
		-- Called when someone connects to the server
		server:on("connect", function(data, client)
			-- Send a message back to the connected client
			client:send("hello", PlayerTable)
		end)
		
		server:on("playerconnect", function(data, client)
			CreatePlayerTableEntry(client:getConnectId(),data.name)
			server:sendToAll("playerconnected",{Table=PlayerTable,name=data.name, disconnect=false})
			recieveChatMessage(data.name.." has joined the Table!")
		end)
		
		server:on("disconnect", function(data, client)
			UpdatePlayerTable();
			server:sendToAll("playerconnected",{Table=PlayerTable, disconnect=true, TT=TurnTable or {}, TI=TurnIndex or 1})
			recieveChatMessage("A player has left the Table.")
		end)
		
		--Called when a client sends a message
		server:on("ClientChatMessage", function(data, client)
			-- Send a message to all clients, and recieve it ourselves
			server:sendToAll("ChatMessage", data)
			recieveChatMessage(data.text,data.name)
		end)
		
		server:on("PlayerDidSomething", function(data, client) 
			if PlayerAction(data.action, data.card, data.id,client) then
			IterateTurnIndex()
			server:sendToAll("GameplayUpdate", {PT=PlayerTable,TT=TurnTable,DT=discardTop,TI=TurnIndex} )
			UpdateHandLook()
			end
		end)
		
		OnlineState = "Server"
		SettingsMenuLoad()
		end
	else appendChatFeed("<col|orng>You are already online!<col|whit>") end
end

function UpdatePlayerTable()
	if OnlineState == "Server" then
		local ConnectIDSet = {host=true}
		for i,n in pairs(server:getClients()) do ConnectIDSet[n:getConnectId()]=true end
		for i,n in pairs(PlayerTable) do 
		if not ConnectIDSet[i] then PlayerTable[i]=nil; end
		for i,n in pairs(TurnTable) do if not ConnectIDSet[n] then table.remove(TurnTable,i); if TurnIndex>#TurnTable then TurnIndex = 1 end end end 
		end
	else print("attempted to UpdatePlayerTable as Client") end
end

function CallLuno()
	appendChatFeed("<col|pink>GAME: <col|whit>You Called <col|blue>{!lu}<col|pink>{!no}<col|whit>!")
end

function ScrollUp() 
	if MessageFeedScrollDex>1 then MessageFeedScrollDex = MessageFeedScrollDex - 1 end
end

function ScrollDown() 
	if MessageFeedScrollDex<#MessageFeedTable then MessageFeedScrollDex = MessageFeedScrollDex + 1 end
end

function CreatePlayerTableEntry(ConnectID, Name)
	PlayerTable[ConnectID] = {name=Name,hand={},handcount=0,spectating=false}
end

function PlayGame()
	local playerCount = 0
	if OnlineState ~= "Server" then appendChatFeed("<col|pink>You are not the host."); return 
	else
		for i,n in pairs(PlayerTable) do playerCount = playerCount + 1 end
			if playerCount<2 and not debugbuild then appendChatFeed("<col|pink>Please wait for more players."); return
			else StartGame()
			end
	end
	
end

function Blank() end

function love.resize(w, h)
  print(("Window resized to width: %d and height: %d."):format(w, h))
end

function HandScrollU() 
	local myID = WhoAmI()
	local theHandCount = PlayerTable[myID] and PlayerTable[myID].handcount or 9
	if  HandIndex<2 then return
	else HandIndex = HandIndex - 1; UpdateHandLook()
	end
end

function HandScrollD() 
	local myID = WhoAmI()
	local theHandCount = PlayerTable[myID] and PlayerTable[myID].handcount or 9
	if  HandIndex+8>theHandCount then return
	else HandIndex = HandIndex + 1; UpdateHandLook()
	end
end



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

function createCButton(CARD,X,Y,S,ID,FUNC)
	cardstodraw[ID]= {card=CARD, x=X, y=Y, s=S, id=ID, func=FUNC}
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