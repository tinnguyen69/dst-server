local require = GLOBAL.require
local TheInput = GLOBAL.TheInput
local ThePlayer = GLOBAL.ThePlayer
local IsServer = GLOBAL.TheNet:GetIsServer()
local Inv = require "widgets/inventorybar"

Assets =
{
    Asset("IMAGE", "images/back.tex"),
    Asset("ATLAS", "images/back.xml"),
    Asset("IMAGE", "images/neck.tex"),
    Asset("ATLAS", "images/neck.xml"),
}
-- for key,value in pairs(GLOBAL.EQUIPSLOTS) do print('4r',key,value) end

GLOBAL.EQUIPSLOTS=
{
    HANDS = "hands",
    HEAD = "head",
    BODY = "body",
    BACK = "back",
    NECK = "neck",
}
GLOBAL.EQUIPSLOT_IDS = {}
local slot = 0
for k, v in pairs(GLOBAL.EQUIPSLOTS) do
    slot = slot + 1
    GLOBAL.EQUIPSLOT_IDS[v] = slot
end
slot = nil

AddComponentPostInit("resurrectable", function(self, inst)
    local original_FindClosestResurrector = self.FindClosestResurrector
    local original_CanResurrect = self.CanResurrect
    local original_DoResurrect = self.DoResurrect

    self.FindClosestResurrector = function(self)
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                return item
            end
        end
        original_FindClosestResurrector(self)
    end

    self.CanResurrect = function(self)
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                return true
            end
        end
        original_CanResurrect(self)
    end

    self.DoResurrect = function(self)
        self.inst:PushEvent("resurrect")
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                self.inst.sg:GoToState("amulet_rebirth")
                return true
            end
        end
        original_DoResurrect(self)
    end
end)

AddComponentPostInit("inventory", function(self, inst)
    local original_Equip = self.Equip
    self.Equip = function(self, item, old_to_active)
        if original_Equip(self, item, old_to_active) and item and item.components and item.components.equippable then
            local eslot = item.components.equippable.equipslot
            if self.equipslots[eslot] ~= item then
                if eslot == GLOBAL.EQUIPSLOTS.BACK and item.components.container ~= nil then
                    self.inst:PushEvent("setoverflow", { overflow = item })
                end
            end
            return true
        else
            return
        end
    end

    self.GetOverflowContainer = function()
        if self.ignoreoverflow then
            return
        end
        local item = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.BACK)
        return item ~= nil and item.components.container or nil
    end
end)

AddGlobalClassPostConstruct("widgets/inventorybar", "Inv", function()
    local Inv_Refresh_base = Inv.Refresh or function() return "" end
    local Inv_Rebuild_base = Inv.Rebuild or function() return "" end

    function Inv:LoadExtraSlots(self)
        self.bg:SetScale(1.35,1,1.25)
        self.bgcover:SetScale(1.35,1,1.25)

        if self.addextraslots == nil then
            self.addextraslots = 1

            self:AddEquipSlot(GLOBAL.EQUIPSLOTS.BACK, "images/back.xml", "back.tex")
            self:AddEquipSlot(GLOBAL.EQUIPSLOTS.NECK, "images/neck.xml", "neck.tex")
        -- else
            -- GLOBAL.GetPlayer().HUD.controls.stickyrecipepopup:Refresh()

            if self.inspectcontrol then
                local W = 68
                local SEP = 12
                local INTERSEP = 28
                local inventory = self.owner.replica.inventory
                local num_slots = inventory:GetNumSlots()
                local num_equip = #self.equipslotinfo
                local num_buttons = self.controller_build and 0 or 1
                local num_slotintersep = math.ceil(num_slots / 5)
                local num_equipintersep = num_buttons > 0 and 1 or 0
                local total_w = (num_slots + num_equip + num_buttons) * W + (num_slots + num_equip + num_buttons - num_slotintersep - num_equipintersep - 1) * SEP + (num_slotintersep + num_equipintersep) * INTERSEP
            	self.inspectcontrol.icon:SetPosition(-4, 6)
            	self.inspectcontrol:SetPosition((total_w - W) * .5 + 3, -6, 0)
            end
        end

        --if not self.controller_build then
        --    self.bg:SetScale(1.22, 1, 1)
        --    self.bgcover:SetScale(1.22, 1, 1)

        --    self.inspectcontrol = self.root:AddChild(TEMPLATES.IconButton(atlas_name, image_name, STRINGS.UI.HUD.INSPECT_SELF, false, false, function() self.owner.HUD:InspectSelf() end, {size = 40}, "self_inspect_mod.tex"))
        --    self.inspectcontrol.icon:SetScale(.7)
        --    self.inspectcontrol.icon:SetPosition(-4, 6)
        --    self.inspectcontrol:SetScale(1.25)
        --    self.inspectcontrol:SetPosition((total_w - W) * .5 + 3, -6, 0)
        --else
        --    self.bg:SetScale(1.15, 1, 1)
        --    self.bgcover:SetScale(1.15, 1, 1)

        --    if self.inspectcontrol ~= nil then
        --        self.inspectcontrol:Kill()
        --        self.inspectcontrol = nil
        --    end
        --end
    end

    function Inv:Refresh()
        Inv_Refresh_base(self)
        Inv:LoadExtraSlots(self)
    end

    function Inv:Rebuild()
        Inv_Rebuild_base(self)
        Inv:LoadExtraSlots(self)
    end
end)

