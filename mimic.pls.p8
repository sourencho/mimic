pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- mimic v0.6.0
-- by sourencho

VERSION = "V0.6.0"

-- DATA

-- SETTINGS

start_level = 7
last_level = 15
level_count = last_level + 1
skip_tutorial = true
skip_levels = {4, 9, 13, 14}
secret_level = 7
got_secret = false

tutorial_level = 30
tutorial_speed = 20

slow_speed = 20 -- the larger the slower the npcs move
tile_slow_speed = 2 -- the larger the slower the tiles animate
player_spr_offset = 32

splash_inst_1 = "take the form of an animal"
splash_inst_2 = "by mimicking its movement"
splash_keys_3 = "start \151"

level_size = 16
ACTOR_ID_INDEX = 0

--[[
debug_mode = false
DEBUG_OUT_FILE = "out.txt"
debug = "DEBUG\n"
--]]

-- spr numbers 2x2 matrix to support large sprites
fish_spr = {{7, nil}, {nil, nil}}
sheep_spr = {{39, nil}, {nil, nil}}
butter_spr = {{21, nil}, {nil, nil}}
bird_spr = {{23, nil}, {nil, nil}}
vishab_spr = {{9, 11}, {nil, nil}}
aralez_spr = {{25, 27}, {nil, nil}}

-- MAP AND TILES
-- tile flag values
tree = 1
water = 2
rock = 4
win = 8
ground = 16
rock_small = 36
cloud = 64
tree_small = 33
cloud_small = 96
teru = 128
actor_reg_tile = 255
actor_sml_tile = 254 -- assumes this spr_n == actor.spr_n + 1
player = 253
secret_win = 40
flower1 = 19
flower2 = 20
flower3 = 21
flower4 = 22
flower5 = 23
grass1 = 16
grass2 = 16


-- tile spr values
ground_spr = 65

static_tiles= {tree, water, rock, ground, win, cloud, teru, 
               secret_win, flower1, flower2, flower3, flower4, flower5, grass1, grass2}
dynamic_tiles = {rock_small, tree_small, cloud_small}

tile_display_names = {  
    [tree] = "trees",
    [tree_small] = "trees",
    [water] = "water",
    [rock] = "rocks",
    [rock_small] = "rocks",
    [ground] = "ground",
    [cloud] = "cloud",
    [cloud_small] = "cloud",
    [teru] = "manish",
    [flower1] = "ground",
    [flower2] = "ground",
    [flower3] = "ground",
    [flower4] = "ground",
    [flower5] = "ground",
    [grass1] = "ground",
    [grass2] = "ground"
}

UP =    {x= 0, y =-1}
RIGHT = {x= 1, y = 0}
DOWN =  {x= 0, y = 1}
LEFT =  {x=-1, y = 0}
OTHER = {x=-1, y =-1}
STILL = {x= 0, y = 0}

DELTAS = {UP, DOWN, LEFT, RIGHT}

def_pal = {1,2,3,4,5,6,7,8,9,10,"-5",12,13,14,15}
red_pal = {1,2,3,4,5,8,7,8,8,10,8   ,8,8,8,8}

-- GAME

-- sprite values of tiles
level_static_tiles = {}
level_dynamic_tiles = {}

game = {
    state = "splash",
    level = tutorial_level,
    tick = 0,
    level_end_tick = 0,
    restart_level = false,
    state_change_tick = 0,
    is_stuck = false,
    stuck_tick = 0,
}

-- TUTORIAL

TUTORIAL_MOVES = {RIGHT, RIGHT, RIGHT, DOWN, DOWN, DOWN, UP, UP, UP, 
                    STILL, STILL, STILL, RIGHT, DOWN, STILL, STILL, STILL, STILL}
tutorial_move_index = 1
tutorial_skippable = false

-- ACTORS
npcs = {
    {
        spr_n = fish_spr,
        pattern = {LEFT, LEFT, LEFT, RIGHT, RIGHT, RIGHT},
        move_abilities = {water, win},
        push_abilities = {},
        display_name = "fish",
        shape = {1, 1}
    },
    {
        spr_n = sheep_spr,
        pattern = {UP, UP, RIGHT, LEFT, DOWN, DOWN},
        move_abilities = {rock, rock_small, win},
        push_abilities = {},
        display_name = "goat",
        shape = {1, 1}
    },
    {
        spr_n = butter_spr,
        pattern = {UP , UP, UP, DOWN, DOWN, DOWN},
        move_abilities = {tree, tree_small, win, secret_win},
        push_abilities = {},
        display_name = "butterfly",
        shape = {1, 1}
    },
    {
        spr_n = bird_spr,
        pattern = {RIGHT, UP, RIGHT, LEFT , DOWN, LEFT},
        move_abilities = {cloud, cloud_small, win},
        push_abilities = {},
        display_name = "bird",
        shape = {1, 1}
    },
    {
        spr_n = vishab_spr,
        pattern = {UP, UP, UP, DOWN, DOWN, DOWN},
        move_abilities = {teru},
        push_abilities = {tree_small, rock_small},
        display_name = "vishab",
        shape = {2, 1}
    },
    {
        spr_n = aralez_spr,
        pattern = {UP, UP, RIGHT, LEFT, DOWN, DOWN},
        move_abilities = {teru},
        push_abilities = {tree_small, rock_small},
        display_name = "aralez",
        shape = {2, 1}
    },
}

-- PATTERNS

animal_big_patterns = {
    -- {a, b} = {
    --      [12] = { {dx1, dy1}, {dx2, dy2} },
    --      [21] = { ... },
    -- } 
}

-- == SFX ==

player_sfx={}
player_sfx.move={}
player_sfx.move[ground]=1
player_sfx.move[flower1]=1
player_sfx.move[flower2]=1
player_sfx.move[flower3]=1
player_sfx.move[flower4]=1
player_sfx.move[flower5]=1
player_sfx.move[tree]=3
player_sfx.move[tree_small]=3
player_sfx.move[rock]=4
player_sfx.move[rock_small]=4
player_sfx.move[water]=5
player_sfx.move[cloud]=16
player_sfx.move[cloud_small]=16
player_sfx.transform=2
die_sfx=8
change_pattern_sfx = 10
transform_sfx = 2

function play_player_sfx(action)
    for p in all(get_players()) do
        if(action == "move") then
            sfx(player_sfx[action][get_dynamic_or_static_tile_class(p.pos)])
        else
            sfx(player_sfx[action])
        end
    end
end

-- == PARTICLES == 

-- particles
particles = {
    --SCHEMA
    --{
    --    pos = {x, y},
    --    col = c,
    --    draw_fn = foobar(pos, curr_tick, start_tick, end_tick),
    --    start_tick = 0,
    --    end_tick = 0,
    --    meta_data = {}
    --}
}
perm_particles = {}

-- == UTIL ==

function pick(ar,k) k=k or #ar return ar[flr(rnd(k))+1] end

function _all(xs, cond)
    for x in all(xs) do
        if (not cond(x)) return false
    end
    return true
end

function _any(xs, cond)
    for x in all(xs) do
        if (cond(x)) return true
    end
    return false
end

-- ternary operator
function tern(cond, T, F)
    if cond then return T else return F end
end

-- inplace deduplicate
function table_dedup(x)
    result = {}
    index = {}
    for t in all(x) do
        if not index[t] then
            index[t] = true
            add(result, t)
        end
    end
    return result
end

