pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- mimic v0.4.3
-- by sourencho

VERSION = "v0.4.3"

-- DATA

-- SETTINGS
start_level = 12
level_count = 14
skip_tutorial = true
skip_levels = {3, 5, 6, 8}

tutorial_level = 15
tutorial_speed = 20

slow_speed = 20 -- the larger the slower the npcs move
tile_slow_speed = 2 -- the larger the slower the tiles animate
player_spr_offset = 32

splash_inst_1 = "take the form of an animal"
splash_inst_2 = "by mimicking its movement"
splash_keys_3 = "start \151"
won_text = "★ you win ★"

level_size = 16
ACTOR_ID_INDEX = 0

debug_mode = false
DEBUG_OUT_FILE = "out.txt"
SHOW_STATS = false
debug = "DEBUG\n"

-- spr numbers 2x2 matrix to support large sprites
fish_spr = {{7, nil}, {nil, nil}}
sheep_spr = {{39, nil}, {nil, nil}}
butter_spr = {{21, nil}, {nil, nil}}
bird_spr = {{23, nil}, {nil, nil}}
frog_spr = {{53, nil}, {nil, nil}}
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

-- tile spr values
ground_spr = 65

static_tiles = {tree, water, rock, ground, win, cloud, teru}
dynamic_tiles = {rock_small, tree_small, cloud_small}

tile_frame_counts = {
    [67] = 4, -- cloud_1_spr
    [83] = 4, -- cloud_2_spr
    [99] = 4, -- cloud_3_spr
    [115] = 4, -- cloud_4_spr
    [126] = 2, -- manish_sparkle
}
tile_frame_speeds = {
    [67] = 500, -- cloud_1_spr
    [83] = 500, -- cloud_2_spr
    [99] = 500, -- cloud_3_spr
    [115] = 500, -- cloud_4_spr
    [126] = 200, -- manish_sparkle
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
    level = tutorial_level,
    tick = 0,
    level_end_tick = 0,
    pause_count = 0, -- the amount of ticks to pause the game
    restart_level = false,
    state_change_tick = 0,
}

-- TUTORIAL

TUTORIAL_MOVES = {RIGHT, RIGHT, RIGHT, DOWN, DOWN, DOWN, UP, UP, UP, 
                    STILL, STILL, STILL, RIGHT, DOWN, STILL, STILL, STILL, STILL}
