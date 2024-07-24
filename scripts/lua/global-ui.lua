function ui_defaults()
    return {{
        tag="Defaults",
        children={{
            tag="Text",
            attributes={
                color="#ffffff",
                fontSize="20",
                outline="#000000"
            }
        }}
    },{
        tag="Panel",
        attributes={
            height="50%",
            width="95%"
        },
        children={}
    }}
end

function ui_alignmentHelpers()
    return {{
        tag="Text",
        value="↖",
        attributes={
            alignment="UpperLeft"
        }
    },{
        tag="Text",
        value="↗︎︎",
        attributes={
            alignment="UpperRight"
        }
    },{
        tag="Text",
        value="X",
        attributes={
            alignment="MiddleCenter"
        }
    },{
        tag="Text",
        value="↙",
        attributes={
            alignment="LowerLeft"
        }
    },{
        tag="Text",
        value="↘︎︎",
        attributes={
            alignment="LowerRight"
        }
    }}
end

function ui_playerNameColored(player_color)
    local player_name = getPlayerName(player_color)

    return string.format(
        '<textcolor color="#%s"><b>%s</b></textcolor>',
        Color[player_color]:toHex(),
        player_name
    )
end

function ui_textBBCodeRainbow(text)
    local rainbow = {"Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple"}
    local r_index = 1
    local retr = {}
    for i = 1, #text do
        local c = string.sub(text, i, i)
        if c ~= " " and c ~= "\n" then
            table.insert(retr, ui_textBBCodeColored(c, rainbow[r_index]))
            r_index = r_index + 1
            if r_index > #rainbow then r_index = 1 end
        else
            table.insert(retr, c)
        end
    end
    
    return table.concat(retr)
end

function ui_textBBCodeColored(text, player_color)
    if player_color == "rainbow" then
        return ui_textBBCodeRainbow(text)
    end
    return string.format(
        '[%s]%s[-]',
        Color[player_color]:toHex(),
        text
    )
end

function ui_playerNameBBCodeColored(player_color)
    return ui_textBBCodeColored(getPlayerName(player_color), player_color)
end

function ui_greeting(color)
    return {
        tag="Panel",
        attributes={
            visibility=color,
            rectAlignment="UpperRight",
            offsetXY="0 0",
            height="100",
            width="400"
        },
        children={{
            tag="Text",
            value="Hello " .. ui_playerNameColored(color) .. ",",
            attributes={
                alignment="UpperRight",
            }
        },{
            tag="Text",
            value="the game hasn't started yet!",
            attributes={
                alignment="UpperRight",
                offsetXY="0 -25"
            }
        },{
            tag="Text",
            value="Check the 'Rules' notebook for more information",
            attributes={
                alignment="UpperRight",
                offsetXY="0 -50"
            }
        }}
    }
end

function ui_backgroundColor()
    return {
        tag="Image",
        attributes={
            color="rgba(0.145,0.145,0.286,0.5)"
        }
    }
end

function ui_pleaseWait(colors_string, color_turn)
    local text = ui_playerNameColored(color_turn) .. "'s turn, please wait"
    -- local width = (string.len(text) * 6) + 10
    return {
        tag="Panel",
        attributes={
            visibility=colors_string,
            rectAlignment="UpperRight",
            offsetXY="0 0",
            height=30,
            width=400
        },
        children={{
            tag="Text",
            value=text,
            attributes={
                alignment="MiddleRight",
                offsetXY="0 0"
            }
        }}
    }
end

function ui_createGameRuleToggle(rule, text, y_offset)

    local game_rules = getCurrentGameRules()

    return {
        tag="Toggle",
        attributes={
            id=rule,
            onValueChanged="ui_onGameRuleToggle",
            isOn=game_rules[rule],
            rectAlignment="UpperRight",
            offsetXY="0 " .. y_offset,
            width="350",
            height="30"
        },
        children={{
            tag="Text",
            value=text,
            attributes={
                fontSize=16
            }
        }}
    }
end

function ui_onGameRuleToggle(player, value, rule)
    setGameRule(rule, value)
    ui_LoadUI()
end

