
function flipObject(tts_object)
    return function(callback)
        if tts_object.getLock() == true then
            flipLockedObject(tts_object)(callback)
            return
        end

        local face_down = tts_object.is_face_down
        tts_object.flip()
        if callback ~= nil then
              
            Wait.condition(
                function() callback(tts_object, true) end, 
                function() 
                    return not tts_object.isDestroyed() and
                    tts_object.is_face_down ~= face_down
                end,
                5,
                function() callback(tts_object, false) end
            )
        end
    end
end

function flipObjectPrime(tts_object, up)
    return function(callback)
        local face_down = tts_object.is_face_down
        if face_down ~= up then
            resolveCallback(callback, tts_object, true)
        else
            flipObject(tts_object)(callback)
        end
    end
end

function flipFaceDown(tts_object)
    return flipObjectPrime(tts_object, false)
end

function flipFaceUp(tts_object)
    return flipObjectPrime(tts_object, true)
end

function flipLockedObject(tts_object)
    return kleisliPipeOn(tts_object, {
        tapFunction(function(t) t.setLock(false) end),
        flipObject,
        tapFunction(function(t)
            waitUntilResting(t)(function(t) t.setLock(true) end)
        end),
    })
end

function smoothRotation(rotation)
    return function(tts_object)
        return function(callback)
            tts_object.setRotationSmooth(rotation, false, false)

            if callback ~= nil then
                Wait.condition(
                    function() callback(tts_object, true) end,
                    function() 
                        return not tts_object.isDestroyed() and
                        not tts_object.isSmoothMoving()
                    end,
                    5,
                    function() callback(tts_object, false) end
                )
            end
        end
    end
end

function smoothRelativeRotation(rotation)
    return function(tts_object)
        return function(callback)
            tts_object.rotate(rotation)

            if callback ~= nil then
                Wait.condition(
                    function() callback(tts_object, true) end,
                    function() 
                        return not tts_object.isDestroyed() and
                        not tts_object.isSmoothMoving()
                    end,
                    5,
                    function() callback(tts_object, false) end
                )
            end
        end
    end
end

-- Wrapper around spawnObject that sets the custom images and state
-- for a card. State is not longer in a card's lua, but can be found
-- JSON encoded on its `.memo` attribute. 
function spawnCard(front_url, back_url, state, pos) 
    return function(callback)
        spawnObject({
            type = "CardCustom",
            position = pos,
            callback_function = function(custom_card)
                custom_card.setCustomObject({
                    face = front_url,
                    back = back_url
                })
                
                local new_card = custom_card.reload()
                new_card.memo = JSON.encode(state)
                waitUntilSpawned(new_card)(callback)
            end
        })
    end
end

function swapCardBack(card, num, color_mask)

    local keep_memo = card.memo
    local backing = generated_back_url(num, color_mask)
    card.setCustomObject({
        face = card.getCustomObject().face,
        back = backing
    })
    
    local new_card = card.reload()
    new_card.memo = keep_memo
    
    return waitUntilSpawned(new_card)
end

function waitUntilSpawned(tts_object)
    return function(callback)
        if callback ~= nil then
            Wait.condition(
                function() callback(tts_object, true) end,
                function() return not tts_object.spawning end,
                5,
                function() callback(tts_object, false) end
            )
        end
    end
end

function spawnFromContainer(guid)
    return function (bag)
        return function(callback)

            if bag.isDestroyed() then return end

            local remain = bag.remainder
            if remain ~= nil then
                callback(remain)
            else
                local bag_pos = bag.getPosition()
                bag.takeObject({
                    guid = guid,
                    position = {bag_pos.x + 2, bag_pos.y + 1, bag_pos.z + 2},
                    smooth = false,
                    callback_function = callback
                })
            end
        end
    end
end

-- Callback_Thunk to instantly move an object, waits 1 frame before it
-- returns.
function move(world_position)
    return function(tts_object)
        tts_object.setPosition(world_position)

        return mapCallback(
            function() return tts_object end,
            waitFrames(1)
        )
    end
end

-- Callback_Thunk for a smooth move that completes when the object stops
-- or if 5 seconds have passed. The second parameter of the callback is
-- a boolean that indicates whether the move was successful
function smoothMove(world_position)
    return function(tts_object)
        return function(callback)
            tts_object.setPositionSmooth(world_position, false, false)

            if callback ~= nil then
                Wait.condition(
                    function() callback(tts_object, true) end,
                    function() 
                        return not tts_object.isDestroyed() and
                        not tts_object.isSmoothMoving()
                    end,
                    5,
                    function() callback(tts_object, false) end
                )
            end

        end
    end
end

-- Callback_Thunk for a smooth move that completes when the object stops
-- or if 5 seconds have passed. The second parameter of the callback is
-- a boolean that indicates whether the move was successful
function smoothRelativeMove(relative_position)
    return function(tts_object)

        local pos = Vector(relative_position)
        local current_pos = tts_object.getPosition()
        local new_pos = {
            current_pos.x + pos.x,
            current_pos.y + pos.y,
            current_pos.z + pos.z
        }
        return smoothMove(new_pos)(tts_object)
        
    end
end

function waitFrames(n)
    local num = 1
    if n > 1 then
        num = n
    end
    return function(callback)
        Wait.frames(callback, num)
    end
end

function waitUntilResting(tts_object)
    return function(callback)
        Wait.condition(
            function() callback(tts_object, true) end,
            function() 
                return not tts_object.isDestroyed() and
                tts_object.resting
            end,
            5,
            function() callback(tts_object, false) end
        )
    end
end

function dealToPlayer(player_color, amount, container)
    return function(callback)
        local target_hand_size = #getCardsInHandZone(player_color) + amount
        container.deal(amount, player_color)

        Wait.condition(
            function() callback(player_color, amount, container, true) end,
            function() return #getCardsInHandZone(player_color) == target_hand_size end,
            5,
            function() callback(player_color, amount, container, false) end
        )
    end
end

function scale(scale)
    local scale_vector = Vector(scale)
    return function(tts_object)
        return function(callback)
            tts_object.scale(scale_vector)
            Wait.condition(
                function() callback(tts_object, scale_vector, true) end,
                function() 
                    return not tts_object.isDestroyed() and
                        tts_object.getScale() == scale_vector
                end,
                5,
                function() callback(tts_object, scale_vector, false) end
            )
        end
    end
end

function changeToAvailableColor(player)
    return function(callback)

        local taken = {}
        for _,player in ipairs(Player.getPlayers()) do
            taken[player.color] = true
        end

        local acted = false
        for _,color in ipairs(Player.getAvailableColors()) do
            if not taken[color] then
                player.changeColor(color)
                acted = true
                Wait.frames(function()
                    callback(player)
                end, 30)
                break
            end
        end

        if not acted then
            player.changeColor("Grey")
            Wait.frames(function()
                callback(player)
            end, 30)
        end

    end
end