AddPrefabPostInit("inventory_classified", function(inst)
    function GetOverflowContainer(inst)
        local item = inst.GetEquippedItem(inst, GLOBAL.EQUIPSLOTS.BACK)
        return item ~= nil and item.replica.container or nil
    end

    function Count(item)
        return item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
    end

    function Has(inst, prefab, amount)
        local count =
            inst._activeitem ~= nil and
            inst._activeitem.prefab == prefab and
            Count(inst._activeitem) or 0

        if inst._itemspreview ~= nil then
            for i, v in ipairs(inst._items) do
                local item = inst._itemspreview[i]
                if item ~= nil and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        else
            for i, v in ipairs(inst._items) do
                local item = v:value()
                if item ~= nil and item ~= inst._activeitem and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        end

        local overflow = GetOverflowContainer(inst)
        if overflow ~= nil then
            local overflowhas, overflowcount = overflow:Has(prefab, amount)
            count = count + overflowcount
        end

        return count >= amount, count
    end

    -- function IsBusy(inst)
    --     return inst._busy or inst._parent == nil
    -- end

    -- local PushItemGet = inst.PushItemGet
    -- local PushStackSize = inst.PushStackSize
    -- local ConsumeByName = inst.ConsumeByName

    -- function UseItemFromInvTile(inst, item)
    --     if not IsBusy(inst) and
    --         inst._parent ~= nil and
    --         inst._parent.components.playeractionpicker ~= nil and
    --         inst._parent.components.playercontroller ~= nil then
    --         local actions = inst._activeitem ~= nil and
    --             inst._parent.components.playeractionpicker:GetUseItemActions(item, inst._activeitem, true) or
    --             inst._parent.components.playeractionpicker:GetInventoryActions(item)
    --         if #actions > 0 then
    --             if actions[1].action == GLOBAL.ACTIONS.RUMMAGE then
    --                 local overflow = GetOverflowContainer(inst)
    --                 if overflow ~= nil and overflow.inst == item then
    --                     if overflow:IsOpenedBy(inst._parent) then
    --                         overflow:Close()
    --                     else
    --                         overflow:Open(inst._parent)
    --                     end
    --                     return
    --                 end
    --             end
    --             inst._parent.components.playercontroller:RemoteUseItemFromInvTile(actions[1], item)
    --         end
    --     end
    -- end

    -- function ReceiveItem(inst, item, count)
    --     if IsBusy(inst) then
    --         return
    --     end
    --     local overflow = GetOverflowContainer(inst)
    --     overflow = overflow and overflow.classified or nil
    --     if overflow ~= nil and overflow:IsBusy() then
    --         return
    --     end
    --     local isstackable = item.replica.stackable ~= nil
    --     local originalstacksize = isstackable and item.replica.stackable:StackSize() or 1
    --     if not isstackable or inst._parent.replica.inventory == nil or not inst._parent.replica.inventory:AcceptsStacks() then
    --         for i, v in ipairs(inst._items) do
    --             if v:value() == nil then
    --                 local giveitem = SlotItem(item, i)
    --                 PushItemGet(inst, giveitem)
    --                 if originalstacksize > 1 then
    --                     PushStackSize(inst, item, nil, nil, 1, false, true)
    --                     return originalstacksize - 1
    --                 else
    --                     return 0
    --                 end
    --             end
    --         end
    --         if overflow ~= nil then
    --             return overflow:ReceiveItem(item, count)
    --         end
    --     else
    --         local originalcount = count and math.min(count, originalstacksize) or originalstacksize
    --         count = originalcount
    --         if item.replica.equippable ~= nil then
    --             local eslot = item.replica.equippable:EquipSlot()
    --             local equip = inst:GetEquippedItem(eslot)
    --             if equip ~= nil and
    --                 equip.prefab == item.prefab and
    --                 equip.replica.stackable ~= nil and
    --                 not equip.replica.stackable:IsFull() then
    --                 local stacksize = equip.replica.stackable:StackSize() + count
    --                 local maxsize = equip.replica.stackable:MaxSize()
    --                 if stacksize > maxsize then
    --                     count = math.max(stacksize - maxsize, 0)
    --                     stacksize = maxsize
    --                 else
    --                     count = 0
    --                 end
    --                 PushStackSize(inst, equip, stacksize, true, nil, nil, nil, SlotEquip(equip, eslot))
    --             end
    --         end
    --         if count > 0 then
    --             local emptyslot = nil
    --             for i, v in ipairs(inst._items) do
    --                 local slotitem = v:value()
    --                 if slotitem == nil then
    --                     if emptyslot == nil then
    --                         emptyslot = i
    --                     end
    --                 elseif slotitem.prefab == item.prefab and
    --                     slotitem.replica.stackable ~= nil and
    --                     not slotitem.replica.stackable:IsFull() then
    --                     local stacksize = slotitem.replica.stackable:StackSize() + count
    --                     local maxsize = slotitem.replica.stackable:MaxSize()
    --                     if stacksize > maxsize then
    --                         count = math.max(stacksize - maxsize, 0)
    --                         stacksize = maxsize
    --                     else
    --                         count = 0
    --                     end
    --                     PushStackSize(inst, slotitem, stacksize, true, nil, nil, nil, SlotItem(slotitem, i))
    --                     if count <= 0 then
    --                         break
    --                     end
    --                 end
    --             end
    --             if count > 0 then
    --                 if emptyslot ~= nil then
    --                     local giveitem = SlotItem(item, emptyslot)
    --                     PushItemGet(inst, giveitem)
    --                     if count ~= originalstacksize then
    --                         PushStackSize(inst, item, nil, nil, count, false, true)
    --                     end
    --                     count = 0
    --                 elseif overflow ~= nil then
    --                     local remainder = overflow:ReceiveItem(item, count)
    --                     if remainder ~= nil then
    --                         count = math.max(count - (originalstacksize - remainder), 0)
    --                     end
    --                 end
    --             end
    --         end
    --         if count ~= originalcount then
    --             return originalstacksize - (originalcount - count)
    --         end
    --     end
    -- end

    -- function RemoveIngredients(inst, recipe, ingredientmod)
    --     if IsBusy(inst) then
    --         return false
    --     end
    --     local overflow = GetOverflowContainer(inst)
    --     overflow = overflow and overflow.classified or nil
    --     if overflow ~= nil and overflow:IsBusy() then
    --         return false
    --     end
    --     for i, v in ipairs(recipe.ingredients) do
    --         local amt = math.max(1, GLOBAL.RoundBiasedUp(v.amount * ingredientmod))
    --         inst.ConsumeByName(inst, v.type, amt, overflow)
    --     end
    --     return true
    -- end

    if not IsServer then
        inst.GetOverflowContainer = GetOverflowContainer
        inst.Has = Has
        -- inst.UseItemFromInvTile = UseItemFromInvTile
        -- inst.ReceiveItem = ReceiveItem
        -- inst.RemoveIngredients = RemoveIngredients
    end
end)