function ui_gameRuleDialog()

    local game_rules = getCurrentGameRules()

    local panel = {
        tag="Panel",
        attributes={
            rectAlignment="UpperRight",
            offsetXY="0 -125",
            width="400",
            height="400",
            visibility=table.concat(Player.getAvailableColors(), "|")
        },
        children={}
    }

    local y_offset = 0
    table.insert(panel.children, {
        tag="Text",
        value="<i>Dealer becomes first player</i>",
        attributes={
            alignment="UpperRight",
            offsetXY="0 " .. y_offset
        }
    })

    y_offset = y_offset - 30
    local include_rainbow_toggle = ui_createGameRuleToggle(
        "include_rainbow",
        "Include rainbow cards",
        y_offset
    )
    if not game_rules.include_rainbow then
        include_rainbow_toggle.attributes.width = 255
    end
    table.insert(panel.children, include_rainbow_toggle)
    
    if game_rules.include_rainbow then

        y_offset = y_offset - 30
        table.insert(panel.children, ui_createGameRuleToggle(
            "rainbow_wild",
            "Rainbow cards are wild",
            y_offset
        ))

        y_offset = y_offset - 30

        if game_rules.rainbow_wild then
            local sub_toggle = ui_createGameRuleToggle(
                "rainbow_one_per_firework",
                "Maximum one wild card per firework",
                y_offset
            )
            sub_toggle.attributes.width = sub_toggle.attributes.width - 30
            table.insert(panel.children, sub_toggle)
        end

        y_offset = y_offset - 30
        table.insert(panel.children, ui_createGameRuleToggle(
            "rainbow_firework",
            "Create a firework out of rainbow cards",
            y_offset
        ))

        y_offset = y_offset - 30
        table.insert(panel.children, ui_createGameRuleToggle(
            "rainbow_multicolor",
            "Rainbow cards are every color for hints",
            y_offset
        ))

        y_offset = y_offset - 30
        table.insert(panel.children, ui_createGameRuleToggle(
            "rainbow_talking",
            "Rainbow is a color (Use as a hint)",
            y_offset
        ))

    end

    y_offset = y_offset - 30
    local button_width = 255
    if game_rules.include_rainbow then
        button_width = 350
    end
    local deal_button = {
        tag="Button",
        value="Deal and begin a game of Hanabi :)",
        attributes={
            onClick="startGame",
            offsetXY="0 " .. y_offset,
            rectAlignment="UpperRight",
            width=button_width,
            height="30"
        }
    }

    table.insert(panel.children, deal_button)

    return panel
end

function ui_activeTurnUi(color)
    local panel = {
        tag="Panel",
        attributes={
            rectAlignment="UpperRight",
            visibility=color,
            offsetXY="0 0",
            width="400",
            height="400"
        },
        children={}
    }

    local message = {
        tag="Text",
        value=ui_playerNameColored(color) .. ", it's your turn.",
        attributes={
            alignment="UpperRight"
        }
    }
    table.insert(panel.children, message)

    local num_hints = #availableHintTokens()
    local txt = "You can play, discard,"
    if num_hints < 1 then
        txt = "You can only play or discard"
    end

    local options = {
        tag="Text",
        value=txt,
        attributes={
            alignment="UpperRight",
            offsetXY="0 -30"
        }
    }

    table.insert(panel.children, options)
    if num_hints > 0 then
        table.insert(panel.children, ui_hintOptions(color))
    end


    return panel
end

