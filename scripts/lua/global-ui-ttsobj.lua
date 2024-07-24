function ui_loadScoreUI()
    local score_ob = getObjectByName("score-string")
    local score = getCurrentScore()

    if score == 0 then
        score_ob.UI.setXml("")
        return
    end

    local rules = getCurrentGameRules()

    logs(">>>>> #getFuseTokens()", #getFuseTokens())
    local font_color = "#ffffff"
    if  score > 29 or
        (   (not rules.include_rainbow or
            not rules.rainbow_firework) and 
            score > 24
        )
    then
        font_color = "#339900"
    elseif #availableFuseTokens() < 1 then
        font_color = "#cc3300"
    end

    local text_ren = {{
        tag="Text",
        value="<b>SCORE: " .. score .. "</b>"
    }}
    score_ob.UI.setXmlTable({{
        tag="Defaults",
        children={{
            tag="Text",
            attributes={
                color=font_color,
                fontSize=200,
                outline="#000000",
                --outlineSize="1 1",
                alignment="MiddleCenter"
            }
        },{
            tag="Panel",
            attributes={
                height=1700,
                width=2300,
                position="0 0 -100",
            }
        }}
    },{
        tag="Panel",
        attributes={
            visibility="Red|Yellow|Green|Purple|Grey|Black",
        },
        children=text_ren
    },{
        tag="Panel",
        attributes={
            visibility="Teal|Blue",
            rotation="0 0 180"
        },
        children=text_ren
    }})
end

function ui_cardUI(card, hidden_from)
    -- front_number
    -- front_color_mask
    -- back_number
    -- back_color_mask
    local info = JSON.decode(card.memo)
    local card_num = tonumber(info.back_number)
    local card_color_mask = tonumber(info.back_color_mask)
    local images = {}

    local visibility = table.concat(
        filterArray(Player.getAvailableColors(), function(c)
            return c ~= hidden_from
        end),
        "|"
    )

    if card_num ~= 0 then
        table.insert(images, {
            tag="Image",
            attributes={
                image="icon_" ..  card_num,
                rectAlignment="MiddleRight",
                preserveAspect=true,
                visibility=visibility
            }
        })
    end

    if card_color_mask ~= 0 then
        table.insert(images, {
            tag="Image",
            attributes={
                image="icon_" ..  colorCharFromMask(card_color_mask),
                rectAlignment="MiddleLeft",
                preserveAspect=true,
                visibility=visibility
            }
        })
    end

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
    }, {
        tag="Panel",
        attributes={
            height="80",
            width="180",
            position="0 -210 0"
        },
        children=images
    }}
end