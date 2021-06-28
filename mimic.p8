pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- mimic v0.4.0
-- by sourencho

VERSION = "v0.4.0"

-- DATA

-- SETTINGS
start_level = 0
level_count = 12
skip_levels = {7}

slow_speed = 20 -- the larger the slower the npcs move
tile_slow_speed = 2 -- the larger the slower the tiles animate
player_spr_offset = 32

splash_inst_1 = "take the form of an animal"
splash_inst_2 = "by mimicking its movement"
splash_keys_1 = "move"
splash_keys_2 = "\139\145\148\131"
splash_keys_3 = "start \151"
won_text = "★ you win ★"

level_size = 16
ACTOR_ID_INDEX = 0

debug_mode = true
DEBUG_OUT_FILE = "out.txt"
SHOW_STATS = true
debug = "DEBUG\n"

-- spr numbers 2x2 matrix to support large sprites
fish_spr = {{7, nil}, {nil, nil}}
sheep_spr = {{39, nil}, {nil, nil}}
butter_spr = {{21, nil}, {nil, nil}}
bird_spr = {{23, nil}, {nil, nil}}
frog_spr = {{53, nil}, {nil, nil}}
llama_spr = {{9, 11}, {nil, nil}}

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

-- tile spr values
cloud_1_spr = 67
cloud_2_spr = 83
cloud_3_spr = 99
cloud_4_spr = 115
ground_spr = 65

static_tiles = {tree, water, rock, ground, win, cloud, teru}
dynamic_tiles = {rock_small, tree_small, cloud_small}

tile_frame_counts = {
    [cloud_1_spr] = 4,
    [cloud_2_spr] = 4,
    [cloud_3_spr] = 4,
    [cloud_4_spr] = 4,
}
tile_frame_speeds = {
    [cloud_1_spr] = 500,
    [cloud_2_spr] = 500,
    [cloud_3_spr] = 500,
    [cloud_4_spr] = 500,
}

tile_display_names = {
    [tree] = "trees",
    [tree_small] = "trees",
    [water] = "water",
    [rock] = "rocks",
    [rock_small] = "rocks",
    [ground] = "ground",
    [cloud] = "cloud",
    [cloud_small] = "cloud",
    [teru] = "manish"
}

UP =    {x= 0, y =-1}
RIGHT = {x= 1, y = 0}
DOWN =  {x= 0, y = 1}
LEFT =  {x=-1, y = 0}
OTHER = {x=-1, y =-1}
STILL = {x= 0, y = 0}

-- GAME

-- sprite values of tiles
level_static_tiles = {}
level_dynamic_tiles = {}

game = {
    state = "splash", -- possible values [splash, play, won]
    level = start_level,
    tick = 0,
    level_end_tick = 0,
    pause_count = 0, -- the amount of ticks to pause the game
    restart_level = false,
}

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
        move_abilities = {tree, tree_small, win},
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
        spr_n = frog_spr,
        pattern = {UP, LEFT, UP, DOWN , RIGHT, DOWN},
        move_abilities = {ground, water, win},
        push_abilities = {tree_small, rock_small},
        display_name = "frog",
        shape = {1, 1}
    },
    {
        spr_n = llama_spr,
        pattern = {DOWN, DOWN, DOWN, UP, UP, UP},
        move_abilities = {teru},
        push_abilities = {tree_small, rock_small},
        display_name = "vishab",
        shape = {2, 1}
    }
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
    if(action == "move") then
        sfx(player_sfx[action][get_dynamic_or_static_tile_class(pl.pos)])
        return
    end
    sfx(player_sfx[action])
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

-- == UTIL ==

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

-- Enumerate and potentially filter a table
function enum(t, filter)
    local i = 0
    filter = filter or function (v) return v end
    return function()
        local o = t[i]
        i += 1
        if (o) return i, filter(o)
    end
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

function get_tile_class(t)
    return fget(t.spr)
end

function get_dynamic_or_static_tile_class(pos)
    local dynamic_tile = get_tile_class(level_dynamic_tiles[pos.x][pos.y])
    if (dynamic_tile != ground) return dynamic_tile
    return get_tile_class(level_static_tiles[pos.x][pos.y])
end

-- checks if two actors are made of the same set of animals
function is_comp_equal(a, b)
    -- sort(a.comp, function (x, y) return x > y end)
    -- sort(b.comp, function (x, y) return x > y end)
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
        return pl.pattern[pl.t]
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

-- == GAME LOGIC == 

function make_actor(pos, spr_n, pattern, move_abilities, push_abilities, display_name, shape, is_player, spr_2, comp)
    local a={}
    a.id = get_next_actor_id()
    a.pos = pos
    a.delta = zero_pos()
    a.spr = spr_n
    a.spr_2 = spr_2
    a.shape = shape
    a.move_abilities = copy_table(move_abilities)
    a.push_abilities = copy_table(push_abilities)
    a.comp = comp -- which sprites is this actor made of

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

    return a
end

function in_bounds(pos)
    return not (pos.x < 0 or pos.x >= level_size or
                pos.y < 0 or pos.y >= level_size)
end

function is_static_tile(tile_class, pos)
    if (not in_bounds(pos)) return false

    return get_tile_class(level_static_tiles[pos.x][pos.y]) == tile_class
end


