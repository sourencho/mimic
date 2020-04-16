pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--DATA

-- settings
slow_speed = 14 -- the larger the slower the npcs move
player_spr_offset = 32
splash = true
won = false
splash_inst_1 = "mimic animal movement"
splash_inst_2 = "pattern to take its form"
splash_keys_1 = "move"
splash_keys_2 = "\139\145\148\131"
splash_keys_3 = "restart"
splash_keys_4 = "\151"
won_text = "★ you win ★"
level_size = 16

-- tile flags
tree = 0
water = 1
rock = 2
win = 3
ground = 4
tiles = {tree, water, rock, ground}

-- actors
player_spr = 3
npcs = {
    {
        spr_n = 5, -- turtle
        pattern = {{-1, 0}, {-1, 0}, {-1, 0}, {1, 0}, {1, 0}, {1, 0}},
        abilities = {water},
    },
    {
        spr_n = 7, -- goat
        pattern = {{1, 0}, {1, 0}, {0, -1}, {0, -1}, {-1, 0}, {-1, 0}, {0, 1}, {0, 1}},
        abilities = {rock},
    },
    {
        spr_n = 23, -- butterfly
        pattern = {{0, 1}, {0, 1}, {0, -1}, {0, -1}},
        abilities = {tree},
    },
}

--sfx
player_sfx={}
player_sfx.move={}
player_sfx.move[ground]=1
player_sfx.move[tree]=3
player_sfx.move[rock]=4
player_sfx.move[water]=5

player_sfx.transform=2


-- player pattern
player_pattern = {}
player_pattern_i = 0
player_pattern_size = 26 -- must be 1 longer than the max npc pattern length
player_abilities = {ground}

-->8
-- Text

function hcenter(s)
  return 64-#s*2
end

function vcenter(s)
  return 61
end

-->8
-- GAME LOGIC

function make_actor(x, y, spr_n, pattern, abilities)
    a={}
    a.x = x
    a.y = y
    a.dx = 0
    a.dy = 0
    a.spr = spr_n
    a.pattern = pattern
    a.abilities = abilities

    -- animation
    a.frame = 0
    a.t = 0
    a.frames = 2
    a.flip_x = false

    add(actors, a)
    return a
end

function is_tile(tile_class,x,y)
    tile=mget(x,y)
    
    --find out if tile sprite is member of class
    return fget(tile,tile_class)
end

function has_ability(a, tile_ability)
    abl = a.abilities[0]
    abl_len=#a.abilities 
    for i=1,abl_len do
        if a.abilities[i] == tile_ability then
            return true
        end
    end
    return false
end

function can_move(x, y, a)
    if is_tile(win,x,y) then
        won = true
        sfx(12)
        return true
    end
    -- if moving to flagged tile check if had ability
    for t in all(tiles) do
        if(is_tile(t,x,y) and has_ability(a,t)) then
            return true
        end
    end
    return false
end

