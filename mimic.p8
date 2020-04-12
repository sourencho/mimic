pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--DATA

-- settings
slow_speed = 14 -- the larger the slower the npcs move

-- constants
tick = 0
actors = {}

-- sprites
player_spr = 3
turtle_spr = 5
worm_spr = 21
butter_spr = 23

--flags
tree=0
water=1
rock=2
win=3
clearing=4

-- start positions
player_pos = {1, 14}
turtle_pos = {10, 3}
worm_pos = {9, 10}
butter_pos = {1, 7}

-- npc patterns
turtle_pattern = {
    {-1, 0}, {-1, 0}, {-1, 0},
    {1, 0}, {1, 0}, {1, 0}}
worm_pattern = {
    {1, 0}, {1, 0},
    {0, -1}, {0, -1}, 
    {-1, 0}, {-1, 0}, 
    {0, 1}, {0, 1}}
butter_pattern = {
    {0, 1}, {0, 1},
    {0, -1}, {0, -1}}

-- npc abilities
worm_abilities = {
    rock
}
turtle_abilities={
    water
}
butter_abilities={
    tree
}

-- player pattern
player_pattern = {}
player_pattern_i = 0
player_pattern_size = 13 -- must be 1 longer than the max npc pattern length
player_abilities= {}




-->8
-- MAP

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
    -- if moving to flagged tile check if had ability
    if(is_tile(clearing,x,y)) then
        return true
    end

    if(is_tile(tree,x,y) and has_ability(a,tree)) then
        return true
    elseif(is_tile(water,x,y) and has_ability(a,water)) then
        return true
    elseif(is_tile(rock,x,y) and has_ability(a,rock)) then
        return true
    end

    return false
end

function move_actor(a)
    local is_player = (#a.pattern == 0)

    if not is_player then 
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

    newx =  a.x + a.dx
    newy = a.y + a.dy
    
    if can_move(newx, newy, a) then
        a.x = mid(0,newx,15)
        a.y = mid(0,newy,15)

        if is_player and (a.dx ~=0 or a.dy ~= 0) then 
            -- save player pattern
            player_pattern_i += 1        
            if player_pattern_i > player_pattern_size then
                player_pattern_i = 1
            end
            player_pattern[player_pattern_i][1] = a.dx;
            player_pattern[player_pattern_i][2] = a.dy;
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

function draw_actor(a)
    spr(a.spr + a.frame, a.x*8, a.y*8, 1, 1, a.flip_x)
end




-->8
--PLAYER
function init_player()
    pl = make_actor(player_pos[1], player_pos[2], player_spr, {}, player_abilities) -- player
    init_player_pattern()
end

function player_input()
    if (btnp(0)) pl.dx = -1
    if (btnp(1)) pl.dx = 1
    if (btnp(2)) pl.dy = -1
    if (btnp(3)) pl.dy = 1
end

function find_player(spr_n)
    for i=0,16 do
		for j=0,16 do
			if mget(i,j) == spr_n then
                -- todo: erase player from map if possible
                -- or find another solution for agent positions
                -- maybe a second layer of the map or define in code?
				return i, j
			end
		end
	end
end

function init_player_pattern()
    player_pattern={}
    for i=0,player_pattern_size do
        add(player_pattern, {0,0})
    end
end




-->8
--GAME MECHANIC

function pattern_match()
    for a in all(actors) do
        local is_player = (#a.pattern == 0)
        if not is_player then
            if contains_pattern(player_pattern, a.pattern) then
                add(pl.abilities,a.abilities[1])
                pl.spr=a.spr
                init_player_pattern()
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
-- GAME LOOP

function _init()
    init_player()
    make_actor(turtle_pos[1], turtle_pos[2], turtle_spr, turtle_pattern, turtle_abilities)
    make_actor(worm_pos[1], worm_pos[2], worm_spr, worm_pattern, worm_abilities)
    bf = make_actor(butter_pos[1], butter_pos[2], butter_spr, butter_pattern, butter_abilities)
end

function _update()
    player_input()
    foreach(actors, move_actor)
    pattern_match()
    tick += 1
end

function _draw()
    cls()
    map(0,0,0,0,16,16)
    foreach(actors, draw_actor)

    -- debugging area
    -- print("is_able:"..tostr(is_able),0,0,7)
    -- print("tile:"..mget(newx,newy),0,10,7)
    -- print("istile:"..tostr(fget(mget(newx,newy),tree)),0,20,7)
    -- print("ab1:"..tostr(pl.abilities[1]))
    -- print("ab2:"..tostr(pl.abilities[2]))
    -- print("len"..tostr(#(pl.abilities)))
end

__gfx__
00000000000000000000000000000000000000000000b00b00b0000b00000000000000003331133333333333cccccccccccccccc000000000000000000000000
0000000008080000000000000888888008888880000033300003333000099000009990003313313333111133cccc77ccccccc77c000000000000000000000000
00700700888880000000000008f8f8800888888000033933003393330099990909999909331b311331155513c77cccc7c7cc7ccc000000000000000000000000
0007700088888000000000000888888008f8f8800bb33393bb33393309d999999d99999931333311315565137cc7cc7ccc77cccc000000000000000000000000
00077000088800000000000008888880088888800bb33393bb333933099999999999999911333b1131555551cccc77cccccccccc000000000000000000000000
00700700008000000000000008888880088888800003393300339333009999090999990913b3333131555651c7cccccccccc77c7000000000000000000000000
0000000000000000000000000888888008888880000033300003333000099000009990001333333131655555cc7cc77c77cccc7c000000000000000000000000
00000000000000000000000000000000000000000000b00b00b0000b00000000000000001114411111155555cccccccccccccccc000000000000000000000000
dddddddd00000000000000003333333300000000000000000000000000000000000000000000000000000000cccccccc00000000000000000000000000000000
dddddddd00000000000000003333a333000000000000000000000000000aaa00000000000000000000000000cccccccc00000000000000000000000000000000
dddddddd0000000000000000333aa933000000000000000000ee000000aaaaa000aaaaa00000000000000000cccccccc00000000000000000000000000000000
dddddddd000000000000000033aaa99300000000e0000ee00e00e00e090aaa00090aaa000000000000000000cccccccc00000000000000000000000000000000
dddddddd000000000000000033399933000000000e00e00ee0000ee000999990009999900000000000000000cccccccc00000000000000000000000000000000
dddddddd0000000000000000333393330000000000ee000000000000090aaa00090aaa000000000000000000cccccccc00000000000000000000000000000000
dddddddd00000000000000003333333300000000000000000000000000aaaaa000aaaaa00000000000000000cccccccc00000000000000000000000000000000
dddddddd000000000000000033333333000000000000000000000000000aaa00000000000000000000000000cccccccc00000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000080000000000000104020200000000000008000000000000000200000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909232323232313232323232323090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909232323232323232323232323090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090923090909230a0a0a090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090923230909230a0a0a090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090909090923230a0a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090909090923230a0a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909230a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0923232323232323090a0a0a0a0a0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0923090909090923090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0923090909090923090a0a0a0a0a090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0923090909090923090909232309090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0923090909090923090909232309090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
