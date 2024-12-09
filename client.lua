local wardrobeId = "ND_AppearanceShops:wardrobe"
local wardrobeSelectedId = ("%s_selected"):format(wardrobeId)
local wardrobe = json.decode(GetResourceKvpString(wardrobeId)) or {}
local currentOpenWardrobe
local fivemAppearance = exports["fivem-appearance"]


-- Define blocked items
local blockedItems = {
    hats = {19, 20, 21, 22, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 139, 140, 141, 142, 149, 160, 161, 170, 171, 172, 173, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233},
    legs = {16, 17, 18, 19, 20, 21, 22, 23, 24, 131, 132, 135, 188, 189, 191, 192, 194},
    bags = {9},
    scarvesChains = {12, 16, 18, 20, 21, 22, 48, 132, 133, 135, 140, 153, 154, 155, 182, 183, 184, 185, 186, 187, 188, 189, 190},
    shirts = {16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 80, 144, 151, 152, 153, 173, 175, 176, 177, 221, 222, 223, 224, 225, 226},
    bodyArmor = {1, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 45, 46, 49, 83, 84, 85, 88, 89, 90, 91},
    jackets = {16, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 40, 41, 42, 43, 45, 46, 47, 48, 49, 89, 253, 348, 349, 350, 351, 352, 353, 354, 355, 356, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545}
}

-- Helper function to check if a value is in a list
local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function to notify the player when blocked items are detected
local function notifyBlockedItem()
    lib.notify({
        title = "Blocked Item",
        description = "You are not allowed to use emergency outfits. Your changes have been reverted.",
        type = "error",
        position = "bottom"
    })
end

-- Filter blocked items from appearance
local function filterBlockedItems(appearance)
    local blockedAttempt = false

    -- Filter props (hats)
    if appearance.props then
        local filteredProps = {}
        for _, prop in ipairs(appearance.props) do
            if prop.prop_id == 0 and contains(blockedItems.hats, prop.drawable) then
                blockedAttempt = true
            else
                table.insert(filteredProps, prop)
            end
        end
        appearance.props = filteredProps
    end

    -- Filter components (legs, bags, scarves/chains, shirts, body armor, jackets)
    if appearance.components then
        local filteredComponents = {}
        for _, component in ipairs(appearance.components) do
            if (component.component_id == 4 and contains(blockedItems.legs, component.drawable)) or
               (component.component_id == 5 and contains(blockedItems.bags, component.drawable)) or
               (component.component_id == 7 and contains(blockedItems.scarvesChains, component.drawable)) or
               (component.component_id == 8 and contains(blockedItems.shirts, component.drawable)) or
               (component.component_id == 9 and contains(blockedItems.bodyArmor, component.drawable)) or
               (component.component_id == 11 and contains(blockedItems.jackets, component.drawable)) then
                blockedAttempt = true
            else
                table.insert(filteredComponents, component)
            end
        end
        appearance.components = filteredComponents
    end

    return blockedAttempt
end


local function inputOutfitName()
    local input = lib.inputDialog("Save current outfit", {"Outfit name:"})
    local name = input?[1]
    if name and name ~= "" then
        return name
    end
end

local function saveWardrobe(name)
    if not name then return end
    local appearance = fivemAppearance:getPedAppearance(cache.ped)
    appearance.hair = nil
    appearance.headOverlays = nil
    appearance.tattoos = nil
    appearance.faceFeatures = nil
    appearance.headBlend = nil
    wardrobe[#wardrobe+1] = {
        name = name,
        appearance = appearance
    }
	SetResourceKvp(wardrobeId, json.encode(wardrobe))
    return true
end

local function getWardrobe()
    local options = {
        {
            title = "Save current outfit",
            icon = "fa-solid fa-floppy-disk",
            onSelect = function()
                saveWardrobe(inputOutfitName())
            end
        }
    }
    for i=1, #wardrobe do
        local info = wardrobe[i]
        options[#options+1] = {
            title = info.name,
            arrow = true,
            onSelect = function()
                currentOpenWardrobe = i
                lib.showContext(wardrobeSelectedId)
            end
        }
    end
    return options
end

local function openWardrobe()
    lib.registerContext({
        id = wardrobeId,
        title = "Outfits",
        options = getWardrobe()
    })
    lib.showContext(wardrobeId)