function move_actor(a)
    if not is_player(a) then 
        -- apply npc pattern
        if a.dx == 0 and a.dy == 0 then
            if tick % slow_speed == 0 then
                local move = a.pattern[(a.t % #a.pattern) + 1]
                a.dx = move[1]
                a.dy = move[2]
                a.t += 1
            end
        end
    end

    newx = a.x + a.dx
    newy = a.y + a.dy
    
    if can_move(newx, newy, a) then
        if(is_player_and_not_stationary(a)) then
            play_player_sfx("move")
        end

        a.x = mid(0,newx,15)
        a.y = mid(0,newy,15)

        if is_player(a) and (a.dx ~=0 or a.dy ~= 0) then 
            -- save player pattern
            player_pattern_i += 1        
            if player_pattern_i > player_pattern_size then
                player_pattern_i = 1
            end
            player_pattern[player_pattern_i][1] = a.dx;
            player_pattern[player_pattern_i][2] = a.dy;
        end
    else
        if (is_player_and_not_stationary(a)) then
            sfx(0)
        end
    end


    -- animation
    if a.dx ~= 0 or a.dy ~= 0 then
        a.frame += 1
        a.frame %= a.frames
        a.flip_x = a.dx > 0
    end

    a.dx = 0
    a.dy = 0
end

function play_player_sfx(action)
    if(action == "move") then
        sfx(player_sfx[action][pl.abilities[1]])
        return
    end
    sfx(player_sfx[action])
end


function is_player(a)
    return (#a.pattern == 0)
end

function is_player_and_not_stationary(a)
    return is_player(a) and not (newx==a.x and newy==a.y)
end

function init_actors(l)
    for n in all(npcs) do
        local n_pos = find_sprite(l, n.spr_n)
        make_actor(n_pos[1], n_pos[2], n.spr_n, n.pattern, n.abilities)
    end
end

-->8
--PLAYER

function init_player(l)
    local player_pos = find_sprite(l, player_spr)
    pl = make_actor(player_pos[1], player_pos[2], player_spr, {}, player_abilities) -- player
    reset_player_pattern()
end

function player_input()
    if (btnp(0)) pl.dx = -1
    if (btnp(1)) pl.dx = 1
    if (btnp(2)) pl.dy = -1
    if (btnp(3)) pl.dy = 1
    if (btnp(5)) then 
        splash = not splash
        won = false
    end
end

function reset_player_pattern()
    player_pattern={}
    for i=0,player_pattern_size do
        add(player_pattern, {0,0})
    end
end

-->8
--GAME MECHANIC

function pattern_match()
    for a in all(actors) do
        if not is_player(a) then
            if contains_pattern(player_pattern, a.pattern) then
                if(not (pl.abilities[1] == a.abilities[1])) then
                    play_player_sfx("transform")
                end
                pl.abilities = a.abilities
                pl.spr = a.spr + player_spr_offset
                reset_player_pattern()
            end
        end
    end
end

function contains_pattern(sup_pattern, sub_pattern)
    local sup_len = #sup_pattern
    local sub_len = #sub_pattern
    for i=1,sup_len do
        local out = true
        for j=1,sub_len do
            local sup_move = sup_pattern[((i+j-1) % sup_len) + 1]
            local sub_move = sub_pattern[j]
            out = out and (sup_move[1] == sub_move[1] and sup_move[2] == sub_move[2]) 
        end
        if out then return true end
    end
    return false
end

-->8
-- LEVEL

-- Given a level number will return the (x,y) position of the sprite
function find_sprite(l, spr_n)
    for i=0,level_size do
		for j=0,level_size do
			if mget(i+((l+1)*level_size),j) == spr_n then
				return {i, j}
			end
		end
	end
end

-->8
-- DRAW

function draw_splash()
    cls() 
    map(0,48,0,0,16,16)
    print(splash_inst_1, hcenter(splash_inst_1), 45, 3)
    print(splash_inst_2, hcenter(splash_inst_2), 55, 3)

    print(splash_keys_1, hcenter(splash_keys_1), 70, 8)
    print(splash_keys_2, 48, 80, 8)

    print(splash_keys_3, hcenter(splash_keys_3), 95, 8)
    print(splash_keys_4, 60, 105, 8)
end

function draw_won()
    cls()
    print(won_text, 38, vcenter(won_text)-30, 9)
    print(won_text, 38, vcenter(won_text)-20, 10)
    print(won_text, 38, vcenter(won_text)-10, 11)
    print(won_text, 38, vcenter(won_text), 12)
    print(won_text, 38, vcenter(won_text)+10, 13)
    print(won_text, 38, vcenter(won_text)+20, 14)
    print(splash_keys_3, hcenter(splash_keys_3), 95, 8)
    print(splash_keys_4, 60, 105, 8)
end

function draw_level(l)
    map(l*level_size, 0, 0, 0, level_size, level_size)
end

function draw_actor(a)
    spr(a.spr + a.frame, a.x*8, a.y*8, 1, 1, a.flip_x)
end

-->8
-- GAME LOOP

function init_level(l)
    restart = false
    tick = 0
    actors = {}
    level = l
    init_actors(l)
    init_player(l)
end

function _init()
    init_level(0)
end

function _update()
    player_input()
    if won then 
        return
    end
    if splash then
        init_level(level)
        return
    end
    foreach(actors, move_actor)
    pattern_match()
    tick += 1
end

function _draw()
    if splash then
        draw_splash()
    elseif won then
        draw_won()
    else
        cls()
        draw_level(level)
        foreach(actors, draw_actor)
    end
end

__gfx__
00000000000000000000000000000000000000000000b00b00b0000b111111111111111111111111111111111111111100000000000000000000000000000000
000000000808000000000000088888800888888000003330000333301111111d111111d111133111111111111111111100000000000000000000000000000000
00700700888880000000000008f8f8800888888000033933003393331212111d212111d1111b3111111555111111111100000000000000000000000000000000
0007700088888000000000000888888008f8f8800bb33393bb3339331dddddddddddddd111333311115565111111111100000000000000000000000000000000
00077000088800000000000008888880088888800bb33393bb3339331dd1dddddd1dddd111333b11115555511111111100000000000000000000000000000000
007007000080000000000000088888800888888000033933003393331221dddd221dddd113b33331155556511111111100000000000000000000000000000000
000000000000000000000000088888800888888000003330000333301111d11d111d11d113333331156555511111111100000000000000000000000000000000
00000000000000000000000000000000000000000000b00b00b0000b11112112111d21d211144111111111111111111100000000000000000000000000000000
000000000000000000000000000000000119900011111111111111111111111111111111cccccccc111111110000000000000000000000000000000000000000
00000000000000000000000000000000011990001111111111111111111aaa1111111111cccccccc1111a1110000000000000000000000000000000000000000
00000000000000000000000000000000000990001111111111ee111111aaaaa111aaaaa1cccccccc111aa9110000000000000000000000000000000000000000
0000000000000000000000000000000000000000e1111ee11e11e11e191aaa11191aaa11cccccccc11aaa9910000000000000000000000000000000000000000
00000000000000000000000000000000011000001e11e11ee1111ee11199999111999991cccccccc111999110000000000000000000000000000000000000000
000000000000000000000000000000000119900011ee111111111111191aaa11191aaa11cccccccc111191110000000000000000000000000000000000000000
0000000000000000000000000000000000099000111111111111111111aaaaa111aaaaa1cccccccc111111110000000000000000000000000000000000000000
00000000000000000000000000000000000000001111111111111111111aaa1111111111cccccccc111111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000b00b00b0000b111111111111111100000000000000000000000000000000000000000000000000000000
011100000111000011111110111110000110000000008880000888801111111d111111d100000000000000000000000000000000000000000000000000000000
011110001111000011111110111110000110000000088988008898881818111d818111d100000000000000000000000000000000000000000000000000000000
01199901119990001199999000999990011990000bb88898bb8889881dddddddddddddd100000000000000000000000000000000000000000000000000000000
01199991199990001199999000999990011990000bb88898bb8889881dd1dddddd1dddd100000000000000000000000000000000000000000000000000000000
011999999999900011990000000119900119900000088988008898881881dddd881dddd100000000000000000000000000000000000000000000000000000000
011990999919900011990000000119900119900000008880000888801111d11d111d11d100000000000000000000000000000000000000000000000000000000
01199009911990001199000000011990011990000000b00b00b0000b11118118111d81d800000000000000000000000000000000000000000000000000000000
01199000011990001199000000011990011990001111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
01199000011990001199000000011990011990001111111111111111111888111111111100000000000000000000000000000000000000000000000000000000
01199000011990001199000000011990011990001111111111881111118888811188888100000000000000000000000000000000000000000000000000000000
01199000011990001199111011111990011990008111188118118118191888111918881100000000000000000000000000000000000000000000000000000000
01199000011990001199111011111990011990001811811881111881119999911199999100000000000000000000000000000000000000000000000000000000
01199000011990000099999000999990011990001188111111111111191888111918881100000000000000000000000000000000000000000000000000000000
00099000000990000099999000999990000990001111111111111111118888811188888100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001111111111111111111888111111111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000021242021242224200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000030343031343234100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000080000000000000104100000000000000000000000000002082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19090b0b0b0b0b1a0b0b0b0b0b0b090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19090b0b0b0b0b0b0b0b0b0b0b0b090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1919191919191919191919191919191900000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090b0909090b0a0a0a090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090b0b09090b0a0a0a090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090b0b0a0a0a0a0a09090900001700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090b0b0a0a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090909090909090b0a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090b0b0b0b0b0b0b090a0a0a0a0a0a0900000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090b09090909090b090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090b09090909090b090a0a0a0a0a090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090b09090909090b0909090b0b09090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090b09090909090b0909090b0b09090900030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400000653007500005002640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000413006020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001f44026430274202e2202e210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003a02023010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001062010600156101060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f74013730167200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003175038740387303872038720387100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
