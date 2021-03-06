local config = {
	removeOnUse = "no",
	usableOnTarget = "yes", -- can be used on target? (fe. healing friend)
	splashable = "no",
	realAnimation = "no", -- make text effect visible only for players in range 1x1
	healthMultiplier = 1.0,
	manaMultiplier = 1.0
}
 
config.removeOnUse = getBooleanFromString(config.removeOnUse)
config.usableOnTarget = getBooleanFromString(config.usableOnTarget)
config.splashable = getBooleanFromString(config.splashable)
config.realAnimation = getBooleanFromString(config.realAnimation)
 
local POTIONS = {
	[8704] = {empty = 7636, splash = 2, health = {50, 100}}, -- small health potion
	[7618] = {empty = 7636, splash = 2, health = {100, 200}}, -- health potion
	[7588] = {empty = 7634, splash = 2, health = {200, 400}, level = 50, vocations = {3, 4, 7, 8}, vocStr = "knights and paladins"}, -- strong health potion
	[7591] = {empty = 7635, splash = 2, health = {500, 600}, level = 80, vocations = {4, 8}, vocStr = "knights"}, -- great health potion
	[8473] = {empty = 7635, splash = 2, health = {700, 750}, level = 130, vocations = {4, 8}, vocStr = "knights"}, -- ultimate health potion
 
	[7620] = {empty = 7636, splash = 7, mana = {70, 130}}, -- mana potion
	[7589] = {empty = 7634, splash = 7, mana = {180, 250}, level = 50, vocations = {1, 2, 3, 5, 6, 7}, vocStr = "sorcerers, druids and paladins"}, -- strong mana potion
	[7590] = {empty = 7635, splash = 7, mana = {350, 380}, level = 80, vocations = {1, 2, 5, 6}, vocStr = "sorcerers and druids"}, -- great mana potion
 
	[8472] = {empty = 7635, splash = 3, health = {200, 400}, mana = {110, 190}, level = 80, vocations = {3, 7}, vocStr = "paladins"} -- great spirit potion
}
 
local exhaust = createConditionObject(CONDITION_EXHAUST)
setConditionParam(exhaust, CONDITION_PARAM_TICKS, (getConfigInfo('timeBetweenExActions') - 100))
 
function onUse(cid, item, fromPosition, itemEx, toPosition)
	local potion = POTIONS[item.itemid]
	if(not potion) then
		return false
	end
 
	if(not isPlayer(itemEx.uid) or (not config.usableOnTarget and cid ~= itemEx.uid)) then
		if(not config.splashable) then
			return false
		end
 
		if(toPosition.x == CONTAINER_POSITION) then
			toPosition = getThingPos(item.uid)
		end
 
		doDecayItem(doCreateItem(2016, potion.splash, toPosition))
		doTransformItem(item.uid, potion.empty)
		return true
	end
 
	if(hasCondition(cid, CONDITION_EXHAUST_HEAL)) then
		doPlayerSendDefaultCancel(cid, RETURNVALUE_YOUAREEXHAUSTED)
		return true
	end
 
	if(((potion.level and getPlayerLevel(cid) < potion.level) or (potion.vocations and not isInArray(potion.vocations, getPlayerVocation(cid)))) and
		not getPlayerCustomFlagValue(cid, PLAYERCUSTOMFLAG_GAMEMASTERPRIVILEGES))
	then
		doCreatureSay(itemEx.uid, "Only " .. potion.vocStr .. (potion.level and (" of level " .. potion.level) or "") .. " or above may drink this fluid.", TALKTYPE_ORANGE_1)
		return true
	end
 
	local health = potion.health
	if(health and not doCreatureAddHealth(itemEx.uid, math.ceil(math.random(health[1], health[2]) * config.healthMultiplier))) then
		return false
	end
 
	local mana = potion.mana
	if(mana and not doPlayerAddMana(itemEx.uid, math.ceil(math.random(mana[1], mana[2]) * config.manaMultiplier))) then
		return false
	end
 
	doSendMagicEffect(getThingPos(itemEx.uid), CONST_ME_MAGIC_BLUE)
	if(not realAnimation) then
		doCreatureSay(itemEx.uid, "Aaaah...", TALKTYPE_ORANGE_1)
	else
		for i, tid in ipairs(getSpectators(getCreaturePosition(cid), 1, 1)) do
			if(isPlayer(tid)) then
				doCreatureSay(itemEx.uid, "Aaaah...", TALKTYPE_ORANGE_1, false, tid)
			end
		end
	end
 
	doAddCondition(cid, exhaust)
 
	local v = getItemParent(item.uid)
	if(not potion.empty or config.removeOnUse) then
		return true
	end
 
	if fromPosition.x == CONTAINER_POSITION then
		for _, slot in ipairs({CONST_SLOT_LEFT, CONST_SLOT_RIGHT, CONST_SLOT_AMMO}) do
			local tmp = getPlayerSlotItem(cid, slot)
			if tmp.itemid == potion.empty and tmp.type < 100 then
				doChangeTypeItem(item.uid, item.type - 1)
				return getPlayerFreeCap(cid) >= getItemInfo(potion.empty).weight and doChangeTypeItem(tmp.uid, tmp.type + 1) or doPlayerAddItem(cid, potion.empty, 1)
			end
		end
	else
		doChangeTypeItem(item.uid, item.type - 1)
		doCreateItem(potion.empty, 1, fromPosition)
		return true
	end
 
	if v.uid == 0 then
		if item.type == 1 and isInArray({CONST_SLOT_LEFT, CONST_SLOT_RIGHT, CONST_SLOT_AMMO}, fromPosition.y) then
			doTransformItem(item.uid, potion.empty)
		else
			-- serversided autostack should take care of this
			doPlayerAddItem(cid, potion.empty, 1)
			doChangeTypeItem(item.uid, item.type - 1)
		end
		return true
	else
		doChangeTypeItem(item.uid, item.type - 1)
		local size = getContainerSize(v.uid)
		for i = 0, size-1 do
			local tmp = getContainerItem(v.uid, i)
			if tmp.itemid == potion.empty and tmp.type < 100 then
				return getPlayerFreeCap(cid) >= getItemInfo(potion.empty).weight and doChangeTypeItem(tmp.uid, tmp.type + 1) or doPlayerAddItem(cid, potion.empty, 1)
			end
		end
 
		if getContainerSize(v.uid) < getContainerCap(v.uid) then
			doAddContainerItem(v.uid, potion.empty)
		else
			doPlayerAddItem(cid, potion.empty, 1)
		end
	end
	return true
end