end


local function startChange(coords, options, i)
    local ped = cache.ped
    local oldAppearance = {
        model = GetEntityModel(ped),
        tattoos = fivemAppearance:getPedTattoos(ped),
        appearance = fivemAppearance:getPedAppearance(ped)
    }
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 1.0)
    SetEntityHeading(ped, coords.w)
    Wait(250)

    fivemAppearance:startPlayerCustomization(function(appearance)
        if not appearance then return end

        -- Check for blocked items
        local blockedAttempt = filterBlockedItems(appearance)
        if blockedAttempt then
            notifyBlockedItem()
            fivemAppearance:setPedAppearance(ped, oldAppearance) -- Revert to the old appearance
            return
        end

        -- Charge the player for valid items
		ped = PlayerPedId()
        local clothing = {
            model = GetEntityModel(ped),
            tattoos = fivemAppearance:getPedTattoos(ped),
            appearance = appearance
        }

        -- Call the server to handle the purchase
        local success = lib.callback.await("ND_AppearanceShops:clothingPurchase", false, i, clothing)
       if not lib.callback.await("ND_AppearanceShops:clothingPurchase", false, i, clothing) then
            fivemAppearance:setPlayerModel(oldAppearance.model)
            ped = PlayerPedId()
            fivemAppearance:setPedTattoos(ped, oldAppearance.tattoos)
            fivemAppearance:setPedAppearance(ped, oldAppearance.appearance)
        end
    end, options)
end


local function getStoreNumber(store)
    for i=1, #Config do
        if store == Config[i] then
            return i
        end
    end

    local number = #Config+1
    Config[number] = store
    return number
end

local function createClothingStore(info)
    local storeNumber = getStoreNumber(info)
    for i=1, #info.locations do
        local location = info.locations[i]
        local options = {
            {
                name = "nd_core:appearanceShops",
                icon = "fa-solid fa-bag-shopping",
                label = info.text,
                distance = 2.0,
                onSelect = function(data)
                    startChange(location.change, info.appearance, storeNumber)
                end
            }
        }
        if info.appearance?.components then
            options[#options+1] = {
                name = "nd_core:appearanceOutfit",
                icon = "fa-solid fa-shirt",
                label = "View outfits",
                distance = 2.0,
                onSelect = function(data)
                    openWardrobe()
                end
            }
        end
        NDCore.createAiPed({
            resource = GetInvokingResource(),
            model = location.model,
            coords = location.worker,
            distance = 25.0,
            blip = info.blip,
            options = options,
            anim = {
                dict = "anim@amb@casino@valet_scenario@pose_d@",
                clip = "base_a_m_y_vinewood_01"
            }
        })
    end
end

lib.registerContext({
    id = wardrobeSelectedId,
    title = "Outfits",
    menu = wardrobeId,
    options = {
        {
            title = "Wear",
            icon = "fa-solid fa-shirt",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                if GetHashKey(selected.appearance.model) ~= GetEntityModel(cache.ped) then
                    return lib.notify({
                        title = "Incorrect player model",
                        description = "This saved outfit is not for the current player model",
                        type = "error"
                    })
                end
                fivemAppearance:setPedAppearance(cache.ped, selected.appearance)
            end
        },
        {
            title = "Edit name",
            icon = "fa-solid fa-pen-to-square",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                local name = inputOutfitName()
                if not name then return end
                selected.name = name
            end
        },
        {
            title = "Remove",
            icon = "fa-solid fa-trash-can",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                local alert = lib.alertDialog({
                    header = "Remove outfit?",
                    content = ("Are you sure you'd like to remove %s?"):format(selected.name),
                    centered = true,
                    cancel = true
                })
                if alert ~= "confirm" then return end
                table.remove(wardrobe, currentOpenWardrobe)
            end
        }
    }
})

for i=1, #Config do
    createClothingStore(Config[i])
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= cache.resource then return end
    SetResourceKvp(wardrobeId, json.encode(wardrobe))
end)


RegisterNetEvent("ND_AppearanceShops:ApplyAppearance", function(clothing)
    if clothing then
        fivemAppearance:setPedAppearance(PlayerPedId(), clothing.appearance)
    end
end)


exports("openWardrobe", openWardrobe)
exports("createClothingStore", createClothingStore)