function ui_hintOptions(color)

    local talk_to = Temp_State.talking_to or ""

    local panel = {
        tag="Panel",
        attributes={
            rectAlignment="UpperRight",
            visibility=color,
            offsetXY="0 -60",
            width="400",
            height="400"
        },
        children={}
    }
    local y_offset = 0
    local x_offset = 0

    local toggle_text = {
        tag="Text",
        value="or talk to a player",
        attributes={
            alignment="UpperRight"
        }
    }
    y_offset = y_offset - 30
    table.insert(panel.children, toggle_text)

    local toggle_group = {
        tag="ToggleGroup",
        attributes={
            allowSwitchOff=true
        },
        children={}
    }
    table.insert(panel.children, toggle_group)
    
    local players_by_color = {}
    for _,player_color in ipairs(Player.getAvailableColors()) do
        if player_color ~= color and #getCardsInHandZone(player_color) > 0 then
            table.insert(players_by_color, player_color)
        end
    end

    -- function getXOffset(num, total)
    --     local players_left = total - num
    --     local to_the_right = (3 - (num % 3)) % 3
    --     if players_left >= to_the_right then
    --         return 0 - (120 * to_the_right)
    --     else
    --         return 0 - (120 * players_left)
    --     end
    -- end

    for _,player_color in ipairs(players_by_color) do
        
        local is_on = false
        if talk_to == player_color then
            is_on = true
        end

        local toggle_string = ui_playerNameColored(player_color)

        table.insert(toggle_group.children, {
            tag="Toggle",
            attributes={
                id="talk_to_" .. player_color,
                onValueChanged="ui_onTalkToToggle",
                isOn=is_on,
                rectAlignment="UpperRight",
                offsetXY="0 "..y_offset,
                textColor="#ffffff",
                width="180",
                height="30"
            },
            children={{
                tag="Text",
                value=toggle_string
            }}
        })
        --if i % 3 == 0 then
        y_offset = y_offset - 30
        --end
            
    end

    y_offset = y_offset - 20

    if talk_to ~= "" then
        local game_rules = getCurrentGameRules()
 
        local cards = mapArray(
            getCardsInHandZone(talk_to),
            function(card)
                local info = JSON.decode(card.memo)
                return {
                    number = info.front_number,
                    color_mask = info.front_color_mask
                }
            end
        )

        local has_rainbow = false
        for _,card in pairs(cards) do
            if card.color_mask == COLOR_MASKS.a then
                has_rainbow = true
                break
            end
        end

        local hint_color_mask = 0
        if game_rules.rainbow_multicolor then
            hint_color_mask = bitwiseOr(mapArray(cards, pluck("color_mask")))
        else
            hint_color_mask = bitwiseOr(filter(
                mapArray(cards, pluck("color_mask")),
                function(mask)
                    return mask ~= COLOR_MASKS.a
                end
            ))
        end

        local button_width = 80
        local button_height = 80
        x_offset = 0
        for c,mask in pairs(COLOR_MASKS) do
            if  mask == COLOR_MASKS.a and has_rainbow or
                (   bit32.band(mask,hint_color_mask) == mask and
                    (mask ~= COLOR_MASKS.a or (   
                        has_rainbow and 
                        game_rules.rainbow_talking
                    ))
                )
            then
                table.insert(panel.children, {
                    tag="Panel",
                    attributes={
                        offsetXY=x_offset .. " " .. y_offset,
                        rectAlignment="UpperRight",
                        width=button_width,
                        height=button_height
                    },
                    children={{
                        tag="Button",
                        attributes={
                            icon="icon_" .. c,
                            id="talk_to_" .. talk_to .. ":" .. c,
                            onClick="ui_onTalkToPlayer(" .. talk_to .. ")",
                            preserveAspect=true,
                            colors="rgba(0,0,0,0)|rgba(1,1,1,0.2)|rgba(0,0,0,0.5)|rgba(0,0,0,0.5)"
                        }
                    }}
                })
                x_offset = x_offset - button_width
            end
        end
        y_offset = y_offset - button_height 
        x_offset = 0

        for i = #NUMBERS_REP, 1, -1 do
            num_rep = NUMBERS_REP[i]
            for _,num in
                ipairs(noDuplicatesArray(mapArray(cards, pluck("number"))))
            do
                if num == i then
                    table.insert(panel.children, {
                        tag="Panel",
                        attributes={
                            offsetXY=x_offset .. " " .. y_offset,
                            rectAlignment="UpperRight",
                            width=button_width,
                            height=button_height
                        },
                        children={{
                            tag="Button",
                            attributes={
                                icon="icon_" .. num_rep,
                                id="talk_to_" .. talk_to .. ":" .. num_rep,
                                onClick="ui_onTalkToPlayer(" .. talk_to .. ")",
                                preserveAspect=true,
                                colors="rgba(0,0,0,0)|rgba(1,1,1,0.2)|rgba(0,0,0,0.5)|rgba(0,0,0,0.5)"
                            }
                        }}
                    })
                    x_offset = x_offset - button_width
                end
            end
        end
    end

    return panel
