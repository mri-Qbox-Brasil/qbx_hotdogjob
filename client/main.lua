local QBCore = exports['qbx-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local HotdogBlip = nil
local IsWorking = false
local StandObject = nil
local IsPushing = false
local IsUIActive = false
local PreparingFood = false
local zoneMade = false
local SpatelObject = nil
local SellingData = {
    Enabled = false,
    Target = nil,
    HasTarget = false,
    RecentPeds = {},
    Hotdog = nil,
}
local OffsetData = {
    x = 0.0,
    y = -0.8,
    z = 1.0,
    Distance = 2
}

local AnimationData = {
    lib = "missfinale_c2ig_11",
    anim = "pushcar_offcliff_f",
}

local DetachKeys = {157, 158, 160, 164, 165, 73, 36, 44}

-- Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if StandObject ~= nil then
            DeleteObject(StandObject)
            ClearPedTasksImmediately(cache.ped)
        end
    end
end)

-- Local Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function LoadAnim(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(1)
    end
end

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(1)
    end
end

local function UpdateBlip()
    if PlayerData.job.name == 'hotdog' then
        CreateThread(function()
            local coords = Config.Locations["take"].coords

            if HotdogBlip ~= nil then
                RemoveBlip(HotdogBlip)
            end

            HotdogBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

            SetBlipSprite(HotdogBlip, 542)
            SetBlipDisplay(HotdogBlip, 4)
            SetBlipScale(HotdogBlip, 0.6)
            SetBlipAsShortRange(HotdogBlip, true)
            SetBlipColour(HotdogBlip, 17)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Lang:t("info.blip_name"))
            EndTextCommandSetBlipName(HotdogBlip)
        end)
    else
        if HotdogBlip then
            RemoveBlip(HotdogBlip)
        end
    end
end

