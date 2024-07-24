function getTurnTokenLocation()

    local turn_token = getObjectByName("turn_token")

    if tokenMatContains(turn_token) then
        return "token_mat"
    end

    local turn_token_position = turn_token.getPosition()

    local closest = {distance=1000, player="token_mat"}

    for _,player_color in ipairs(getActivePlayerColors()) do
        local hand_pos = getHandZone(player_color).getPosition()
        local delta_d = turn_token_position:distance(hand_pos)
        if delta_d < closest.distance then
            closest = {distance=delta_d, player=player_color}
        end
    end

    return closest.player
end

function getTokenMatObjects()
    return filterArray(
        getObjectFromGUID(TTS_GUID.token_mat).getObjects(),
        function(oby) return oby.type ~= "Surface" end
    )
end

function tokenMatContains(tts_object)
    for _,o in pairs(getTokenMatObjects()) do
        if o.getGUID() == tts_object.getGUID() then
            return true
        end
    end
    
    return false
end

function advanceTurnToken()
    kleisliCallbackPipe({
        turnDeal,
        continueIf(function(...)
            local args = {...}
            return args[#args] ~= false
        end),
        function()
        
            local location = getTurnTokenLocation()
            local turn_order = {}

            for _,player_color in ipairs(Player.getAvailableColors()) do
                if #getCardsInHandZone(player_color) > 0 then
                    table.insert(turn_order, player_color)
                end
            end

            for i, player_color in ipairs(turn_order) do
                if player_color == location then
                    if i < #turn_order then
                        moveTurnTokenTo(turn_order[i+1])
                        return
                    else
                        moveTurnTokenTo(turn_order[1])
                        return
                    end
                end
            end

            displayLog("Alert: Failure to advance the turn token")

    
        end
    })()()
end

function moveTurnTokenTo(color)
    local pos = getPositionInfrontOf(color)
    local token = getObjectByName("turn_token")
    smoothMove(pos)(token)()
end

function getHintTokens()
    local tokens = {}
    for n=1,8 do
        local hint_token = getObjectByName("hint_token_" .. n)
        if hint_token ~= nil and not hint_token.isDestroyed() then
            table.insert(tokens, hint_token)
        end
    end
    return tokens
end

function availableHintTokens()
    local tokens = {}
    for _,hint_token in ipairs(getHintTokens()) do
        if not hint_token.is_face_down then
            table.insert(tokens, hint_token)
        end
    end
    return tokens
end

function usedHintTokens()
    local tokens = {}
    for _,hint_token in ipairs(getHintTokens()) do
        if hint_token.is_face_down then
            table.insert(tokens, hint_token)
        end
    end
    return reverseArray(tokens)
end

function useHintToken()
    return kleisliPipeOnLazy(availableHintTokens, {
        function(ts)
            if #ts > 0 then
                return flipObject(ts[1])
            else
                return liftValuesToCallback(nil)
            end
        end
    })
end

function recoverHintToken()
    return kleisliPipeOnLazy(usedHintTokens, {
        function(ts)
            if #ts > 0 then
                return flipObject(ts[1])
            else
                return liftValuesToCallback(1)
            end
        end
    })
end

function resetHintTokens()
    parallelCallback(mapArray(usedHintTokens(), flipObject))()
end

function getFuseTokens()
    local tokens = {}
    for n=1,3 do
        local fuse_token = getObjectByName("fuse_token_" .. n)
        if fuse_token ~= nil and not fuse_token.isDestroyed() then
            table.insert(tokens, fuse_token)
        end
    end
    return tokens
end

function availableFuseTokens()
    local fuse_tokens = getFuseTokens()
    local avail = {}
    for _,fuse in ipairs(fuse_tokens) do
        fuse_r = fuse.getRotation()
        if  fuse.resting and 
            tokenMatContains(fuse) and
            fuse_r.x < 20 and
            fuse_r.y > 160 and
            fuse_r.z < 20
        then
            table.insert(avail, fuse)
        end
    end
    return avail
end

function fuseTokenLayoutPos(i)
    local token_mat_pos = getObjectFromGUID(TTS_GUID.token_mat).getPosition()

    return {
        x=token_mat_pos.x + 4,
        y=1,
        z=token_mat_pos.z - 4 + (2 * (i-1))
    }
end

function resetFuseTokens()
    for i,fuse in ipairs(getFuseTokens()) do
        kleisliPipeOn(fuse, {
            smoothMove(fuseTokenLayoutPos(i)),
            smoothRotation({x=0,y=180,z=0})
        })()
    end
end

function useFuseToken()
    return kleisliPipeOnLazy(
        function()
            local fuse_tokens = availableFuseTokens()
            if #fuse_tokens > 0 then return fuse_tokens[1]
            else return nil end
        end, {
            continueIf(function(fuse) return fuse ~= nil end),
            tapFunction(function(fuse)
                local num = tonumber(fuse.getName():sub(-1))
                if num == 1 then
                    broadcastToAll("A missfired rocket, the crowd is restless")
                elseif num == 2 then
                    broadcastToAll("A second missfire, be careful")
                elseif num == 3 then
                    broadcastToAll(
                        "The third missfire, the show cannot go on\n" ..
                        "Final score is " .. getCurrentScore()
                    )
                end
            end),
            smoothMove({0,4,0}),
            smoothMove({0,40,0}),
            function(fuse)

                local fuse_num = tonumber(fuse.getName():sub(-1))
                if not fuse_num then
                    fuse_num = 1
                end

                local new_pos = fuseTokenLayoutPos(fuse_num)
                new_pos.y = 1.5
                
                return kleisliPipeOn(fuse, {
                    move(new_pos),
                    tapCallback(waitFrames(45)),
                    smoothRotation({x=90,y=90,z=0})
                })
            end
        }
    )
end