AddStategraphPostInit("wilson", function(self)
    for key,value in pairs(self.states) do
        if value.name == 'amulet_rebirth' then
            local original_amulet_rebirth_onexit = self.states[key].onexit


            self.states[key].onexit = function(inst)
                local item = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
                if item and item.prefab == "amulet" then
                    item = inst.components.inventory:RemoveItem(item)
                    if item then
                        item:Remove()
                        item.persists = false
                    end
                end
                original_amulet_rebirth_onexit(inst)
            end
        end
    end
end)

function backpackpostinit(inst)
    if IsServer then
        inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.BACK or GLOBAL.EQUIPSLOTS.BODY
    end
end

function amuletpostinit(inst)
    if IsServer then
        inst.components.equippable.equipslot = GLOBAL.EQUIPSLOTS.NECK or GLOBAL.EQUIPSLOTS.BODY
    end
end


AddPrefabPostInit("amulet", amuletpostinit)
AddPrefabPostInit("blueamulet", amuletpostinit)
AddPrefabPostInit("purpleamulet", amuletpostinit)
AddPrefabPostInit("orangeamulet", amuletpostinit)
AddPrefabPostInit("greenamulet", amuletpostinit)
AddPrefabPostInit("yellowamulet", amuletpostinit)

AddPrefabPostInit("backpack", backpackpostinit)
AddPrefabPostInit("krampus_sack", backpackpostinit)
AddPrefabPostInit("piggyback", backpackpostinit)
AddPrefabPostInit("icepack", backpackpostinit)