local function GetAvailableHotdog()
    local retval = nil
    local AvailableHotdogs = {}
    for k, v in pairs(Config.Stock) do
        if v.Current > 0 then
            AvailableHotdogs[#AvailableHotdogs+1] = {
                key = k,
                value = v,
            }
        end
    end
    if next(AvailableHotdogs) ~= nil then
        local Random = math.random(1, #AvailableHotdogs)
        retval = AvailableHotdogs[Random].key
    end
    return retval
end

local function UpdateLevel()
    local MyRep = PlayerData.metadata["jobrep"]["hotdog"]

    if MyRep ~= nil then
        if MyRep >= 1 and MyRep < 50 then
            Config.MyLevel = 1
        elseif MyRep >= 50 and MyRep < 100 then
            Config.MyLevel = 2
        elseif MyRep >= 100 and MyRep < 200 then
            Config.MyLevel = 3
        elseif MyRep >= 100 and MyRep < 200 then
            Config.MyLevel = 3
        elseif MyRep >= 200 then
            Config.MyLevel = 4
        end
    else
        Config.MyLevel = 1
    end

    local ReturnData = {
        lvl = Config.MyLevel,
        rep = MyRep
    }

    return ReturnData
end

local function UpdateUI()
    IsUIActive = true
    CreateThread(function()
        while true do
            SendNUIMessage({
                action = "UpdateUI",
                IsActive = IsUIActive,
                Stock = Config.Stock,
                Level = UpdateLevel()
            })
            if not IsUIActive then
                break
            end
            Wait(1000)
        end
    end)
end

local function LetKraamLose()
    DetachEntity(StandObject, false, false)
    SetEntityCollision(StandObject, true, true)
    ClearPedTasks(cache.ped)
    IsPushing = false
    lib.hideTextUI()
end

if Config.UseTarget then
    RegisterCommand('letgostand', function()
        if IsPushing then
            LetKraamLose()
        end
    end, false)
    RegisterKeyMapping('letgostand',Lang:t("keymapping.gkey"), 'keyboard', 'G')
end

local function CheckLoop()
    CreateThread(function()
        while true do
            if IsWorking then
                if IsPushing then
                    for _, PressedKey in pairs(DetachKeys) do
                        if IsControlJustPressed(0, PressedKey) or IsDisabledControlJustPressed(0, PressedKey) then
                            LetKraamLose()
                        end
                    end

                    if IsPedShooting(cache.ped) or IsPlayerFreeAiming(cache.ped) or IsPedInMeleeCombat(cache.ped) then
                        LetKraamLose()
                    end

                    if IsPedDeadOrDying(cache.ped, false) then
                        LetKraamLose()
                    end

                    if IsPedRagdoll(cache.ped) then
                        LetKraamLose()
                    end
                else
                    Wait(1000)
                end
            else
                break
            end
            Wait(0)
        end
    end)
end

local function AnimLoop()
    CreateThread(function()
        while true do
            if IsPushing then
                if not IsEntityPlayingAnim(cache.ped, AnimationData.lib, AnimationData.anim, 3) then
                    LoadAnim(AnimationData.lib)
                    TaskPlayAnim(cache.ped, AnimationData.lib, AnimationData.anim, 8.0, 8.0, -1, 50, 0, false, false, false)
                end
            else
                break
            end
            Wait(1000)
        end
    end)
end

local function PreparingAnimCheck()
    PreparingFood = true
    CreateThread(function()
        while true do
            if PreparingFood then
                if not IsEntityPlayingAnim(cache.ped, 'amb@prop_human_bbq@male@idle_a', 'idle_b', 3) then
                    LoadAnim('amb@prop_human_bbq@male@idle_a')
                    TaskPlayAnim(cache.ped, 'amb@prop_human_bbq@male@idle_a', 'idle_b', 6.0, -6.0, -1, 49, 0, false, false, false)
                end
            else
                DetachEntity(SpatelObject, false, false)
                DeleteEntity(SpatelObject)
                ClearPedTasksImmediately(cache.ped)
                break
            end

            Wait(200)
        end
    end)
end

local function PrepareAnim()
    LoadAnim('amb@prop_human_bbq@male@idle_a')
    TaskPlayAnim(cache.ped, 'amb@prop_human_bbq@male@idle_a', 'idle_b', 6.0, -6.0, -1, 47, 0, false, false, false)
    SpatelObject = CreateObject(`prop_fish_slice_01`, 0, 0, 0, true, true, true)
    AttachEntityToEntity(SpatelObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.08, 0.0, -0.02, 0.0, -25.0, 130.0, true, true, false, true, 1, true)
    PreparingAnimCheck()
end

local function TakeHotdogStand()
    IsPushing = true
    NetworkRequestControlOfEntity(StandObject)
    LoadAnim(AnimationData.lib)
    TaskPlayAnim(cache.ped, AnimationData.lib, AnimationData.anim, 8.0, 8.0, -1, 50, 0, false, false, false)
    SetTimeout(150, function()
        AttachEntityToEntity(StandObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), -0.45, -1.2, -0.82, 180.0, 180.0, 270.0, false, false, false, false, 1, true)
    end)
    FreezeEntityPosition(StandObject, false)
    AnimLoop()
end

local function FinishMinigame(faults)
    local Quality = "common"
    if faults == 0 then
        Quality = "exotic"
    elseif faults == 1 then
        Quality = "rare"
    end
    if Config.Stock[Quality].Current + 1 <= Config.Stock[Quality].Max[Config.MyLevel] then
        TriggerServerEvent('qb-hotdogjob:server:UpdateReputation', Quality)
        if Config.MyLevel == 1 then
            QBCore.Functions.Notify(Lang:t("success.made_hotdog", {value = Config.Stock[Quality].Label}), "success")
            Config.Stock[Quality].Current = Config.Stock[Quality].Current + 1
        else
            local Luck = math.random(1, 2)
            local LuckyNumber = math.random(1, 2)
            local LuckyAmount = math.random(1, Config.MyLevel)
            if Luck == LuckyNumber then
                QBCore.Functions.Notify(Lang:t("success.made_luck_hotdog", {value = LuckyAmount, value2 = Config.Stock[Quality].Label}), "success")
                Config.Stock[Quality].Current = Config.Stock[Quality].Current + LuckyAmount
            else
                QBCore.Functions.Notify(Lang:t("success.made_hotdog", {value = Config.Stock[Quality].Label}), "success")
                Config.Stock[Quality].Current = Config.Stock[Quality].Current + 1
            end
        end
    else
        QBCore.Functions.Notify(Lang:t("error.no_more", {value = Config.Stock[Quality].Label}), "error")
    end
    PreparingFood = false
