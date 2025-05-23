pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- endless fall game
-- sprite assignments:
-- player: sprite 1
-- coins: sprite 10
-- hazards: sprite 0

-- game states
menu = 0
playing = 1
game_over = 2
high_scores = 3

-- difficulty levels
easy = 1
medium = 2
hard = 3

function _init()
				cartdata("endless_fall_data")
    game_state = menu
    high_scores = {0,0,0} -- for each difficulty
    load_high_scores()
    selected_menu = 1 -- 1=play, 2=high scores
    selected_difficulty = medium
    
    -- initialize game variables
    init_game()
end

function init_game()
    score = 0
    fall_time = 0
    multiplier = 1
    player_facing_left = true
    
    -- player
    player = {
        x = 60,
        y = 10,
        w = 8,
        h = 8,
        spd = 2
    }
    
    -- objects
    coins = {}
    hazards = {}
    
    -- spawn timers
    coin_timer = 0
    hazard_timer = 0
    
    -- set difficulty based parameters
    if selected_difficulty == easy then
        base_speed = 1
        hazard_chance = 0.3
    elseif selected_difficulty == medium then
        base_speed = 1.5
        hazard_chance = 0.5
    else -- hard
        base_speed = 2
        hazard_chance = 0.7
    end
    
    -- backgrounds
    clouds = {}
    for i=1,10 do
        add(clouds, {
            x = rnd(128),
            y = rnd(128),
            spd = 0.5 + rnd(0.5)
        })
    end
end

function load_high_scores()
    if dget(0) ~= nil then
        high_scores[easy] = dget(0) or 0
        high_scores[medium] = dget(1) or 0
        high_scores[hard] = dget(2) or 0
    end
end

function save_high_scores()
    dset(0, high_scores[easy])
    dset(1, high_scores[medium])
    dset(2, high_scores[hard])
end

function _update()
    if game_state == menu then
        update_menu()
    elseif game_state == playing then
        update_game()
    elseif game_state == game_over then
        if btnp(🅾️) then
            game_state = menu
        end
    elseif game_state == high_scores then
        if btnp(🅾️) then
            game_state = menu
        end
    end
end

function update_menu()
    -- menu navigation
    if btnp(⬆️) then
        selected_menu = max(1, selected_menu - 1)
        sfx(2)
    elseif btnp(⬇️) then
        selected_menu = min(2, selected_menu + 1)
        sfx(2)
    end
    
    -- in play menu, change difficulty
    if selected_menu == 1 then
        if btnp(⬅️) then
            selected_difficulty = max(easy, selected_difficulty - 1)
            sfx(2)
        elseif btnp(➡️) then
            selected_difficulty = min(hard, selected_difficulty + 1)
            sfx(2)
        end
    end
    
    -- select menu option
    if btnp(🅾️) then
        sfx(0)
        if selected_menu == 1 then
            game_state = playing
            init_game()
        else
            game_state = high_scores
        end
    end
end

function update_game()
    -- update fall time and multiplier (adjusted for 30fps)
    fall_time += 1
    multiplier = 1 + flr(fall_time / 500) -- adjusted for 30fps
    
    -- player movement and facing direction
    if btn(⬅️) then 
        player.x -= player.spd
        player_facing_left = true
    end
    if btn(➡️) then 
        player.x += player.spd
        player_facing_left = false
    end
    
    -- keep player on screen
    player.x = mid(0, player.x, 120)
    
    -- spawn coins (from bottom)
    coin_timer -= 1
    if coin_timer <= 0 then
        local move_diagonal = rnd(1) < 0.3 -- 30% chance to move diagonal
        add(coins, {
            x = rnd(128),
            y = 128, -- spawn at bottom
            spd_y = -(base_speed + rnd(1)), -- move upward
            spd_x = move_diagonal and (rnd(2)-1) or 0 -- left/right if diagonal
        })
        coin_timer = 20 + rnd(30)
    end
    
    -- spawn hazards (from bottom)
    hazard_timer -= 1
    if hazard_timer <= 0 and rnd(1) < hazard_chance then
        local move_diagonal = rnd(1) < 0.4 -- 40% chance to move diagonal
        add(hazards, {
            x = rnd(128),
            y = 128, -- spawn at bottom
            spd_y = -(base_speed + 0.5 + rnd(1.5)), -- move upward
            spd_x = move_diagonal and (rnd(2)-1) or 0 -- left/right if diagonal
        })
        hazard_timer = 20 + rnd(40)
    end
    
    -- update coins
    for c in all(coins) do
        c.y += c.spd_y
        c.x += c.spd_x
        if c.y < -8 or c.x < -8 or c.x > 128 then
            del(coins, c)
        elseif collides(player, c) then
            score += 10 * multiplier
            del(coins, c)
            sfx(0)
        end
    end
    
    -- update hazards
    for h in all(hazards) do
        h.y += h.spd_y
        h.x += h.spd_x
        if h.y < -8 or h.x < -8 or h.x > 128 then
            del(hazards, h)
        elseif collides(player, h) then
            -- update high score if needed
            if score > high_scores[selected_difficulty] then
                high_scores[selected_difficulty] = score
                save_high_scores()
            end
            game_state = game_over
            sfx(1)
        end
    end
    
    -- update clouds (parallax background)
    for c in all(clouds) do
    c.y -= c.spd * 0.6  -- move faster and upward
    if c.y < -10 then
        c.y = 138
        c.x = rnd(128)
    end
end

end

function _draw()
    cls(12) -- sky blue background
    
    if game_state == menu then
        draw_menu()
    elseif game_state == playing then
        draw_game()
    elseif game_state == game_over then
        draw_game_over()
    elseif game_state == high_scores then
        draw_high_scores()
    end