end

function ui_onTalkToPlayer(player, talking_to, id)
    local talk_char = id:sub(-1)
    Temp_State.talking_to = nil
    local is_number = tonumber(talk_char)

    local talk_about = "cards"
    if is_number ~= nil then
        giveHintNumber(talking_to, is_number)
        talk_about = NUMBER_STRINGS[is_number]
    else
        giveHintColors(talking_to, COLOR_MASKS[talk_char])
        talk_about = ui_textBBCodeColored(
            COLOR_STRINGS[talk_char],
            COLOR_STRINGS[talk_char]
        )
    end

    local speaker = ui_playerNameBBCodeColored(player.color)
    local listener = ui_playerNameBBCodeColored(talking_to)

    broadcastToAll(
        speaker .. " told " ..
        listener .. " about their " ..
        talk_about .. "(s)"
    )

    useHintToken()(advanceTurnToken)
end

function ui_onTalkToToggle(player, toggle_is_on, id)
    if toggle_is_on == "False" or not toggle_is_on then
        Temp_State.talking_to = nil
    else 
        -- id = talk_to_<color>
        local color = id:sub(9)
        Temp_State.talking_to = color
    end
    ui_LoadUI()
end

function ui_askAfterRainbowPlayLocation(info)

    local vis = getTurnTokenLocation()

    if vis == "token_mat" then
        vis = table.concat(Player.getAvailableColors(), "|")
    end

    local panel = {
        tag="Panel",
        attributes={
            id="ui_askAfterRainbowPlayLocation",
            visibility=vis,
            rectAlignment="MiddleCenter",
            height=400,
            width=125 * #info.color_masks
        },
        children={}
    }

    local x_offset = 0
    for _,color_mask in ipairs(info.color_masks) do

        table.insert(panel.children, {
            tag="Panel",
            attributes={
                onClick="ui_onSelectCardPlayLocation(" .. info.card_num .. " " .. color_mask .. ")",
                offsetXY=x_offset .. " 0",
                rectAlignment="UpperLeft",
                width=120,
                height=400
            },
            children={{
                tag="Image",
                attributes={
                    image="card_front_" .. info.card_num .. colorCharFromMask(color_mask),
                    preserveAspect=true
                }
            }}
        })
        x_offset = x_offset + 125
    end

    return panel
end

function ui_onSelectCardPlayLocation(_, call_str)

    local tokens = {}
    for token in string.gmatch(call_str, "[^%s]+") do
        table.insert(tokens, token)
    end
    
    local num = tonumber(tokens[1])
    local color_mask = tonumber(tokens[2])

    local info = Temp_State.askAfterRainbowPlayLocation
    if info == nil then
        displayLog("Alert: ui_onSelectCardPlayLocation run without Temp_State set")
        return
    end

    info.callback(num, color_mask)
end

function ui_loadAssetBundle()

    if not Temp_State.isLoadedUiAssetBundle then
        Temp_State.isLoadedUiAssetBundle = true
        local assets = {}

        for color,_ in pairs(COLOR_MASKS) do
            table.insert(assets, {
                name="icon_" .. color,
                url=getHanabiIconUrl(color)
            })
        end
        for _,num in ipairs(NUMBERS_REP) do
            table.insert(assets, {
                name="icon_" .. num,
                url=getHanabiIconUrl(num)
            })
        end

        for color_char,_ in pairs(COLOR_MASKS) do
            for _,num in ipairs(NUMBERS_REP) do
                table.insert(assets, {
                    name="card_front_" .. num .. color_char,
                    url=generated_front_url_char(num, color_char)
                })
            end
        end

        for _,color_mask in pairs(COLOR_MASKS) do
            table.insert(assets, {
                name="card_back_no_number_" .. color_mask,
                url=generated_back_url(0, color_mask)
            })
            for num,_ in ipairs(NUMBERS_REP) do
                table.insert(assets, {
                    name="card_back_" .. num .. "_" .. color_mask,
                    url=generated_back_url(num, color_mask)
                })
            end
        end

        for num,_ in ipairs(NUMBERS_REP) do
            table.insert(assets, {
                name="card_back_" .. num .. "_no_mask",
                url=generated_back_url(num, 0)
            })
        end

        table.insert(assets, {
            name="perfect_score_spash",
            url=getHanabiPerfectScoreSplash()
        })

        UI.setCustomAssets(assets)
    end