end

local function StartHotdogMinigame()
    PrepareAnim()
    TriggerEvent('qb-keyminigame:show')
    TriggerEvent('qb-keyminigame:start', FinishMinigame)
end

local function HotdogLoop()
    CreateThread(function()
        while true do
            local PlayerPos = GetEntityCoords(cache.ped)
            local ClosestObject = GetClosestObjectOfType(PlayerPos.x, PlayerPos.y, PlayerPos.z, 3.0, `prop_hotdogstand_01`, false, false, false)

            if StandObject ~= nil then
                if ClosestObject ~= nil and ClosestObject == StandObject then
                    local ObjectOffset = GetOffsetFromEntityInWorldCoords(ClosestObject, 1.0, 0.0, 1.0)
                    local ObjectDistance = #(PlayerPos - vector3(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z))

                    if ObjectDistance < 1.0 then
                        if not IsPushing then
                            DrawText3Ds(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z, Lang:t("info.grab_stall"))
                            if IsControlJustPressed(0, 47) then
                                if SellingData.Enabled then
                                    if SellingData.Target ~= nil then
                                        SetPedKeepTask(SellingData.Target, false)
                                        SetEntityAsNoLongerNeeded(SellingData.Target)
                                        ClearPedTasksImmediately(SellingData.Target)
                                        FreezeEntityPosition(cache.ped, false)
                                    end
                                    SellingData.Enabled = false
                                    SellingData.Target = nil
                                    SellingData.HasTarget = false
                                    TakeHotdogStand()
                                else
                                    TakeHotdogStand()
                                end
                            end
                        else
                            DrawText3Ds(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z, Lang:t("info.drop_stall"))
                            if IsControlJustPressed(0, 47) then
                                LetKraamLose()
                            end
                        end
                    elseif ObjectDistance < 3.0 then
                        DrawText3Ds(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z, Lang:t("info.grab"))
                    end
                end
            else
                break
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while true do
            Wait(0)
            if IsPushing then
                DisableControlAction(0, 244, true) -- m
                DisableControlAction(0, 23, true) -- f
            end
        end
    end)

    CreateThread(function()
        while true do
            local PlayerPos = GetEntityCoords(cache.ped)
            local ClosestObject = GetClosestObjectOfType(PlayerPos.x, PlayerPos.y, PlayerPos.z, 3.0, `prop_hotdogstand_01`, false, false, false)

            if StandObject ~= nil then
                if ClosestObject ~= nil and ClosestObject == StandObject then
                    local ObjectOffset = GetOffsetFromEntityInWorldCoords(StandObject, 0.0, 0.0, 1.0)
                    local ObjectDistance = #(PlayerPos - vector3(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z))

                    if ObjectDistance < 1.0 then
                        if SellingData.Enabled then
                            DrawText3Ds(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z, Lang:t("info.selling_prep"))
                        else
                            DrawText3Ds(ObjectOffset.x, ObjectOffset.y, ObjectOffset.z, Lang:t("info.not_selling"))
                        end

                        if IsControlJustPressed(0, 38) then
                            StartHotdogMinigame()
                        end
                    end
                end
            else
                break
            end

            Wait(0)
        end
    end)
