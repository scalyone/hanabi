---------------------------------------------------------------------
---------------- [[ Global Hanabi Script ]] -------------------------
---------------------------------------------------------------------

--[[ 
    PLAY- TESTING NOTES!
    
    Deal after 3 player?
]]

-- Pictures are stored/hosted by this project's github repo
-- They can be uploaded to steam cloud eventually (Though both are
-- stable/fast hosts).
ASSET_URL = "https://raw.githubusercontent.com/Trequetrum/tts-hanabi/main/assets/"
ASSET_VERSION = "v2"
ASSET_GENED_URL = ASSET_URL .. "generated/"
ASSET_BACK_BLANK_URL = ASSET_URL .. "back_blank_" .. ASSET_VERSION .. ".png"

-- Filenames describe cards and have a canonical order for colors as
-- listed here
COLOR_ORDER = {'b', 'g', 'r', 'w', 'y'}

COLOR_STRINGS = {
    a="rainbow",
    b="blue",
    g="green",
    r="red",
    w="white",
    y="yellow"
}

-- Bit mask for the card colors. Used to describe the 'notes' on the
-- back of a card. While players can infer that anything more than one
-- color is a rainbow, 'all five colors' is semantically equivalent to 
-- rainbow (I'm not sure yet if that complicates the implementation of
-- the basic rule-set, but I don't think it will as the masks can be
-- compared directly)
--
-- The keys in this table hard-code how each color is represented as a
-- string on their respective filenames
--
-- a: all/rainbow
-- b: blue
-- g: green
-- r: red
-- w: white
-- y: yellow
COLOR_MASKS = {
    a = tonumber('11111', 2), -- 31
    b = tonumber('1', 2), -- 1
    g = tonumber('10', 2), -- 2
    r = tonumber('100', 2), -- 4
    w = tonumber('1000', 2), -- 8
    y = tonumber('10000', 2) -- 16
}

-- Hard-coding how each number is represented as a string on their 
-- respective filenames.
NUMBERS_REP = {'1','2','3','4','5'}

NUMBER_STRINGS = {"one", "two", "three", "four", "five"}

-- Hard-coding how many cards of each number exist for a color.
-- Used when generating the hanabi deck
COLOR_LAYOUT = {
    default=2,
    [1]=3,
    [5]=1
}

LAYOUT_CARD_WIDTH = 3.99
LAYOUT_CARD_HEIGHT = 5.58

