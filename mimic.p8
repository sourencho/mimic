pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
 -- mimic v0.6.4
-- by sourencho

VERSION = "V0.6.4"

-- DATA

-- SETTINGS

start_level = 0
last_level = 15
level_count = last_level + 1
skip_tutorial = false
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
grass_spr = 59

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
player_sfx.move[cloud]=9
player_sfx.move[cloud_small]=9
player_sfx.move[teru]=8
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

function  pos_equal(a, b) 
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

    if a.is_player then
        for p in all(get_players()) do
            if (p != a and pos_equal(p.pos, pos)) return false
        end
    end

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
        sfx(7)
        for p in all(players) do
            win_vfx(p.pos)
        end
        game.level_end_tick = game.tick
        return victory
    end
    return victory
end

function init_victory()
    sfx(7)
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
        if _level == 0 and game.state != "play" then
            music(0, 10000)
        end

        change_state("play")
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
end

-- Loads in level by populating 2d array of tiles `level_static_tiles` and `level_dynamic_tiles`
function init_tiles_and_actors(l)
    -- need to predefine small tiles because they might be under actors
    tile_sprites = {
        [cloud_small] = 67,
        [tree_small] = 98,
        [rock_small] = 82,
    }
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
                static_spr = grass_spr
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
heart_sound = 6
function overlap_effects()
    for p in all(get_players()) do
        -- tile hearts
        for t in all(heart_tiles) do
            if is_static_tile(t, p.pos) then
                spawn_heart(p, heart_sound)
            end
        end

        -- actor hearts
        for a in all(actors) do
            if (not a.is_player) and collides(get_body(p), get_body(a)) then
               spawn_heart(a, heart_sound)
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
    print(VERSION, 103, 2, 1)
    print("game", 2, 115, 1)
    print("sourencho", 2, 121, 1)
    print("music", 107, 115, 1)
    print("notehead", 95, 121, 1)


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

    print("game", 2, 115, 1)
    print("sourencho", 2, 121, 1)
    print("music", 107, 115, 1)
    print("notehead", 95, 121, 1)
end

function draw_level_splash(l)
    cls()

    local txt_clr
    local margin = 3
    local padding = 2
    local row_size = 27 * 4/3
    local col_size = 27
    local row = 0
    local col = 0

    -- border
    rect(0,0,127,127,1)
    rect(1,1,126,126,1)

    local level_text = 0
    for i=0,level_count-1 do
        -- coord
        local x = margin + (row % 4) * (col_size + 2 * padding)
        local y = margin + col * (row_size + 2 * padding)

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
            x + col_size/2 - 2, y + row_size/2 - 1, txt_clr)

        if i == l and l != level_count-1 then
            spr(58, x + col_size/2 - 2, y + row_size/2 + 5)
        end

        if i == level_count-1 then
            local win_clr = 1
            if (i == l) win_clr = 10 
            print('★', x + col_size/2 - 2, y + row_size/2 + 6, win_clr)
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
DEBUG_OUT_FILE = "out.txt"
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

    music(62, 10000)

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

    printh(s)
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