end

local function StartWorking()
    local HasMoney = lib.callback.await('qb-hotdogjob:server:HasMoney', false)
    if HasMoney then
        if Config.UseTarget then
            local SpawnCoords = Config.Locations["spawn"].coords
            IsWorking = true
            LoadModel("prop_hotdogstand_01")
            StandObject = CreateObject(`prop_hotdogstand_01`, SpawnCoords.x, SpawnCoords.y, SpawnCoords.z, true, true, false)
            PlaceObjectOnGroundProperly(StandObject)
            SetEntityHeading(StandObject, SpawnCoords.w - 90)
            FreezeEntityPosition(StandObject, true)
            exports['qb-target']:AddTargetEntity(StandObject, {
                options = {
                    {
                        icon = "fas fa-hand",
                        label = Lang:t('info.grab'),
                        canInteract = function()
                            return IsWorking
                        end,
                        action = function()
                            if not IsPushing then
                                if SellingData.Enabled then
                                    if SellingData.Target ~= nil then
                                        SetPedKeepTask(SellingData.Target, false)
                                        SetEntityAsNoLongerNeeded(SellingData.Target)
                                        ClearPedTasksImmediately(SellingData.Target)
                                        FreezeEntityPosition(cache.ped, false)
                                    end
                                    SellingData.Enabled = false
                                    SellingData.Target = nil
                                    SellingData.HasTarget = false
                                    TakeHotdogStand()
                                    lib.showTextUI(Lang:t('info.drop_stall'))
                                else
                                    TakeHotdogStand()
                                    lib.showTextUI(Lang:t('info.drop_stall'))
                                end
                            else
                                LetKraamLose()
                            end
                        end
                    }, {
                        icon = "fas fa-hotdog",
                        label = Lang:t('info.prepare'),
                        canInteract = function()
                            return IsWorking
                        end,
                        action = function()
                            if not IsPushing then
                                StartHotdogMinigame()
                            end
                        end
                    }, {
                        icon = "fas fa-hand-holding-usd",
                        label = Lang:t('info.toggle_sell'),
                        type = 'client',
                        event = 'qb-hotdogjob:client:ToggleSell',
                        canInteract = function()
                            return IsWorking
                        end
                    }
                },
                distance = 3.0
            })
            UpdateUI()
            QBCore.Functions.Notify(Lang:t("success.deposit", {deposit = Config.StandDeposit}), 'success')
        else
            local SpawnCoords = Config.Locations["spawn"].coords
            IsWorking = true
            LoadModel("prop_hotdogstand_01")
            StandObject = CreateObject(`prop_hotdogstand_01`, SpawnCoords.x, SpawnCoords.y, SpawnCoords.z, true, true, false)
            PlaceObjectOnGroundProperly(StandObject)
            SetEntityHeading(StandObject, SpawnCoords.w - 90)
            FreezeEntityPosition(StandObject, true)
            HotdogLoop()
            UpdateUI()
            CheckLoop()
            QBCore.Functions.Notify(Lang:t("success.deposit", {deposit = Config.StandDeposit}), 'success')
        end
    else
        QBCore.Functions.Notify(Lang:t("error.no_money"), 'error')
    end
end

local function StopWorking()
    if DoesEntityExist(StandObject) then
        local DidBail = lib.callback.await('qb-hotdogjob:server:BringBack', false)
        if DidBail then
            DeleteObject(StandObject)
            ClearPedTasksImmediately(cache.ped)
            IsWorking = false
            StandObject = nil
            IsPushing = false
            IsUIActive = false

            for _, v in pairs(Config.Stock) do
                v.Current = 0
            end
            QBCore.Functions.Notify(Lang:t("success.deposit_returned", {deposit = Config.StandDeposit}), 'success')
        else
            QBCore.Functions.Notify(Lang:t("error.deposit_notreturned"), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t("error.no_stand_found"), 'error')
        IsWorking = false
        StandObject = nil
        IsPushing = false
        IsUIActive = false

        for _, v in pairs(Config.Stock) do
            v.Current = 0
        end
    end