end

function ui_clickPerfectScoreSpash()
    Temp_State.perfect_score_spash = false
    ui_LoadUI()
end

function ui_LoadUI()

    ui_loadAssetBundle()

    local game_rules = getCurrentGameRules()
    setTableImage(game_rules.include_rainbow, game_rules.rainbow_firework)

    local global_layout = ui_defaults()
    local parent_table = global_layout[2].children

    if Temp_State.perfect_score_spash then
        table.insert(global_layout, {
            tag="Panel",
            attributes={
                height="80%",
                width="45%",
                --color="rgba(1,1,1,0.5)"
                rectAlignment="MiddleCenter"
            },
            children={{
                tag="Image",
                attributes={
                    image="perfect_score_spash",
                    preserveAspect=true,
                    rectAlignment="MiddleCenter",
                    onClick="ui_clickPerfectScoreSpash"
                }
            }}
        })
    end
    
    local all_colors = Player.getAvailableColors()
    local turn_token_location = getTurnTokenLocation()

    if turn_token_location == "token_mat" then
        for _,player_color in ipairs(all_colors) do
            table.insert(parent_table, ui_greeting(player_color))
        end

        table.insert(parent_table, ui_gameRuleDialog())
    else
        local wait_colors = {}
        for _,player_color in ipairs(all_colors) do
            if player_color ~= turn_token_location then
                wait_colors = table.insert(wait_colors, player_color)
            end
        end
        wait_colors_str = table.concat(wait_colors, "|")
        table.insert(parent_table, ui_pleaseWait(wait_colors_str, turn_token_location))

        if turn_token_location ~= "unknown" then
            table.insert(parent_table, ui_activeTurnUi(turn_token_location))
        end

    end

    if Temp_State.askAfterRainbowPlayLocation ~= nil then
        table.insert(
            parent_table,
            ui_askAfterRainbowPlayLocation(
                Temp_State.askAfterRainbowPlayLocation
            )
        )
    end

    UI.setXmlTable(global_layout)

    -- table.insert(parent_table, {
    --     tag="Text",
    --     value="Hello World"
    -- })

    -- UI.setXmlTable(global_layout)

end

function getHanabiSwatchUrl(name)
    name = "" .. name
    return ASSET_URL .. "back_" .. name .. "_" .. ASSET_VERSION .. ".png"
end

function getHanabiIconUrl(name)
    name = "" .. name
    return ASSET_URL .. "icon_" .. name .. "_" .. ASSET_VERSION .. ".png"
end

function getHanabiPerfectScoreSplash()
    return ASSET_URL .. "transparent-fireworks-art.png"
end

function getTableImage(has_rainbow, has_rainbow_firework)
    local image_prefix = ASSET_URL .. "hanabi_layout_table_img_"
    local image_postfix = ASSET_VERSION .. ".png"
    local updated_img = ""
    if not has_rainbow then
        updated_img = image_prefix .. image_postfix
    elseif has_rainbow_firework then
        updated_img = image_prefix .. "wf_" .. image_postfix
    else
        updated_img = image_prefix .. "w_" .. image_postfix
    end

    return updated_img
end

function setTableImage(has_rainbow, has_rainbow_firework)

    local table = getObjectByName("table_surface")
    local table_data = getObjectByName("table_surface").getCustomObject()
    local new_img = getTableImage(has_rainbow, has_rainbow_firework)

    if new_img ~= table_data.image then
        table_data.image = new_img
        table.setCustomObject(table_data)
        table.reload()
    end

end