-- While I generally prefer to find things without relying on GUID
-- (They're so fickle!). Scripting zones arn't external resources,
-- they're always made within TTS. GUID is as good as a name then.
TTS_GUID = {
    token_mat = "d60259",
    play_mat = "ee75ab",
    discard_mat = "169cee",
    layout_playzone = "f311cf",
    layout_discardzone = "707002"
}

-- Store info that is fine to get lost when the game is reset. Mostly
-- used as a cashe of commonly searched for items (like the hanabi 
-- deck). Basically name-spaces global state.
Temp_State={
    active_cards={}
}

function colorCharFromMask(color_mask)
    for char, mask in pairs(COLOR_MASKS) do
        if mask == color_mask then return char end
    end
    return 'a'
end

function isObjectInZone(tts_zone)
    return function(tts_object)
        for _,check in pairs(tts_zone.getObjects()) do
            if  not check.isDestroyed() and 
                not tts_object.isDestroyed() and
                check.getGUID() == tts_object.getGUID()
            then
                return true
            end
        end
        return false
    end
end

function onObjectEnterZone(tts_zone, tts_object)
    -- Hanabi cards that enter a player's hand are revealed to all
    -- other players
    if tts_zone.type == "Hand" and isHanabiCard(tts_object) then
        tts_object.setHiddenFrom({tts_zone.getValue(), "Grey"})
        tts_object.UI.setXmlTable(ui_cardUI(tts_object, tts_zone.getValue()))
        flipFaceUp(tts_object)()
    end

    -- If the turn token enters a players hand zone, reload the UI
    -- so it updates for that player
    if tts_zone.type == "Scripting" and tts_object.getName() == "turn_token" then
        kleisliPipeOn(tts_object, {
            continueIf(function(card)
                local continue = Temp_State.tracking_turn_token ~= true
                Temp_State.tracking_turn_token = true
                return continue
            end),
            waitUntilResting,
            tapFunction(function()
                local location = getTurnTokenLocation()
                -- if location ~= "token_mat" then
                --     broadcastToAll("Starting " .. ui_playerNameBBCodeColored(location) .. "'s turn")
                -- end
                ui_LoadUI()
                Temp_State.tracking_turn_token = false
            end)
        })()
    end

    -- Hanabi cards that are layed on the table once played or
    -- discarded are revealed to all players
    -- and
    -- when a card is played, calculate and display the score
    if  (tts_zone.guid == TTS_GUID.layout_playzone or
        tts_zone.guid == TTS_GUID.layout_discardzone) and
        isHanabiCard(tts_object)
    then
        tts_object.setHiddenFrom({})
        tts_object.UI.setXml("")
        ui_loadScoreUI()
    end

    -- Play and discard cards once they come to a rest
    if  tts_zone.guid == TTS_GUID.play_mat or
        tts_zone.guid == TTS_GUID.discard_mat
    then
        kleisliPipeOn(tts_object, {
            continueIf(isHanabiCard),
            continueIf(function(card)
                local continue = Temp_State.active_cards[card.getGUID()] ~= true
                Temp_State.active_cards[card.getGUID()] = continue
                return continue
            end),
            waitUntilResting,
            continueIf(function(card)
                local continue = not card.isDestroyed() and isObjectInZone(tts_zone)(card)
                Temp_State.active_cards[card.getGUID()] = continue
                return continue
            end),
            tapFunction(function(card)
                card.setHiddenFrom({})
                card.UI.setXml("")
            end),
            flipFaceUp,
            continueIf(notDestoyed),
            smoothRelativeMove({0, 5, 0}),
            continueIf(notDestoyed),
            function(card)
                if tts_zone.guid == TTS_GUID.discard_mat then
                    recoverHintToken()()
                    return discardCard(card)
                elseif tts_zone.guid == TTS_GUID.play_mat then
                    return playCard(card)
                end
            end,
            continueIf(notDestoyed),
            tapFunction(function(card)
                Temp_State.active_cards[card.getGUID()] = false
            end),
            tapFunction(advanceTurnToken)
        })()

        kleisliPipeOn(tts_object, {
            continueIf(isHanabiCardContainer),
            continueIf(function(deck)
                local continue = Temp_State.active_cards[deck.getGUID()] ~= true
                Temp_State.active_cards[deck.getGUID()] = true
                return continue
            end),
            waitUntilResting,
            continueIf(notDestoyed),
            continueIf(function(deck)
                local continue = isObjectInZone(tts_zone)(deck)
                if not continue then
                    Temp_State.active_cards[deck.getGUID()] = false
                end
                return continue
            end),
            function(deck)
                local sequence = {}

                for _,maybe_card in pairs(deck.getObjects()) do
                    if isHanabiCard(maybe_card) then
                        table.insert(
                            sequence,
                            kleisliPipeOn(deck, {
                                continueIf(notDestoyed),
                                -- This is a short leak, I don't expect this code
                                -- to run very often or for very long, so who cares?
                                continueIf(isObjectInZone(tts_zone)),
                                spawnFromContainer(maybe_card.guid),
                                continueIf(notDestoyed),
                                smoothRelativeMove({0,0.1,0}),
                                continueIf(notDestoyed),
                                tapFunction(function(card)
                                    if tts_zone.getGUID() == TTS_GUID.discard_mat then
                                        discardCard(card)()
                                    elseif tts_zone.getGUID() == TTS_GUID.play_mat then
                                        playCard(card)()
                                    else
                                        smoothMove({0,10,0})(card)()
                                    end
                                end)
                            })
                        )
                    end
                end

                return seriesCallback(sequence)
            end
        })()

    end

end

function onObjectLeaveZone(tts_zone, tts_object)

    -- Cards cleaving the playzone trigger a recount of
    -- the score
    if  (tts_zone.guid == TTS_GUID.layout_playzone or
        tts_zone.guid == TTS_GUID.layout_discardzone) and
        isHanabiCard(tts_object)
    then
        ui_loadScoreUI()
    end
end

function onObjectSpawn(tts_object)
    if isHanabiCard(tts_object) then
        tts_object.setHiddenFrom(table.insert(Player.getAvailableColors(), "Grey"))
    end
end

function settupGameKeys()

    local function moveHotkey(destination)
        return function(player_color, tts_object)
            if isHanabiCard(tts_object) then
                local hand_pos = getPositionInfrontOf(player_color)
                destination.y = 1
                kleisliPipeOn(tts_object, {
                    move(hand_pos),
                    smoothMove(destination)
                })()
            end
        end
    end

    addHotkey("Play Card", moveHotkey(getObjectFromGUID(TTS_GUID.play_mat).getPosition()))
    addHotkey("Discard Card", moveHotkey(getObjectFromGUID(TTS_GUID.discard_mat).getPosition()))

end

function ensureLegalPlayerColors()
    local legal = {Grey=true}
    for _,color in ipairs(Player.getAvailableColors()) do
        legal[color] = true
    end

    local series = {}

    for _,player in ipairs(Player.getPlayers()) do
        if not legal[player.color] then
            table.insert(series, changeToAvailableColor(player))
        end
    end

    seriesCallback(series)()
end

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    log("Hello World!")
    ensureLegalPlayerColors()
    hideCardsInHands()
    settupGameKeys()
    ui_loadScoreUI()
    -- Be sure to load the global UI last, 
    -- it needs any prep to be done already
    ui_LoadUI()
    

    -- Wait.time(
    --     function()
    --         logs(">>>>> getCurrentScore() ", getCurrentScore())
    --     end,
    --     5,
    --     100
    -- )
end

function onPlayerConnect()
    ensureLegalPlayerColors()
end