end

local function SellToPed(ped)
    SellingData.HasTarget = true

    if SellingData.RecentPeds ~= nil then
        for i = 1, #SellingData.RecentPeds, 1 do
            if SellingData.RecentPeds[i] == ped then
                SellingData.HasTarget = false
                return
            end
        end
    end

    SetEntityAsNoLongerNeeded(ped)
    ClearPedTasks(ped)

    local SellingPrice
    local HotdogsForSale

    SellingData.Hotdog = GetAvailableHotdog()

    if SellingData.Hotdog ~= nil then
        if Config.Stock[SellingData.Hotdog].Current > 1 then
            if Config.Stock[SellingData.Hotdog].Current >= 3 then
                HotdogsForSale = math.random(1, 3)
            else
                HotdogsForSale = math.random(1, Config.Stock[SellingData.Hotdog].Current)
            end
        elseif Config.Stock[SellingData.Hotdog].Current == 1 then
            HotdogsForSale = 1
        end

        if SellingData.Hotdog ~= nil then
            SellingPrice = math.random(Config.Stock[SellingData.Hotdog].Price[Config.MyLevel].min, Config.Stock[SellingData.Hotdog].Price[Config.MyLevel].max)
        end
    end

    local coords = GetOffsetFromEntityInWorldCoords(StandObject, OffsetData.x, OffsetData.y, OffsetData.z)
    local pedCoords = GetEntityCoords(ped)
    local pedDist = #(coords - pedCoords)
    local PlayerDist

    TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, 1.2, -1, 0.0, 0.0)

    while pedDist > OffsetData.Distance do
        local playercoords = GetEntityCoords(cache.ped)
        coords = GetOffsetFromEntityInWorldCoords(StandObject, OffsetData.x, OffsetData.y, OffsetData.z)
        PlayerDist = #(playercoords - coords)
        pedCoords = GetEntityCoords(ped)
        TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, 1.2, -1, 0.0, 0.0)
        pedDist = #(coords - pedCoords)
        if PlayerDist > 10.0 then
            SellingData.HasTarget = false
            SetPedKeepTask(ped, false)
            SetEntityAsNoLongerNeeded(ped)
            ClearPedTasksImmediately(ped)
            SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
            SellingData.Enabled = false
            SellingData.Target = nil
            SellingData.HasTarget = false
            SellingData.Hotdog = nil
            QBCore.Functions.Notify(Lang:t("error.too_far"), 'error')
            break
        end
        Wait(100)
    end

    FreezeEntityPosition(ped, true)
    TaskLookAtEntity(ped, cache.ped, 5500.0, 2048, 3)
    TaskTurnPedToFaceEntity(ped, cache.ped, 5500)
    local heading = (GetEntityHeading(cache.ped) + 180)
    SetEntityHeading(ped, heading)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT", 0, false)
    SellingData.Target = ped

    while pedDist < OffsetData.Distance and SellingData.HasTarget do
        local playercoords = GetEntityCoords(cache.ped)
        coords = GetOffsetFromEntityInWorldCoords(StandObject, OffsetData.x, OffsetData.y, OffsetData.z)
        PlayerDist = #(playercoords - coords)
        pedCoords = GetEntityCoords(ped)
        pedDist = #(coords - pedCoords)

        if PlayerDist < 4 then
            if SellingData.Hotdog ~= nil then
                if HotdogsForSale == 0 and SellingPrice == 0 then
                    if Config.Stock[SellingData.Hotdog].Current > 1 then
                        if Config.Stock[SellingData.Hotdog].Current >= 3 then
                            HotdogsForSale = math.random(1, 3)
                        else
                            HotdogsForSale = math.random(1, Config.Stock[SellingData.Hotdog].Current)
                        end
                    elseif Config.Stock[SellingData.Hotdog].Current == 1 then
                        HotdogsForSale = 1
                    end

                    if SellingData.Hotdog ~= nil then
                        SellingPrice = math.random(Config.Stock[SellingData.Hotdog].Price.min, Config.Stock[SellingData.Hotdog].Price.max)
                    end
                end

                if Config.UseTarget then
                    if not zoneMade then
                        zoneMade = true
                        local targetPed = NetworkGetNetworkIdFromEntity(ped)
                        local optionNames = { 'startSelling', 'declineOffer' }
                        local options = {
                            {
                                name = 'startSelling',
                                icon = 'fas fa-hand-holding-dollar',
                                label = Lang:t("info.sell_dogs_target", {value = HotdogsForSale, value2 = (HotdogsForSale * SellingPrice)}),
                                onSelect = function()
                                    QBCore.Functions.Notify(Lang:t("success.sold_hotdogs", {value = HotdogsForSale, value2 = (HotdogsForSale * SellingPrice)}), 'success')
                                    TriggerServerEvent('qb-hotdogjob:server:Sell', pedCoords, HotdogsForSale, SellingPrice)
                                    SellingData.HasTarget = false
                                    LoadAnim('mp_common')
                                    TaskPlayAnim(cache.ped, 'mp_common', 'givetake1_b', 8.0, 8.0, 1100, 48, 0.0, false, false, false)
                                    FreezeEntityPosition(ped, false)
                                    SetPedKeepTask(ped, false)
                                    SetEntityAsNoLongerNeeded(ped)
                                    ClearPedTasksImmediately(ped)
                                    SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
                                    Config.Stock[SellingData.Hotdog].Current = Config.Stock[SellingData.Hotdog].Current - HotdogsForSale
                                    SellingData.Hotdog = nil
                                    exports.ox_target:removeEntity(targetPed, optionNames)
                                    zoneMade = false
                                end,
                            },
                            {
                                name = 'declineOffer',
                                icon = 'fas fa-x',
                                label = Lang:t("info.decline_offer"),
                                onSelect = function()
                                    QBCore.Functions.Notify(Lang:t("error.cust_refused"), 'error')
                                    SellingData.HasTarget = false
                                    FreezeEntityPosition(ped, false)
                                    SetPedKeepTask(ped, false)
                                    SetEntityAsNoLongerNeeded(ped)
                                    ClearPedTasksImmediately(ped)
                                    SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
                                    SellingData.Hotdog = nil
                                    exports.ox_target:removeEntity(targetPed, optionNames)
                                    zoneMade = false
                                end,
                            },
                        }
                        exports.ox_target:addEntity(targetPed, options)
                    end
                else
                    DrawText3Ds(pedCoords.x, pedCoords.y, pedCoords.z, Lang:t("info.sell_dogs", {value = HotdogsForSale, value2 = (HotdogsForSale * SellingPrice)}))
                    if IsControlJustPressed(0, 161) or IsDisabledControlJustPressed(0, 161) then
                        QBCore.Functions.Notify(Lang:t("success.sold_hotdogs", {value = HotdogsForSale, value2 = (HotdogsForSale * SellingPrice)}), 'success')
                        TriggerServerEvent('qb-hotdogjob:server:Sell', pedCoords, HotdogsForSale, SellingPrice)
                        SellingData.HasTarget = false
                        local Selling = true
                        local HotdogObject = nil
                        local AnimPlayed = false

                        while Selling do
                            if not IsEntityPlayingAnim(cache.ped, 'mp_common', 'givetake1_b', 3) then
                                LoadAnim('mp_common')
                                if not AnimPlayed then
                                    TaskPlayAnim(cache.ped, 'mp_common', 'givetake1_b', 8.0, 8.0, 1100, 48, 0.0, false, false, false)
                                    AnimPlayed = true
                                end
                                if HotdogObject == nil then
                                    HotdogObject = CreateObject(`prop_cs_hotdog_01`, 0, 0, 0, true, true, true)
                                end
                                AttachEntityToEntity(HotdogObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.12, 0.0, -0.05, 220.0, 120.0, 0.0, true, true, false, true, 1, true)
                                SetTimeout(1250, function()
                                    Selling = false
                                end)
                            end

                            Wait(0)
                        end

                        if HotdogObject ~= nil then
                            DetachEntity(HotdogObject, true, true)
                            DeleteEntity(HotdogObject)
                        end

                        FreezeEntityPosition(ped, false)
                        SetPedKeepTask(ped, false)
                        SetEntityAsNoLongerNeeded(ped)
                        ClearPedTasksImmediately(ped)
                        SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
                        Config.Stock[SellingData.Hotdog].Current = Config.Stock[SellingData.Hotdog].Current - HotdogsForSale
                        SellingData.Hotdog = nil
                        break
                    end

                    if IsControlJustPressed(0, 162) or IsDisabledControlJustPressed(0, 162) then
                        QBCore.Functions.Notify(Lang:t("error.cust_refused"), 'error')
                        SellingData.HasTarget = false

                        FreezeEntityPosition(ped, false)
                        SetPedKeepTask(ped, false)
                        SetEntityAsNoLongerNeeded(ped)
                        ClearPedTasksImmediately(ped)
                        SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
                        SellingData.Hotdog = nil
                        break
                    end
                end
            else
                SellingData.HasTarget = false
                FreezeEntityPosition(ped, false)
                SetPedKeepTask(ped, false)
                SetEntityAsNoLongerNeeded(ped)
                ClearPedTasksImmediately(ped)
                SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
                SellingData.Enabled = false
                SellingData.Target = nil
                SellingData.HasTarget = false
                SellingData.Hotdog = nil
                QBCore.Functions.Notify(Lang:t("error.no_dogs"), 'error')
                QBCore.Functions.Notify(Lang:t('info.no_selling'), 'primary')
                break
            end
        else
            SellingData.HasTarget = false
            FreezeEntityPosition(ped, false)
            SetPedKeepTask(ped, false)
            SetEntityAsNoLongerNeeded(ped)
            ClearPedTasksImmediately(ped)
            SellingData.RecentPeds[#SellingData.RecentPeds+1] = ped
            SellingData.Enabled = false
            SellingData.Target = nil
            SellingData.HasTarget = false
            SellingData.Hotdog = nil
            QBCore.Functions.Notify(Lang:t("error.too_far"), 'error')
            QBCore.Functions.Notify(Lang:t('info.no_selling'), 'primary')
            break
        end

        Wait(3)
    end
end

local function ToggleSell()
    local pos = GetEntityCoords(cache.ped)
    local objpos = GetEntityCoords(StandObject)
    local dist = #(pos - objpos)

    if StandObject ~= nil then
        if dist < 5.0 then
            CreateThread(function()
                while true do
                    if SellingData.Enabled then
                        local coords = GetOffsetFromEntityInWorldCoords(StandObject, OffsetData.x, OffsetData.y, OffsetData.z)

                        if not SellingData.HasTarget then
                            local PlayerPeds = {}
                            if next(PlayerPeds) == nil then
                                for _, player in ipairs(GetActivePlayers()) do
                                    local ped = GetPlayerPed(player)
                                    PlayerPeds[#PlayerPeds + 1] = ped
                                end
                            end

                            local closestPed, closestDistance = QBCore.Functions.GetClosestPed(coords, PlayerPeds)

                            if closestDistance < 15.0 and closestPed ~= 0 and not IsPedInAnyVehicle(closestPed, false) then
                                SellToPed(closestPed)
                            end
                        end
                    else
                        break
                    end
                    Wait(100)
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("error.too_far"), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t("error.no_stand"), 'error')
    end
end

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    UpdateLevel()
    UpdateBlip()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    UpdateBlip()
end)

RegisterNetEvent('qb-hotdogjob:client:UpdateReputation', function(JobRep)
    PlayerData.metadata["jobrep"] = JobRep
    UpdateLevel()
end)

RegisterNetEvent('qb-hotdogjob:client:ToggleSell', function()
    if not SellingData.Enabled then
        SellingData.Enabled = true
        ToggleSell()
        QBCore.Functions.Notify(Lang:t('info.selling'), 'primary')
    else
        if SellingData.Target ~= nil then
            SetPedKeepTask(SellingData.Target, false)
            SetEntityAsNoLongerNeeded(SellingData.Target)
            ClearPedTasksImmediately(SellingData.Target)
        end
        SellingData.Enabled = false
        SellingData.Target = nil
        SellingData.HasTarget = false
        QBCore.Functions.Notify(Lang:t('info.no_selling'), 'primary')
    end
end)

RegisterNetEvent('qb-hotdogjob:staff:DeletStand', function()
    local pos = GetEntityCoords(cache.ped)
    local Object = GetClosestObjectOfType(pos.x, pos.y, pos.z, 10.0, `prop_hotdogstand_01`, true, false, false)

    if Object ~= nil then
        local ObjectCoords = GetEntityCoords(Object)
        local ObjectDistance = #(pos - ObjectCoords)

        if ObjectDistance <= 5 then
            NetworkRegisterEntityAsNetworked(Object)
            Wait(100)
            NetworkRequestControlOfEntity(Object)
            if not IsEntityAMissionEntity(Object) then
                SetEntityAsMissionEntity(Object, true, true)
            end
            Wait(100)
            DeleteEntity(Object)
            QBCore.Functions.Notify(Lang:t("info.admin_removed", "primary"))
        end
    end
end)

-- Threads

CreateThread(function()
    if Config.UseTarget then
        exports['qb-target']:AddBoxZone('hotdog_start', vector3(Config.Locations["take"].coords.x, Config.Locations["take"].coords.y, Config.Locations["take"].coords.z), 1, 1, {
            name = 'hotdog_start',
            debugPoly = false,
            heading = Config.Locations["take"].coords.w,
            minZ = Config.Locations["take"].coords.z - 1,
            maxZ = Config.Locations["take"].coords.z + 1,
        }, {
            options = {
                {
                    label = Lang:t('info.toggle_work'),
                    job = 'hotdog',
                    icon = 'fa-solid fa-hotdog',
                    action = function()
                        if not IsWorking then
                            StartWorking()
                        else
                            StopWorking()
                        end
                    end
                }
            },
            distance = 2.5
        })
    else
        local inZone = false
        local hotdogStart = BoxZone:Create(vector3(Config.Locations["take"].coords.x, Config.Locations["take"].coords.y, Config.Locations["take"].coords.z), 1.0, 1.0, {
            name="hotdog_start",
            debugPoly = false,
            minZ = Config.Locations["take"].coords.z - 1,
            maxZ = Config.Locations["take"].coords.z + 1,
        })

        hotdogStart:onPlayerInOut(function(isPointInside)
            if isPointInside then
                inZone = true
                if PlayerData.job.name == 'hotdog' then
                    if not IsWorking then
                        exports['qbx-core']:DrawText(Lang:t("info.start_working"), 'left')
                        CreateThread(function()
                            while inZone do
                                Wait(0)
                                if IsControlJustPressed(0, 38) then
                                    StartWorking()
                                end
                            end
                        end)
                    else
                        exports['qbx-core']:DrawText(Lang:t("info.stop_working"), 'left')
                        CreateThread(function()
                            while inZone do
                                Wait(0)
                                if IsControlJustPressed(0, 38) then
                                    StopWorking()
                                end
                            end
                        end)
                    end
                end
            else
                inZone = false
                exports['qbx-core']:HideText()
            end
        end)
    end
end)