function is_dynamic_tile(tile_class, pos)
    if (not in_bounds(pos)) return false

    -- find out if tile sprite is member of class
    return get_tile_class(level_dynamic_tiles[pos.x][pos.y]) == tile_class
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
    if level_dynamic_tiles[pos.x][pos.y].spr != ground_spr then 
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
    if (is_static_tile(ground, new_pos) and is_dynamic_tile(ground, new_pos)) then
        level_dynamic_tiles[new_pos.x][new_pos.y] = level_dynamic_tiles[pos.x][pos.y]
        level_dynamic_tiles[pos.x][pos.y] = make_tile(ground_spr)
    end
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
    add(dying, a)
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
    a.no_trans_count = flr((#a.pattern - 1) * 1.5) -- don't transform until doing a pattern loop

    -- vfx
    local frame_len = #a.pattern - 1
    sfx(change_pattern_sfx)
    -- confused_effects(a, new_move, old_move, 60)
    transform_vfx(a, get_spr_col(a.spr), 60, get_spr_col(a.spr_2))
    -- pause(slow_speed * 2)
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
        if can_move(new_pos, a) and not is_paused() then
            -- fuzz_trail_vfx(a.x, a.y, new_x, new_y, tern(a.is_player, 8, get_spr_col(a.spr)))

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
        if (not is_paused()) then 
            a.frame += 1
            a.frame %= a.frames
            a.no_trans_count = max(a.no_trans_count - 1, 0)
        end

        if (a.delta.x != 0) a.flip_x = a.delta.x > 0
    end
end

function update_actors()
    foreach(actors, update_actor)
end

function post_update_actors()
    for a in all(actors) do
        a.delta = zero_pos()
    end
end

function update_particles()
    remove = {}
    for p in all(particles) do
        if (p.end_tick < game.tick) then
            add(remove, p)
        end
    end

    for p in all(remove) do
        del(particles, p)
    end
end

function update_dyings()
    foreach(dying, update_dying)
end

function init_actors(l)
    for n in all(npcs) do
        local n_pos = find_sprite(l, n.spr_n[1][1])
        if n_pos != nil then
            local a = make_actor(
                n_pos,
                n.spr_n,
                n.pattern,
                n.move_abilities,
                n.push_abilities,
                n.display_name,
                n.shape,
                false,
                nil,
                {n.spr_n[1][1]}
            )
            add(actors, a)
        end
    end
end

function is_stuck()
    return not (can_move(v_addv(pl.pos, RIGHT), pl) or
                can_move(v_addv(pl.pos, LEFT), pl) or
                can_move(v_addv(pl.pos, UP), pl) or
                can_move(v_addv(pl.pos, DOWN), pl))
end

function no_npc()
    return #actors == 1
end

-- == PLAYER == 

player_spr = {{5, nil}, {nil, nil}}

PLAYER_PATTERN_SIZE = 8 -- must be at least 1 longer than the max npc pattern length and even

player_move_abilities = {ground, win}
player_push_abilities = {rock_small, tree_small, cloud_small}

function init_player(l)
    local player_pos = find_sprite(l, player_spr[1][1])
    pl = make_actor(
        player_pos,
        player_spr,
        {},
        player_move_abilities,
        player_push_abilities,
        "you",
        {1,1},
        true,
        nil,
        {})
    pl.t = 1;
    add(actors, pl)
    reset_player_pattern()
end

function player_input()
    if (btnp(0)) pl.delta.x = -1
    if (btnp(1)) pl.delta.x = 1
    if (btnp(2)) pl.delta.y = -1
    if (btnp(3)) pl.delta.y = 1
    if (btnp(4) and debug_mode) then
        -- transform_vfx(pl, 8, 20, 7)
    end
    if (btnp(5)) then
        if game.state == "splash" then
            game.state = "play"
        elseif game.state == "play" then
            game.restart_level = true
        else
            -- noop
        end
    end

    -- prevent diagonal movement
    if (pl.delta.x != 0) pl.delta.y = 0
end

function reset_player_pattern()
    pl.pattern={}
    for i=1,PLAYER_PATTERN_SIZE do
        add(pl.pattern, zero_pos())
    end
    -- init_player_big_pattern()
end

function update_player(p)
    -- check player victory
    if on_win(p) then
        change_level = game.level + 1
        while contains(skip_levels, change_level) do
            change_level += 1
        end
        sfx(11)
        win_vfx(pl.pos)
        game.level_end_tick = game.tick
        return
    end

    p.t = (p.t % #p.pattern) + 1;
    p.pattern[p.t] = copy_pos(p.delta);
end

-- == MECHANIC ==

-- BIG PATTERN

-- function player_big_pattern_mimic()
--     for shape_key, actor_to_pat in pairs(player_big_pattern) do
--         for a in all(actors) do
--             local a_shape_key = 10*a.shape[1] + a.shape[2]
--             if not a.is_player and a_shape_key == shape_key then
--                 for pair_actor, big_pattern in pairs(actor_to_pat) do
--                     if is_mimic(big_pattern, a.pattern, #pl.pattern, pl.t) then
--                         local new_pos = {min(pl.x, pair_actor.x), min(pl.y, pair_actor.y)}
--                         transform_player(a, new_pos)
--                         del(actors, pair_actor)
--                     end
--                 end
--             end
--         end
--     end
-- end

-- function update_player_big_pattern()
--     -- for all actors that move, update the players big pattern with then
--     -- if the player moved then update its big pattern with all actors
--     for a in all(actors) do
--         if moved(a) then
--             if a.is_player then
--                 for _a in all(actors) do
--                     _update_player_big_pattern(_a)
--                 end
--             else
--                 _update_player_big_pattern(a)
--             end
--         end
--     end

-- end

-- function _update_player_big_pattern(a)
--     -- for each shape and animal set the big pattern move if they are adjacent and their moves match
--     -- if their moves dont match then set the pattern move to OTHER 
--     local shape = form_shape(get_body(pl), get_body(a))
--     if shape ~= nil then
--         local shape_key = 10*shape[1] + shape[2]
--         player_big_pattern[shape_key][a][pl.t] = tern(
--             pair_equal(get_last_move(pl), get_last_move(a)), get_last_move(pl), OTHER)
--     end
-- end

-- function init_player_big_pattern()
--     player_big_pattern = {
--         -- key is (shape[1]*10 + shape[2])
--         [12] = {
--             -- assuming player always first of pair, each key is an actor
--             -- a1 = {pattern}
--             -- a2 = {pattern}
--         },
--         [21] = {
--             -- assuming player always first of pair, each key is an actor
--             -- a1 = {pattern}
--             -- a2 = {pattern}
--         }
--     }
--     for shape, t in pairs(player_big_pattern) do
--         for a in all(actors) do
--             if not a.is_player then
--                 t[a] = {}
--                 for i=1,#pl.pattern do
--                     add(t[a], OTHER)
--                 end
--             end
--         end
--     end
-- end


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
                -- local pattern_index = tern(a.is_player or b.is_player, pl.t, a.t % #a.pattern + 1)
                -- animal_big_patterns[animals][shape_key][pattern_index] = 
                --     tern(shape_key == pair_shape_key and pair_equal(get_last_move(a), get_last_move(b)),
                --     get_last_move(a), OTHER)
                -- if shape_key == 21 and (a.is_player or b.is_player) then 
                --     debug.print({{a.display_name, moved(a)}, {b.display_name, moved(b)}, pattern_index})
                --     debug.print({get_last_move(a), get_last_move(b), pair_shape_key})
                --     debug.print(animal_big_patterns[animals][shape_key])
                -- end
            end
        end
    end
end


-- function init_big_patterns()
--     animal_big_patterns = {}
--     for i=1,#actors-1 do
--         for j=i+1,#actors do
--             if not (actors[i].is_player or actors[j].is_player) then
--                 animal_big_patterns[{actors[i], actors[j]}] =
--                 {
--                     [12] = {},
--                     [21] = {},
--                 }
--             end
--         end
--     end
-- end

-- function update_big_patterns()
--     for animals, shape_key_to_pattern in pairs(animal_big_patterns) do
--         local a, b = animals[1], animals[2]
--         if moved(a) or moved(b) then
--             for shape_key, pattern in pairs(shape_key_to_pattern) do
--                 local pair_shape = form_shape(get_body(a), get_body(b))
--                 local pair_shape_key = -1
--                 if (pair_shape ~= nil) pair_shape_key = 10*pair_shape[1] + pair_shape[2]
--                 if shape_key == pair_shape_key and
--                    pair_equal(get_last_move(a), get_last_move(b)) then
--                     add(animal_big_patterns[animals][shape_key], get_last_move(a))
--                 else
--                     animal_big_patterns[animals][shape_key] = {}
--                 end
--             end
--         end
--     end
-- end

function animal_big_mimic()
    local actors_to_add = {}
    local actors_to_del = {}
    for a in all(actors) do
        local shape_key = 10*a.shape[1] + a.shape[2]
        if (a.is_player or body_size(a) != 3) goto cont
        for animals, shape_keys in pairs(animal_big_patterns) do
            local a1, a2 = animals[1], animals[2]
            for pair_shape_key, pat in pairs(shape_keys) do
                if shape_key == pair_shape_key then
                    local maybe_player, other = maybe_get_player_and_other(a1, a2)
                    if is_mimic(pat, a.pattern, #maybe_player.pattern, maybe_player.t % #maybe_player.pattern + 1) then
                        if maybe_player.is_player then
                            local new_pos = {x = min(maybe_player.pos.x, other.pos.x), y = maybe_player.pos.y}
                            transform_player(a, new_pos)
                            actors_to_del = table_concat(actors_to_del, {other})
                        else 
                            to_add, to_del = merge_big_animal(a, a1, a2)
                            actors_to_add = table_concat(actors_to_add, to_add)
                            actors_to_del = table_concat(actors_to_del, to_del)
                        end 
                        goto cont
                    end
                end
            end

        end
        ::cont::
    end

    -- TODO: we need to update the animal_big_patterns properly for add and del actors here
    for x in all(actors_to_del) do
        del(actors, x)
        for animals,shape_keys in pairs(animal_big_patterns) do
            if (contains(animals, x)) animal_big_patterns[animals] = nil
        end
    end

    foreach(actors_to_add, function(x) add(actors, x) end) 
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

function shift_pattern_halfway(pattern)
    shifted = {}
    local half_len = #pattern / 2.0 - 1
    for i = 1,#pattern do
        shifted[i] = {}
        shifted[i].x = pattern[((i + half_len) % #pattern) + 1].x
        shifted[i].y = pattern[((i + half_len) % #pattern) + 1].y
    end
    return shifted
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
    animal_mimic()
    animal_big_mimic()
    -- player_big_pattern_mimic()
end

function transform_player(a, new_pos)
    transform_animal(pl, a, new_pos)
    reset_player_pattern()
end

function transform_animal(a, other, new_pos)
    debug.print({a.pos, new_pos})
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
end

-- currently hardcoded to only work for shape {2,1}
function merge_big_animal(a, o1, o2)

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
        {o1.spr[1][1], a.spr[1][1]}
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
        {o2.spr[1][1], a.spr[1][1]}
    )

    -- dont allow them to transform for one pattern loop
    new_big.no_trans_count = flr((#new_big.pattern - 1) * 1.5) -- don't transform until doing a pattern loop
    new_o1.no_trans_count = flr((#new_o1.pattern - 1) * 1.5) -- don't transform until doing a pattern loop
    new_o2.no_trans_count = flr((#new_o2.pattern - 1) * 1.5) -- don't transform until doing a pattern loop

    -- TODO: mark the actors we are going to delete as "used"
    --       so that they dont participate in other merges
    
    -- fx
    play_player_sfx("transform")
    transform_vfx(o1, get_spr_col(a.spr), 20)
    transform_vfx(o2, get_spr_col(a.spr), 20)
    transform_vfx(a, get_spr_col(o1.spr), 20, get_spr_col(o2.spr))

    return {new_big, new_o1, new_o2}, {o1, o2, a}
end

function merge_animals(a, b)
    local merged_move_abilities = table_concat(a.move_abilities, b.move_abilities)
    a.move_abilities = copy_table(merged_move_abilities)
    b.move_abilities = copy_table(merged_move_abilities)
    a.spr_2 = b.spr
    b.spr_2 = a.spr
    a.comp = {a.spr[1][1], b.spr[1][1]}
    b.comp = {a.spr[1][1], b.spr[1][1]}
end

function animal_mimic()
    for a in all(actors) do
        for b in all(actors) do
            if (not is_comp_equal(a, b) and 
               is_mimic(a.pattern, b.pattern, #a.pattern, tern(a.is_player, a.t, 0)) and
               a.no_trans_count <= 0 and b.no_trans_count <= 0 and
               a.shape[1] == b.shape[1] and a.shape[2] == b.shape[2] and
               pair_equal(a.shape, {1,1}) and pair_equal(b.shape, {1,1})) then
                if a.is_player then
                    transform_player(b)
                elseif b.is_player then
                    transform_player(a)
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
    if patterns_match(in_pattern, fit_pattern, start_i) then
        return true
    else
        return false
    end
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

function get_player_pattern_coords()
    local coords = {}
    for i=3,1,-1 do
        local p_i = ((pl.t - i) % #pl.pattern) + 1
        local pattern_move = pl.pattern[p_i]
        add(coords, pattern_move)
    end
    return rev_pattern(coords)
end

function get_player_pattern_tile_coords()
    local coords = {}
    local loc = copy_pos(pl.pos)
    for pattern_move in all(get_player_pattern_coords()) do
        local new_loc = v_subv(loc, pattern_move)
        add(coords, new_loc)
        loc = new_loc
    end
    add(coords, pl.pos)
    return coords
end

-- == LEVEL and MAP ==

function make_tile(tile_spr)
    local tile = {
        -- SCHEMA:
        -- (int) frames
        -- (int) speed
        -- (int) tick_offset
        -- (int) spr
        -- (int) frame
    }

    local tile_frame_count = tile_frame_counts[tile_spr]
    if (tile_frame_count == nil) tile_frame_count = 0
    tile.frames = tile_frame_count

    local tile_frame_speed = tile_frame_speeds[tile_spr]
    if (tile_frame_speed == nil) tile_frame_speed = 0
    tile.speed = tile_frame_speed
    tile.tick_offset = flr(rnd(tile.speed))

    tile.spr = tile_spr
    tile.frame = flr(rnd(tile_frame_count))
    return tile
end

function init_level(_level)
    actors = {}
    game.tick = game.level_end_tick
    game.level = _level
    change_level = game.level
    -- game.tick = 0
    init_tiles(_level)
    init_actors(_level)
    init_player(_level)
    init_big_patterns()
    menuitem(2,"level: ⬅️ "..change_level.." ➡️", menu_choose_level)
    --music(01)
end

-- Loads in level by populating 2d array of tiles `level_static_tiles` and `level_dynamic_tiles`
function init_tiles(l)
    for i=0,level_size-1 do
        level_static_tiles[i] = {}
        level_dynamic_tiles[i] = {}

        for j=0,level_size-1 do
            local tile_spr = get_tile(i, j, l)
            local tile_class = fget(tile_spr)
            if (tile_spr == 0) then 
                print(tile_spr)
                print(tile_class)
                stop(i.." "..j)
            end
            if contains(dynamic_tiles, tile_class) then
                level_static_tiles[i][j] = make_tile(ground_spr)
                level_dynamic_tiles[i][j] = make_tile(tile_spr)
            elseif contains(static_tiles, tile_class) then
                level_static_tiles[i][j] = make_tile(tile_spr)
                level_dynamic_tiles[i][j] = make_tile(ground_spr)
            else
                debug_log(tile_class.." tile not dynamic or static")
            end
        end
    end
end

-- Given a level number will return the (x,y) position of the sprite
function find_sprite(l, spr_n)
    for i=0,level_size-1 do
        for j=0,level_size-1 do
             if get_sprite(i,j,l) == spr_n then
                return {x = i, y = j}
            end
        end
    end
    return nil
end

function get_tile(x,y,l)
    i = (x + 2*l*level_size) % 128
    j = y + flr(level_size * 2*l / 128)*level_size
    return mget(i,j)
end

function get_sprite(x,y,l)
    i = (x + (2*l+1)*level_size) % 128
    j = y + flr(level_size * 2*l / 128)*level_size
    return mget(i,j)
end

-- == VFX ==

function fuzz_trail_vfx(r1, c1, r2, c2, col)
    fuzz_line_vfx({{r1*8+4, c1*8+4}, {r2*8+4, c2*8+4}}, col, 2, nil, 3, 0)
end

function box_vfx(pos, col)
    local box_particle = {
        pos = v_mults(pos, 8),
        col = col,
        draw_fn = draw_box,
        start_tick = game.tick,
        end_tick = game.tick + 30,
        meta_data = {}, 
    }
    add(particles, box_particle)
end

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

function draw_box(pos, col, curr_tick, start_tick, end_tick, meta_data)
    rect(pos.x, pos.y, pos.x + 7, pos.y + 7, col)
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

function draw_confused_animal(pos, col, curr_tick, start_tick, end_tick, meta_data)
    print("!", pos.x + 1, pos.y + 1, col)
    print("!", pos.x + 4, pos.y + 1, col)
end

function draw_dot(pos, col, curr_tick, start_tick, end_tick, meta_data)
    rectfill(pos.x + 3, pos.y + 3, pos.x + 4, pos.y + 4, col)
end

function draw_blocked_cross(pos, col, curr_tick, start_tick, end_tick, meta_data)
    line(pos.x + 2, pos.y + 2, pos.x + 5, pos.y + 5, col)
    line(pos.x + 2, pos.y + 5, pos.x + 5, pos.y + 2, col)
end

-- confused effect when animal needs to change pattern
function confused_effects(a, new_move, old_move, dur)
    local blocked_tile = v_addv(a.pos, old_move)
    for k, l in pairs(get_tile_lines(blocked_tile)) do
        fuzz_line_vfx(l, 8, dur, 2, 1)
    end
end

-- heart pops up when you meet an animal
function overlap_effects()
    for a in all(actors) do
        if (not a.is_player) and
           collides(get_body(pl), get_body(a)) then
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
        end
    end
end

function win_vfx(pos)
    explode_vfx(pos, 10, 1.5, 40, 30, 90, 0.3, 1.5)
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

function transform_vfx_crude(a)
    if (not debug_mode) return 
    for pos in all(add(tiles, get_pattern_tile_coords(a))) do
        box_vfx(pos, 8)
    end
end

function explode_vfx(pos, col, size, count, min_dur, max_dur, min_spd, max_spd)
    for i=0,count do
        spark = {
            pos = {x = pos.x*8 + 4, y = pos.y*8 + 4},
            col = col,
            draw_fn = draw_spark,
            start_tick = game.tick,
            end_tick = game.tick + rnd(max_dur - min_dur) + min_dur,
            meta_data = {
                dir = v_normalize({x=rnd(2) - 1, y=rnd(2) - 1}),
                size = flr(rnd(size)),
                spd = rnd(max_spd - min_spd) + min_spd,
            },
        }
        add(particles, spark)
    end
end

-- == DRAW ==

function draw_splash()
    cls()

    print(splash_keys_3, hcenter(splash_keys_3)-2, 105, 8)

    if(game.tick % 60 > 0 and game.tick % 60 < 20) cls()


    map(100,58,36,10,8,4)
    print("ALPHA", 94, 20, 1)
    print(VERSION, 103, 121, 1)

    print(splash_inst_1, hcenter(splash_inst_1), 54, 13)
    print(splash_inst_2, hcenter(splash_inst_2), 64, 13)

    print(splash_keys_1, hcenter(splash_keys_1), 78, 13)
    print(splash_keys_2, 48, 88, 13)
end

function draw_won()
    cls()
    print(won_text, 38, vcenter(won_text)+1, 1)
    print(won_text, 38, vcenter(won_text)+2, 9)
    if game.tick % (flr(rnd(10)) + 40) == 0 then
        explode_vfx(
            {x = mid(6, flr(rnd(16)), 10), y = mid(8, flr(rnd(16)), 8)},
            9, 2, 40, 30, 60, 1.5, 2.5)
    end
    draw_particles()
end

function draw_level_splash_2(l)
    --cls(7)
    local txt_clr
    local box_clr = 1
    local margin = 3
    local padding = 2
    local size = 27
    local row = 0
    local col = 0
    local x, y
    local level_text

    -- border
    rect(1,1,127,127,box_clr)
    rect(2,2,126,126,box_clr)

    for i=0,level_count-1 do
        -- coord
        x = margin + (row % 4) * (size + 2 * padding)
        y = margin + col * (size + 2 * padding)

        -- text
        level_text = i
        if (i < 10) level_text = "0"..level_text
        if (i == l) then txt_clr = 7 else txt_clr = 1 end
        if (contains(skip_levels, i)) level_text = "xx"


        -- draw
        -- rect(x + padding, y + padding, x + size, y + size, box_clr)
        -- circ(x + padding + size/2, y + padding + size/2, size / 2, box_clr)
        print(level_text, x + size/2 - 2, y + size/2 - 1, txt_clr)

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
    end
    draw_particles()
    draw_actor(pl)
end

function draw_level_splash(l)
    draw_actor(pl)
    draw_particles()
    local level_text="level "..l
    print(level_text, hcenter(level_text), vcenter(level_text), 1)
end

function draw_level()
    local t
    for i=0,level_size-1 do
        for j=0,level_size-1 do
            for t in all({level_static_tiles[i][j], level_dynamic_tiles[i][j]}) do
                if (t.spr == nil) print(i.." "..j)
                if t.spr > 0 then
                    if t.frames != 0 and (game.tick + t.tick_offset) % t.speed == 0 then
                        t.frame += 1
                        t.frame %= t.frames
                    end
                    spr(t.spr + t.frame, i*8, j*8)
                end
            end
        end
    end
end

function draw_actor(a)
    -- change colors to be red
    if a.is_player then
        pal({[6]=8, [9]=8, [10]=8, [11]=8, [12]=8, [13]=8, [14]=8})
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
                spr(
                    spr_n + a.frame,
                    ax,
                    ay,
                    1, 1, tern(body_size(a) < 3, a.flip_x, false))
            end
        end
    end

    pal()
end

function draw_dying(a)
    spr(a.spr, a.x*8, a.y*8, 1, 1, a.flip_x)
    print("?", a.x*8 + 1, a.y*8 + 1, 8)
    print("!", a.x*8 + 4, a.y*8 + 1, 8)
end

function draw_particle(p)
    p.draw_fn(p.pos, p.col, game.tick, p.start_tick, p.end_tick, p.meta_data)
end

function draw_actors()
    foreach(actors, draw_actor)
    foreach(dying, draw_dying)
end

function draw_particles()
    foreach(particles, draw_particle)
end

function draw_ui()
    if is_stuck() then
        -- "restart"
        stuck_text = "press \151 to restart"
        print(stuck_text, hcenter(stuck_text), vcenter(stuck_text), 7)

        -- "gota can't"
        local explain_txt_animal = pl.display_name.." can't"
        print(explain_txt_animal, hcenter(explain_txt_animal), vcenter(explain_txt_animal) + 8, 7)

        -- trees or ground
        local explain_txt_tiles = ""

        local surr_tiles = {}
        if (pl.pos.x+1 < 16) add(surr_tiles, tile_display_names[get_dynamic_or_static_tile_class(v_addv(pl.pos, RIGHT))])
        if (pl.pos.x-1 > 0) add(surr_tiles, tile_display_names[get_dynamic_or_static_tile_class(v_addv(pl.pos, LEFT))])
        if (pl.pos.y+1 < 16) add(surr_tiles, tile_display_names[get_dynamic_or_static_tile_class(v_addv(pl.pos, DOWN))])
        if (pl.pos.y-1 > 1) add(surr_tiles, tile_display_names[get_dynamic_or_static_tile_class(v_addv(pl.pos, UP))])

        surr_tiles = table_dedup(surr_tiles)
        for i=1,#surr_tiles do
            if (i > 1) explain_txt_tiles ..= " or "
            explain_txt_tiles ..= surr_tiles[i]
        end
        print(explain_txt_tiles, hcenter(explain_txt_tiles), vcenter(explain_txt_tiles) + 16, 7)
    end
end

-- == COLLISION ==

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

-- == DEBUG ==

-- function draw_debug(file)
--     if file != nil then
--         printh(debug, file, true)
--     else
--         print(debug, 0, 0, 8)
--     end
-- end

-- function debug_log(s)
--     if(s == null) s = "nil"
--     debug = s.."\n"..debug
-- end

-- function debug_log_table(xs)
--     for x in all(xs) do
--         debug ..= x.." "
--     end
--     debug ..="\n"
-- end

-- function debug_log_pair_table(xs)
--     for i = 1,#xs do
--         debug ..= pair_str(xs[i]).."\n"..debug
--     end
-- end

-- function pair_str(p)
--     return (p[1] or "nil").."_"..(p[2] or "nil")
-- end

-- function str_player_big_pattern()
--     local out = ""
--     for ss, as in pairs(player_big_pattern) do
--         for a, pat in pairs(player_big_pattern[ss]) do
--             if a.display_name == "butterfly" then
--                 out ..= ss.." "..a.display_name.."\n"
--                 for i = 1,#pat do
--                     out ..= pair_str(pat[i]).."\n"
--                 end
--             end
--         end
--     end
--     return out
-- end

-- == DEBUG pico-kit ==

debug = {}
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

-- == GAME LOOP ==

function is_paused()
    return game.pause_count > 0
end

function pause(dur)
    game.pause_count += dur
end

function increment_tick()
    if is_paused() then
    	game.pause_count -= 1
    else 
    	game.tick += 1
    end
end

function _init()
    init_level(game.level)
    menuitem(1, "skip level", menu_skip_level)
    menuitem(2,"level: ⬅️ "..change_level.." ➡️", menu_choose_level)
end

function menu_skip_level()
    change_level = game.level + 1
    while contains(skip_levels, change_level) do
        change_level += 1
    end
end

function menu_choose_level(b)
    if (b&1 > 0) change_level -= 1
    if (b&2 > 0) change_level += 1
    
    change_level = min(change_level, level_count - 1)
    change_level = max(0, change_level)

    menuitem(2,"level: ⬅️ "..change_level.." ➡️", menu_choose_level)

    return true
end

function _update()
    -- pre update
    increment_tick()

    if (is_paused()) return

    player_input()

    if game.state == "splash" then
        -- noop
    elseif game.state == "play" then
        update_play()
    elseif game.state == "won" then
        update_particles()
    end    
end

function update_play()
    -- check win
    if change_level == level_count then
        sfx(11)
        game.state = "won"
        particles={}
        return
    end

    -- check level switch
    if game.restart_level then
        init_level(game.level)
        game.restart_level = false
        particles={}
        return
    end

    if change_level != game.level then
        init_level(change_level)
        return
    end

    -- play level
    npc_input()
    if (is_paused()) return
    update_actors()
    -- update_player_big_pattern()
    update_big_patterns()
    update_particles()
    mimic()
    post_update_actors()
end

function _draw()
    if game.state == "splash" then
        draw_splash()
    elseif  game.state == "won" then
        draw_won()
    elseif game.state == "play" then
        draw_play()
    end
    if SHOW_STATS then
        print("mem: "..stat(0),80,0,7)
        print("cpu: "..stat(1),80,10,7)
    end
end

function draw_play()
    cls()
    if game.tick - game.level_end_tick < 50 then
        draw_level_splash_2(game.level)
    else
        draw_level()
        draw_actors()
        draw_particles()
        draw_ui()
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000022220000000
00000000080800000000000000000000000000000088880000000000000000000000000000000ddd0000ddd00ddd0ddd0ddd0ddd000000222200220020000000
00700700888880000000000000000000000000000888888000888800009990900099090000000dd000000dd000dd0d0d00dd0d0d000002200220022020000000
000770008888800000000000000000000000000008f8f88008888880099999000999900000dddddd00dddddddddd000ddddd000d000000200020002000000000
00077000088800000000000000000000000000000888888008f8f880099999000999900000dddddd00dddddddddddddddddddddd000002202220022200000000
00700700008000000000000000000000000000000888888008888880009990900099090000dddddd00dddddddddddddddddddddd000000002000220200000000
00000000000000000000000000000000000000000088880000888800000000000000000000000dd000000dd000dd000000dd0000000000002200200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000ddd00ddd00000ddd0000000000000022000000000000
000000000000000000000000000000000000000000e00e000e0000e0000000000000000000000000000000000000000000000000000000000288200000000000
00000000000000000000000000000000000000000eeeeee0eee00eee00000000c000000c00000000000000000ddd000000000000000000002888820000000000
00000000000000000000000000000000000000000eeeeee0eee00eee000cc000cc0cc0cc000000000000000000dd0ddd00000000000000002888882000000000
000000000000000000000000000000000000000000eeee000eeeeee000cccc000cccccc00000000000000000dddd0d0d00000000222200002882220000000000
0000000000000000000000000000000000000000000ee00000eeee000cccccc000cccc000000000000000000dddd000d00000000200000002882000000000000
000000000000000000000000000000000000000000eeee000eeeeee0cc0cc0cc000cc0000000000000000000dddddddd00000000200000002882000090900000
00000000000000000000000000000000000000000eeeeee0eee00eeec000000c00000000000000000000000000dd000000000000200000002882000909090000
000000000000000000000000000000000000000000e00e000e0000e0000000000000000000000000000000000ddd000000000000200000002882000090900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222882000909090000
01110000011100001111111011111000011000000000000000000000066000000066000000000000000000000000909008880ccc288888888882000090900000
01111000111100001111111011111000011000000000000000bb0000066000000066000000000000000000000000040008980c2c222222222222000000000000
0119990111999000119999900099999001199000b0000bb00b00b00b0666666600666666000000000000000009090409088eeccc200200002002000000000000
01199991199990001199999000999990011990000b00b00bb0000bb00666666000666660000000000000000000400440aaaefe00200200002002000000000000
011999999999900011990000000119900119900000bb0000000000000666666000666660000000000000000000400400a9aeee00200200002002000000000000
011990999919900011990000000119900119900000000000000000000600006000600060000000000000000000044400aaa00000200200002002000000000000
01199009911990001199000000011990011990000000000000000000060000600066006600000000000000000000400000000000220220002202200000000000
01199000011990001199000000011990011990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900011990000000119900119900000b00bb0000b00b0000000000000000000000000099900090000000000000000000000000000000999000900
011990000119900011990000000119900119900000bbbb00000bbbb0000000000000000000000000990990990000000000000000000000000000009909909900
0119900001199000119911101111199001199000bbbbbb000bbbbbb0000000000000000000000000900099900000000000000000000000000000009000999000
0119900001199000119911101111199001199000bbbbbb000bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900000999990009999900119900000bbbb00000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000
000990000009900000999990009999900009900000b00bb0000b00b0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc00000000000000000
0000a00000000000010000000000000000000000000000000000000000cccccccccccccccccccc00cccccc000cccccc0cccccc00cccccccc0222000001000000
000aaa000000000000000001000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0212002011100000
00aaaaa00000000000000000000077000007700000077000000077000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0222022201000020
000aaa000000000000000000007777700777770007777700007777700cccccccccccccccccccccc0ccccccc00cccccc0ccc77cc0cccccccc0000002000000222
0000a0000000000000000100000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0cc7cc7c0cccccccc0010000000111020
000000000000000000100000000000000000000000000000000000000cccccccccccccccccccccc0cccccc0000cccc00ccccccc0cccccccc0111000000121000
000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc000000000000000000cccccc0000000000010000000111000
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc0000000000000000000000000000000000000002000000010
000550000000000000000000077000007700000077000000077000000cccccc0ccccccc00ccccccc00cccc0000cccccc00000000000000000000022200000111
005555000005550000000000000000000007700000077000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000111002000000010
055555500055550000000000000770000077770000777700000770000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000121000001000000
055555500055555000055000007777000077777000777770007777000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000111000011102220
055555500555555000555500007777700777777007777770007777700cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000000010001002120
005555000555555000555550077777700000000000000000077777700cccccc0ccccccc00ccccccc0cccccc000cccccc00000b00000000000000111000002220
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc00000000000000000000000000000010000000000
000330000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0cccccccc0cccccc00cccccc00000000000000000
003333000003300000000000000000000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
003333000003300000000000007770000007770000077700007770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
033333300033330000033000077777700077777000777770077777700cccccccccccccccccccccc00ccc77ccccccccccccccccc0cc77ccc00000000000000000
033333300033330000333300000000000000000000000000000000000cccccccccccccccccccccc00cc7cc7cccccccccccccccc0c7cc7cc00000000000000000
003333000333333000333300000770000077000000770000000770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
0004400000044000000440000077770007777000077770000077770000ccccccccccccccccccccc000cccccccccccccccccccc00cccccc000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000cccccccc00000000000000000000000000000000
000000000000000010000000000007000000000000000000000007000000000000000000000000000cccccc00cccccc000000000000000000000000000000000
0000000000100000000000100000777000000700000007000000777000cccccccccccccccccccccc0cccccc00cc77cc000000000000000000000000000000000
001000000000000000000000000000000000777000007770000000000cccccccccccc77ccccccccc0cccccc00c7cc7c000000000000000000000000000000000
000000000000000000100000007700000770000007700000007700000ccc77cccccc7cc7ccc77ccc0cc77cc00cccccc000000000000000000000000000000000
000000000000001000000000077770007777000077770000077770000cc7cc7cc77ccccccc7cc7cc0c7cc7c00cc77cc000000000000000000000000000000000
000010000000000000000000077777707777770077777700077777700ccccccc7cc7cccccccccccc0cccccc00c7cc7c000000000000000000000000000000000
000000001001000010000000000000000000000000000000000000000ccccccccccccccccccccccc0cccccc00cccccc000000000000000000000000000000000
000000000000000000000001000000000000000000000000000000000cccccc000000000000000000cccccc00cccccc000000000000000000000000000000000
05151505051505750606060615151515000000000000000000000000000000002714141414142414141404141424141400000000000000000000000000000000
060626161616060505343737373537350000000000000000000000000000000006060606060606060606e5f5f4f4f5e500000000000000000000000000000000
05052414051515751614171415151515000000000000000000000000000000001414140714141414243436342714141400000000000000000000000000000000
167784848784848484978484c435353500000000007000000000000000000014f4f5f4f4f4e4061606f4e5f4f4e4f4e400000000000000000000000000000000
15151414142514751614260714151515000000000072000000000000000000001417140714141414344644373414141400000000000000000000000000000000
1675141735350535343505057684943700000000000000000000000000000014f4f416f5f4e4e4f4e5f4e4e4f4f4f4f500000000000000000000000000000000
05071414141417a71616161414241515000000000000000000000000000000001414141414141436343534363536241400000000000000000000000000000000
1675073435360515353634470535753700000071000000000000000000000014e4e5f5e5f5e4f4f4e5f4f5f404e4f5e400000000000000000000000000000000
17141427140514751616167484a41515000000000000000000000000000000001414141414143437353634053435341400000000000000007100000000000000
26b7171436353505050535054736a73700000000000000000000000000000000060606e5e5e5f4f4e4f4e4e5e5f4e4e400000000000000009000000000000000
0614141405050575161616a715151515000000000000000000005100000000001414241414143636343405051546371400000000000000000000000000000000
16750717062606061505050534367537000000000000000000000000000000000606161524f4f5f4e4f4f4f4f4f5e5e500000000000000000000000000000000
06141405050505958484849615151515000000000000000000000000000000001714141414363534350515150535343500000000000000000000000000000000
1675141406060606060605050534751600000000000000000000000000000000e406061525e4e5f4f4f4f5f5e5f5f5e500000000000000000000000000000000
06051515151515752414147515151515000000000000000000000000000000001414141435351515251515151505153400000000000000000000000000000000
16a7141417161616161606151515751600000000000000000000000000000000e406061524f4f4e5f4f4f4e4f5f5e4e400000000000000000000000000000000
06071574848484d6141474c605150515000000000000000053000000000000001414141415151515151515151515151500000000000000000000720000000000
1675061414140606161614251407b72600000000000000000000007200000000e40616151424e5f5e5e5f4f4f4f5f5e500005172000000000000000000000000
061515a7060606151424751405171515000000000000000000000000000000001414151515151515152515151505151500000000000000000000000000000000
1675061414141406161414141406750600000000000000000000000000000000f4061616140724251414141424f5e4f500000000000000000000000000000000
061516b4060505050714752414141414000000000000000000000000005000001415151516161515151515161515151500000000000000000000000000000000
06a70616171414240614141406167516000000000000000000000000000000000616061414171407241424141414f5f400000000000000000000000000000000
06161616060505051515751514241406000000000000000000000000000000001524261414141616161616161616161600000000000000000000000000000000
2675061617141424242425748484d626000000000000000000000000000000000607141414140714141414141414e4e400000000000000000000000000000000
06161616060505051515751516060606000000000000000000000000000000000505160624140716161616162416161600000000000000000000000000000000
06750506171714242425057516161605000000000000000000000000000000000614071414071414241414141414f4e500000000000000000000000000000000
06161616160505151515b41506060606000000000000000000000000000000000616161614141474848784a40714141614000000000000000000000000000000
1675050626171414150574d616051535000000000000000000000000000000000614141414141714141414140714f5e500005000000000000000000000000000
061616161616161515151515060604060000000000000000000000000000000016161616161714a7141714142426241600005100000000530000000000005000
26b70605061614051526769425350437000000000000500000000000000000000614241414141414141417141414f5e400000000000000000000000000000000
060606060606060615051515060606060000000000000000000000000000000084878484849784c6061616160606060600000000000000000000000000000000
16750626160516161615157515373437000000000000000000000000000000000606060606060606060606060606e5e400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000707070707070707070707070707070707070707070707070707070707070707
00000000000000000000000000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714141414141414141414141414140707141414141414141414141414141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000070505141414b6b6b6b6140606060607070505050514b6b6b6b6140606060607
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000070505141414b6b6b6b6140606060607070505050514b6b6b6b6140606060607
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000007050525251405b6b6b614060606060707050505051405b6b62c1406062d0607
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000070505141414b6b6b6b6140606060607074c05050514b6b6b6b6140505060507
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0b01414141425141406050605070714b0b0141414142514140505050507
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0b01414141414141406060506070714b0b0141414141414140505050507
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0b01414141414141414141414070714b0b0141414141414141414141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0000000000000000000001414070714b000000000000000000000141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0000212420212422200001414070714b000021242021242224200141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0000313430313432300001414070714b000031343031343234100141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0000000000000000000001414070714b000000000000000000000141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0005100700072007100141414070714b0b0b0b0b0b0b0b0b0b014141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000714b0b0b0b0b0b0b0b0b000b0141407070cb0b0b0b0b0b0b0b0b0b0b0141407
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000707070707070707070707070707070707070707070707070707070707070707
__label__
00033000000330000003300000033000000330000003300000033000000330000003300000033000777077707770001000007770777070700000777077707770
00333300003333000033330000333300003333000033330000333300003333000033330000333300777072227770071101000070717070700000717170700272
00333300003333000033330000333300003333000033330000333300003333000033330000333300717177207070001011107770777077700000707071717770
03333330033333300333333003333330033333300333333003333330033333300333333003333330717170007170070001007020017000700100707071717000
03333330033333300333333003333330033333300333333003333330033333300333333003333330717177707170222000007772007002721710777077717770
00333300003333000033330000333300003333000033330000333300003333000033330000333300000001000100212000111020001110200100212000000100
00044000000440000004400000044000000440000004400000044000000440000004400000044000000011100000222000121000001210000000222000001110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000111000001110000000000000000100
00000000000000100000000000000000000000000000000000033000000000000003300000000000000000200000000000000000000000000000000000000000
01000000000001110100000001000000010000000222000000333300000330000033330001000000000002220100000001000000022200000100000002220000
11100000000000101110000011100000111000000212002000333300000330000033330011100000077177707170000011107770021277707770777072120020
01000020010000000100002001000020010000200222022203333330003333000333333001000020712170707170072001007070022202727170707072220222
00000222111022200000022200000222000002220000002003333330003333000333333000000222711177707070022200007272000007707770727277700020
00111020010021200011102000111020001110200010000000333300033333300033330000111020700071007071172000117070001000707071707070700000
00121000000022200012100000121000001210000111000000044000000440000004400000121000077071100772100000127770071177707772777077710000
00111000000000000011100000111000001110000010000000000000000000000000000000111000000001000011100000111000001000000011100000100000
00000000000000000000000000000010000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000010
01000000010000000003300000000111010000000222000002220000010000000000022201000000022200000222000001000000010000000100000000000111
11100000111000000003300000000010111000000212002002120020111000000111002011100000021200200212002011100000111000001110000000000010
01000020010000200033330001000000010000200222022202220222010000200121000001000020022202220222022201000020010000200100002001000000
00000222000002220033330011102220000002220000002000000020000002220111000000000222000000200000002000000222000002220000022211102220
00111020001110200333333001002120001110200010000000100000001110200000010000111020001000000010000000111020001110200011102001002120
00121000001210000004400000002220001210000111000001110000001210000000111000121000011100000111000000121000001210000012100000002220
00111000001110000000000000000000001110000010000000100000001110000000010000111000001000000010000000111000001110000011100000000000
00000000000000200000001000000020000000100000000000000000000000000000002000000000000000100000000000000000000000000000001000000000
0222000000000222000001110000022200000111022200000100000001000000000002220100000000000111010000000000a000022200000000011102220000
021200200111002000000010011100200000001002120020111000001110000001110020111000000000001011100000000aaa00021200200000001002120020
02220222012100000100000001210000010000000222022201000020010000200121000001000020010000000100002000aaaaa0022202220100000002220222
000000200111000011102220011100001110222000000020000002220000022201110000000002221110222000000222000aaa00000000201110222000000020
0010000000000100010021200000010001002120001000000011102000111020000001000011102001002120001110200000a000001000000100212000100000
01110000000011100000222000001110000022200111000000121000001210000000111000121000000022200012100000000000011100000000222001110000
00100000000001000000000000000100000000000010000000111000001110000000010000111000000000000011100000000000001000000000000000100000
00000000000000100000002000000020000000200000002000000000000000000000000000000000000000000000002000000020000000000000000000000000
01000000000001110000022200000222000002220000022201000000010000000222000001000000022200000000022200000222010000000222000002220000
11100000000000100111002001110020011100200111002011100000111000000212002011100000021200200111002001110020111000000212002002120020
01000020010000000121000001210000012100000121000001000020010000200222022201000020022202220121000001210000010000200222022202220222
00000222111022200111000001110000011100000111000000000222000002220000002000000222000000200111000001110000000002220000002000000020
00111020010021200000010000000100000001000000010000111020001110200010000000111020001000000000010000000100001110200010000000100000
00121000000022200000111000001110000011100000111000121000001210000111000000121000011100000000111000001110001210000111000001110000
00111000000000000000010000000100000001000000010000111000001110000010000000111000001000000000010000000100001110000010000000100000
00000000000330000e0000e000000000000000000000000000000010000000000000000000000000000000000000000000000000000000100000002000000020
0222000000333300eee33eee00000000010000000100000000000111010000000222000001000000010000000100000001000000000001110000022200000222
0212002000333300eee33eee00055500000000011110000000000010111000000212002011100000111000001110000011100000000000100111002001110020
02220222033333300eeeeee000555500000000000100002001000000010000200222022201000020010000200100002001000020010000000121000001210000
000000200333333000eeee0000555550000000000000022211102220000002220000002000000222000002220000022200000222111022200111000001110000
00100000003333000eeeeee005555550000001000011102001002120001110200010000000111020001110200011102000111020010021200000010000000100
0111000000044000eee44eee05555550001000000012100000002220001210000111000000121000001210000012100000121000000022200000111000001110
00100000000000000e0000e000000000000000000011100000000000001110000010000000111000001110000011100000111000000000000000010000000100
00000000000330000003300000000000000000000000000000000020000000000000000000000000000000100000001000000020000000100000001000000020
02220000003333000033330000000000000066000222000000000222010000000100000001000000000001110000011100000222000001110000011100000222
02120020003333000033330000055500000066000212002001110020111000001110000011100000000000100000001001110020000000100000001001110020
02220222033333300333333000555500666666000222022201210000010000200100002001000020010000000100000001210000010000000100000001210000
00000020033333300333333000555550066666000000002001110000000002220000022200000222111022201110222001110000111022201110222001110000
00100000003333000033330005555550066666000010000000000100001110200011102000111020010021200100212000000100010021200100212000000100
01110000000440000004400005555550065556500111000000001110001210000012100000121000000022200000222000001110000022200000222000001110
00100000000000000000000000000000660066000010000000000100001110000011100000111000000000000000000000000100000000000000000000000100
00000000000330000003300000000000000000000000000000000000000000200000000000000000000000000000000000000010000000100000000000000000
02220000003333000033330000000000010000000100000001000000000002220100ddd00ddd0ddd010000000222000000000111000001110222000002220000
021200200033330000333300000555000000000111100000111000000111002011100dd011dd0d0d111000000212002000000010000000100212002002120020
022202220333333003333330005555000000000001000020010000200121000001dddddddddd002d010000200222022201000000010000000222022202220222
000000200333333003333330005555500000000000000222000002220111000000dddddddddddddd000002220000002011102220111022200000002000000020
001000000033330000333300055555500000010000111020001110200000010000dddddddddddddd001110200010000001002120010021200010000000100000
011100000004400000044000055555500010000000121000001210000000111000121dd000dd1000001210000111000000002220000022200111000001110000
00100000000000000000000000000000000000000011100000111000000001000011ddd00ddd1000001110000010000000000000000000000010000000100000
00000000000330000000000000000000000000000000000000000020000000100000002000000020000000000000000000000000000000100000001000000020
02220000003333000003300000000000000000000100000000000222000001110000022200000222010000000100000001000000000001110000011100000222
02120020003333000003300000055500000000000000000101110020000000100111002001110020111000001110000011100000000000100000001001110020
02220222033333300033330000555500000000000000000001210000010000000121000001210000010000200100002001000020010000000100000001210000
00000020033333300033330000555550000000000000000001110000111022200111000001110000000002220000022200000222111022201110222001110000
00100000003333000333333005555550000000000000010000000100010021200000010000000100001110200011102000111020010021200100212000000100
01110000000440000004400005555550000000000010000000001110000022200000111000001110001210000012100000121000000022200000222000001110
00100000000000000000000000000000000000000000000000000100000000000000010000000100001110000011100000111000000000000000000000000100
00000000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000010
01000000003333000003300000033000000000000000000001000000000000000000000000000000000000000000000001000000000001110222000000000111
11100000003333000003300000033000000000000010000000000001000000000000000000000000000000000000000000000001000000100212002000000010
01000020033333300033330000333300000000000000000000000000000000000000000000000000000000000000000000000000010000000222022201000000
00000222033333300033330000333300000000000000000000000000000550000000000000000000000000000000000000000000111022200000002011102220
00111020003333000333333003333330000000000000100000000100005555000000000000000000000000000000000000000100010021200010000001002120
00121000000440000004400000044000000000000000000000100000005555500000000000000000000000000000000000100000000022200111000000002220
00111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000
00033000000000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000
00333300000330000033330000000000000000000010000000000000000000000100000000000000010000000000000000000000000000000000011101000000
00333300000330000033330000000000008888000000000000000000001000000000000100000000000000010000000000000000000000000000001011100000
03333330003333000333333000000000088888800000000000000000000000000000000000000000000000000000000000000000000000000100000001000020
03333330003333000333333000000000088f8f800000001000000000000000000000000000000000000000000000000000000000000000001110222000000222
00333300033333300033330000000000088888800000000000000000000010000000010000000000000001000000000000000000000000000100212000111020
00044000000440000004400000000000008888001001000000000000000000000010000000000000001000000000000000000000000000000000222000121000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000
00033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222000002220000
00333300001000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000212002002120020
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222022202220222
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020
00333300000010000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000010000000100000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000001110000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000100000
00033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
00333300000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000100000000000222
00333300000000000010000000000000000000000010000000000000000000000000000100000000000000000000000000000000000000001110000001110020
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100002001210000
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022201110000
00333300000000000000100000000000000000000000100000000000000000000000010000000000000000000000000000000000000000000011102000000100
00044000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000012100000001110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000100
00033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000020
00333300000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000011100000222
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000001001110020
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001210000
03333330000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000001110222001110000
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000100212000000100
00044000000000000000000000000000000000000000000010010000000000000000000000000000000000000000000000000000000000000000222000001110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100
00033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000
00333300000000000100000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000011102220000
00333300000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001002120020
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000002220222
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000001110222000000020
00333300000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100212000100000
00044000000000000010000000000000000000000000000000000000000000000000000000000000100100000000000000000000000000000000222001110000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000
00033000000330000003300000033000000330000003300000033000000330000003300000033000000330000003300000033000000330000000002000000000
00333300003333000033330000333300003333000033330000333300003333000033330000333300003333000033330000333300003333000000022202220000
00333300003333000033330000333300003333000033330000333300003333000033330000333300003333000033330000333300003333000111002002120020
03333330033333300333333003333330033333300333333003333330033333300333333003333330033333300333333003333330033333300121000002220222
03333330033333300333333003333330033333300333333003333330033333300333333003333330033333300333333003333330033333300111000000000020
00333300003333000033330000333300003333000033330000333300003333000033330000333300003333000033330000333300003333000000010000100000
00044000000440000004400000044000000440000004400000044000000440000004400000044000000440000004400000044000000440000000111001110000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000100000

__gff__
0000000000000000000306020604000000000000000000000002030206000000000000000000000000020201000000000000000000000000000200000000000008101060606060020202020202028080040424404040400202020202000080800101214040404002020202020202000810101040404040020202020224212108
0808080808080808080808080808080802020202020000000800000000000000020202020000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6060606060606060606060606060606000000000000000000000000000000000414171416161414141724141704141410000000000000000000000000000000060616162606060606060606060616060000000000000000000000000000000006057616061616060606061616060606100000000000000000000000000000000
606160616062606161606162606060620000000000000000000000000000000041714161626161414141704141414241000000000000000000000000000000006060616060606060606162606260606000000000000000000000000000000000617b616141724140414172414160616100000000000000000000000000000000
60606060616060616060626060606060000000000000000000000000000000004141604748784961414141417041414100000000000000000000000000000000484c6062606160616260606060606060000000000000000000000000000000006057604141414170414141414142616100000000000000000000000000000000
6060606260606060606060606160616000000000000000000000000000000000716062574070674960704141414141410000000000000000000000000000000051576060604060606060606051606060000000000000000000000000000000006157614171414141417141414141416000000000000000004100000000000000
616060606160606061616260606061600000000000000000000000000000000041416057414171674c614141707141410000000000000000000000000000000051677848484c6061474849606051606000000000000000000000000000000000626a484878484848794848487848484800000000000000000007000000000000
60606060606060616060606060606060000000000000000000000000000000004141616a49414141576041414141414100000000000000000000000000000000505151515167484858707a5151516060000000000000000007000000000000005051515150606060515151515051505000000000000000000000000000000000
6072414241704241417042416060406000050000000000000000000000000000424141616749417057607160606070410000000000000000000000000000000050515151515151516a486c5151606060000000000000000000000000000000005150516060616060515051515160606100000000000000000000000000000000
6060606060416060606060606061606000000000000000000000000000000000417041416067784858606062606060600000000000000000000000000000000050515051515050515151515151616060002700000000000000000000000000005150606072515151515151516060606000000000050000000000000000000000
6160606160714260616061606060606000000000000000000000000000000000414141416060606067496160606260600000000000000000000000000000000051515150515151515150774a51606060000000000000000000000000000000005161604241605151505151505160606100000000000000000000000000000000
6060626061604170426060606260606000000000000000000000000000000000417141416160606160674848487949610000000000000000000000000007000041424141425151505151575150606060000005000000000000000000000000006061414170616060615150515150506000000000000000000000270000000000
626060606060606070416060606160600000000000000000000000000000000071414170414141416060616160606a4800000000000000000000000000000000515141414141715147796c5160616061000000000000000000000000000015006041714141414161605160605151506000000000000000000000000000000000
6060606060606260627060606060626000000000000000000000000000000000414141714141424141414260606061600000000000000000000000000000000050517748784848486c51515151506060000000000000000000000000000000006142606060607241606060616060616100000000000000000000000000000000
4878484960606060604260606260606000000000000000000000000000000000414141417041414141414160606060600000000000000000000000000000000060505760505050515151515050516060000000000000000000000000000000006141606160606061606051606060506000000000000000000000000000000000
6060606a48496060604160606060606000000000000000000000000015000000414241417141414142414161626261600000000000000000000000000000000060615760605070415150515151606060000000000000000000000000000000006041606060616161515151515150505000000000000000000000000000000000
6061616061674960606060606060616000000000000000000000000000000000414141704171414141414160616160610000050000000000000000000000150048486d60616050606051515060606061000000000000000000000000000000006042606060616060605150505150505000000000000000000000000000000000
6260626060607a60606060626060606000000000000000000000000000000000704141414170414141417141716061610000000000000000000000000000000060606060606261606160606060606162000000000000000000000000000000006160606160606161615150505050505000000000001500000000000000000000
4141414141414141414141414141414100000000000000000000000000000000606060606060606060606060606060600000000000000000000000000000000061606261606060606160506160616060000000000000000000000000000000006061616060616161615050505751505000000000000000000000000000000000
4141414143414143416341414141414100000000000000000000000000000000606060606060606060606060606160610000000000000000000000000000000060616060606060616162615050626060000000000000000000000000000000006060606060616060605050476c51515100000000000000000000000000000000
4143434143436343435343414143414100000000000000000000000000000000616161606161616161616061474878480000000000000000000000000000000060626260616161626060616050506060000000000000000000000000000000006060606060615b484848486d5151505000000000000000000000000000000000
4163405343537363734343634343636300000000001700000000000000000000616061616261606161616161576060600000000000000000000000000000000060606161606060606160605151506061000000000000000000000000000000006160606060616060606161425050505000000000000000000000000000270000
43435363436343435373736343636343000000000000000000000000000000004878484961616147487848495760606100000000001500000000000000000000606161616062626060616050405060600000000000000000000000000000000061605a6060616160606061415050505000000000000000000000000000000000
434343774848784848794a5351515053000000000000000000000000000000006060615761616157515050676d60616100000000000000000000000000000000606060606060606161606050505060600000000000000000000000000000000061607a6060606160606061416060505000000000000000000000000000000000
4879486c61606061604161635150506300000000000000000000000000000000606061677948486d5161616160607061000000000000000000000000000000006062605160606062605150515051515000000000000000000000000000000000616067484960616061774a417260505000000000000000000000000000000000
616160616161616161615150505151514100000000000000000000000000000061616051505150515141714172414161000000000000000000000000000000006050515160606060605041505050615100000000000000000000000000000000516060607a616060615760414160505000000000000000000000000000000000
6141414172414141414241414172416000000000000000000000000000000000605151515050515051417041414141610000000000000000000000000000000060515051424170606051715051506050000000000000000000000000000000005050516159484878486c60704160505000000000000000000007000000000000
5041724141414241414160515050516000000000000000000000000000000000615151505051505147784a4141417261000000000000000000000000000000006160515141414141605041505150605100000000000000000000000000000000515047486c604172414141416060505000000000000000000000000000000000
507041514141417241606050515051510000000063000000000000000000000051515152514748486d4141417241616100000000000000000000000000000000606051505241414260504150505060500000000000000000000000000000000051517a6060414162414141416060505000000000000000000000000000000000
5051415060526041605151515150515100000000000000000000000000000000515250505257617041417141414160610000270000000000000000000000000062605050414141414141415060506060000000000000000000000000000000005050576071416061606070715151515000000000000000000000000000000000
515051516041606151515150515051510000000000000000000000000000000051515151517a614162414141417261610000000000000000000000000000000060605150704141414241715060506062000000270000000000000000000000005150574141416161606060505051405000000000000000000000000000000000
5050506061726160605050505150505100000000000000000000000000000000514051515167496142624141714160610000000000000000000000000000000062605150506141616161515161515061000000000000050000000000000000005050574241606060606061515151505000000005000000150000000000000000
51506060614161616060515151515151000000000005000000000027000000005151515151515761416160604141616000000000000000000500000000000000606150515060606060606260606061610000000000000000000000000000000050507b6060606051525161616150505000000000000000000000000000000000
50505050505050505050505050505050000000000000000000000000000000005150505250507a6060606060606060600000000000000200000000000000000060515050616061616161616161616060000000000000000000000000000000005050576160615250515151606060606000000000000000000000000000000000
__sfx__
000400000653007500005002640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000101700e060170500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001f43026420274102e2102e210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001402015010150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001063010600156201060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f76013750167400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000011150111501715017150111501115012150121500e1500d1500b150061500215001150001500015000150076500765007650076500010000100001000010000100001000010000100056000560005600
001000002610026130261300e1300e1300e13026130261300e1300e1300e13026130261302d61032610376103d6103f6103c6103d6103c6102f630296301e610176000b600076000560003600026000060000600
000c0000220601e050210501d0501e05027050240502100029100291000000024000006000060000600006000060000600006000060000600006000060000600006000060012600126001260012600126000c600
000700003051030520305103b100001001c7001570016600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e0000210501c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000000001e02001000000001e030230502705000000010002f050040002f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003175038740387303872038720387100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800100c55000500105500050013550005000e55010550155500c5500e550135500e55017550155501355013500005000050000500005000050000500005000050000500005000050000500005000050000500
010c00100c0530c000000000c0000c6532960034600396000c0530c0000c0530c0530c6531b60015600126000c0000f6000f6000f6000c0000f6000d6000c6000a60000600076000460000600006000060000600
010c00202401524025240052b0252b0152700528015280252d0152d025270052b0252b0152700524015240252501525025240052c0252c0152700528015280252701527025270052702527015270052501525025
001000000361005610046000560003600016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b328000009552265000b550275050e5000e552105500050013550005000955000500175520050013550275000e5520050010500005000e550005000b5001755215550005000b5002750015550005001355200500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 4d0e0f44
03 14424344