tutorial_move_index = 1
tutorial_player_pos = nil
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
perm_particles = {}

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
    sort(a.comp, function (x, y) return x > y end)
    sort(b.comp, function (x, y) return x > y end)

    if (a.is_player or b.is_player) then
        debug.print({"a", a.comp})
        debug.print({"b", b.comp})
        debug.print(flat_table_equal(a.comp, b.comp))
    end

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
        if can_move(new_pos, a) and not is_paused() then

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
                nil
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
        nil)
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
    for a in all(actors) do
        local shape_key = 10*a.shape[1] + a.shape[2]
        -- comp >= 3 check is so that the goat + vishab + butter animal doesn't transform back 
        -- this is a feature that i've intentionally removed so that they dont keep transforming
        -- back and forth. Also the sprite draw algo doesn't work really well for that case lol
        if (a.is_player or body_size(a) != 3 or #a.comp >= 3) goto cont
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
    b.comp = {b.spr[1][1], a.spr[1][1]}
end

function animal_mimic()
    for a in all(actors) do
        for b in all(actors) do
            if a != b and is_mimic(a.pattern, b.pattern, #a.pattern, tern(a.is_player, a.t, 0)) and
               ((a.no_trans_count + b.no_trans_count <= 0) or (a.is_player or b.is_player)) and
               a.shape[1] == b.shape[1] and a.shape[2] == b.shape[2] and pair_equal(a.shape, {1,1})
               and not is_comp_equal(a, b) then
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
    if _level != tutorial_level then
        game.state = "play"
    end

    actors = {}
    game.tick = game.level_end_tick
    game.level = _level
    change_level = game.level
    -- game.tick = 0
    init_tiles(_level)
    init_actors(_level)
    init_player(_level)
    init_big_patterns()

    if game.level != tutorial_level then
        menuitem(2,"level: ⬅️ "..change_level.." ➡️", menu_choose_level)
    end
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
                --print(tile_spr)
                --print(tile_class)
                --stop(i.." "..j)
            end
            if contains(dynamic_tiles, tile_class) then
                level_static_tiles[i][j] = make_tile(ground_spr)
                level_dynamic_tiles[i][j] = make_tile(tile_spr)
            elseif contains(static_tiles, tile_class) then
                level_static_tiles[i][j] = make_tile(tile_spr)
                level_dynamic_tiles[i][j] = make_tile(ground_spr)
            else
                print(i.." "..j.." "..tile_class.." tile not dynamic or static")
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
        add(perm_particles, spark)
    end
end

-- == DRAW ==

function draw_splash()
    cls()

    print(splash_keys_3, hcenter(splash_keys_3)-2, 71, 1)
    print(splash_keys_3, hcenter(splash_keys_3)-2, 70, 8)

    if(game.tick % 60 > 0 and game.tick % 60 < 20) cls()

    map(117,60,32,40,8,4)
    print("ALPHA", 92, 50, 1)
    print(VERSION, 103, 121, 1)
    print("sourencho", 2, 121, 1)

    -- print(splash_inst_1, hcenter(splash_inst_1), 54, 13)
    -- print(splash_inst_2, hcenter(splash_inst_2), 64, 13)

    -- print(splash_keys_1, hcenter(splash_keys_1), 78, 13)
    -- print(splash_keys_2, 48, 88, 13)
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

function draw_level_splash(l)
    cls(0)

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
    --draw_actor(pl)
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

-- == DEBUG ==

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
end

function menu_skip_level()
    change_level = tern(game.level == tutorial_level, start_level, game.level + 1)
    while contains(skip_levels, change_level) do
        change_level += 1
    end
end

function menu_choose_level(b)
    if (b&1 > 0) change_level -= 1
    if (b&2 > 0) change_level += 1
    
    change_level = min(change_level, level_count - 1)
    change_level = max(0, change_level)

    if game.level != tutorial_level then
        menuitem(2,"level: ⬅️ "..change_level.." ➡️", menu_choose_level)
    end

    return true
end

function change_state(s)
    game.state = s
    game.change_state_tick = game.tick
end

function _update()
    -- pre update
    increment_tick()

    if (is_paused()) return

    player_input()

    if game.state == "splash" then
        -- noop
    elseif game.state == "tutorial" then
        update_tutorial()
    elseif game.state == "level_splash" then
        if (game.tick - game.level_end_tick > 50) game.state = "play"
    elseif game.state == "restart" then
        if (game.tick - game.level_end_tick > 16) game.state = "play"
    elseif game.state == "play" then
        update_play()
    elseif game.state == "won" then
        update_particles(particles)
        update_particles(perm_particles)
    end    
end

function update_tutorial()
    if skip_tutorial then
        init_level(start_level)
        return
    end

    if game.level != tutorial_level then
        init_level(tutorial_level)
        tutorial_player_pos = pl.pos 
    end


    -- move
    pl.delta = STILL

    if tutorial_move_index > #TUTORIAL_MOVES then
        tutorial_move_index = 1
        del(actors, pl)
        init_player(game.level)
        tutorial_skippable = true
    end

    if game.tick % tutorial_speed == 0 then
        pl.delta = TUTORIAL_MOVES[tutorial_move_index]
        tutorial_move_index += 1
    end

    update_play()
end

function update_play()
    -- check win
    if change_level == level_count then
        sfx(11)
        change_state("won")
        particles={}
        return
    end

    -- check level switch
    if game.restart_level then
        init_level(game.level)
        game.restart_level = false
        particles={}
        change_state("restart")
        return
    end

    if change_level != game.level then
        init_level(change_level)
        particles = {} 
        change_state("level_splash")
        return
    end

    -- play level
    npc_input()
    if (is_paused()) return
    update_actors()
    -- update_player_big_pattern()
    update_big_patterns()
    update_particles(particles)
    update_particles(perm_particles)
    mimic()
    post_update_actors()
end

function _draw()
    if game.state == "splash" then
        draw_splash()
    elseif  game.state == "won" then
        draw_won()
    elseif game.state == "level_splash" then
        draw_level_splash(game.level)
    elseif game.state == "restart" then 
        draw_restart()
    elseif game.state == "play" or game.state == "tutorial" then
        draw_play()
    end

    
    if SHOW_STATS then
        print("mem: "..stat(0),80,0,7)
        print("cpu: "..stat(1),80,10,7)
    end
end

function draw_tutorial()
    if tutorial_skippable then
        print(splash_keys_3, hcenter(splash_keys_3)-2, 115, 1)
        print(splash_keys_3, hcenter(splash_keys_3)-2, 114, 8)
    end

    print(splash_inst_1, hcenter(splash_inst_1), 15, 1)
    print(splash_inst_1, hcenter(splash_inst_1), 14, 6)
    print(splash_inst_2, hcenter(splash_inst_2), 23, 1)
    print(splash_inst_2, hcenter(splash_inst_2), 22, 6)
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
    draw_actors()
    draw_particles()
    draw_ui()
    if (game.state == "tutorial") draw_tutorial()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000022220000000
000000000808000000aaaaaaaaaaaa00000000000088880000000000000000000000000000000ddd0000ddd00ddd0ddd0ddd0ddd000000222200220020000000
00700700888880000aaaaaaaaaaaaaa0000000000888888000888800009990900099090000000dd000000dd000dd0d0d00dd0d0d000002200220022020000000
00077000888880000aaadaaaaaaadaa00000000008f8f88008888880099999900999990000dddddd00dddddddddd000ddddd000d000000200020002000000000
00077000088800000aaaaaaaaaaaaaa0000000000888888008f8f880099999900999990000dddddd00dddddddddddddddddddddd000002202220022200000000
00700700008000000aaaaaaaaaaaaaa0000000000888888008888880009990900099090000dddddd00dddddddddddddddddddddd000000002000220200000000
000000000000000000aaaaaaaaaaaa00000000000088880000888800000000000000000000000dd000000dd000dd000000dd0000000000002200200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000ddd00ddd00000ddd0000000000000022000000000000
000aa0000000000000000000000000000000000000e00e000e0000e0000000000000000000000000000000000000000000000000000000000288200000000000
00aaaa000000000000aaaa0000111100000000000eeeeee0eee00eee00000000c000000c00000fff0000fff00fff0fff0fff0fff000000002888820000000000
0ddaaaa0000000000aaaaaa001111110000000000eeeeee0eee00eee000cc000cc0cc0cc00000ff000000ff000ff0f0f00ff0f0f000000002888882000000000
dd1da1aa000000000adadaa0011d1d100000000000eeee000eeeeee000cccc000cccccc000ffffff00ffffffffff000fffff000f222200002882220000000000
dd1da1aa000000000aaaaaa00111111000000000000ee00000eeee000cccccc000cccc0000ffffff00ffffffffffffffffffffff200000002882000000000000
0ddddaa0000000000aaaaaa0011111100000000000eeee000eeeeee0cc0cc0cc000cc00000ffffff00ffffffffffffffffffffff200000002882000090900000
00dddd000000000000aaaa0000111100000000000eeeeee0eee00eeec000000c0000000000000ff000000ff000ff000000ff0000200000002882000909090000
000dd0000000000000000000000000000000000000e00e000e0000e0000000000000000000000fff0000fff00fff00000fff0000200000002882000090900000
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
000550000000000000000000077000007700000077000000077000000cccccc0ccccccc00ccccccc00cccc0000cccccccccccccc000000000000022200000111
005555000005550000000000000000000007700000077000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccc000000000111002000000010
055555500055550000000000000770000077770000777700000770000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccc000000000121000001000000
055555500055555000055000007777000077777000777770007777000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccc000000000111000011102220
055555500555555000555500007777700777777007777770007777700cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccc000000000000010001002120
005555000555555000555550077777700000000000000000077777700cccccc0ccccccc00ccccccc0cccccc000cccccccccccccc000000000000111000002220
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000cccccc0000000000000010000000000
000330000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0cccccccc0cccccc00cccccc00000000000000000
003333000003300000000000000000000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000001000
003333000003300000000000007770000007770000077700007770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00010000000200020
033333300033330000033000077777700077777000777770077777700cccccccccccccccccccccc00ccc77ccccccccccccccccc0cc77ccc00111000000000000
033333300033330000333300000000000000000000000000000000000cccccccccccccccccccccc00cc7cc7cccccccccccccccc0c7cc7cc00010020000000000
003333000333333000333300000770000077000000770000000770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000222000002000
0004400000044000000440000077770007777000077770000077770000ccccccccccccccccccccc000cccccccccccccccccccc00cccccc000000020001000010
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000cccccccc00000000000000000000000000000000
000000000000000010000000000007000000000000000000000007000000000000000000000000000cccccc00cccccc000000000000000000000000000000000
0000000000100000000000100000777000000700000007000000777000cccccccccccccccccccccc0cccccc00cc77cc00000f0000000a0000000000000000000
001000000000000000000000000000000000777000007770000000000cccccccccccc77ccccccccc0cccccc00c7cc7c0000fff00000aa0000100000000002000
000000000000000000100000007700000770000007700000007700000ccc77cccccc7cc7ccc77ccc0cc77cc00cccccc000fffff000aaa0000000020001000000
000000000000001000000000077770007777000077770000077770000cc7cc7cc77ccccccc7cc7cc0c7cc7c00cc77cc0000fff00000a00000000000000000000
000010000000000000000000077777707777770077777700077777700ccccccc7cc7cccccccccccc0cccccc00c7cc7c00000f000000000000020000000000010
000000001001000010000000000000000000000000000000000000000ccccccccccccccccccccccc0cccccc00cccccc000000000000000000000010000200000
000000000000000000000001000000000000000000000000000000000cccccc000000000000000000cccccc00cccccc000000000000000000000000000000000
05151505051505750606060615151515000000000000000000000000000000001414141424141414041414241414141400000000000000000000000000000000
06062616161606050534373737353735000000000000000000000000000000001414141414141414141414141414141400000000000000000000000000000000
05052414051515751614171415151515000000000000000000000000000000001407141414142434363427141414141400000000000000000000000000000000
167784848784848484978484c4353535000000000070000000000000000000141407141414141414171414141414141400000000000000000000000000000000
15151414142514751614260714151515000000000072000000000000000000001407141414143446443734141414141400000000000000000000000000000000
167514173535053534350505768494370000000000000000000000000000001414141414e7141414141414f61414141400000000000000000000000000000000
05071414141417a71616161414241515000000000000000000000000000000001414141414363435343635362414141400000000000000710000000000000000
16750734353605153536344705357537000000710000000000000000000000141414141414141427141414141414241400000000000000000000000000000000
17141427140514751616167484a41515000000000000000000000000000000001414141434373536150534353414001400000000000000000000000000000000
26b7171436353505050535054736a737000000000000000000000000000000001414141414141414141414141414141400000000000000000000000000000000
0614141405050575161616a715151515000000000000000000005100000000002414141436363415050515463714141400000000000000000000000000000000
16750717062606061505050534367537000000000000000000000000000000002714050505050505050505050505141400000000000000000000000000000000
06141405050505958484849615151515000000000000000000000000000000001414141415251515151505152514141400000000000000000000000000000000
16751414060606060606050505347516000000000000000000000000000000001414051427060606e6f6e7e5f705141400000050000000000000000000000000
06051515151515752414147515151515000000000000000000000000000000001414251515151515251515151505252400000000000000000000000000000000
16a71414171616161616061515157516000000000000000000000000000000001414051714060606f5e7e6e7e605140700000000000000000000000000000000
06071574848484d6141474c605150515000000000000000053000000000000001415151515151515151515151515151500000000000000000000000000000000
1675061414140606161614251407b726000000000000000000000072000000001414051407060606e7e6e5e60405141400000000000000000000000000000000
061515a7060606151424751405171515000000000000000000000000000000001505151616061616061616061615151500000000000000000000000000000000
16750614141414061614141414067506000000000000000000000000000000001414050727060606e6f5e6f6e705141400000000000051000090000000000000
061516b4060505050714752414141414000000000000000000000000005000001515061624141407141414070616061600000000000000000000000000000000
06a70616171414240614141406167516000000000000000000000000000000000714050505050505050505050505141400000000000000000000000000000000
06161616060505051515751514241406000000000000000000000000000000000505161414261414142414071416161600000000000000000000000000000000
2675061617141424242425748484d626000000000000000000000000000000001414141414141414141414141414141400000000000000000000000000000000
06161616060505051515751516060606000000000000000000000000000000001505161714061614150514140714050614000000000000000000000000500000
06750506171714242425057516161605000000000000000000000000000000001414f61414171414141414141424141400000000000000000000000000000000
06161616160505151515b41506060606000000000000000000000000000000001516160616062714152414140715151600000000000000000000000000000000
1675050626171414150574d6160515350000000000000000000000000000000014141414141414141414e7141414141400000000000000000000000000000000
06161616161616151515151506060406000000000000000000000000000000001606060616061615051505151515250600000000005100007200000000000000
26b70605061614051526769425350437000000000000500000000000000000001414141414141414071414141414141400000000000000000000000000000000
06060606060606061505151506060606000000000000000000000000000000000616160616161515151505050505152500000000000000000000000000000000
16750626160516161615157515373437000000000000000000000000000000001414141414141414141414141414141400000000000000000000000000000000
14141405151414141414141407051414000000000000000000000000000000001606050505150515057506071414161600000000000000000000000000000000
74849406067484940606e5f5f4f4f5e5000000000000000000000000000000001414141414141414141414141414141414000000000000000000000000000000
1407141407071405241414142414151400000000500000000000000000000000060616160605e4f7e4a716162474849700000000000000000000000000000000
7504768484c6047506f4e5f4f4e4f4e4000000000000000000000000000000001414140714141414141414141414141414000000000000000000000000000000
14151414141405151414142514141727000000000000000000000000000000001616160506160615e675161616b7061600000000000000000000000000000000
750605f5f4150675e5f4e4e4f4f4f4f5000000000000000000000000000000001414141414141414141414141414141414000000000000000000000000000000
07141405142405152514071414251414000000000000000000000000000000000616a5e505150605e57687848496160700000000000000000000000000000000
750506e5f5061575e5f4f5f4e7e4f5e4000000000000000000000000000000001414141414271414141414141414171414000000000000000000000000000000
14151417150505151715151414141414000000000000000000000000000000000606b7f6f4e6e516e7e7f4e6e775161400000000000000000000000000000000
750605e5e5150675e4f4e4e5e5f4e4e4000000000000000000000000000000001407141414141414141714141414141414000000000000000000000000000000
14251505e5e6151515f7f4250514141400000000000000720000000000000000061676849794e7e6e5e6e6e7f4a7061700000000000000000000000000000000
750506e4e4061575e4f4f4f4f4f5e5e5000000000000000091000000000000001427150505150505050505150505141414000000000000000000000000000000
05e6f71515e4e7e4e7e615051527141400000000000000000000000000000000060616061676878494e6e6e6f676940600000000000000000000000000000000
750615e4e41506b4f4f4f5f5e5f5f5e5000000000000000000000000000000001414052714141427160616061605141414000000000000000000000000000000
2415e4e715f6f6e6f6f505e7e415141400000000000000000000000000000000060614141414142475e7e4e6e6e676c400000000000000000000000000000000
958494e4e4f4f4e5f4f4f4e4f5f5e4e4000000000000000000000000000000001414051417140714061616160615140714000000500000000000000000000007
140515e5e7f5f7e6e6e7e4f70514141400000000000000000000000000000000161614161514141575f6f4e6e7e6f67500000000000000000000000000000000
7516b4151515e5f5e5e5f4f4f4f5f5e5000000000000000000000000000010001414051414141414161616160615141414000000000000000000000000000000
14171505e6e7f507e7e6050507141414000000000000000000000000000000000606140615251474d6e7e6f7e67484c600000000000000000000900000000000
75060615140524241414141424f5e4f5000000000000000000000000000000001414051417141424161606061605141414000000000000000000000000000000
252415f5f704e7e6e6e7051524141414000000000000000000000000000000000616141605142775e7e4e7e6e6b7160600000000000000000000000000000000
7516161525171407241424142424f5f4000000000000000000000000000000001414150714141414160606161605271414000000000000000000510000000000
140515e5f7f6e7e5e6f6e71514051714000000000000009000000000000000000606140605151575f6e604f6e675161400000051720000000000000000000000
7516161514150714141414353535e4e4000000000000000000000000000000001414051714140714061616160605141414000000000000000000000000000000
140715e7f5e5f4e4e7e7e615151414140000000000000000000000000000000016141406161515b7e6e6e6e6f675161700000000000000000000000000000000
c616161514151414241414353535f4e5000051720000000000000000000000001414051515050515050515051505141414000000000212420212422200000000
1415f5e6152505f40515e5e7151405140000000000000000000000000000000006141716061574868494e4e674c6061400500000000000000000000000000000
0505050514151714141434353535f5e5000000000000000000007100000000001414171414141414141414141427141414000000000313430313432300000000
0525e60507170525140715150715071400000000000000000000000000000000061616161505a7160675f674d616161400000000000000000000000000000000
0514241414151414141417353535f5e4005000000000000000000000000000001414141414141407141414141414141414000000000000000000000000000000
1714152414140514141714151414141400000000000000000000000000000000061616150515751616a684c61616140700000000000000000000000000000000
050505050515141414373737e5e5e5e4000000000000000000000000000000001414141417141414141414171414141414000000000000000000000000000000
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
00000000000000000000000000000000011100000111000001100000011100000111000001100000111111100000000000000000000000000000000000000000
00000000000000000000000000000000011110001111000001100000011110001111000001100000111111100000000000000000000000000000000000000000
00000000000000000000000000000000011999011199900001199000011999011199900001199000119999900000000000000000000000000000000000000000
00000000000000000000000000000000011999911999900001199000011999911999900001199000119999900000000000000000000000000000000000000000
00000000000000000000000000000000011999999999900001199000011999999999900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990999919900001199000011990999919900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990099119900001199000011990099119900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000000000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119911100000011010000110101001100000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119911100000101010001010101010100000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000009999900000111010001110111011100000000000000000
00000000000000000000000000000000000990000009900000099000000990000009900000099000009999900000101001101000101010100000000000000000
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
00000000000000000000000000000000000000000000000008808880888088808880000008888800000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000081101810818081801810000088181880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088800800888088100800000088818880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011800800818081800800000088181880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088100800808080800800000018888810000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011000100101010100100000001111100000000000000000000000000000000000000000000000000
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
00011001101010111011101100011010100110000000000000000000000000000000000000000000000000000000000000000001010111000001010000011100
00100010101010101010001010100010101010000000000000000000000000000000000000000000000000000000000000000001010101000001010000000100
00111010101010110011001010100011101010000000000000000000000000000000000000000000000000000000000000000001010101000001110000001100
00001010101010101010001010100010101010000000000000000000000000000000000000000000000000000000000000000001110101000000010000000100
00110011000110101011101010011010101100000000000000000000000000000000000000000000000000000000000000000000100111001000010010011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000306020604000008000000000000000003060206000000000000000000000000020201000000000000000000000000000200000000000008101060606060020202020202028080040424404040400202020202020080800101214040404002020202020202808010101040404040020202020208088080
0808080808080808080808080808080802020202020000000800000000000000020202020000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6060606160606060606060606061606000000000000000000000000000000000414141414141414141414141414141410000000000000000000000000000000060616162606060606060606060616060000000000000000000000000000000006057616061616060606061616060606100000000000000000000000000000000
607141417042606061606161606160620000000000000000000000000000000041714161626161704141704141414241000000000000000000000000000000006060616060606060606162606260606000000000000000000000000000000000617b616141724140414172414160616100000000000000000000000000000000
61417041414160606072417042616060000000000000000000000000000000004141604748784961714141414141414100000000000000000000000000000000484c6062606160616260606060606060000000000000000000000000000000006057604141414170414141414142616100000000000000000000000000000000
6071414141716061604161606161616000000000000000000000000000000000716062574070674960414141414141700000000000000000000000000000000051576060604060606060606051606060000001000000000000000000000000006157614171414141417141414141416000000000000000004100000000000000
616060606160606142416060616161600000000000000000000000000000000041416057414171674c617041417141410000000000000000000000000000000051677848484c6061474849606051606000000000000000000000000000000000626a484878484848794848487848484800000000000000000007000000000000
60606060606060614160616060606060000000000000000000000000000000004141616a49414141576041414141414100000000000000000000000000000000505151515167484858707a5151516060000000000000000007000000000000005051515150606060515151515051505000000000000000000000000000000000
6072414241704241417042416060406000050000000000000000000000000000424141616749417057607160606070410000000000000000000000000000000050515151515151516a486c5151606060000000000000000000000000000000005150516060616060515051515160606100000000000000000000000000000000
6060606060416060606060606061606000000000000000000000000000000000417041416067784858606062606060600000000000000000000000000000000050515051515050515151515151616060002700000000000000000000000000005150606072515151515151516060606000000000050000000000000000000000
6160606160414260616061606060606000000000000000000000000000000000414141416060606067496160606260600000000000000000000000000000000051515150515151515150774a51606060000000000000000000000000000000005161604241605151505151505160606100000000000000000000000000000000
6060616061604141426060606160606000000000000000000000000000000000417141416160606160674848487949610000000000000000000000000007000041424141425151505151575150606060000005000000000000000000000000006061414170616060615150515150506000000000000000000000270000000000
626060606060606070416060606160600000000000000000000000000000000071414170414141416060616160606a4800000000000000000000000000000000515141414141715147796c5160616061000000000000000000000000000015006041714141414161605160605151506000000000000000000000000000000000
6060606060606160617060606060616000000000000000000000000000000000414141714141714141414260606061600000000000000000000000000000000050517748784848486c51515151506060000000000000000000000000000000006142606060607241606060616060616100000000000000000000000000000000
4878484960606060604260606160606000000000000000000000000000000000414141414141414141414160606060600000000000000000000000000000000060505760505050515151515050516060000000000000000000000000000000006141606160606061606051606060506000000000000000000000000000000000
6060606a48496160604160606060606000000000000000000000000015000000414241414241414142414161626261600000000000000000000000000000000060615760605070415150515151606060000000000000000000000000000000006041606060616161515151515150505000000000000000000000000000000000
6061616061674960606060606060616000000000000000000000000000000000414141704171414141414160616160610000050000000000000000000000150048486d60616050606051515060606061000000000000000000000000000000006042606060616060605150505150505000000000000000000000000000000000
6160616060607a60616060616060606000000000000000000000000000000000704141414170414141417141716061610000000000000000000000000000000060606060606261606160606060606162000000000000000000000000000000006160606160606161615150505050505000000000001500000000000000000000
4141414141414141414141414141414100000000000000000000000000000000606060606060606060016060606060600000000000000000000000000000000061606261606060606160506160616060000000000000000000000000000000004241717060616060605050505151505000000000000000000000000000000000
4141414143414143416341414141414100000000000000000000000000000000606060606060606060606060606160610000000000000000000000000000000060616060606060616162615050626060000000000000000000000000000000004141416060616177484950474848784800000000000000000000000000000000
4143434143436343435343414143414100000000000000000000000000000000616161606161616161616061474878480000000000000000000000000000000060626260616161626060616050506060000000000000000000000000000000004141716060615b6c6159486d5170424100000000000000000000000000000000
4163405343537363734343634343636300000000001700000000000000000000616061616261606161616161576060600000000000000000000000000000000060606161606060606160605151506061000000000000000000000000000000007160606060616060605751505050507000000000000000000000000000000000
4343536343634343537373634363634300000000000000000000000000000000487848496161614748784849576060610000000000150000000000000000000060616161606262606061605040506060000000000000000000000000000000006160616161616160607b50505050505000000000000000000000000000000000
43434361616061606060605351515053000000000000000000000000000000006060615761616157515050676d6061610000000000000000000000000000000060606060606060616160605050506060000000000000000000000000000000006160606161606160604b51515151505000000000000000000000000027000000
6060606161416061606061635150506300000000000000000000000000000000606061677948486d51616161606070610000000000000000000000000000000060626051606060626051505150515150000000000000000000000000000000005160606161606160616170505050505000000000000000000000000000000000
6161614141414161606151505051515141000000000000000000000000000000616160515051505151417141724141610000000000000000000000000000000060505151606060606050415050506151000000000000000000000000000000005151605b49616060616141505050507100000000000000000000000000000000
606141417241414141424141417241600000000000000000000000000000000060515151505051505141704141414161000000000000000000000000000000006051505142417060605171505150605000000000000000000000000000000000505051517b616161616071515050414100000000000000000007000000000000
6141724141414241414160515050516000000000000000000000000000000000615151505051505147784a4141417261000000000000000000000000000000006160515141414141605041505150605100000000000000000000000000000000504748486c604172414141505151424100000000000000000000000000000000
507041514141417241606050515051510000000063000000000000000000000051515152514748486d41414172416161000000000000000000000000000000006060515052414142605041505050605000000000000000000000000000000000517a606160414162414141505051514100000000000000000000000000000000
5051415060526041605151515150515100000000000000000000000000000000515250505257617041417141414160610000270000000000000000000000000062605050414141414141415060506060000000000000000000000000000000005057616071416061606142505051515000000000000000000000000000000000
515051516041606151515150515051510000000000000000000000000000000051515151517a614162414141417261610000000000000000000000000000000060605150704141414241715060506062000000270000000000000000000000005057604141416161606041615040515000000000000000000000000000000000
5050506061726160605050505150505100000000000000000000000000000000514051515167496142624141714160610000000000000000000000000000000062605150506141616161515161515061000000000000050000000000000000005057704241424160604141615051505000000005000000150000000000000000
5150606061416161606051515151515100000000000500000000002700000000515151515151576141616060414161600000000000000000050000000000000060615051506060606060626060606161000000000000000000000000000000005059784848494141417261616150505000000000000700000000000000000000
50505050505050505050505050505050000000000000000000000000000000005150505250507a60606060606060606000000000000000000000000000000000605150506160616161616161616160600000000000000000000000000000000050576061617a6060616162606160606000000000000000000000000000000000
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