end

function draw_menu()
    -- title
    print("endless fall", 30, 20, 7)
    print("avoid hazards", 30, 30, 7)
    print("collect coins", 30, 40, 7)
    
    -- play option
    local play_color = selected_menu == 1 and 11 or 7
    print("> play", 40, 60, play_color)
    
    -- difficulty indicator
    local diff_colors = {[easy]=11, [medium]=9, [hard]=8}
    local diff_names = {[easy]="easy", [medium]="medium", [hard]="hard"}
    print("difficulty: "..diff_names[selected_difficulty], 
          30, 70, diff_colors[selected_difficulty])
    
    -- high scores option
    local hs_color = selected_menu == 2 and 11 or 7
    print("> high scores", 40, 80, hs_color)
    
    -- controls
    print("arrows: move/select", 20, 100, 6)
    print("🅾️: confirm", 20, 108, 6)
end

function draw_game()
    -- draw clouds
    for c in all(clouds) do
        circfill(c.x, c.y, 5, 7)
        circfill(c.x+4, c.y, 5, 7)
    end
    
    -- draw player (flipped when facing right)
    if player_facing_left then
        spr(1, player.x, player.y)
    else
        spr(1, player.x, player.y, 1, 1, true) -- flipped
    end
    
    -- draw coins
    for c in all(coins) do
        spr(10, c.x, c.y)
    end
    
    -- draw hazards
    for h in all(hazards) do
        spr(0, h.x, h.y)
    end
    
    -- draw ui
    print(score, 2, 2, 0) -- black, minimal

end

function draw_game_over()
    -- draw game over screen
    print("game over!", 40, 40, 8)
    print("score: "..score, 40, 50, 7)
    
    -- show if new high score
    if score == high_scores[selected_difficulty] then
        print("new high score!", 30, 60, 11)
    end
    
    local diff_names = {[easy]="easy", [medium]="medium", [hard]="hard"}
    print("difficulty: "..diff_names[selected_difficulty], 30, 70, 7)
    
    print("press 🅾️ to continue", 20, 90, 7)
end

function draw_high_scores()
    cls(12)
    print("high scores", 40, 20, 7)
    
    local diff_names = {[easy]="easy", [medium]="medium", [hard]="hard"}
    local diff_colors = {[easy]=11, [medium]=9, [hard]=8}
    
    for i=1,3 do
        print(diff_names[i]..": "..high_scores[i], 40, 40 + i*10, diff_colors[i])
    end
    
    print("press 🅾️ to return", 30, 90, 7)
end

function collides(a, b)
    return a.x < b.x+8 and
           a.x+a.w > b.x and
           a.y < b.y+8 and
           a.y+a.h > b.y
end
-->8
--player

		
__gfx__
80000008000666000006660000066600000666000006660000066600000000000000000000000000000000000000000000000000000000000000000000000000
05500550006ddd60006ddd60006ddd60006ddd60006ddd60006ddd60000000000000000000000000000aa0000000000000000000000000000000000000000000
0888888000d77cd600d77cd600d77cd600d77cd600d77cd600d77cd600000000000000000000000000aa9a000000000000000000000000000000000000000000
0058850000dcccd600dcccd600dcccd600dcccd600dcccd600dcccd60000000000000000000000000aa9aaa00000000000000000000000000000000000000000
00888800006ddd60006ddd60006ddd60006ddd60006ddd60006ddd600000000000000000000000000aa9a9a00000000000000000000000000000000000000000
0550055000666d6000666d6000666d6000666d6000666d6000666d6000000000000000000000000000aa9a000000000000000000000000000000000000000000
08000080006d6660006d6660006d6660006d6660006d6660006d6660000000000000000000000000000aa0000000000000000000000000000000000000000000
80000008006000600060006000600060006000600060006000600060000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa9a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa9aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa9a9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa9a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccc
cc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc0c0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc0c0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc0c0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6ddd6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6dc77dcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6dcccdcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6ddd6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6d666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666d6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6ccc6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccc8cccccc8cc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc55cc55ccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccc77777888888cccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc77777775885cccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc7777777788887cccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777775577557cccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777778777787ccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777787777778cccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777cccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777cccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc7777777777777ccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc77777777777cccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccc777777777cccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc7777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc77777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777ccccccccccccccccccccccc
cccccccccccccc777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777cccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777cccccccccccccc7777777
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777cccccccccccccc77777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccc777777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777
ccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777
cccccccccccccccccccccccccccccccccccccccc77777777777cccccaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777
ccccccccccccccccccccccccccccccccccccccc7777777777777cccaa9accccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777
cccccccccccccccccccccccccccccccccccccc777777777777777caa9aaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777
cccccccccccccccccccccccccccccccccccccc777777777777777caa9a9accccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777
cccccccccccccccccccccccccccccccccccccc777777777777777ccaa9accccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777
cccccccccccccccccccccccccccccccccccccc777777777777777cccaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777
cccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc7777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc7777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777777777777777ccccccccc8cccccc8cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777777777777777cccccccccc55cc55ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777777777777777cccccccccc888888ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc777777777777777ccccccccccc5885ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccc
ccccccccccc7777777777777cccccccccccc8888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccc
cccccccccccc77777777777cccccccccccc55cc55cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777cccccccccccccc
ccccccccccccc777777777ccccccccccccc8cccc8ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccc
cccccccccccccccccccccccccccccccccc8cccccc8cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777ccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777cccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0001010100010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