skip_countdown = #TUTORIAL_MOVES
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
        skip_countdown -= 1
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
    local txt = tern(tutorial_skippable, splash_keys_3, "start("..skip_countdown..")")
    local txt_col = tern(tutorial_skippable, 8, 1)
    local shd_col = tern(tutorial_skippable, 1, 0)
    thick_print(txt, hcenter(splash_keys_3)-2, 115, txt_col, shd_col)

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
0ddaaaa0000000000aaaaaa001111110001111000eeeeee0eee00eee000cc000cc0cc0cc00000bb000000bb000bb0b0b00bb0b0b000000002888882000000000
dd1da1aa000000000adadaa0011d1d100111111000eeee000eeeeee000cccc000cccccc000bbbbbb00bbbbbbbbbb000bbbbb000b222200002882220000000000
dd1da1aa000000000aaaaaa00111111001011010000ee00000eeee000cccccc000cccc0000bbbbbb00bbbbbbbbbbbbbbbbbbbbbb200000002882000000000000
0ddddaa0000000000aaaaaa0011111100111111000eeee000eeeeee0cc0cc0cc000cc00000bbbbbb00bbbbbbbbbbbbbbbbbbbbbb200000002882000090900000
00dddd000000000000aaaa0000111100011111100eeeeee0eee00eeec000000c0000000000000bb000000bb000bb000000bb0000200000002882000909090000
000dd0000000000000000000000000000011110000e00e000e0000e0000000000000000000000bbb0000bbb00bbb00000bbb0000200000002882000090900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222882000909090000
011100000111000001111110111110000110000000000000000000000ff0000000ff0000000000000000b0b0000090900000ddd0288888888882000090900000
01111000111100001111111011111000011000000000000000bb00000ff0000000ff0000000000000b00030000000400ddd0d1d0222222222222000000000000
0119990111999000111999900099999001199000b0000bb00b00b00b0fffffff00ffffff000000000030000009090409d1d0ddd0200200002002000000000000
01199991199990001199999000999990011990000b00b00bb0000bb00ffffff000fffff0000000000030030000400440ddd00300200200002002000000000000
011999999999900011990000000119900119900000bb0000000000000ffffff000fffff000000000b00030b00040040000303000200200002002000000000000
011990999919900011990000000119900119900000000000000000000f0000f000f000f000000000030030000004440000030000200200002002000000000000
011990099119900011990000000119900119900000000000000000000f0000f000ff00ff00000000000000000000400000000000220220002202200000000000
01199000011990001199000000011990011990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900011990000000119900119900000b00bb0000b00b000000000000000000000000009990009000000000000ccc0999000000000fff000000eee
011990000119900011990000000119900119900000bbbb00000bbbb000000000000000000000000099099099000000000000c1c09a900999fff0f5f00eee0e2e
0119900001199000119911101111199001199000bbbbbb000bbbbbb000000000000000000000000090009990000000b00300ccc0999009a9f5f0fff00e2e0eee
0119900001199000119911101111199001199000bbbbbb000bbbbbb00000000000000000000000000000000000300300b030030000303999fff030000eee0030
011990000119900001999990009999900119900000bbbb00000bbbb0000000000000000000000000000000000b03030000303000000300000033000000300300
000990000009900000099990009999900009900000b00bb0000b00b0000000000000000000000000000000000003000000303000000300000003000000030300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc00000000000000000
0000a00000000000010000000000000000000000000000000000000000cccccccccccccccccccc00cccccc000cccccc0cccccc00cccccccc0222000001000000
000aaa000000000000000001000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0212002011100000
00aaaaa00000000000000000000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0222022201000020
000aaa000000000000000000000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccc77cc0cccccccc0000002000000222
0000a0000000000000000100000660000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0cc7cc7c0cccccccc0010000000111020
000000000000000000100000006666000000000000000000000000000cccccccccccccccccccccc0cccccc0000cccc00ccccccc0cccccccc0111000000121000
000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc000000000000000000cccccc0000000000010000000111000
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00000000000000000000000000cccccc00000002000000010
000550000000000000000000000000000000000000000000000000000cccccc0ccccccc00ccccccc00cccc0000cccccccccccccccccccccc0000022200000111
005555000005550000000000006600000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0111002000000010
055555500055550000000000066660000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0121000001000000
055555500055555000055000000000000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0111000011102220
055555500555555000555500000666000000000000000000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccccccccccccccccccc0000010001002120
005555000555555000555550006666600000000000000000000000000cccccc0ccccccc00ccccccc0cccccc000cccccccccccccccccccccc0000111000002220
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000cccccc00cccccc00000010000000000
000330000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0cccccccc0cccccc00cccccc00000000000000000
003333000003300000000000000000000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000001000
003333000003300000000000006660000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00010000000200020
033333300033330000033000066666600000000000000000000000000cccccccccccccccccccccc00ccc77ccccccccccccccccc0cc77ccc00111000000000000
033333300033330000333300000000000000000000000000000000000cccccccccccccccccccccc00cc7cc7cccccccccccccccc0c7cc7cc00010020000000000
003333000333333000333300000660000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000222000002000
0004400000044000000440000066660000000000000000000000000000ccccccccccccccccccccc000cccccccccccccccccccc00cccccc000000020001000010
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000cccccccc00000000000000000000000000000000
000000000000000010000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc000000000000000000000000000000000
0000000000100000000000100000060000000000000000000000000000cccccccccccccccccccccc0cccccc00cc77cc0000030000000a0000000000000000000
001000000000000000000000000066600000000000000000000000000cccccccccccc77ccccccccc0cccccc00c7cc7c000033300000aa0000100000000020000
000000000000000000100000000000000000000000000000000000000ccc77cccccc7cc7ccc77ccc0cc77cc00cccccc00033333000aaa0000000020000222000
000000000000001000000000006600000000000000000000000000000cc7cc7cc77ccccccc7cc7cc0c7cc7c00cc77cc000033300000a00000000000000020000
000010000000000000000000066660000000000000000000000000000ccccccc7cc7cccccccccccc0cccccc00c7cc7c000003000000000000020000000000000
000000001001000010000000066666600000000000000000000000000ccccccccccccccccccccccc0cccccc00cccccc000000000000000000000010000000000
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
00000000000000000000000000000000000000000000000000000000000000001414141414141414141414141414141414000000000000000000000000000000
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
6060606160606060606060606061616041414141414141414141414141414141606161626060606060606060606160604141414141414141414141414141414160606060606060606060606060606060616062616060606061605061606160606060606060606060606060606060606041414141414141414141414141414171
6071414170426060616061616061606241714161626161704141704141414241606061606060606060616260626060604141414153414153416341414141414160606060606060606060606060616061606160606060606161626150506260606060606060606060606060606061606141414141414141414141414141414171
6141704141416060607241704261606041416047487849617141414141414141484c60626061606162606060606060604153634143436343436343414153414161616160616161616161606147784a6160626260616161626060616050506060616161606161616161616061477848484141704141414141414172412a3b4141
6071414141716061604161606161616071606257407067496041414141414170515760606040606060606060516060604163406343177363734343634343636361606161626060616161616157606060606061616060606061606051515060616160616160607c616161616157606060414141413b3e41714141413b402a4141
6160606061606061424160606161616041416057414171674c6170414171414151677848484960606147484960516060534363634363434363737363436363434878484961606147487848495760606160616161606262606061605040506060605b7949616061474878484957606061414171413b4141414141413b2a414141
606060606060606141606160606060604141616a49414141576041414141414150515151516a48480758707a5151606063436361616061606060606351515053606061576161617b515050676d60616160606060606060616160605050506060606061576161617b515050676d606161424141412a4141414141414141414142
60054142417042414170424160604060424141616749417057607160606070415051515151515151516a486c5160606060606061614160616060616351505063606061677948486c516161616060606160626051606060626051505150515150606061677948486c516161616060606141414141414141714141424141414141
6060606060416060606060606061606041704141606778485860606260606060502750515150505151515151516160606161614141414161606151505051515161616051505150515151716272606061605051516060606060504150505061516161605150515051514171627260606141414141424141413b3c414141414141
616060616041426061606160606060604141414160606060674961606062606051515150515151515150774a5160606060614141724141414142414141724160605151515050515051517041414141616051505142417060605171505150605060515151505051505142414141414161414141414141412a3b414141413f4141
60606160616041414260606061606060417141416160606160674848790749610542414142515150515157515060156061417241414142414141605150505160615151505051505147784a414141726161605151414141416050415051506051505151505051505147784a414141726141412c2c4141414141414171412a4141
6260606060606060704160606061606071414170414141416060616160606a48515141414141715147796c51606160615070415141414172416060505150515151515152514748486d414162414160616060515052414142605041505050605051515152514748486d4141624141606141412a3b4141417042414141413b4141
606060606060616061706060606061604141417141417141414142606060616050517748784848486c525151505060605051415060526041605151515150515151522750525761704141606160416061626050504141414141414150605060605152275052576170414160616041606141413b2a4141414141414141412a4141
4878484960606060604260606160606041414141414141414141416060606060515057515050505151515150505160605150515160416061515151505150515151515151517a614142606161604260616060512742414141424171506050606251515151517a6141426061616042606141412a2a417041414141414141424141
6060606a484961606041606015606060414241414241414142414161626261605150575151505151515051505160606050505060617261606050505051505051514051515167496142426115604160616260515050610561616151516151506151515151516749614242611560416061414141414141413b2a2a3d4141414141
606161606167496060606060606061604141057041714141414141606161156148486d515051505150515150606060615150606061056161606051275151515151515151515157610542414141416060606150515060606060606260606061615140515151515761054141414170606070054141414141414141414141417041
6160616060607a6061606061606060607041414141704141414171417160616152515051515150515151515150526162505050505050505050505050505050505150505250507a606060606060606060605150506160616161616161616160605150505250507a60606060606060606041724141714141414241414141414141
4141414141414141414141414141414160606060606060606060606060606060515151515151515050537353736373634141414141414141414141414141414141414141414141414141414141414141414141505141414141414141705041416160606050515051505760704141616153637363635363736363537363736373
41414141424141414041414241414141606060606060606060606060606160616177484878484848077948484c5363534170414141414141714141414141414141704141414141417141414141417e414170414105704150424141414241514160606160605051514e7a61614247487973737363736353736363537363636363
417041414141424363437241414141416161616061616161616160614748784861574171437350735353505067484973414141417e4141414141416f4141414141414141417e4141515151515151414141514141414141514141415241414171616161606051515e6e576161617b60615373637342414141417241727363636e
41704141414173635373434141414141616061616261606161616161576060606157701873635051736353535053577341414141414141724141414141414241414141414141417251054172515142417041415041427051524141704152414160615a60605151505e677848486961706163637241414363734341186373634e
4141414141535317635353634241414148784849611561474878484957606061627b7141637353505050735053637a5341414141414141414141414141414141417141414141414151414152415141414151417151505051714151514141414160607b6060515e5e7e7e4f6e7e576141606061414147784848484c7163635e7e
424141414373636351505363434141416060615761616157515050676d606161615770716062606051505050536357737241505050505050505050505050414141416060606060605041414170514141415251505e6e512751507e4f52504141606167487948496e5e6e6e7e4f7a607161616141776c4241417167496f5f6e6e
41414141635353515050517373414141606061677948486d51616161606070616157414160606060606050505043576141415005726161606e6f7e5e7e5041414141606e6f7e5e7e5142414141514141506e7e51514e7e4e7e6f6e51505172416060616061606778496e6e6e6f67496060606141576051417051617b4f7e6f5e
4141417351525151515150515263414261616051505150515141714172414161617a414171616161616160515151576141415071416060615f7e6e7e6e5041704141605f7e6e406e505241417251417042514e7e516f6f6e6f6e5f507e4e51416060724141706060577e4e6e6e6e674c6161614157504041414050575e6e6f7e
414152515151515152515151515052516051515150505150514170414141416161576041414160606161412841707b6241415041706060607e6e5e6e405041417e41607e6e5e6e4f5041415251517e414150515e7e5f7e6e4e6f7e4e6e5041416161416151417151576f4f6e7e6e6f57616060417b60506f7e516057197e5f6f
51505151616061616061616061515151615151505051505147784a41414172616157604141414160617141414160576041415070726061156e096e6f7e5041414141606e6f6e6f7e2751414250514141417151506e7e5f707e5f6e505070414160604160515241476d7e096f6e47486c606051415751607e7e6151574f6e7e5f
5151516142414170414141706061606151515152514748486d41414172416161607a6061714141424141414748486d61704150505050505050505050505041417041607e6f6f7e7e60515151515141415142515f7e407e6e6e7e7e505142414160617161504172577e4e7e6e6e7b616061615152674c517e6f51476d7e6f6f4f
505061414162414141424170416161615152275052576170414171414141606162576061714141414170525761606162414141414141414141414141414141414141607e095e7e6e60414141414141414150515e7e6f7e096e6f6f7e5141507160604115275151576f6e406f6e57614161615141504b607e6f614b516e7e7e50
5150617141606141515041417051506051515151517a614162414141417261616057506071714142425250576161615041416f414171414141414141414241414141607e6e5f6f4e6041417e414141414170517e5f5e4f4e7e5f7e6e51514141617170606151517b6e6e6e6e6f5761716115274150514e7e7e6e7e4f4e7e5151
516161606160724151424141700551615140515151674961426241417141606161575060627141415150476d51636353414141414141414141417e414141416f4141606060606060604141414141414141515f6e5152504f5051515e7e514150600542616051476848494e6e476c60415050504150516e6f7e7e7e7e7e7e5151
6160606061156151275150515151526051515151515157610561606041416160627b6050606105505162674963504073414141414141414170414141414141414141417041414141704141414171414150526e507071505241517051517051706061616151507a6160576f476d616141500541725151524e6e4f4f4f5f525151
606161606161515151515050505051525150505250507a606060606060606060615760626150616161515157515153734141414141414141414141414141414141414141414141414141414141414141714151424141504141714151414141416061615150515761616a486c6161417050505050505150515150515051515151
__sfx__
010400000753007500005002640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000107500e740177300070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010600001f04026030270202e0202e020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001402015010150200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001062010600156101060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001076013750187400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002b7502f7501c7000c7000f7002c7000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01080000000001f02001000000001f0302405028050000000100030050040002f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000111001100211001d1001e10027100241002110029100291000010024100001000010000100001000010000100001000010000100001000010000100001000010012100121001210012100121000c100
010700000161000610006003b600006001c6001560016600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010e00001305018050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
780f0020175553b5553755536555325552f5551f5551e5551a5551755513555125500e5500b55007550065503f5553c555395553555534555305552d555295552855524555215551d5501c5500c5501555011550
910f000036055320552f0552d0552b0553600000000000000000000000000000000000000000000000000000370553505534055300552d0550000000000000002403528035290452d04530045340453505539055
010f00000e0500e0500e0500e0500e0400e0400e0400e0300e0300e0200b0500b0500b0500b0500e0500e051110501105010050100500c0500c0500c0500c0500c0400c0400c0400c0300c0300c0300c0200c010
780f00003e5553b5553755536555325552f5551f5551e5551a5551755513555125500e5500b5500755006550005553c555395553555534555305552d555295552855524555215551d5501c5500c5501555011550
011000200005000050000500005000050000500705007050070500705507050070500b0500b0500c0500c0500505005050050500505005050050500a0500a0500a0500a050090500905007050070500505005050
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c05300000000000000000000000000c6550c6000c6000c6000c0530c6000c655000000c05300000
49100020000000000000000000000000000000340453403534025340153401534015320353201530035300153204532035320253201532015320152b0452b0352b0252b0252b0252b0152b0152b0150000500000
01100020000500005000050000500005000050070500705007050070550705007050000500005004050040500505005050050500505005050050500a0500a0500a0500a05009050090500a0500a0500c0500c050
491000200000000000000000000000000000003404534035340253401534015340153203532015300353001532045320353202532015320153201537045370353702537025370253701537015370150000500000
011000200005000050000500005000050000500705007050070500705507050070500b0500b0500c0500c0500e0500e0500e0500e0500e0500e05009050090500905009050090500905002050020500105001050
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c05300000000000000000000000000c053000000c600000000c053000000c655000000c05300000
49100020000000000000000000000000000000340453403534025340153401534015320353201530035300152f0452f0352f0252f0152f0152f0152d0452d0352d0252d0252d0252d01528045280352802528015
011000200a0500a0500a0500a0500a0500a05005050050500505005055050500505009050090500a0500a050030500305503050030500f0500f05503050030550505005055050500505011050110550505005055
011000200c05300000000000000000000000000c0530000000000000000c053000000c6550c6000c6000c6000c053000000c053000000c655000000c053240330c053180330c053180330c655000001305311053
491000202904529035290252901529015290153004530035300253001530015300152d0452d0352d0252d0152b0452b0352b0252b0252b0252b0152b0152b0152b0152b0152b0150000000000000000000000000
011000200005000050000500005000050000500705007050070500705507050070500b0500b0500c0500c0500505005050050500505005050050500a0000a0000a0000a000090000900007000070000500005000
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c0530000024033210331c043000001804300000150430000013043000000c033000000e03300000
911000203712534125301252f1252b1252812524125231251352517525185251c5251f5252352524525285253912535125321252e1252d125291252612522125215252252526525295252b5252e5253052535525
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c053000000c6350c6350c655000000c6350000018053000000c0530000018620186201861018614
011000200005000050000500005000050000500705007050070500705507050070500b0500b0500c0500c0500e0500e0500e0500e0500d0500d050090500905009050090500e0500e0500d0500d0500b0500b050
911000203712534125301252f1252b1252812524125231251352517525185251c5251f5252352524525285253912536125311252f1252d1252a12525125211252152523525255252a5252d5252f5253152536525
011000200a0500a0500a0500a050090500905005050050500505005055050500505009050090500a05000055030500305503055030550f0500f055030500f0550505011045050500505011050110551104511045
011000200c05300000000000000000000000000c0530000000000000000c053000000c6550c0530c6000c6000c0530c6350c053000000c655000000c0530c6350c0530c6550c053180330c655000000c6550c645
911000203912535125321252e1252d125291252612522125215252252526525295252b5252e52530525355252252526525295252b5252e5253052532525355252402528525295252d52530525345353554539555
0110002000000000000000000000000001c5211c5201c5201c5201c5201c5221c5221a5201a52018520185201a5201a5201a5201a5221a5221a52013521135201352013520135221352213523000000000000000
0110002000000000000000000000000001c5211c5201c5201c5201c5201c5221c5221a5201a52018520185201a5201a5201a5201a5221a5221a5201f5211f5201f5201f5201f5221f5221f523000000000000000
0110000000000000000000000000000001c5211c5201c5201c5201c5201c5221c5221a5201a520185201852017520175201752017522175221752015521155201552015520155221552210521105201052010520
011000201152011520115201152211522115221852118520185201852018522185221552115520155201552013521135201352013520135221352213522135221352213522135221352213523000000000000000
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c0530000024053210531c053000001805300000150530000013053000000c053000000e05300000
010f00200b0500b0500b0500b0500b0400b0400b0400b0300b0300b020070500705007050070500b0500b0510c0500c0500b0500b050050500505005050050500504005040050400503007050070500705007040
491000201f54623546285461f53623536285361f52623526285261f51623516285161f5162351628516235161a0001a0001a0001a0001a5001a5001a5001a5001a50000000000000000000000000000000000000
011000200c05300000000000000000000000000c05300000000000000000000000000c6550000000000000000c053000000c6550c6550c653000000c6550000018053000000c0530000018640186201861018614
491000201c5461f546235461c5361f536235361c5261f526235261c5161f516235161c5161f51623516235161d546215461a5461d536215361a5361d526215261a5261d516215161a5161d516215161a5161a516
01100020000000000000000000000000000000287542875028750287502874028730267542675024754247502675426750267502674026740267301f7541f7501f7501f7501f7401f7301f7201f7100000000000
01100020000000000000000000000000000000287542875028750287502874028730267542675024754247502675426750267502674026740267302b7142b7202b7302b7402b7502b7302b0202b0100000000000
491000201c5461f546235461c5361f536235361c5261f526235261c5161f516235161c5161f51623516235161e54621546255461e53621536255361e52621526255261e51621516255161e516215162551621516
49100020000000000000000000000000000000287542875028750287502874028730267542675024754247502375423750237502374023740237302175421750217502175021750217401c7541c7501c7501c750
011000200a0500a0500a0500a0500a0500a05005050050500505005055050501005009050090500a0500a050030500305503050030500f0500f05503050030550505005055050500505011050110550505005055
011000200c05300000000000000000000000000c0530000000000000000c053000000c6550c6000c6000c6000c053000000c053000000c655000000c053240330c053180330c053180330c655000000c6550c645
491000201d54621546265461d53621536265361d52621526265261d52621516265161d5162151626516215161f54622546265461f53622536265361f526225262154624546285362153624546285461f53624536
491000201d7541d7501d7501d7501d7501d750247542475024750247502475024750217542175021750217501f7541f7501f7501f7501f7501f7401f7301f720180551c0551f0552105524055280552b0552d055
011000200e0500e0500e0500e0500e0500e0500905009050090500905009050090500e0500e05010050100501105011050110501105011050110500c0500c0500c0500c0500c0500c05011050110501305013050
011000200c0530000018000000000c655000000c053000000c000000000c053000000c655000000c053000000c0530000018000000000c655000000c053000000c000000000c053000000c655000000c05300000
4910002021546245462a54621536245362a53621526245262a52621516245162a51621516245162a5162151621546245462854621536245362853621526245262852621516245162851621516245162851621516
011000202475424750247502475024750247502175421750217502175021750217502475424750217542175024754247502475024750247502475021754217502175021750217502175024754247502675426750
011000200005000050000500005000050000500705007050070500705007050070500005000050000500005005050050500505005050090500905009050090500c0500c0500c0500c0500f0500f0500f0500f050
491000201f54624546285461f53624536285361f52624526285261f51624516285161f5162451628516247161d5462154624546275361f53621526295262d51624546275462b5462153624546275462954618536
011000202875428750287502875028750287501f7541f7501f7501f7501f7501f75028754287501f7541f75027754277502675426750267502675024754247502475024750217502175024750267502475024750
491000001f54624546285461f53624536285361f52624526285261f51624516285161f5162451628516247161d546205462654629536145362e5262952620516325261d5362054622536265461d5361a52622516
01100020287542875028750287502875028750287502875028750287551f7541f750247542475028754287502975429750287542875028750287502475424750247502475020754207501f7541f7501875418750
011000200c00000000000000000000000000000c00000000000000000000000000000c6000000000000000000c0000000024000210001c000000001800000000150000000013000000000c000000000e00000000
011000200c00000000000000000000000000000c00000000000000000000000000000c6000000000000000000c000000000c6000c6000c600000000c6000000018000000000c0000000018600186001860018600
000400001100011000150001500029000180001c0001c0001d0001d0002100021000240002400028000280003500035000350003500034000240002d000290002800018000210001100005000000000000000000
__music__
01 0f505162
00 12505364
00 14555663
00 17585965
01 0f105162
00 12105364
00 14155663
00 17185965
00 0f101162
00 12101364
00 14151663
00 17181965
00 1a1b501c
00 1a1d501c
00 0f102362
00 12102464
00 14152563
00 17182665
00 0f105162
00 12105364
00 1e15511f
02 20215222
00 81828384
00 81828384
01 1a27291c
00 1a2a291c
00 0f102b2c
00 12102b2d
00 14152e2f
00 30313233
00 34353637
00 3835393a
00 34353637
02 38353b3c
00 81828384
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 81828384
00 81828384
00 80808080
00 81828384
00 81828384
00 81828384
00 81828384
00 81828384
00 81828384
00 81828384
00 81828384
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 81828384
00 81828384
00 41424344
00 41424344
00 41424344
00 41424344
01 0b0c0d44
02 0e0c2844