function table_concat(t1, t2)
    local tc = {}
    for i=1,#t1 do
        tc[i] = t1[i]
    end
    for i=1,#t2 do
        tc[#t1+i] = t2[i]
    end
    return tc
end

function flat_table_equal(t1, t2) 
    if (#t1 != #t2) return false
    for i=1,#t1 do
        if (t1[i] != t2[i]) return false
    end
    return true
end

function copy_table(table)
    copy = {}
    for i=1,#table do
      copy[i] = table[i]
    end
    return copy
end

function copy_pos_table(table)
    copy = {}
    for i=1,#table do
      copy[i] = copy_pos(table[i])
    end
    return copy
end

function copy_pos(pos)
    return {x = pos.x, y = pos.y}
end

function shuffle(t)
  for i = #t, 1, -1 do
    local j = flr(rnd(i)) + 1
    t[i], t[j] = t[j], t[i]
  end
end

function get_players()
    local ps = {}
    for x in all(actors) do
        if (x.is_player) add(ps, x)
    end
    return ps
end

-- e.g. given UP will return LEFT and RIGHT
function get_perp_moves(move)
    if move.x == 0 then
        return {LEFT, RIGHT}
    else
        return {UP, DOWN}
    end
end

function pair_equal(a, b)
    if (a == nil and b == nil) then
        return true
    elseif a == nil or b == nil then
        return false
    elseif (a[1] == b[1] and a[2] == b[2]) then
        return true
    else
        return false
    end
end

function pos_equal(a, b) 
    return a.x == b.x and a.y == b.y
end

function get_spr_col(spr_n)
    if (spr_n == nil) return nil
    local spr_page = flr(spr_n[1][1] / 64)
    local spr_row = flr((spr_n[1][1] % 64) / 16)
    local spr_col = (spr_n[1][1] % 64) % 16

    return sget(spr_col * 8 + 4, (spr_page * 32) + (spr_row * 8) + 4)
end

function contains(xs, e)
    for x in all(xs) do
        if (x == e) return true
    end
    return false
end

function contains_pos(xs, e)
    for x in all(xs) do
        if (pos_equal(x, e)) return true
    end
    return false
end

-- returns array of start and end pos of lines that form a tile
function get_tile_lines(t)
    r = t.x
    c = t.y
    return {
        bot = {{r*8, c*8}, {r*8 + 8, c*8}},
        right = {{r*8 + 8, c*8}, {r*8 + 8, c*8 + 8}},
        top = {{r*8 + 8, c*8 + 8}, {r*8, c*8 + 8}},
        left = {{r*8, c*8 + 8}, {r*8, c*8}},
    }
end

function are_tiles_adj(t1, t2)
    if (abs(t1.x - t2.x) + abs(t1.y - t2.y) == 1) then
        return true
    else
        return false
    end
end

function sort(a,cmp)
    for i=1,#a do
        local j = i
            while j > 1 and cmp(a[j-1],a[j]) do
                a[j],a[j-1] = a[j-1],a[j]
                j = j - 1
        end
    end
    return a
end

-- given two adj tiles, return directions from first to second and vice-versa
function tile_pair_dirs(t1, t2)
    if (t1.x < t2.x) return {"left", "right"}
    if (t1.x > t2.x) return {"right", "left"}
    if (t1.y < t2.y) return {"bot", "top"}
    if (t1.y > t2.y) return {"top", "bot"}
end

-- true if actor moved
function moved(a)
    return a.delta.x != 0 or a.delta.y != 0
end

-- compute magnitude of v
function v_mag(v)
    return sqrt((v.x * v.x) + (v.y * v.y))
end

-- normalizes v into a unit vector
function v_normalize(v)
    local len = v_mag(v)
    return {x = v.x/len, y = v.y/len}
end

-- Add v1 to v2
function v_addv(v1, v2)
    return {x = v1.x + v2.x, y = v1.y + v2.y}
end

-- Subtract v2 from v1
function v_subv(v1, v2)
    return {x = v1.x - v2.x, y = v1.y - v2.y}
end

-- Multiply v by scalar n
function v_mults(v, n)
    return {x = v.x * n, y = v.y * n}
end

function get_dynamic_or_static_tile_class(pos)
    if not in_bounds(pos) then
        return nil
    end
    local dynamic_tile = fget(level_dynamic_tiles[pos.x][pos.y])
    if (dynamic_tile != ground) return dynamic_tile
    return fget(level_static_tiles[pos.x][pos.y])
end

-- checks if two actors are made of the same set of animals
function is_comp_equal(a, b)
    -- does this sort even work? 
    sort(a.comp, function (x, y) return x > y end)
    sort(b.comp, function (x, y) return x > y end)

    return flat_table_equal(a.comp, b.comp)
end

-- unique id for actors
function get_next_actor_id()
    ACTOR_ID_INDEX += 1
    return ACTOR_ID_INDEX
end

-- returns a table of references to actors but sorted by id
function get_actor_pair_key(a, b)
    return sort({a,b}, function (x, y) return x.id < y.id end)
end

-- -- takes two actors and returns {player, other} 
function maybe_get_player_and_other(a, b)
    if (not b.is_player) return a, b
    return b, a
end

function get_last_move(a)
    if a.is_player then
        return a.pattern[a.t]
    else
        return get_pattern_move_offset(a, -1)
    end
end

-- creates a table of size n where all elements are x
function create_table_of_xs(x, n)
    local t = {}
    for i=1,n do add(t, x) end
    return t
end

function zero_pos()
    return {x=0, y=0}
end

-- == TEXT == 

function hcenter(s)
  return 64-#s*2
end

function vcenter(s)
  return 61
end

function thick_print(s, x, y, c1, c2)
    print(s, x, y+1, c2)
    print(s, x, y, c1)
end

-- == GAME LOGIC == 

function make_actor(
    pos,
    spr_n,
    pattern,
    move_abilities,
    push_abilities,
    display_name,
    shape,
    is_player,
    spr_2,
    comp
)
    local a={}
    a.id = get_next_actor_id()
    a.pos = pos
    a.delta = zero_pos()
    a.spr = spr_n
    a.spr_2 = spr_2
    a.shape = shape
    a.move_abilities = copy_table(move_abilities)
    a.push_abilities = copy_table(push_abilities)
    a.comp = (comp == nil and {spr_n[1][1]}) or comp -- which sprites is this actor made of

    -- pattern
    a.pattern = copy_pos_table(pattern)
    a.t = 0
    a.last_move = zero_pos()
    a.no_trans_count = 0 -- amount of frames can't transform

    -- animation
    a.frame = 0
    a.frames = 2
    a.flip_x = false

    -- display
    a.display_name = display_name

    a.is_player = is_player
    a.mimicked = false -- already transformed this mimic loop

    return a
end

function in_bounds(pos)
    return not (pos.x < 0 or pos.x >= level_size or
                pos.y < 0 or pos.y >= level_size)
end

function is_static_tile(tile_class, pos)
    if (not in_bounds(pos)) return false

    return fget(level_static_tiles[pos.x][pos.y]) == tile_class
end


function is_dynamic_tile(tile_class, pos)
    if (not in_bounds(pos)) return false

    -- find out if tile sprite is member of class
    return fget(level_dynamic_tiles[pos.x][pos.y]) == tile_class
end

function has_move_ability(a, tile_ability)
    return contains(a.move_abilities, tile_ability)
end

function has_push_ability(a, tile_ability)
    return contains(a.push_abilities, tile_ability)
end

function on_win(a)
    result = false
    for r=0,a.shape[2]-1 do
        for c=0,a.shape[1]-1 do
            if is_static_tile(secret_win, v_addv(a.pos, {x=c, y=r})) then
                result = true
                got_secret = true
            end
            result = result or is_static_tile(win, v_addv(a.pos, {x=c, y=r}))
        end
    end
    return result
end

function can_move(pos, a)
    result = false
    for r=0,a.shape[2]-1 do
        for c=0,a.shape[1]-1 do
            local pos_with_shape = v_addv(pos, {x=c, y=r})
            if (not in_bounds(pos_with_shape)) return false
            result = result or valid_move(pos_with_shape, a)
        end
    end
    return result
end

function valid_move(pos, a)
    if (not in_bounds(pos)) return false

    -- For all tile types, check if this tile is of that type and actor has ability to move
    if level_dynamic_tiles[pos.x][pos.y] != ground_spr then 
        return valid_move_dynamic(pos, a)
    end
    return valid_move_static(pos, a)
end

function valid_move_static(pos, a)
    for t in all(static_tiles) do
        if(is_static_tile(t, pos) and has_move_ability(a, t)) then
            return true
        end
    end
    return false
end

function valid_move_dynamic(pos, a)
    for t in all(dynamic_tiles) do
        if(is_dynamic_tile(t, pos) and has_move_ability(a,t)) then
            return true
        end
    end
    return false
end

function can_push(pos, a)
    if (not in_bounds(pos)) return false
    
    -- For all tile types, check if this tile is of that type and actor has ability to move
    for t in all(dynamic_tiles) do
        if(is_dynamic_tile(t, pos) and has_push_ability(a, t)) then
            return true
        end
    end
    return false
end

-- push if the tile has somewhere to go
function maybe_push(pos, delta)
    local new_pos = v_addv(pos, delta)

    -- only allow to push onto ground for now
    if (is_pushable(pos, delta)) then
        level_dynamic_tiles[new_pos.x][new_pos.y] = level_dynamic_tiles[pos.x][pos.y]
        level_dynamic_tiles[pos.x][pos.y] = ground_spr
    end
end

function is_pushable(pos, delta)
    local new_pos = v_addv(pos, delta)
    -- only allow to push onto ground for now
    return is_static_tile(ground, new_pos) and is_dynamic_tile(ground, new_pos)
end

function is_pushable_anywhere(pos)
    for d in all(DELTAS) do
        if (is_pushable(pos, v_mults(d,-1)) and is_pushable(pos, d)) return true
    end
    return false
end

function get_pattern_index(a)
    return (a.t % #a.pattern) + 1
end

function get_pattern_move(a)
    return a.pattern[get_pattern_index(a)]
end

-- returns the next move according to the pattern offset by i
function get_pattern_move_offset(a, i)
    return a.pattern[((a.t + i) % #a.pattern) + 1]
end

function npc_get_move(a)
    local new_move, alt_move

    -- Move according to pattern if possible
    local pattern_move = get_pattern_move(a)
    local new_loc = v_addv(a.pos, pattern_move)
    if can_move(new_loc, a) then
        return pattern_move
    end

    -- Alternative move
    prev_loc = v_subv(a.pos, a.last_move)

    -- try perpendicular moves first
    local perp_moves = get_perp_moves(pattern_move)
    local could_not_move = false
    local perp_move
    for i=1,#perp_moves do
        perp_move = perp_moves[i]
        alt_loc = v_addv(a.pos, perp_move)

        if can_move(alt_loc, a) then
            -- dont allow move into prev pos as alt
            if not pos_equal(alt_loc, prev_loc) then
                update_pattern(a, perp_move)
                return perp_move
            end
        end
    end

    -- need to go backwards
    back_loc = v_subv(a.pos, pattern_move)
    if can_move(back_loc, a) then
        return zero_pos() -- we dont allow moving back
    end


    -- nowhere to move... stuck
    return zero_pos()
end

function npc_die(a)
    a.t = 0
    del(actors, a)
    sfx(die_sfx)
end

function npc_input()
    for a in all(actors) do
        if not a.is_player then
            -- apply npc pattern
            if pos_equal(a.delta, STILL) then
                if game.tick % slow_speed == 0 then
                    move = npc_get_move(a)
                    if pos_equal(move, STILL) then
                        npc_die(a)
                    else
                        a.delta = copy_pos(move)
                        a.last_move = copy_pos(move)
                    end
                end
            end
        end
    end
end

function update_npc(a)
    if moved(a) then
        a.t += 1
    end
end

function update_pattern(a, new_move)
    local update_index = (a.t % #a.pattern) + 1
    local old_move = a.pattern[update_index]
    a.pattern[update_index] = copy_pos(new_move)
    -- also mirror the move on the way back to keep the pattern looping
    local mirror_update_index = #a.pattern - update_index
    a.pattern[(mirror_update_index % #a.pattern) + 1] = v_mults(new_move, -1)

    -- side effects
    a.no_trans_count = flr((#a.pattern - 1) * 2) -- don't transform until doing a pattern loop

    -- vfx
    local frame_len = #a.pattern - 1
    sfx(change_pattern_sfx)
    transform_vfx(a, get_spr_col(a.spr), 60, get_spr_col(a.spr_2))
end

function update_actor(a)
    -- move actor
    if moved(a) then
        local new_pos = v_addv(a.pos, a.delta)

        -- push
        if a.is_player then
            for r=0,a.shape[2]-1 do
                for c=0,a.shape[1]-1 do
                    new_pos_and_shape = v_addv(new_pos, {x=c, y=r})
                    if can_push(new_pos_and_shape, a) and valid_move_static(new_pos, a) then
                        maybe_push(new_pos_and_shape, a.delta)
                    end
                end
            end
        end


        -- move
        if can_move(new_pos, a) then
            a.pos = new_pos

            if a.is_player then
                update_player(a)
                play_player_sfx("move")
                overlap_effects()
            else
                update_npc(a)
            end
        else
            -- can't move
            if a.is_player then
                sfx(0)
            end
        end

        -- actor animation
        a.frame += 1
        a.frame %= a.frames
        a.no_trans_count = max(a.no_trans_count - 1, 0)

        if (a.delta.x != 0) a.flip_x = a.delta.x > 0
    end
end

function update_actors()
    actors = sort(actors, function (x, y) return x.is_player end) -- make sure players update last
    foreach(actors, update_actor)
end

function post_update_actors()
    for a in all(actors) do
        a.delta = zero_pos()
    end
end

function update_particles(ps)
    remove = {}
    for p in all(ps) do
        if (p.end_tick < game.tick) then
            add(remove, p)
        end
    end

    for p in all(remove) do
        del(ps, p)
    end
end

function init_actor(spr_n, pos)
    for n in all(npcs) do
        if n.spr_n[1][1] == spr_n then
            local a = make_actor(
                pos,
                n.spr_n,
                n.pattern,
                n.move_abilities,
                n.push_abilities,
                n.display_name,
                n.shape,
                false,
                nil
            )
            add(actors, a)
            return a
        end
    end
end

function is_stuck(p)
    for d in all(DELTAS) do
        if (can_move(v_addv(p.pos, d), p)) return false
    end
    return true
end

function no_npc()
    return #actors == 1
end

-- == PLAYER == 

player_spr = {{5, nil}, {nil, nil}}

PLAYER_PATTERN_SIZE = 8 -- must be at least 1 longer than the max npc pattern length and even

player_move_abilities = {ground, win, secret_win, flower1, flower2, flower3, flower4, flower5}
player_push_abilities = copy_table(dynamic_tiles)

function init_player(pos)
    local p = make_actor(
        pos,
        player_spr,
        {},
        player_move_abilities,
        player_push_abilities,
        "you",
        {1,1},
        true,
        nil)
    p.t = 1;
    add(actors, p)
    reset_player_pattern(p)
    return p
end

function player_input()
    for p in all(get_players()) do
        if (btnp(0)) p.delta.x = -1
        if (btnp(1)) p.delta.x = 1
        if (btnp(2)) p.delta.y = -1
        if (btnp(3)) p.delta.y = 1

        -- prevent diagonal movement
        if (p.delta.x != 0) p.delta.y = 0
    end
    if (btnp(5)) then
        if game.state == "splash" then
            change_state("tutorial")
        elseif game.state == "tutorial" and tutorial_skippable then
            change_level = start_level
            particles={}
        elseif game.state == "play" then
            game.restart_level = true
        else
            -- noop
        end
    end

end

function reset_player_pattern(p)
    p.pattern={}
    for i=1,PLAYER_PATTERN_SIZE do
        add(p.pattern, zero_pos())
    end
    -- init_player_big_pattern()
end

-- returns true if player is victorious (won last level)
function check_win()
    local victory = false
    local players = get_players()
    if _all(players, on_win) then
        if game.level == last_level then
            init_victory()
            victory = true
        end

        -- proceed to next level
        change_level = game.level + 1
        while contains(skip_levels, change_level) do
            change_level += 1
        end
        if change_level == secret_level and not got_secret then
            change_level += 1
        end

        -- effects
        sfx(11)
        for p in all(players) do
            win_vfx(p.pos)
        end
        game.level_end_tick = game.tick
        return victory
    end
    return victory
end

function init_victory()
    sfx(11)
    change_state("victory")
    particles={}

    -- gather win tiles to spawn final visuals on 
    victory_sprite_pos = find_tiles(game.level, tile_sprites[win])
    victory_sprites = {}
    for i=1,#victory_sprite_pos do
        add(victory_sprites, player_spr[1][1])
    end

    victory_sprite_candidates = {player_spr[1][1], player_spr[1][1], player_spr[1][1]}
    for x in all(npcs) do
        if body_size(x) < 3 then
            add(victory_sprite_candidates, x.spr_n[1][1])
        end
    end
end

function update_player(p)
    p.t = (p.t % #p.pattern) + 1;
    p.pattern[p.t] = copy_pos(p.delta);
end

-- == MECHANIC ==

function init_big_patterns()
    animal_big_patterns = {}
    for i=1,#actors-1 do
        for j=i+1,#actors do
            local a, b = actors[i], actors[j]
            if (body_size(a) < 3 and body_size(b) < 3) then
                local maybe_player, other = maybe_get_player_and_other(a, b)
                local init_pattern = create_table_of_xs(OTHER, #maybe_player.pattern)
                animal_big_patterns[{actors[i], actors[j]}] =
                {
                    [12] = copy_pos_table(init_pattern),
                    [21] = copy_pos_table(init_pattern),
                }
            end
        end
    end
end

function update_big_patterns()
    for animals, shape_key_to_pattern in pairs(animal_big_patterns) do
        local a, b = animals[1], animals[2]
        if moved(a) or moved(b) then
            local pair_shape = form_shape(get_body(a), get_body(b))
            for shape_key, pattern in pairs(shape_key_to_pattern) do
                if (pair_shape ~= nil) then
                    local pair_shape_key = 10*pair_shape[1] + pair_shape[2]
                    local maybe_player, other = maybe_get_player_and_other(a, b)
                    local pattern_index = maybe_player.t % #maybe_player.pattern + 1
                    animal_big_patterns[animals][shape_key][pattern_index] = tern(
                        shape_key == pair_shape_key and pos_equal(get_last_move(a), get_last_move(b)),
                        get_last_move(a), OTHER)
                end
            end
        end
    end
end

function animal_big_mimic()
    local actors_to_add = {}
    local actors_to_del = {}
    local to_add, to_del = {}, {} 
    for a in all(actors) do
        local shape_key = 10*a.shape[1] + a.shape[2]
        -- comp >= 3 check is so that the goat + vishab + butter animal doesn't transform back 
        -- this is a feature that i've intentionally removed so that they dont keep transforming
        -- back and forth. Also the sprite draw algo doesn't work really well for that case lol
        if (body_size(a) != 3 or #a.comp >= 3) goto cont
        for animals, shape_keys in pairs(animal_big_patterns) do
            local a1, a2 = animals[1], animals[2]
            for pair_shape_key, pat in pairs(shape_keys) do
                if shape_key == pair_shape_key then
                    local maybe_player, other = maybe_get_player_and_other(a1, a2)
                    local pat_1, pat_2 = pat, a.pattern
                    local pat_size, pat_start = #maybe_player.pattern, get_pattern_index(maybe_player)
                    if can_mimic({a, a1, a2}) and 
                       can_trans(a1, a2)
                    then
                        if a.is_player then
                            -- shifting the pattern here is an shameless hack ... my brain hurts 
                            -- and its too hard to refactor the `update_big_pattern` code to 
                            -- run after actors move but _before_ we update the a.t value
                            -- its also weird that using a.t here works but get_pattern_index(a)
                            -- does not ... the mod code is kinda messed up ... rip
                            pat_1, pat_2 = a.pattern, shift_pattern(pat, #pat)
                            pat_size, pat_start = #a.pattern, a.t
                        end
                        if is_mimic(pat_1, pat_2, pat_size, pat_start) then
                            if maybe_player.is_player then
                                -- small actor and player into big player
                                local new_pos = {x = min(maybe_player.pos.x, other.pos.x), y = maybe_player.pos.y}
                                transform_player(maybe_player, a, new_pos)
                                to_del = {other}
                            elseif a.is_player then
                                -- big player into two small players
                                to_add, to_del = transform_big_player(a, a1, a2)
                            elseif (#a.comp < 3) then 
                                -- two small actors into one big actor
                                to_add, to_del = merge_into_big_animal(a, a1, a2)
                            end 
                            actors_to_add = table_concat(actors_to_add, to_add)
                            actors_to_del = table_concat(actors_to_del, to_del)
                            goto cont
                        end
                    end
                end
            end

        end
        ::cont::
    end

    foreach(actors_to_del, function(x) del(actors, x) end) 
    foreach(actors_to_add, function(x) add(actors, x) end) 

    -- reset patterns
    if #actors_to_add + #actors_to_del > 0 then 
        init_big_patterns()
    end

end

function rev_pattern(pattern)
    reverse = {}
    for i = 1,#pattern do
        reverse[i] = {}
        reverse[i].x = pattern[#pattern-i+1].x
        reverse[i].y = pattern[#pattern-i+1].y
    end
    return reverse
end

function shift_pattern(pattern, len)
    shifted = {}
    for i = 1,#pattern do
        shifted[i] = {}
        shifted[i].x = pattern[((i + len) % #pattern) + 1].x
        shifted[i].y = pattern[((i + len) % #pattern) + 1].y
    end
    return shifted
end

function shift_pattern_halfway(pattern)
    local half_len = #pattern / 2.0 - 1
    return shift_pattern(pattern, half_len)
end

-- given a pattern returns the concat of the pattern and its inverted reverse
function get_full_pattern(pattern)
    local back_pattern = rev_pattern(pattern)
    for i=1,#back_pattern do
        back_pattern[i].x = back_pattern[i].x * -1
        back_pattern[i].y = back_pattern[i].y * -1
    end
    return table_concat(pattern, back_pattern)
end

-- give player ability of animal it mimics
function mimic()
    reset_mimicked()
    animal_big_mimic()
    animal_mimic()
    -- player_big_pattern_mimic()
end

function reset_mimicked()
    for a in all(actors) do
        a.mimicked = false
    end
end

function transform_player(p, a, new_pos)
    transform_animal(p, a, new_pos)
    reset_player_pattern(p)
    a.mimicked = true
end

function transform_animal(a, other, new_pos)
    if (new_pos != nil) then
        a.pos = new_pos
    end
    play_player_sfx("transform")
    a.shape = other.shape
    a.move_abilities = copy_table(other.move_abilities)
    a.push_abilities = copy_table(other.push_abilities)
    a.spr = other.spr
    a.spr_2 = other.spr_2
    a.display_name = other.display_name
    if (other.spr_2 != nil) a.display_name = "chimera"
    a.comp = {other.spr[1][1]}
    if (other.spr_2 != nil) add(a.comp, other.spr_2[1][1])
    transform_vfx(other, 8, 20)
    transform_vfx(a, get_spr_col(other.spr), 20, get_spr_col(other.spr_2))
    a.mimicked = true
    other.mimicked = true
end

function transform_big_player(a, o1, o2)
    if (o1.pos.x > o2.pos.x or o1.pos.y > o2.pos.y) then 
        right = o1
        left = o2
    else
        right = o2
        left = o1
    end

    -- new players
    local new_o1 = make_actor(
        a.pos,
        left.spr,
        {},
        copy_table(left.move_abilities),
        copy_table(left.push_abilities),
        "chimera",
        {1,1},
        true,
        left.spr_2,
        left.comp
    )

    local new_o2 = make_actor(
        v_addv(a.pos, {x=1, y=0}),
        right.spr,
        {},
        copy_table(right.move_abilities),
        copy_table(right.push_abilities),
        "chimera",
        {1,1},
        true,
        right.spr_2,
        right.comp
    )

    -- stuff needed for new players
    new_o1.t = 1
    new_o2.t = 1
    reset_player_pattern(new_o1)
    reset_player_pattern(new_o2)

    -- fx
    play_player_sfx("transform")
    transform_vfx(o1, 8, 20)
    transform_vfx(o2, 8, 20)
    transform_vfx(a, get_spr_col(o1.spr), 20, get_spr_col(o2.spr))

    a.mimicked = true
    o1.mimicked = true
    o2.mimicked = true

    return {new_o1, new_o2}, {a}
end

-- currently hardcoded to only work for shape {2,1}
function merge_into_big_animal(a, o1, o2)
    -- make sure o1 is pointing to the top_left one
    local tmp = o1
    if (o1.pos.x > o2.pos.x or o1.pos.y > o2.pos.y) then 
        o1 = o2
        o2 = tmp
    end

    -- o1, o2 -> [o1 a a o2] (using the actor a)
    local new_big = make_actor(
        {x = min(o1.pos.x, o2.pos.x), y = min(o1.pos.y, o2.pos.y)},
        {{o1.spr[1][1], a.spr[1][2]}, {}},
        copy_pos_table(o1.pattern),
        table_concat(a.move_abilities, table_concat(o1.move_abilities, o2.move_abilities)),
        table_concat(a.push_abilities, table_concat(o1.push_abilities, o2.push_abilities)),
        "vishab",
        a.shape,
        false,
        {{a.spr[1][1], o2.spr[1][1]}, {nil, nil}},
        {o1.spr[1][1], o2.spr[1][1], a.spr[1][1]}
    )


    -- o1 -> [o1, a]
    local new_o1 = make_actor(
        a.pos,
        {{o1.spr[1][1], nil}, {nil, nil}},
        copy_pos_table(a.pattern),
        table_concat(a.move_abilities, o1.move_abilities),
        table_concat(a.push_abilities, o1.push_abilities),
        "chimera",
        {1,1},
        false,
        {{a.spr[1][2], nil}, {nil, nil}},
        {o1.spr[1][1], a.spr[1][2]}
    )

    -- o2 -> [a, o2]
    local new_o2 = make_actor(
        v_addv(a.pos, {x=1, y=0}),
        {{o2.spr[1][1], nil}, {nil, nil}},
        copy_pos_table(a.pattern),
        table_concat(a.move_abilities, o2.move_abilities),
        table_concat(a.push_abilities, o2.push_abilities),
        "chimera",
        {1,1},
        false,
        {{a.spr[1][2], nil}, {nil, nil}},
        {o2.spr[1][1], a.spr[1][2]}
    )

    -- fx
    play_player_sfx("transform")
    transform_vfx(o1, get_spr_col(a.spr), 20)
    transform_vfx(o2, get_spr_col(a.spr), 20)
    transform_vfx(a, get_spr_col(o1.spr), 20, get_spr_col(o2.spr))

    a.mimicked = true
    o1.mimicked = true
    o2.mimicked = true

    return {new_big, new_o1, new_o2}, {o1, o2, a}
end

function merge_animals(a, b)
    local merged_move_abilities = table_concat(a.move_abilities, b.move_abilities)
    a.move_abilities = copy_table(merged_move_abilities)
    b.move_abilities = copy_table(merged_move_abilities)
    a.spr_2 = b.spr
    b.spr_2 = a.spr
    a.comp = {a.spr[1][1], b.spr[1][1]}
    b.comp = {b.spr[1][1], a.spr[1][1]}

    a.mimicked = true
    b.mimicked = true
end

function animal_mimic()
    for a in all(actors) do
        for b in all(actors) do
            if a != b and
               can_mimic({a, b}) and 
               can_trans(a, b) and 
               is_mimic(a.pattern, b.pattern, #a.pattern, tern(a.is_player, a.t, 0)) and
               a.shape[1] == b.shape[1] and
               a.shape[2] == b.shape[2] and
               pair_equal(a.shape, {1,1}) and 
               not is_comp_equal(a, b)
            then
                if a.is_player then
                    transform_player(a, b)
                elseif b.is_player then
                    transform_player(b, a)
                elseif #a.comp < 2 and #b.comp < 2 then
                    merge_animals(a, b)
                    play_player_sfx("transform")
                    transform_vfx(a, get_spr_col(b.spr), 20, get_spr_col(a.spr_2))
                    transform_vfx(b, get_spr_col(a.spr), 20, get_spr_col(b.spr_2))
                end
            end
        end
    end
end

function can_mimic(as) 
    for a in all(as) do
        if (a.mimicked) return false
    end
    return true
end

function can_trans(a, b)
    return (a.no_trans_count + b.no_trans_count <= 0) or (a.is_player or b.is_player)
end

function is_mimic(pattern_a, pattern_b, pattern_a_size, pattern_a_start) 
    -- check regular pattern and shifted pattern for backwards mimic
    return contains_pattern(pattern_a, pattern_b, pattern_a_size, pattern_a_start) or
        contains_pattern(pattern_a, shift_pattern_halfway(pattern_b), pattern_a_size, pattern_a_start)
end

function patterns_match(pattern_a, pattern_b, start_a)
    local a_len = #pattern_a
    local b_len = #pattern_b
    for i=1, b_len do
        local a_i = ((start_a + i - 1) % a_len) + 1
        local b_i = i
        if not pos_equal(pattern_a[a_i], pattern_b[b_i]) then
            return false
        end
    end
    return true
end

function contains_pattern(in_pattern, fit_pattern, in_pattern_size, in_pattern_start)
    local in_len = #in_pattern
    local fit_len = #fit_pattern
    -- start matching pattern from fit pattern length back from current player pattern index (wrapped)
    local start_i = ((in_pattern_start - fit_len + in_pattern_size - 1) % in_pattern_size) + 1
    return patterns_match(in_pattern, fit_pattern, start_i)
end

-- get the postitions of the tiles the actor's pattern covers
function get_pattern_tile_coords(a)
    local coords = {}
    local loc = a.pos
    for i=0,7 do
        local pattern_move = get_pattern_move_offset(a, i)
        local new_loc = v_addv(loc, pattern_move)
        if (not contains_pos(coords, new_loc)) then
            add(coords, new_loc)
        end
        loc = new_loc
    end
    return coords
end

function get_player_pattern_coords(p)
    local coords = {}
    for i=3,1,-1 do
        local p_i = ((p.t - i) % #p.pattern) + 1
        local pattern_move = p.pattern[p_i]
        add(coords, pattern_move)
    end
    return rev_pattern(coords)
end

function get_player_pattern_tile_coords(p)
    local coords = {}
    local loc = copy_pos(p.pos)
    for pattern_move in all(get_player_pattern_coords(p)) do
        local new_loc = v_subv(loc, pattern_move)
        add(coords, new_loc)
        loc = new_loc
    end
    add(coords, p.pos)
    return coords
end

-- == LEVEL and MAP ==

function init_level(_level)
    if _level != tutorial_level then
        change_state("play")

        if _level == 0 then
            --music(-1, 10000)
            ---music(6, 3000)
        end
    end

    actors = {}
    game.tick = game.level_end_tick
    game.level = _level
    change_level = game.level
    game.is_stuck = false
    init_tiles_and_actors(_level)
    init_big_patterns()

    if game.level != tutorial_level and game.level <= last_level-1 then
        menuitem(1, "skip level", menu_skip_level)
    else
        menuitem(1)
    end
    --music(01)
end

-- Loads in level by populating 2d array of tiles `level_static_tiles` and `level_dynamic_tiles`
function init_tiles_and_actors(l)
    tile_sprites = {}
    for i=0,level_size-1 do
        level_static_tiles[i] = {}
        level_dynamic_tiles[i] = {}

        for j=0,level_size-1 do
            local tile_spr = get_tile(i, j, l)
            local tile_class = fget(tile_spr)
            local tile_pos = {x=i, y=j}
            local dynamic_spr, static_spr

            tile_sprites[tile_class] = tile_spr

            if contains(dynamic_tiles, tile_class) then
                dynamic_spr = tile_spr
                static_spr = ground_spr
            elseif contains(static_tiles, tile_class) then
                dynamic_spr = ground_spr
                static_spr = tile_spr
            elseif tile_class == actor_reg_tile then
                a = init_actor(tile_spr, tile_pos)
                dynamic_spr = ground_spr
                static_spr = tile_sprites[a.move_abilities[1]]
            elseif tile_class == actor_sml_tile then
                a = init_actor(tile_spr-1, tile_pos)
                dynamic_spr = tile_sprites[a.move_abilities[2]]
                static_spr = ground_spr
            elseif tile_class == player then
                a = init_player(tile_pos)
                dynamic_spr = ground_spr
                static_spr = tile_sprites[a.move_abilities[1]]
            else
                -- debug.print(i.." "..j.." "..tile_class.." tile not dynamic or static")
            end
            level_dynamic_tiles[i][j] = dynamic_spr
            level_static_tiles[i][j] = static_spr
        end
    end
end

function find_tiles(l, spr_n)
    local sprites = {}
    for i=0,level_size-1 do
        for j=0,level_size-1 do
            if get_tile(i,j,l) == spr_n then
                add(sprites, {x = i, y = j})
            end
        end
    end
    return sprites
end

function get_tile(x,y,l)
    i = (x + l*level_size) % 128
    j = y + flr(level_size * l / 128)*level_size
    return mget(i,j)
end

-- == VFX ==

function fuzz_line_vfx(l, col, dur, col2, speed, max_size)
    local x = l[1][1]
    local y = l[1][2]
    local x2 = l[2][1]
    local y2 = l[2][2]
    if x == x2 then
        dx = 0
        if y2 > y then dy = 1 else dy = -1 end
    else
        if x2 > x then dx = 1 else dx = -1 end
        dy = 0
    end
    local i = 0
    while x != x2 or y != y2 do
        local c = col
        local s = 0
        if (rnd() > 0.9) s = max_size
        if (col2 != nil and rnd() > 0.5) c = col2
        if i % 2 == 0 then
            local fuzz = {
                pos = {x = x + flr(rnd(3)) - 1, y = y + flr(rnd(3)) - 1},
                col = c,
                draw_fn = draw_fuzz,
                start_tick = game.tick,
                end_tick = game.tick + flr(rnd(10)) + dur,
                meta_data = {
                    size = s,
                    speed = speed,
                    dx = 0,
                    dy = 0
                },
            }
            add(particles, fuzz)
        end
        i += 1
        x += dx
        y += dy
    end

end

function draw_fuzz(pos, col, curr_tick, start_tick, end_tick, meta_data)
    if (curr_tick - start_tick) % meta_data["speed"] == 1 then
        meta_data["dx"] = flr(rnd(3)) - 1
        meta_data["dy"] = flr(rnd(3)) - 1
    end
    circfill(pos.x + meta_data["dx"], pos.y + meta_data["dy"], meta_data["size"], col)
end

function draw_spark(pos, col, curr_tick, start_tick, end_tick, meta_data)
    local delta = curr_tick - start_tick
    local x = pos.x + meta_data.dir.x * delta * meta_data.spd
    local y = pos.y + meta_data.dir.y * delta * meta_data.spd
    circfill(x, y, meta_data.size, col)
end

function draw_heart(pos, col, curr_tick, start_tick, end_tick, meta_data)
    local waver = game.tick % 4
    if (game.tick % 8) < 4 then waver *= -1 end 
    waver += ({[true]=1,[false]=-1})[(rnd() > 0.5)]*flr(rnd(1))
    print("\135", pos.x + (waver - 4), pos.y - (curr_tick - start_tick), 8)
end

-- heart pops up when you meet an animal
heart_tiles = {flower1, flower2, flower3, flower4, flower5}
heart_sounds = {
    [flower1]=12,
    [flower2]=13,
    [flower3]=14,
    [flower4]=16,
    [flower5]=16,
}
function overlap_effects()
    for p in all(get_players()) do
        -- tile hearts
        for t in all(heart_tiles) do
            if is_static_tile(t, p.pos) then
                spawn_heart(p, heart_sounds[t])
            end
        end

        -- actor hearts
        for a in all(actors) do
            if (not a.is_player) and collides(get_body(p), get_body(a)) then
                spawn_heart(a, 12)
            end
        end
    end
end

function spawn_heart(a, snd)
    local frame_len = #a.pattern - 1
    local end_tick = game.tick + (4 * frame_len)
    local heart = {
        pos = {x = a.pos.x*8 + 4, y = a.pos.y*8 + 4},
        col = 10,
        draw_fn = draw_heart,
        start_tick = game.tick,
        end_tick = end_tick,
        meta_data = {},
    }
    add(particles, heart)
    sfx(snd)
end

function win_vfx(pos)
    explode_vfx(pos, {10}, 1.5, 40, 30, 90, 0.5, 1.5)
end

function transform_vfx(a, col1, dur, col2)
    -- get tiles
    local tiles
    if a.is_player then
        tiles = get_player_pattern_tile_coords(a)
    else
        tiles = get_pattern_tile_coords(a)
    end

    -- add tiles for big animals
    big_tiles = {}
    for r=1,a.shape[2]-1 do
        for t in all(tiles) do add(big_tiles, {x=t.x, y=t.y+r}) end
    end
    for c=1,a.shape[1]-1 do
        for t in all(tiles) do add(big_tiles, {x=t.x+c, y=t.y}) end
    end
    tiles = table_concat(tiles, big_tiles)

    -- gen lines
    tile_lines = {}
    for i=1,#tiles do
        add(tile_lines, get_tile_lines(tiles[i]))
    end

    -- remove adj lines
    for i=1,#tiles-1 do
        for j=i+1,#tiles do
            local t1, t2 = tiles[i], tiles[j]
            if are_tiles_adj(t1, t2) then
                -- border lines to remove
                local dirs = tile_pair_dirs(tiles[i], tiles[j])
                tile_lines[i][dirs[2]] = nil
                tile_lines[j][dirs[1]] = nil
            end
        end
    end

    -- draw lines
    for i=1,#tiles do
        for k, l in pairs(tile_lines[i]) do
            fuzz_line_vfx(l, col1, dur, col2, 2, 1)
        end
    end
end

function explode_vfx(pos, cols, size, count, min_dur, max_dur, min_spd, max_spd)
    for i=0,count do
        spark = {
            pos = {x = pos.x*8 + 4, y = pos.y*8 + 4},
            col = pick(cols),
            draw_fn = draw_spark,
            start_tick = game.tick,
            end_tick = game.tick + rnd(max_dur - min_dur) + min_dur,
            meta_data = {
                dir = v_normalize({x=rnd(2) - 1, y=rnd(2) - 1}),
                size = flr(rnd(size)),
                spd = rnd(max_spd - min_spd) + min_spd,
            },
        }
        add(perm_particles, spark)
    end
end

-- == DRAW ==

function draw_splash()
    cls()
    pal()

    print(splash_keys_3, hcenter(splash_keys_3), 66, 9)

    if(game.tick % 60 > 0 and game.tick % 60 < 20) then
        cls()
    end

    if game.tick % 60 == 0 then
        splash_red_sprite_count += 1
    end

    map(117,60,36,34,8,4)
    print("ALPHA", 80, 121, 1)
    print(VERSION, 103, 121, 1)
    print("sourencho", 2, 121, 1)


    -- local d, r = 0, 50
    local d, r = -game.tick/420, 50
    for i=1,#splash_sprites do
        if (splash_sprite_indexes[i] < splash_red_sprite_count) then
            pal(red_pal)
        else
            pal() pal(def_pal,1)
        end
        spr(splash_sprites[splash_sprite_indexes[i]], 60 + r * cos(d), 56 + r * sin(d), 1, 1, i % 2 == 0)
        d += 1 / (#splash_sprites)
    end
end

function draw_win()
    for p in all(get_players()) do 
        if (on_win(p)) explode_vfx(p.pos, {10}, 1, 2, 6, 9, 0.3, 1)
    end
end


function draw_victory()
    cls()
    draw_particles()

    -- draw player reflection
    pal(red_pal)
    for i=1,#victory_sprite_pos do
        local v_pos = victory_sprite_pos[i]

        -- draw sparks
        explode_vfx(v_pos, {1}, 1, 2, 6, 9, 0.3, 1)

        -- draw sprite
        local on_right = v_pos.x*8 > 64
        local total_switch_time = 230
        -- switch sprites over time
        if on_right then
            local time_per_spr = total_switch_time / #victory_sprite_candidates
            local tick_window = (game.tick - game.level_end_tick) % total_switch_time
            local spr_index = flr(tick_window / time_per_spr) + 1
            victory_sprites[i] = victory_sprite_candidates[spr_index]
        end

        spr(victory_sprites[i], v_pos.x*8, v_pos.y*8, 1, 1, not on_right)
    end
    pal(def_pal)

    -- text
    won_text_1 = "★ thanks for playing ★"
    won_text_2 = "sourencho"
    print(won_text_1, hcenter(won_text_1), 102, 1)
    print(won_text_2, hcenter(won_text_2), 112, 1)
end

function draw_level_splash(l)
    cls()

    local txt_clr
    local margin = 3
    local padding = 2
    local size = 27
    local row = 0
    local col = 0

    -- border
    rect(0,0,127,127,1)
    rect(1,1,126,126,1)

    local level_text = 0
    for i=0,level_count-1 do
        -- coord
        local x = margin + (row % 4) * (size + 2 * padding)
        local y = margin + col * (size + 2 * padding)

        -- text
        if (i == l) then txt_clr = 7 else txt_clr = 1 end

        if (contains(skip_levels, i)) goto cont

        -- draw
        if level_text == secret_level-1 then
            draw_text = "??"
        else 
            draw_text = level_text
        end
        print(tern(draw_text != "??" and level_text < 10, "0"..draw_text, draw_text),
            x + size/2 - 2, y + size/2 - 1, txt_clr)

        if i == l and l != level_count-1 then
            spr(58, x + size/2 - 2, y + size/2 + 5)
        end

        if i == level_count-1 then
            local win_clr = 1
            if (i == l) win_clr = 10 
            print('★', x + size/2 - 2, y + size/2 + 6, win_clr)
        end

        -- update
        row += 1
        col = flr(row / 4)

        level_text += 1
        ::cont::
    end
    draw_particles()
end

function maybe_add_shake(x, y)
    local speed = slow_speed * 7
    if game.tick % speed < 3 then
        return x, y-1
    elseif game.tick % speed < 4 then
        return x, y
    elseif game.tick % speed < 7 then
        return x, y-1
    else
        return x, y
    end
end

function draw_level()
    for i=0,level_size-1 do
        for j=0,level_size-1 do
            local x, y = i*8, j*8
            if level_static_tiles[i][j] != ground_spr then
                spr(level_static_tiles[i][j], x, y)
            end
            if level_dynamic_tiles[i][j] != ground_spr then
                if (is_pushable_anywhere({x=i, y=j})) x, y = maybe_add_shake(x, y)
                spr(level_dynamic_tiles[i][j], x, y)
            end
        end
    end

    -- tutorial text in levels
    if game.level == 0 then
        print("move", 21, 12, 1)
        print("\139\145\148\131", 13, 22, 1)
    elseif game.level == 1 then
        print("restart", 86, 17, 1)
        print("\151", 86 + 10, 17 + 8, 1)
    end

end

function draw_actor(a)
    -- change colors to be red
    if a.is_player then
        pal(red_pal)
    end

    for r=1,a.shape[2] do
        for c=1,a.shape[1] do
            spr_n = a.spr[r][c]

            -- chimera
            local ax, ay = (a.pos.x + (c-1))*8, (a.pos.y + (r-1))*8
            if a.spr_2 != nil then
                spr_n_2 = a.spr_2[r][c]
                -- sspr formula from https://pico-8.fandom.com/wiki/Sspr
                local a_sx, a_sy = ((spr_n + a.frame) % 16) * 8, ((spr_n + a.frame) \ 16) * 8
                local b_sx, b_sy = ((spr_n_2 + a.frame) % 16) * 8, ((spr_n_2 + a.frame) \ 16) * 8
                if (a.flip_x) then 
                    sspr(a_sx, a_sy, 4, 8 , ax + 4, ay, 4, 8, a.flip_x)
                    sspr(b_sx + 4, b_sy, 4, 8 , ax, ay, 4, 8, a.flip_x)
                else
                    sspr(a_sx, a_sy, 4, 8 , ax, ay)
                    sspr(b_sx + 4, b_sy, 4, 8 , ax + 4, ay)
                end
            else -- normal
                if (a.flip_x) ax = (a.pos.x + a.shape[1] - 1 - (c-1)) * 8 -- draw backwards
                spr(
                    spr_n + a.frame,
                    ax,
                    ay,
                    1, 1, a.flip_x)
            end
        end
    end

    pal()
    pal(def_pal,1)
end

function draw_particle(p)
    p.draw_fn(p.pos, p.col, game.tick, p.start_tick, p.end_tick, p.meta_data)
end

function draw_actors()
    foreach(actors, draw_actor)
end

function draw_particles()
    foreach(particles, draw_particle)
    foreach(perm_particles, draw_particle)
end

function draw_ui()
    local players = get_players()
    if _all(players, is_stuck) then
        if (not game.is_stuck) game.stuck_tick = game.tick
        game.is_stuck = true
        if (game.stuck_tick > game.tick - 100) return
        local stuck_text = "you are stuck"
        thick_print(stuck_text, hcenter(stuck_text), vcenter(stuck_text) - 8, 9, 1)
        stuck_text = "press \151 to restart"
        thick_print(stuck_text, hcenter(stuck_text), vcenter(stuck_text), 9, 1)
        if #players > 1 then
            return
        else
            local p = players[1]
            -- "gota can't"
            local explain_txt_animal = p.display_name.." cannot"
            thick_print(explain_txt_animal, hcenter(explain_txt_animal), vcenter(explain_txt_animal) + 8, 9, 1)

            -- trees or ground
            local explain_txt_tiles = ""

            local surr_tiles = {}
            for delta in all({UP, DOWN, LEFT, RIGHT}) do 
                local tc = get_dynamic_or_static_tile_class(v_addv(p.pos, delta))
                if tc != nil then
                    add(surr_tiles, tile_display_names[tc])
                end
            end

            surr_tiles = table_dedup(surr_tiles)
            for i=1,#surr_tiles do
                if (i > 1) explain_txt_tiles ..= " or "
                explain_txt_tiles ..= surr_tiles[i]
            end
            thick_print(explain_txt_tiles, 
                hcenter(explain_txt_tiles), vcenter(explain_txt_tiles) + 16, 9, 1)
        end
    end
end

-- == COLLISION ==

-- SCHEMA
-- body = {
--    pos = {col,row}
--    shape = {width, height}
-- }

function get_body(a)
    return {pos=a.pos, shape=a.shape} 
end

-- where a and b are body
function collides(a, b)
    if a.pos.x <= b.pos.x + b.shape[1]-1 and
       a.pos.x + a.shape[1]-1 >= b.pos.x and
       a.pos.y <= b.pos.y + b.shape[2]-1 and
       a.pos.y + a.shape[2]-1 >= b.pos.y then
        return true
    end
    return false
end

-- what shape do bodies a and b form together
-- currently only supports bodies of shape {1,1}
function form_shape(a, b)
    if (not are_tiles_adj(a.pos, b.pos)) return nil
    if (collides(a, b)) return nil
    if (not pair_equal(a.shape, {1,1}) or not pair_equal(b.shape, {1,1})) return nil 
    local pair_dir = tile_pair_dirs(a.pos, b.pos)
    if (pair_dir[1] == "left" or pair_dir[1] == "right") return {2, 1}
    if (pair_dir[1] == "bot" or pair_dir[1] == "top") return {1, 2}
    return nil
end

-- returns size of body
function body_size(b)
    return b.shape[1]+b.shape[2]
end

-- == DEBUG pico-kit ==

--[[
debug = {}
printh("",DEBUG_OUT_FILE,true)
function debug.tstr(t, indent)
 indent = indent or 0
 local indentstr = ''
 for i=0,indent do
  indentstr = indentstr .. ' '
 end
 local str = ''
 for k, v in pairs(t) do
  if type(v) == 'table' then
   str = str .. indentstr .. k .. '\n' .. debug.tstr(v, indent + 1) .. '\n'
  else
   str = str .. indentstr .. tostr(k) .. ': ' .. tostr(v) .. '\n'
  end
 end
  str = sub(str, 1, -2)
 return str
end
function debug.print(...)
 printh("\n=["..game.tick.."]=", DEBUG_OUT_FILE)
 for v in all{...} do
  if type(v) == "table" then
   printh(debug.tstr(v), DEBUG_OUT_FILE)
  elseif type(v) == "nil" then
    printh("nil", DEBUG_OUT_FILE)
  else
   printh(v, DEBUG_OUT_FILE)
  end
 end
end
--]]

-- == GAME LOOP ==

function _init()
    init_splash()
    init_level(game.level)
end

function init_splash()
    -- create splash sprites
    splash_sprites = {}
    splash_sprite_indexes = {}
    splash_red_sprite_count = 0
    local i = 1
    for n=1,2 do
        for x in all(npcs) do
            if body_size(x) < 3 then
                add(splash_sprites, tern(rnd() > 0.5, x.spr_n[1][1], x.spr_n[1][1]+1))
                add(splash_sprite_indexes, i)
                i += 1
            end
        end
    end

    shuffle(splash_sprite_indexes)

    --music(2, 10000)

    change_state("splash")
end

function menu_skip_level()
    change_level = tern(game.level == tutorial_level, start_level, game.level + 1)
    while contains(skip_levels, change_level) do
        change_level += 1
    end
end

function change_state(s)
    game.state = s
    game.change_state_tick = game.tick
end

function _update()
    -- pre update
    game.tick += 1

    player_input()

    if game.state == "splash" then
        -- noop
    elseif game.state == "tutorial" then
        update_tutorial()
    elseif game.state == "level_splash" then
        if (game.tick - game.level_end_tick > 50) game.state = "play"
        update_level_switch()
    elseif game.state == "restart" then
        if (game.tick - game.level_end_tick > 16) game.state = "play"
    elseif game.state == "play" then
        update_play()
    elseif game.state == "victory" then
        update_particles(particles)
        update_particles(perm_particles)
    end    
end

function update_tutorial()
    local p = get_players()[1] -- assume one player

    if skip_tutorial then
        init_level(start_level)
        return
    end

    if game.level != tutorial_level then
        init_level(tutorial_level)
    end

    -- move
    p.delta = STILL

    if game.tick % tutorial_speed == 0 then
        p.delta = TUTORIAL_MOVES[tutorial_move_index]
        tutorial_move_index += 1
    end

    update_play()

    if tutorial_move_index > #TUTORIAL_MOVES then
        init_level(tutorial_level)
        tutorial_skippable = true
        tutorial_move_index = 1
    end
end

function update_level_switch()
    if change_level != game.level then
        init_level(change_level)
        particles = {} 
        change_state("level_splash")
        return true
    end
    return false
end

function update_play()
    -- restart
    if game.restart_level then
        init_level(game.level)
        game.restart_level = false
        particles={}
        change_state("restart")
        return
    end

    if (update_level_switch()) return

    -- play level
    npc_input()
    update_actors()
    check_win()
    -- update_player_big_pattern()
    update_big_patterns()
    update_particles(particles)
    update_particles(perm_particles)

    if _any(actors, moved) then
        mimic()
    end

    post_update_actors()
end

function _draw()
    if game.state == "splash" then
        draw_splash()
    elseif  game.state == "victory" then
        draw_victory()
    elseif game.state == "level_splash" then
        draw_level_splash(game.level)
    elseif game.state == "restart" then 
        draw_restart()
    elseif game.state == "play" or game.state == "tutorial" then
        draw_play()
    end
end

function draw_tutorial()
    if tutorial_skippable then
        thick_print(splash_keys_3, hcenter(splash_keys_3)-2, 115, 8, 1)
    end

    thick_print(splash_inst_1, hcenter(splash_inst_1), 14, 6, 1)
    thick_print(splash_inst_2, hcenter(splash_inst_2), 22, 6, 1)
    print("mimicking", 26, 22, 8)

    print("movement", 82, 22, 14)
end

function draw_restart()
    -- trasevol_dog fade
    drk={[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,8,10}
    for k=0,(game.tick - game.change_state_tick)/2 do
        for c=0,15 do
            cc=c
            for i=0,k do
                cc=drk[cc]
            end
            pal(c,cc,1)
        end
    end
end

function draw_play()
    cls()
    draw_level()
    draw_win()
    draw_actors()
    draw_particles()
    draw_ui()
    if (game.state == "tutorial") draw_tutorial()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000022220000000
000000000808000000aaaaaaaaaaaa00000000000088880000000000000000000000000000000ddd0000ddd00ddd0ddd0ddd0ddd000000222200220020000000
00700700888880000aaaaaaaaaaaaaa0000000000888888000888800009990900099090000000dd000000dd000dd0d0d00dd0d0d000002200220022020000000
00077000888880000aaadaaaaaaadaa0000000000878788008888880099999900999990000dddddd00dddddddddd000ddddd000d000000200020002000000000
00077000088800000aaaaaaaaaaaaaa0000000000888888008787880099999900999990000dddddd00dddddddddddddddddddddd000002202220022200000000
00700700008000000aaaaaaaaaaaaaa0000000000888888008888880009990900099090000dddddd00dddddddddddddddddddddd000000002000220200000000
000000000000000000aaaaaaaaaaaa00000000000088880000888800000000000000000000000dd000000dd000dd000000dd0000000000002200200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000ddd00ddd00000ddd0000000000000022000000000000
000aa0000000000000000000000000000000000000e00e000e0000e0000000000000000000000000000000000000000000000000000000000288200000000000
00aaaa000000000000aaaa0000111100000000000eeeeee0eee00eee00000000c000000c00000bbb0000bbb00bbb0bbb0bbb0bbb000000002888820000000000
0ddaaaa0000000000aaaaaa001111110000000000eeeeee0eee00eee000cc000cc0cc0cc00000bb000000bb000bb0b0b00bb0b0b000000002888882000000000
dd1da1aa000000000adadaa0011d1d100000000000eeee000eeeeee000cccc000cccccc000bbbbbb00bbbbbbbbbb000bbbbb000b222200002882220000000000
dd1da1aa000000000aaaaaa00111111000000000000ee00000eeee000cccccc000cccc0000bbbbbb00bbbbbbbbbbbbbbbbbbbbbb200000002882000000000000
0ddddaa0000000000aaaaaa0011111100000000000eeee000eeeeee0cc0cc0cc000cc00000bbbbbb00bbbbbbbbbbbbbbbbbbbbbb200000002882000090900000
00dddd000000000000aaaa0000111100000000000eeeeee0eee00eeec000000c0000000000000bb000000bb000bb000000bb0000200000002882000909090000
000dd0000000000000000000000000000000000000e00e000e0000e0000000000000000000000bbb0000bbb00bbb00000bbb0000200000002882000090900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222882000909090000
011100000111000001111110111110000110000000000000000000000ff0000000ff0000000000000000b0b00000909008880ccc288888888882000090900000
01111000111100001111111011111000011000000000000000bb00000ff0000000ff0000000000000b0003000000040008980c2c222222222222000000000000
0119990111999000111999900099999001199000b0000bb00b00b00b0fffffff00ffffff000000000030000009090409088eeccc200200002002000000000000
01199991199990001199999000999990011990000b00b00bb0000bb00ffffff000fffff0000000000030030000400440aaaefe00200200002002000000000000
011999999999900011990000000119900119900000bb0000000000000ffffff000fffff000000000b00030b000400400a9aeee00200200002002000000000000
011990999919900011990000000119900119900000000000000000000f0000f000f000f0000000000300300000044400aaa00000200200002002000000000000
011990099119900011990000000119900119900000000000000000000f0000f000ff00ff00000000000000000000400000000000220220002202200000000000
01199000011990001199000000011990011990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900011990000000119900119900000b00bb0000b00b000000000000000000000000009990009000000000000aaa0999000000000ccc000000eee
011990000119900011990000000119900119900000bbbb00000bbbb000000000000000000000000099099099000000000000a2a092900999ccc0c1c00eee0e2e
0119900001199000119911101111199001199000bbbbbb000bbbbbb000000000000000000000000090009990000000b00300aaa099900929c1c0ccc00e2e0eee
0119900001199000119911101111199001199000bbbbbb000bbbbbb00000000000000000000000000000000000300300b030030000303999ccc030000eee0030
011990000119900001999990009999900119900000bbbb00000bbbb0000000000000000000000000000000000b03030000303000000300000033000000300300
000990000009900000099990009999900009900000b00bb0000b00b0000000000000000000000000000000000003000000303000000300000003000000030300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc00000000000000000
0000a00000000000010000000000000000000000000000000000000000cccccccccccccccccccc00cccccc000cccccc0cccccc00cccccccc0222000001000000
000aaa000000000000000001000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0212002011100000
00aaaaa00000000000000000000066000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0222022201000020
000aaa000000000000000000006666600000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccc77cc0cccccccc0000002000000222
0000a0000000000000000100000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0cc7cc7c0cccccccc0010000000111020
000000000000000000100000000000000000000000000000000000000cccccccccccccccccccccc0cccccc0000cccc00ccccccc0cccccccc0111000000121000
000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc000000000000000000cccccc0000000000010000000111000
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00000000000000000000000000cccccc00000002000000010
000550000000000000000000066000000000000000000000000000000cccccc0ccccccc00ccccccc00cccc0000cccccccccccccccccccccc0000022200000111
005555000005550000000000000000000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0111002000000010
055555500055550000000000000660000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0121000001000000
055555500055555000055000006666000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0111000011102220
055555500555555000555500006666600000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0000010001002120
005555000555555000555550066666600000000000000000000000000cccccc0ccccccc00ccccccc0cccccc000cccccccccccccccccccccc0000111000002220
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000cccccc00cccccc00000010000000000
000330000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0cccccccc0cccccc00cccccc00000000000000000
003333000003300000000000000000000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000001000
003333000003300000000000006660000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00010000000200020
033333300033330000033000066666600000000000000000000000000cccccccccccccccccccccc00ccc77ccccccccccccccccc0cc77ccc00111000000000000
033333300033330000333300000000000000000000000000000000000cccccccccccccccccccccc00cc7cc7cccccccccccccccc0c7cc7cc00010020000000000
003333000333333000333300000660000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000222000002000
0004400000044000000440000066660000000000000000000000000000ccccccccccccccccccccc000cccccccccccccccccccc00cccccc000000020001000010
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000cccccccc00000000000000000000000000000000
000000000000000010000000000006000000000000000000000000000000000000000000000000000cccccc00cccccc000000000000000000000000000000000
0000000000100000000000100000666000000000000000000000000000cccccccccccccccccccccc0cccccc00cc77cc0000030000000a0000000000000000000
001000000000000000000000000000000000000000000000000000000cccccccccccc77ccccccccc0cccccc00c7cc7c000033300000aa0000100000000020000
000000000000000000100000006600000000000000000000000000000ccc77cccccc7cc7ccc77ccc0cc77cc00cccccc00033333000aaa0000000020000222000
000000000000001000000000066660000000000000000000000000000cc7cc7cc77ccccccc7cc7cc0c7cc7c00cc77cc000033300000a00000000000000020000
000010000000000000000000066666600000000000000000000000000ccccccc7cc7cccccccccccc0cccccc00c7cc7c000003000000000000020000000000000
000000001001000010000000000000000000000000000000000000000ccccccccccccccccccccccc0cccccc00cccccc000000000000000000000010000000000
000000000000000000000001000000000000000000000000000000000cccccc000000000000000000cccccc00cccccc000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
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
00000000000000000000000000000000000000000000000000000000000000000000000000e4e400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000e4e4e4000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000e4e400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000091b100000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05151505051505750606060615151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414141414141414141414141414141400000000000000000000000000000000
05052414051515751614171415151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414140714141414141414141414141414000000000000000000000000000000
15151414148214751614260714151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414141414141414141414141414141414000000000000000000000000000000
05071414141417a71616161414241515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414141414271414141414141414171414000000000000000000000000000000
17141427140514751616167484a41515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001407141414141414141714141414141414000000000000000000000000000000
0614141405050575161651a715151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001427150505150505050505150505141414000000000000000000000000000000
06141405050505958484849615151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414052714141427160616061605141414000000000000000000000000000000
06051515151515752414147515151515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414051450140714061616160615140714000000000000000000000000000000
06071574848484d6531474c605150515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414051414141414161616160615141414000000000000000000000000000000
061515a7060606151424751405171515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414051417141424161606061605141414000000000000000000000000000000
061516b4060505050714752414501414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414150714141414160651161605271414000000000000000000000000000000
06161616060505051515751514241406000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414051714140714061616160605141414000000000000000000000000000000
06161616060505051515751516060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414051515050515050515051505141414000000000212420212422200000000
06161616160505151515b41506060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414171414141414141414141427141414000000000313430313432300000000
06161616161616151515151506060406000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414141414141407141414141414141414000000000000000000000000000000
06060606060606061505151506060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001414141417141414141414171414141414000000000000000000000000000000
__label__
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
000000000000000000000000000000000000000000000ff000000000000000000000000000000000e0000e000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000ff00000000000000000000000000000000eee00eee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000ffffff00000000000000000000000000000000eee00eee00000000000000000000000000000000000000000
000000000000000000000000000000000000000000fffff000000000000000000000000000000000eeeeee000000000000000000000000000000000000000000
000000000000000000000000000000000000000000fffff0000000000000000000000000000000000eeee0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000f000f000000000000000000000000000000000eeeeee000000000000000000000000000000000000000000
00000000000000000000000000000000000000000ff00ff00000000000000000000000000000000eee00eee00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000e0000e000000000000000000000000000000000000000000
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
00000000000000000000000000000000000001110000011100000110000001110000011100000110000001111110000000000000000000000000000000000000
00000000000000000000000000000000000001111000111100000110000001111000111100000110000011111110000000000000000000000000000000000000
0000000000000000ff00000000000000000001199901119990000119900001199901119990000119900011199990000000000000000000000000000000000000
0000000000000000ff00000000000000000001199991199990000119900001199991199990000119900011999990000000000000000000000000000000000000
0000000000000000ffffff0000000000000001199999999990000119900001199999999990000119900011990000000000000000000909990000000000000000
0000000000000000fffff00000000000000001199099991990000119900001199099991990000119900011990000000000000000000999999000000000000000
0000000000000000fffff00000000000000001199009911990000119900001199009911990000119900011990000000000000000000999999000000000000000
0000000000000000f000f00000000000000001199000011990000119900001199000011990000119900011990000000000000000000909990000000000000000
0000000000000000ff00ff0000000000000001199000011990000119900001199000011990000119900011990000000000000000000000000000000000000000
00000000000000000000000000000000000001199000011990000119900001199000011990000119900011990000000000000000000000000000000000000000
00000000000000000000000000000000000001199000011990000119900001199000011990000119900011991110000000000000000000000000000000000000
00000000000000000000000000000000000001199000011990000119900001199000011990000119900011991110000000000000000000000000000000000000
00000000000000000000000000000000000001199000011990000119900001199000011990000119900001999990000000000000000000000000000000000000
00000000000000000000000000000000000000099000000990000009900000099000000990000009900000099990000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000099099909990999099900000099999000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000900009009090909009000000990909900000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000999009009990990009000000999099900000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000009009009090909009000000990909900000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000990009009090909009000000099999000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000e0000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000eee00eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000eee00eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c000000000000000
00000000000000eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0cc0cc000000000000000
000000000000000eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000000000
00000000000000eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc00000000000000000
0000000000000eee00eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc000000000000000000
00000000000000e0000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000c000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000cc0cc0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000cccccc000000000000000000000000000000009099900000000000000000000000000000000000000000000
000000000000000000000000000000000000000000cccc0000000000000000000000000000000009999990000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000cc00000000000000000000000000000000009999990000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000009099900000000000000000000000000000000000000000000
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
00011001101010111011101100011010100110000000000000000000000000000000000000000000000000000000000000000000000111000001000000011100
00100010101010101010001010100010101010000000000000000000000000000000000000000000011010000110101001100001010101000001000000010100
00111010101010110011001010100011101010000000000000000000000000000000000000000000101010001010101010100001010101000001110000010100
00001010101010101010001010100010101010000000000000000000000000000000000000000000111010001110111011100001110101000001010000010100
00110011000110101011101010011010101100000000000000000000000000000000000000000000101001101000101010100000100111001001110010011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000fd00fffeff0602060400000800000000fffefffeff0602060000000000000000ff00fffe021001130000000000000000ff00000002001014151617081010601010100202020202020280800404244010101002020202020202808001012140101010020202020202028080101010401010100202020202280880a0
0808080808080808080808080808080802020202020000000800000000000000020202020000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
60606061606060606060606060616060414141414141414141414141414141416061616260606060606060606061606041414141414141414141414141414141606060606060606060606060606060606160626160606060616050616061606060606060606060606060606060606060712a4141414141417141714141414171
6071414170426060616061616061606241714161626161704141704141414241606061606060606060616260626060604141414153414153416341414141414160606060606060606060606060616061606160606060606161626150506260606060606060606060606060606061606170414141613c4141414172412c604171
6141704141416060607241704261606041416047487849617141414141414141484c60626061606162606060606060604153634143436343436343414153414161616160616161616161606147784a6160626260616161626060616050506060616161606161616161616061477848484141413b7241412a3f41412a412a4141
6071414141716061604161606161616071606257407067496041414141414170515760606040606060606060516060604163406343177363734343634343636361606161626060616161616157606060606061616060606061606051515060616160616160607c61616161615760606070413c613b41414241424242413e4141
6160606061606061424160606161616041416057414171674c6170414171414151677848484960606147484960516060534363634363434363737363436363434878484961606147487848495760606160616161606262606061605040506060605b794961606147487848495760606141412a41412a3d722a413b4141414141
606060606060606141606160606060604141616a49414141576041414141414150515151516a48480758707a5151606063436361616061606060606351515053606061576161617b515050676d60616160606060606060616160605050506060606061576161617b515050676d6061614141412c414141424241423e61414142
60054142417042414170424160604060424141616749417057607160606070415051515151515151516a486c5160606060606061614160616060616351505063606061677948486c516161616060606160626051606060626051505150515150606061677948486c516161616060606141724141422a42422a3b422a72414141
60606060604160606060606060616060417041416067784858606062606060605027505151505051515151515161606061616141414141616061515050515151616160515051505151517162726060616050515160606060605041505050615161616051505150515141716272606061414141413b3e413b402a414141412a41
616060616041426061606160606060604141414160606060674961606062606051515150515151515150774a51606060606141417241414141424141417241606051515150505150515170414141416160515051424170606051715051506050605151515050515051424141414141613b414141424241412a713b3f72413c2a
60606160616041414260606061606060417141416160606160674848790749614142054142515150515157515060156061417241414142414141605150505160615151505051505147784a414141726161605151414141416050415051506051505151505051505147784a41414172612a41714141412a70414241422a417241
6260606060606060704160606061606071414170414141416060616160606a48515141414141715147796c51606160615070415141414172416060505150515151515152514748486d414162414160616060515052414142605041505050605051515152514748486d4141624141606141724141412a2c2a423b607242414141
606060606060616061706060606061604141417141417141414142606060616050517748784848486c51515151506060505141506052604160515151515051515152275052576170414160616041606162605050414141414141415060506060515227505257617041416061604160614141613d4172424141413c4142424141
4878484960606060604260606160606041414141414141414141416060606060605057605050505151515150505160605150515160416061515151505150515151515151517a614142606161604260616060512742414141424171506050606251515151517a6141426061616042606141413b2a414141413b3e41412a424171
6060606a48496160604160601560606041424141424141414241416162626160606157606050704151505151516060605050506061726160605050505150505151405151516749614242611560416061626051505061056161615151615150615151515151674961424261156041606141414241413c3b413f4142412c3b4141
606161606167496060606060606061604141057041714141414141606161156148486d606160506060515150606060615150606061056161606051275151515151515151515157610542414141416060606150515060606060606260606061615140515151515761054141414170606070054242414141414141414141617241
6160616060607a6061606061606060607041414141704141414171417160616160606060606261606160606060606162505050505050505050505050505050505150505250507a606060606060606060605150506160616161616161616160605150505250507a606060606060606060717241414141412a4241414141417071
4141414141414141414141414141414160606060606060606060606060606060606062616161605050437343736373634141414141414141414141414141414141414150514141414141414170504141616060605051505150576070414161615050505050505050505050505050505043637363634363736363437363736373
41414141424141414041414241414141606060606060606060606060606160616177484878484848077948484c436363417041414141414171414141414141414170414105704150424141414241514160606160605051514e7a6161424748795041414141414141414141414141415073737363736343736363437363636363
417041414141424363437241414141416161616061616161616160614748784861574171637350734343505067484973414141417e4141414141416f4141414141514141414141514141415241414171616161606051515e6e576161617b6061504141414141414141414141414141504373637342414141417241727363636e
417041414141736363734341414141416160616162616061616161615760606061577018736350517363434350635773414141414141417241414141414142417041415041427051524141704152414160615a60605151505e67784848696170504141414141414141414141414141506163637241414363734341416373634e
4141414141634317436363634241414148784849611561474878484957606061627b7141637343505050735043637a43414141414141414141414141414141414151417151505051714151514141414160607b6060515e5e7e7e4f6e7e57614150414141414141414141414141414150606061414147784848484c7163635e7e
424141414373636351504363434141416060615761616157515050676d6061616157707160626060515050504363577372415050505050505050505050504141415251505e6e512751507e4f52504141606167487948496e5e6e6e7e4f7a60715041414141414141414141414141415061616141776c4241417167496f5f6e6e
41414141636343515050517373414141606061677948486d51616161606070616157414160606060606050505043576141415005726060606e6f7e5e7e504141506e7e51514e7e4e7e6f6e51505172416060616061606778496e6e6e6f6749605041414141417373734e4e414141415060606141576051417051617b4f7e6f5e
4141417351525151515150515263414261616051505150515141714172414161617a414171616161616160515151576141415071416060605f7e6e7e6e50417042514e7e516f6f6e6f6e5f507e4e51416060724141706060577e4e6e6e6e674c5041414141187373734e4e41414141506161614157504041414050575e6e6f7e
414152515151515152515151515052516051515150505150514170414141416161576041414160606161412841707b6241415041706060607e6e5e6e405041414150515e7e5f7e6e4e6f7e4e6e5041416161416151417151576f4f6e7e6e6f575041414141417373414e4e4141414150616060417b60506f7e516057197e5f6f
51505151616061616061616061515151615151505051505147784a41414172616157604141414160614141414160576041415070726015606e096e6f7e504141417151506e7e5f707e5f6e505070414160604160515241476d7e096f6e47486c5060514141414e4e4e4e4e4141414150606051415751607e7e6151574f6e7e5f
5151516142414170414141706061606151515152514748486d41414172416161607a6061714141426041414160615761704150505050505050505050505041415142515f7e407e6e6e7e7e505142414160617161504172577e4e7e6e6e7b616050605141414e5f5e5f4e5f414141415061615152674c517e6f51476d7e6f6f4f
505061414162414141424170416161615152275052576170414171414141606162576061714141424242524748486d62414141414141414141414141414141414150515e7e6f7e096e6f6f7e5141507160604115275151576f6e406f6e57614150605141414e5e5f5e4e41414141415061615142504b607e6f614b516e7e7e50
5150617141606141515041417051506051515151517a614162414141417261616057506071714142425250576161615041416f414171414141414141414241414170517e5f5e4f4e7e5f7e6e51514141617170606151517b6e6e6e6e6f57617150152741414e5f5e194e4141414141506115274150514e7e7e6e7e4f4e7e5151
516161606160724151424141700551615140515151674961426241417141606161575060627141415150476d61505143414141414141414141417e414141414141515f6e5152504f5051515e7e514150600542616051476848494e6e476c60415041414141414e4e5f4e4141414141505050504150516e6f7e7e7e7e7e7e5151
6160606061156151275150515151526051515151515157610561606041416160627b60506061055051626749524340734141414141414141704141414141414150526e507071505241517051517051706061616151507a6160576f476d61614150054141414141414141414141414150500542415151524e6e4f4f4f5f525151
606161606161515151515050505051525150505250507a6060606060606060606157606261506161615151575173437341414141414141414141414141414141714151424141504141714151414141416061615150515761616a486c616141705050505050515151515151505151515150505050505150515150515051515151
__sfx__
000400000653007500005002640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000107500e740177300070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000600001f04026030270202e0202e020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001402015010150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001062010600156101060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f76013750167400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000011150111501715017150111501115012150121500e1500d1500b150061500215001150001500015000150076500765007650076500010000100001000010000100001000010000100056000560005600
001000002610026130261300e1300e1300e13026130261300e1300e1300e13026130261302d61032610376103d6103f6103c6103d6103c6102f630296301e610176000b600076000560003600026000060000600
000c0000220601e050210501d0501e05027050240502100029100291000000024000006000060000600006000060000600006000060000600006000060000600006000060012600126001260012600126000c600
000700003051030520305103b100001001c7001570016600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00001305018050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000000001e02001000000001e030230502705000000010002f050040002f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000245202c5102c5102c5102c5102c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400001e520275102751027510275102c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400001b520225102251022510225102c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400000a520125101251012510125102c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00040000125201b5101b5101b5101b5102c5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
790f00203e5553b5553755536555325552f5551f5551e5551a5551755513555125500e5500b55007550065503f5553c555395553555534555305552d555295552855524555215551d5501c5500c5501555011550
910f000036055320552f0552d0552b0553600000000000000000000000000000000000000000000000000000370553505534055300552d0550000000000000002403528035290452d04530045340453505539055
010f00000e0500e0500e0500e0500e0400e0400e0400e0300e0300e0200b0500b0500b0500b0500e0500e051110501105010050100500c0500c0500c0500c0500c0400c0400c0400c0300c0300c0300c0200c010
b328000009552265000b550275050e5000e552105500050013550005000955000500175520050013550275000e5520050010500005000e550005000b5001755215550005000b5002750015550005001355200500
790f00003e5553b5553755536555325552f5551f5551e5551a5551755513555125500e5500b5500755006550005553c555395553555534555305552d555295552855524555215551d5501c5500c5501555011550
010f00000b0500b0500b0500b0500b0400b0400b0400b0300b0300b020070500705007050070500b0500b0510c0500c0500b0500b050050500505005050050500504005040050400503007050070500705007040
011300200c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c053000030000300003
011300200e1000e1001a5573e5560e1000e10039556210470e1000e1001f55737556091000e100350561d057091000e1001a556265471a5362652726517265130e1003055432554355542d5542b5302952500000
491300200b0400b0400b0400b0450b0400b0400b0400b0450b0400b0400b0400b0450b0400b0400b0400b0450a0400a0400a0400a0450a0400a0400a0400a0450a0400a0400a0400a0450a0400a0400a0400a045
011300200c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c0530000300003000030c053000030c5630c553
011300201d5541d5421d5321d5251a5541a5501d5541d5501f550215512155221552215501f5501d5501d5501f5521f5521f5501d5511a5501a55018554185401853218522185101851418500000000000000000
491300200904009040090400904509040090400904009045090400904009040090450904009040090400904503040030400304003045030400304003040030450004000040000400004500040000400004000045
011300201d5541d5421d5321d5251a5541a5501d5541d5501f550215512155221552215501f5501d5501d55024554245522455024551215542155026550265402653226522285542855029554295502d5542d552
49130020300002e0002b000290002800024000300002e0002b000290002800024000000000000000000000000000000000000000000000000000000000000000300262e0362b046290262803624047300362e026
011300200c0530000300003000030c0530000300003000030c053000030c5630c5530c053000030a5630a5530c0530000300003000030c0530000300003000030c053000030a5630a5530c053000030c5630c553
011300202d5522d5522b5502b55029551295502d5542d5522d5522d55229554295502b5542b5502d5542e5542d5542d5522d5522d5522b5542b55029554295502955229552245542555426554295542655426550
49130020290462605623046210361d027290162601623016150161102615026170361a0361d0472104623056290462605622046210361d027290162601622016150161102615026160361a0361d0472104622056
011300201d5541d5521d5521d5551a554185501a5500000021551215522455000000215512155024550000002255422550215501f5501d550000001a5541a5521a5521a5521a5521c5401d550185501d5501f554
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49130020300443005230042300323002230012300123001439000350003900030000340003500039000300002e0442e0522e0422e0322e0222e0122e0122e0142d0442d0522d0522d0522d0522d0522d0522d054
011300202105421052210522105023054230502405424052240502405026054260522605226052210542105221052210422105421052290512905028052280522b0542b0502d0522d0522b0542b0522905429050
49130020290442905229042290322b0542b0522d0522d0522d0522d054350543505035052350523205432042320423203232042320322d0542d05230051300503005030050290442905026054260522404424040
011300200c0530000300003000030c0530000300003000030c053000030c5630c5530c053000030a5630a55330615306152462524635306353063524625246253064530635306253063524643306432465330643
011300202153421552215522155221552215522154221542215322153221522215222151221512215140000027534275302753027532275322753227532275352653426530265302653226532265322653226535
491300200505005050050500505505050050500505005055050500505005050050550505005050050500505501050010500105001055010500105001050010550305003050030500305503050030500305003055
49130020180361d0461f0562104624036290462b0562d0463003629037300463504637056390563c0563505738036350463104630056380463504631056300563703633046320462e0563704633046320562e056
011300200c0530000000000000000c6550000000000000000c0530000000000000000c6550000000000000000c0530000000000000000c6550000000000000000c0530000000000000000c655000000000000000
011300201d5501d5501d5521d552115511155011552115520555105550055520555205552055530000000000000000000027355293552b3552c3552b3552b3442935524300273552430524355243442935500000
49130020186501865018640186401863018630186201862018610186100c6100c61000610006100061000614197161d7262073624746197561d74620736247261b7161f72622736267461b7561f7462273626726
011300200c0530000300003000030c6550000300003000030c053000030c5630c5530c655000030a5630a5530c0530000300003000030c6550000300003000030c0530000322563225530c655000032456324553
011300200505005050050500505505050050500505005055050500505005050050550505005050050500505508050080500805008055080500805008050080550a0500a0500a0500a0550a0500a0500a0500a055
491300200000000000243552432424320243102431430300273552400526355240052435524354273552400024000240002635524000243552435426355000000000000000243552433422355180052135521324
49130020000000000000000000000000000000000000000000000000000000000000000000000000000000002071624726277362b7462075624746277362b7262271626726297362d7462275626746297362d726
0113002021314213001d0501f05021051210521a0500000018050000001d0501d0501a0511a05218050000001f050200501b0501b050180501805016050160501d0501b05018050180501a0511a0501105211052
01130020197001d7002070024700197001d70020700247001b7001f70022700267001b7001f7002270026700197161d7262073624746197561d74620736247261b7161f72622736267461b7561f7462273626726
011300200c0530000300003000030c6550000300003000030c0531861418620186300c653000030a5630a5530c053000030c653000030c655000030c6550c6550c0530065324553225630c15313063115630c553
4913002011042110321102211014000000000029355000002d35000000303500000027356333503235032350293563535033350333553235500000293563535033355000003235000000393562d3542935500000
011300200c0500c0500c0500c0550c0500c0500c0500c0550c0500c0500c0500c0550c0500c0500c0500c0550d0500d0500d0500d0550d0500d0500d0500d0550d0500d0500d0500d0550d0500d0500d0500d055
01130020220512405124052240522405224051210512105021050210502105221052220502205222052220502205124051240522405224052240512905129050290522905229052290512b0512b0502b0502b050
19130020307552b75528755247551f75518735307552b74528745247451f74518735307552b7452874524745307552d75529755257551f75519735307552d74529745257452174519735307552d7452974525745
011300200e0500e0500e0500e0550e0500e0500e0500e0550e0500e0500e0500e0550e0500e0500e0500e0550f0500f0500f0500f0550f0500f0500f0500f0550f0500f0500f0500f0550f0500f0500f0500f055
011300202905129052290522905128051280502b0522b0522b0522b05228050280502905129050280502805026052260522605226050240512405027052270522705227051260512605226052260522205022050
19130020327552d7552975526755217551a035327552d7452974526745217451a035327552d7452974526745337552e7552b75527755227551b735337552e7452b74527745227451b735337552e7452b74527745
011300202b0512d0512d0522d0522d0522d0512e0512e0502e0502e0502e0522e051300513005230052300502b0512d0512d0522d0522d0522d051250512505025052250512405124050290542b0502905029050
01130020350313504035040350503505035052350523505235051340513405034050340523405234051300513005030052300522905129050290522905229042290422904229052180501d0501f0501d05229053
7913002000000000000000000000354553345530455304243545530000334553000030455304242c4552c4352c4252c4142c455000002e45500000304553043530425304142b4542b4352b4252b4142945500000
4913002000000000000000000000294552745524455244242b45500000294550000027455000002945529435294252941427455000002445500000204550000021455224551d4551d4351d4251d4141141411414
__music__
00 4d0e0f44
03 14424344
00 81828384
01 11121344
02 15121644
00 81828384
01 17181944
00 1a1b1c44
00 17181944
00 1a1d1c1e
00 1f201921
00 1a221c24
00 1a251926
00 2728292a
00 2b292c2d
00 2e2f3031
00 2b293233
00 342f3531
00 2b363738
00 2b393a3b
00 2b363c38
00 2b393d3b
00 2b293e2d
00 2e2f3f31
00 2b298033
00 802f8031
00 2b368038
00 2b39803b
00 2b368038
00 3439803b

