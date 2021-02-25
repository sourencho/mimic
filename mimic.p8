pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
-- mimic v0.5
-- by souren and nana

-- DATA

-- SETTINGS
slow_speed = 20 -- the larger the slower the npcs move
tile_slow_speed = 2 -- the larger the slower the tiles animate
player_spr_offset = 32

dying_time = 90 -- number of frames dying npc is shown

splash_inst_1 = "take the form of an animal"
splash_inst_2 = "by mimicking its movement"
splash_keys_1 = "move"
splash_keys_2 = "\139\145\148\131"
splash_keys_3 = "start \151"
won_text = "★ you win ★"
stuck_text = "press \151 to restart"

level_size = 16
level_count = 9
start_level = 0

debug_mode = false
debug = "DEBUG\n"

show_trail = false

-- spr numbers
fish_spr = 7
sheep_spr = 39
butter_spr = 21
bird_spr = 23
frog_spr = 53

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

-- tile spr values
cloud_1_spr = 67
cloud_2_spr = 83
cloud_3_spr = 99
cloud_4_spr = 115
ground_spr = 65

static_tiles = {tree, water, rock, ground, win, cloud}
dynamic_tiles = {rock_small, tree_small}

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
}

-- GAME

-- sprite values of tiles
level_static_tiles = {}
level_dynamic_tiles = {}

game = {
    state = "splash", -- [splash, play, won]
    level = start_level,
}

-- ACTORS
npcs = {
    {
        spr_n = fish_spr,
        pattern = {{-1, 0}, {-1, 0}, {-1, 0}, {1, 0}, {1, 0}, {1, 0}},
        move_abilities = {water, win},
        push_abilities = {},
        display_name = "fish",
    },
    {
        spr_n = sheep_spr,
        pattern = {{0, -1}, {0, -1}, {1, 0}, {-1, 0}, {0, 1}, {0, 1}},
        move_abilities = {rock, rock_small, win},
        push_abilities = {},
        display_name = "goat",
    },
    {
        spr_n = butter_spr,
        pattern = {{0, 1}, {0, 1}, {0, 1}, {0, -1} , {0, -1}, {0, -1}},
        move_abilities = {tree, tree_small, win},
        push_abilities = {},
        display_name = "butterfly",
    },
    {
        spr_n = bird_spr,
        pattern = {{0, -1}, {1, 0}, {0, 1}, {0, -1} , {-1, 0}, {0, 1}},
        move_abilities = {cloud, win},
        push_abilities = {},
        display_name = "bird",
    },
    {
        spr_n = frog_spr,
        pattern = {{-1, 0}, {0, -1}, {-1, 0}, {1, 0} , {0, 1}, {1, 0}},
        move_abilities = {ground, water, win},
        push_abilities = {tree_small, rock_small},
        display_name = "frog",
    },
}

-- death
dying = {}
dead = {}

-- SFX
player_sfx={}
player_sfx.move={}
player_sfx.move[ground]=1
player_sfx.move[tree]=3
player_sfx.move[tree_small]=3
player_sfx.move[rock]=4
player_sfx.move[rock_small]=4
player_sfx.move[water]=5
player_sfx.move[cloud]=16
player_sfx.transform=2
die_sfx=8
change_pattern_sfx = 10

-- particles
particles = {
    --SCHEMA
    --{
    --    pos = {x, y},
    --    col = c,
    --    draw_fn = foobar(pos, curr_tick, start_tick, end_tick),
    --    start_tick = 0,
    --    end_tick = 0,
    --}
}


-->8
-- particles

function create_trail(a)
    if (not show_trail) return

    local pos = {a.x * 8, a.y * 8}
    local col = get_spr_col(a.spr)
    local pattern_index = get_pattern_index(a)

    local draw_fn
    if a.dx == 1 then
        draw_fn = draw_trail_right_box
    elseif a.dx == -1 then
        draw_fn = draw_trail_left_box
    elseif a.dy == 1 then
        draw_fn = draw_trail_down_box
    elseif a.dy == -1 then
        draw_fn = draw_trail_up_box
    end

    local frame_len = #a.pattern - 1

    --[[
    -- trail dies before animal steps on it when returning
    if pattern_index > 3 then
        pattern_index -= 3
    end
    frame_len = #a.pattern - 1 - ((pattern_index - 1) * 2)
    --]]

    local end_tick = tick + (slow_speed * frame_len)

    local trail = {
        pos = pos,
        col = col,
        draw_fn = draw_fn,
        start_tick = tick,
        end_tick = end_tick
    }
    add(particles, trail)
end

function draw_trail_up(pos, col, curr_tick, start_tick, end_tick)
    line(pos[1] + 2, pos[2] + 2, pos[1] + 3, pos[2] + 1, col)
    line(pos[1] + 4, pos[2] + 2, col)
    line(pos[1] + 2, pos[2] + 2, col)
end

function draw_trail_down(pos, col, curr_tick, start_tick, end_tick)
    line(pos[1] + 5, pos[2] + 5, pos[1] + 4, pos[2] + 6, col)
    line(pos[1] + 3, pos[2] + 5, col)
    line(pos[1] + 5, pos[2] + 5, col)
end

function draw_trail_right(pos, col, curr_tick, start_tick, end_tick)
    line(pos[1] + 5, pos[2] + 2, pos[1] + 6, pos[2] + 3, col)
    line(pos[1] + 5, pos[2] + 4, col)
    line(pos[1] + 5, pos[2] + 2, col)
end

function draw_trail_left(pos, col, curr_tick, start_tick, end_tick)
    line(pos[1] + 2, pos[2] + 5, pos[1] + 1, pos[2] + 4, col)
    line(pos[1] + 2, pos[2] + 3, col)
    line(pos[1] + 2, pos[2] + 5, col)
end

function draw_trail_up_box(pos, col, curr_tick, start_tick, end_tick)
    rectfill(pos[1] + 2, pos[2] + 1, pos[1] + 3, pos[2] + 2, col)
end

function draw_trail_down_box(pos, col, curr_tick, start_tick, end_tick)
    rectfill(pos[1] + 4, pos[2] + 5, pos[1] + 5, pos[2] + 6, col)
end

function draw_trail_right_box(pos, col, curr_tick, start_tick, end_tick)
    rectfill(pos[1] + 5, pos[2] + 2, pos[1] + 6, pos[2] + 3, col)
end

function draw_trail_left_box(pos, col, curr_tick, start_tick, end_tick)
    rectfill(pos[1] + 1, pos[2] + 4, pos[1] + 2, pos[2] + 5, col)
end

-->8
-- util

function copy_table(table)
    copy = {}
    for i=1,#table do
      copy[i] = table[i]
    end
    return copy
end

-- e.g. given UP will return LEFT and RIGHT
function get_perp_moves(move)
    if move[1] == 0 then
        return {{-1, 0}, {1, 0}}
    else
        return {{0, -1}, {0, 1}}
    end
end

function pair_equal(a, b)
    if (a[1] == b[1] and a[2] == b[2]) then
        return true
    else
        return false
    end
end

function get_spr_col(spr_n)
    local spr_page = flr(spr_n / 64)
    local spr_row = flr((spr_n % 64) / 16)
    local spr_col = (spr_n % 64) % 16

    local spr_x = spr_col * 8
    local spr_y = (spr_page * 32) + (spr_row * 8)

    return sget(spr_x + 4, spr_y + 4)
end

function contains(xs, e)
    for x in all(xs) do
        if (x == e) return true
    end
    return false
end

function get_tile_class(t)
    return fget(t.spr)
end

function get_dynamic_or_static_tile_class(x, y)
    local dynamic_tile = get_tile_class(level_dynamic_tiles[x][y])
    if (dynamic_tile != ground) return dynamic_tile
    return get_tile_class(level_static_tiles[x][y])
end


-->8
-- text

function hcenter(s)
  return 64-#s*2
end

function vcenter(s)
  return 61
end

-->8
-- game logic

function make_actor(x, y, spr_n, pattern, move_abilities, push_abilities, display_name)
    local a={}
    a.x = x
    a.y = y
    a.dx = 0
    a.dy = 0
    a.spr = spr_n
    a.move_abilities = copy_table(move_abilities)
    a.push_abilities = copy_table(push_abilities)

    -- pattern
    a.pattern = copy_table(pattern)
    a.t = 0
    a.last_move = {0,0}

    -- animation
    a.frame = 0
    a.frames = 2
    a.flip_x = false

    -- effects
    a.confused = 0

    -- display
    a.display_name = display_name

    add(actors, a)
    return a
end

function in_bounds(x, y)
    if x < 0 or x >= level_size or
       y < 0 or y >= level_size then
        return false
    end

    return true
end

function is_static_tile(tile_class, x, y)
    if (not in_bounds(x, y)) return false

    return get_tile_class(level_static_tiles[x][y]) == tile_class
end


function is_dynamic_tile(tile_class, x, y)
    if (not in_bounds(x, y)) return false

    -- find out if tile sprite is member of class
    return get_tile_class(level_dynamic_tiles[x][y]) == tile_class
end

function has_move_ability(a, tile_ability)
    return contains(a.move_abilities, tile_ability)
end

function has_push_ability(a, tile_ability)
    return contains(a.push_abilities, tile_ability)
end

function can_move(x, y, a)
    if (not in_bounds(x, y)) return false

    -- For all tile types, check if this tile is of that type and actor has ability to move
    if level_dynamic_tiles[x][y].spr != ground_spr then 
        for t in all(dynamic_tiles) do
            if(is_dynamic_tile(t, x, y) and has_move_ability(a,t)) then
                return true
            end
        end
        return false
    end
    for t in all(static_tiles) do
        if(is_static_tile(t, x, y) and has_move_ability(a,t)) then
            return true
        end
    end
    return false
end

function can_push(x, y, a)
    if (not in_bounds(x, y)) return false
    
    -- For all tile types, check if this tile is of that type and actor has ability to move
    for t in all(dynamic_tiles) do
        if(is_dynamic_tile(t, x, y) and has_push_ability(a, t)) then
            return true
        end
    end
    return false
end

-- push if the tile has somewhere to go
function maybe_push(x, y, dx, dy)
    local new_x = x + dx;
    local new_y = y + dy;

    -- only allow to push onto ground for now
    if (is_static_tile(ground, new_x, new_y) and is_dynamic_tile(ground, new_x, new_y)) then
        level_dynamic_tiles[new_x][new_y] = level_dynamic_tiles[x][y]
        level_dynamic_tiles[x][y] = make_tile(ground_spr)
    end
end

function get_pattern_index(a)
    return (a.t % #a.pattern) + 1
end

function get_pattern_move(a)
    return a.pattern[get_pattern_index(a)]
end

function npc_get_move(a)
    local new_move, alt_move

    -- Move according to pattern if possible
    local pattern_move = get_pattern_move(a)
    new_loc = {
        a.x + pattern_move[1],
        a.y + pattern_move[2]
    }
    if can_move(new_loc[1], new_loc[2], a) then
        return pattern_move
    end

    -- Alternative move
    prev_loc = {
        a.x - a.last_move[1],
        a.y - a.last_move[2],
    }

    -- try perpendicular moves first
    local perp_moves = get_perp_moves(pattern_move)
    local could_not_move = false
    local perp_move
    for i=1,#perp_moves do
        perp_move = perp_moves[i]
        alt_loc = {
            a.x + perp_move[1],
            a.y + perp_move[2],
        }

        if can_move(alt_loc[1], alt_loc[2], a) then
            -- dont allow move into prev pos as alt
            if not pair_equal(alt_loc, prev_loc) then
                update_pattern(a, perp_move)
                return perp_move
            end
        end
    end

    -- need to go backwards
    back_move = {-pattern_move[1], -pattern_move[2]}
    back_loc = {
        a.x + back_move[1],
        a.y + back_move[2],
    }
    if can_move(back_loc[1], back_loc[2], a) then
        return {0, 0}
    end


    -- nowhere to move... stuck
    return {0, 0}
end

function npc_die(a)
    a.t = 0
    del(actors, a)
    add(dying, a)
    sfx(die_sfx)
end

function npc_input()
    for a in all(actors) do
        if not is_player(a) then
            -- apply npc pattern
            if a.dx == 0 and a.dy == 0 then
                if tick % slow_speed == 0 then
                    move = npc_get_move(a)
                    if pair_equal(move, {0,0}) then
                        npc_die(a)
                    else
                        a.dx = move[1]
                        a.dy = move[2]
                        a.last_move = move
                        create_trail(a)
                    end
                end
            end
        end
    end
end

function update_npc(a)
    if a.dx != 0 or a.dy != 0 then
        a.t += 1
    end
end

function update_dying(a)
    a.t += 1
    if a.t == dying_time then
        add(dead, a)
    end
end

function update_dead()
    for a in all(dead) do
        del(dying, a)
    end
    dead = {}
end

function update_pattern(a, new_move)
    local update_index = (a.t % #a.pattern) + 1
    a.pattern[update_index] = {new_move[1], new_move[2]}
    -- also mirror the move on the way back to keep the pattern looping
    local mirror_update_index = #a.pattern - update_index
    a.pattern[(mirror_update_index % #a.pattern) + 1] = {-new_move[1], -new_move[2]}

    -- effects
    sfx(change_pattern_sfx)
    a.confused = 1
end

function update_actor(a)
    -- move actor
    if(a.dx != 0 or a.dy != 0) then
        local new_x = a.x + a.dx
        local new_y = a.y + a.dy

        -- push
        if is_player(a) then
            if can_push(new_x, new_y, a) then
                maybe_push(new_x, new_y, a.dx, a.dy)
            end
        end

        if (a.confused == 2) a.confused = 0
        if (a.confused == 1) a.confused += 1

        -- move
        if can_move(new_x, new_y, a) then
            if is_player(a) then
                save_player_move(a)
            end

            a.x = new_x
            a.y = new_y

            if is_player(a) then
                update_player(a)
                play_player_sfx("move")
            else
                update_npc(a)
            end
        else
            if is_player(a) then
                sfx(0)
            end
        end

        -- actor animation
        a.frame += 1
        a.frame %= a.frames
        if (a.dx != 0) a.flip_x = a.dx > 0

        a.dx = 0
        a.dy = 0

        -- effects
    end
end

function update_actors()
    foreach(actors, update_actor)
end

function update_particles()
    remove = {}
    for p in all(particles) do
        if (p.end_tick < tick) then
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
        local n_pos = find_sprite(l, n.spr_n)
        if n_pos != nil then
            make_actor(
                n_pos[1],
                n_pos[2],
                n.spr_n,
                n.pattern,
                n.move_abilities,
                n.push_abilities,
                n.display_name)
        end
    end
end

function is_stuck()
    if not can_move(pl.x+1, pl.y, pl) and
       not can_move(pl.x-1, pl.y, pl) and
       not can_move(pl.x, pl.y+1, pl) and
       not can_move(pl.x, pl.y-1, pl) then
        return true
    else
        return false
    end
end

function no_npc()
    return #actors == 1
end

-->8
-- player

player_spr = 5
player_pattern = {}
player_pattern_i = 0
player_pattern_size = 10 -- must be 1 longer than the max npc pattern length
player_move_abilities = {ground, win}
player_push_abilities = {rock_small, tree_small}

player_trail={
    --SCHEMA
    --{
    --    from_x,
    --    from_y,
    --    dx,
    --    dy
    --}
}
player_trail_index = 0

function init_player(l)
    local player_pos = find_sprite(l, player_spr)
    pl = make_actor(
        player_pos[1],
        player_pos[2],
        player_spr,
        {},
        player_move_abilities,
        player_push_abilities,
        "you")
    reset_player_pattern()
    reset_player_trail()
end

function player_input()
    if (btnp(0)) pl.dx = -1
    if (btnp(1)) pl.dx = 1
    if (btnp(2)) pl.dy = -1
    if (btnp(3)) pl.dy = 1
    -- if (btnp(4)) show_trail = not show_trail
    if (btnp(5)) then
        if game.state == "splash" then
            game.state = "play"
        elseif game.state == "play" then
            change_level = game.level
        else
            -- noop
        end
    end
end

function reset_player_pattern()
    player_pattern={}
    for i=1,player_pattern_size do
        add(player_pattern, {0,0})
    end
end

function reset_player_trail()
    player_trail={}
    for i=1,6 do
        add(player_trail, {-1,-1,0,0})
    end
    player_trail_index = 0
end

function play_player_sfx(action)
    if(action == "move") then
        sfx(player_sfx[action][pl.move_abilities[1]])
        return
    end
    sfx(player_sfx[action])
end


function is_player(a)
    return (#a.pattern == 0)
end

function update_player(p)
    -- check player victory
    if is_static_tile(win, p.x, p.y) then
        change_level = game.level + 1
        sfx(11)
        return
    end

    -- save player pattern
    player_pattern_i += 1
    if player_pattern_i > player_pattern_size then
        player_pattern_i = 1
    end
    player_pattern[player_pattern_i][1] = p.dx;
    player_pattern[player_pattern_i][2] = p.dy;
end

function save_player_move(p)
    if p.dx != 0 or p.dy != 0 then
        local move = {
            from_x = p.x,
            from_y = p.y,
            dx = p.dx,
            dy = p.dy,
        }
        player_trail[player_trail_index % #player_trail + 1] = move
        player_trail_index += 1
    end
end

-->8
-- game mechanic

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

function rev_pattern(pattern)
    reverse = {}
    for i = 1,#pattern do
        reverse[i] = {}
        reverse[i][1] = pattern[#pattern-i+1][1]
        reverse[i][2] = pattern[#pattern-i+1][2]
    end
    return reverse
end

function shift_pattern_halfway(pattern)
    shifted = {}
    local half_len = #pattern / 2.0 - 1
    for i = 1,#pattern do
        shifted[i] = {}
        shifted[i][1] = pattern[((i + half_len) % #pattern) + 1][1]
        shifted[i][2] = pattern[((i + half_len) % #pattern) + 1][2]
    end
    return shifted
end

-- given a pattern returns the concat of the pattern and its inverted reverse
function get_full_pattern(pattern)
    local back_pattern = rev_pattern(pattern)
    for i=1,#back_pattern do
        back_pattern[i][1] = back_pattern[i][1] * -1
        back_pattern[i][2] = back_pattern[i][2] * -1
    end
    return table_concat(pattern, back_pattern)
end

-- give player ability of animal it mimics
function mimic()
    for a in all(actors) do
        if not is_player(a) then
            -- check regular pattern and shifted pattern for backwards mimic
            if contains_pattern(player_pattern, a.pattern) or
                contains_pattern(player_pattern, shift_pattern_halfway(a.pattern)) then
                if(not (pl.move_abilities[1] == a.move_abilities[1])) then
                    play_player_sfx("transform")
                end
                pl.move_abilities = copy_table(a.move_abilities)
                pl.push_abilities = copy_table(a.push_abilities)
                pl.spr = a.spr
                pl.display_name = a.display_name
                reset_player_pattern()
            end
        end
    end
end

function patterns_match(pattern_a, pattern_b, start_a)
    local a_len = #pattern_a
    local b_len = #pattern_b
    for i=1, b_len do
        local a_i = ((start_a + i - 1) % a_len) + 1
        local b_i = i
        if pattern_a[a_i][1] != pattern_b[b_i][1] or
           pattern_a[a_i][2] != pattern_b[b_i][2] then
            return false
        end
    end
    return true
end

function contains_pattern(in_pattern, fit_pattern)
    local in_len = #in_pattern
    local fit_len = #fit_pattern
    -- start matching pattern from fit pattern length back from current player pattern index (wrapped)
    local start_i = ((player_pattern_i - fit_len + player_pattern_size - 1) % player_pattern_size) + 1
    if patterns_match(in_pattern, fit_pattern, start_i) then
        return true
    else
        return false
    end
end

-->8
-- level and map

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
    tick = 0
    actors = {}
    dying = {}
    dead = {}
    particles={}
    game.level = _level
    init_tiles(_level)
    init_actors(_level)
    init_player(_level)
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
                debug_log("oops")
            end
        end
    end
end

-- Given a level number will return the (x,y) position of the sprite
function find_sprite(l, spr_n)
    for i=0,level_size-1 do
        for j=0,level_size-1 do
             if get_sprite(i,j,l) == spr_n then
                return {i, j}
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

-->8
-- draw

function draw_splash()
    cls()

    print(splash_keys_3, hcenter(splash_keys_3)-2, 105, 8)

    if(tick % 60 > 0 and tick % 60 < 20) cls()


    map(100,58,36,10,8,4)

    print(splash_inst_1, hcenter(splash_inst_1), 54, 13)
    print(splash_inst_2, hcenter(splash_inst_2), 64, 13)

    print(splash_keys_1, hcenter(splash_keys_1), 78, 13)
    print(splash_keys_2, 48, 88, 13)
end

function draw_won()
    cls()
    print(won_text, 38, vcenter(won_text)-30, 9)
    print(won_text, 38, vcenter(won_text)-20, 10)
    print(won_text, 38, vcenter(won_text)-10, 11)
    print(won_text, 38, vcenter(won_text), 12)
    print(won_text, 38, vcenter(won_text)+10, 13)
    print(won_text, 38, vcenter(won_text)+20, 14)
end

function draw_level_splash(l)
    draw_actor(pl)
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
                    if t.frames != 0 and (tick + t.tick_offset) % t.speed == 0 then
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
    if is_player(a) then
        pal({[6]=8, [9]=8, [10]=8, [11]=8, [12]=8, [13]=8, [14]=8})
    end
    spr(a.spr + a.frame, a.x*8, a.y*8, 1, 1, a.flip_x)
    pal()
    if (a.confused > 0) print("!", a.x*8 + 3, a.y*8 + 1, 8)
end

function draw_dying(a)
    spr(a.spr, a.x*8, a.y*8, 1, 1, a.flip_x)
    print("?", a.x*8 + 1, a.y*8 + 1, 8)
    print("!", a.x*8 + 4, a.y*8 + 1, 8)
end

function draw_particle(p)
    p.draw_fn(p.pos, p.col, p.curr_tick, p.start_tick, p,end_tick)
end

function draw_actors()
    foreach(actors, draw_actor)
    foreach(dying, draw_dying)
end

function draw_particles()
    foreach(particles, draw_particle)
end

function draw_player_trail()
    if (not show_trail) return

    for m in all(player_trail) do
        local draw_fn
        if m.dx == 1 then
            draw_fn = draw_trail_right_box
        elseif m.dx == -1 then
            draw_fn = draw_trail_left_box
        elseif m.dy == 1 then
            draw_fn = draw_trail_down_box
        elseif m.dy == -1 then
            draw_fn = draw_trail_up_box
        else
            return
        end

        draw_fn({m.from_x * 8, m.from_y * 8}, 7)
    end
end

function draw_ui()
    if is_stuck() then
        print(stuck_text, hcenter(stuck_text), vcenter(stuck_text), 7)
        local stuck_tile = get_dynamic_or_static_tile_class(pl.x, pl.y)
        local explain_text = pl.display_name.." can't "..tile_display_names[stuck_tile]
        print(explain_text, hcenter(explain_text), vcenter(explain_text) + 8, 7)
    end
end

-->8
-- debug

function draw_debug()
    print(debug, 0, 0, 11)
end

function debug_log(s)
    if(s == null) s = "nil"
    debug..=s.."\n"
end

function debug_log_table(xs)
    for x in all(xs) do
        debug ..= x.." "
    end
    debug ..="\n"
end

function debug_log_pair_table(xs)
    for i = 1,#xs do
        debug ..= pair_str(xs[i]).."\n"
    end
end

function pair_str(p)
    return p[1].."_"..p[2]
end


-->8
-- game loop

function _init()
    init_level(game.level)
    change_level = -1
    menuitem(1, "skip level", menu_skip_level)
end

function menu_skip_level()
    change_level = game.level + 1
end

function _update()
    -- pre update
    tick += 1
    player_input()

    if game.state == "splash" then
        return
    elseif game.state == "play" then
        update_play()
    elseif game.state == "won" then
        return
    end    
end

function update_play()
    -- check win
    if change_level == level_count then
        game.state = "won"
        return
    end

    -- check level switch
    if change_level >= 0 then
        init_level(change_level)
        change_level = -1
        return
    end

    -- play level
    npc_input()
    update_actors()
    update_particles()
    -- update_dyings()
    -- update_dead()
    mimic()
end

function _draw()
    if game.state == "splash" then
        draw_splash()
    elseif  game.state == "won" then
        draw_won()
    elseif game.state == "play" then
        draw_play()
    end
end

function draw_play()
    cls()
    if tick < 50 then
        draw_level_splash(game.level)
    else
        draw_level()
        draw_particles()
        draw_player_trail()
        draw_actors()
        draw_ui()
        if (debug_mode) draw_debug()
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000022220000000
00000000080800000000000000000000000000000088880000000000000000000000000000000000000000000000000000000000000000222200220020000000
00700700888880000000000000000000000000000888888000888800009990900099090000000000000000000000000000000000000002200220022020000000
000770008888800000000000000000000000000008f8f88008888880099999000999900000000000000000000000000000000000000000200020002000000000
00077000088800000000000000000000000000000888888008f8f880099999000999900000000000000000000000000000000000000002202220022200000000
00700700008000000000000000000000000000000888888008888880009990900099090000000000000000000000000000000000000000002000220200000000
00000000000000000000000000000000000000000088880000888800000000000000000000000000000000000000000000000000000000002200200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000
00000000000000000000000000000000000000000e0000e000e00e00000000000000000000000000000000000000000000000000000000000288200000000000
0000000000000000000000000000000000000000eee00eee0eeeeee000000000c000000c00000000000000000000000000000000000000002888820000000000
0000000000000000000000000000000000000000eee00eee0eeeeee0000cc000cc0cc0cc00000000000000000000000000000000000000002888882000000000
00000000000000000000000000000000000000000eeeeee000eeee0000cccc000cccccc000000000000000000000000000000000222200002882220000000000
000000000000000000000000000000000000000000eeee00000ee0000cccccc000cccc0000000000000000000000000000000000200000002882000000000000
00000000000000000000000000000000000000000eeeeee000eeee00cc0cc0cc000cc00000000000000000000000000000000000200000002882000090900000
0000000000000000000000000000000000000000eee00eee0eeeeee0c000000c0000000000000000000000000000000000000000200000002882000909090000
00000000000000000000000000000000000000000e0000e000e00e00000000000000000000000000000000000000000000000000200000002882000090900000
00000000000000000000000000000000000000000000000000000000066000000066000000000000000000000000000000000000222222222882000909090000
01110000011100001111111011111000011000000000000000000000066000000066000000000000000000000000909008880ccc288888888882000090900000
01111000111100001111111011111000011000000000000000bb0000066666660066666600000000000000000000040008980c2c222222222222000000000000
0119990111999000119999900099999001199000b0000bb00b00b00b0666666000666660000000000000000009090409088eeccc200200002002000000000000
01199991199990001199999000999990011990000b00b00bb0000bb00666666000666660000000000000000000400440aaaefe00200200002002000000000000
011999999999900011990000000119900119900000bb0000000000000600006000600060000000000000000000400400a9aeee00200200002002000000000000
011990999919900011990000000119900119900000000000000000000600006000660066000000000000000000044400aaa00000200200002002000000000000
01199009911990001199000000011990011990000000000000000000000000000000000000000000000000000000400000000000220220002202200000000000
01199000011990001199000000011990011990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900011990000000119900119900000b00bb0000b00b0000000000000000000000000000000000000000000000000000000000000000999000900
011990000119900011990000000119900119900000bbbb00000bbbb0000000000000000000000000000000000000000000000000000000000000009909909900
0119900001199000119911101111199001199000bbbbbb000bbbbbb0000000000000000000000000000000000000000000000000000000000000009000999000
0119900001199000119911101111199001199000bbbbbb000bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000
011990000119900000999990009999900119900000bbbb00000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000
000990000009900000999990009999900009900000b00bb0000b00b0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc00000000000000000
0000a00000000000000000000000000000000000000000000000000000cccccccccccccccccccc00cccccc000cccccc0cccccc00cccccccc0000000000000000
000aaa000000000000000000000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0000000000000000
00aaaaa00000000000000000000077000007700000077000000077000cccccccccccccccccccccc0ccccccc00cccccc0ccccccc0cccccccc0000000000000000
000aaa000000000000000000007777700777770007777700007777700cccccccccccccccccccccc0ccccccc00cccccc0ccc77cc0cccccccc0000000000000000
0000a0000000000000000000000000000000000000000000000000000cccccccccccccccccccccc0ccccccc00cccccc0cc7cc7c0cccccccc0000000000000000
000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccc0cccccc0000cccc00ccccccc0cccccccc0000000000000000
000000000000000000000000000000000000000000000000000000000cccccc0000000000cccccc000000000000000000cccccc0000000000000000000000000
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000
000550000000000000000000077000007700000077000000077000000cccccc0ccccccc00ccccccc00cccc0000cccccc00000000000000000000000000000000
005555000005550000000000000000000007700000077000000000000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000000000000000000
055555500055550000000000000770000077770000777700000770000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000000000000000000
055555500055555000055000007777000077777000777770007777000cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000000000000000000
055555500555555000555500007777700777777007777770007777700cccccc0ccccccc00ccccccc0cccccc00ccccccc00000000000000000000000000000000
005555000555555000555550077777700000000000000000077777700cccccc0ccccccc00ccccccc0cccccc000cccccc00000b00000000000000000000000000
000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc00000000000000000000000000000000000000000
000330000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0cccccccc0cccccc00cccccc00000000000000000
003333000003300000000000000000000000000000000000000000000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
003333000003300000000000007770000007770000077700007770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
033333300033330000033000077777700077777000777770077777700cccccccccccccccccccccc00ccc77ccccccccccccccccc0cc77ccc00000000000000000
033333300033330000333300000000000000000000000000000000000cccccccccccccccccccccc00cc7cc7cccccccccccccccc0c7cc7cc00000000000000000
003333000333333000333300000770000077000000770000000770000cccccccccccccccccccccc00cccccccccccccccccccccc0ccccccc00000000000000000
0004400000044000000440000077770007777000077770000077770000ccccccccccccccccccccc000cccccccccccccccccccc00cccccc000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000cccccccc00000000000000000000000000000000
111111110000000000000000000007000000000000000000000007000000000000000000000000000cccccc00000000000000000000000000000000000000000
1ae89ea100000000000000000000777000000700000007000000777000cccccccccccccccccccccc0cccccc00000000000000000000000000000000000000000
1ebddbe10000000000000000000000000000777000007770000000000cccccccccccc77ccccccccc0cccccc00000000000000000000000000000000000000000
19dccd810000000000000000007700000770000007700000007700000ccc77cccccc7cc7ccc77ccc0cc77cc00000000000000000000000000000000000000000
18dccd910000000000000000077770007777000077770000077770000cc7cc7cc77ccccccc7cc7cc0c7cc7c00000000000000000000000000000000000000000
1ebddbe10000000000000000077777707777770077777700077777700ccccccc7cc7cccccccccccc0cccccc00000000000000000000000000000000000000000
1ae98ea10000000000000000000000000000000000000000000000000ccccccccccccccccccccccc0cccccc00000000000000000000000000000000000000000
111111110000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc00000000000000000000000000000000000000000
05151505051505750606060615151515000000000000000000000000000000001414141414141414141404141414141400000000000000000000000000000000
06162616161616161616161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05051414051515751614141415151515000000000000000000000000000000001414141414141414143436341414141400000000000000000000000000000000
16141414141414141414141414141416000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000
15141414142514751614261414151515000000000072000000005100000000001414141414141414344644373414141400000000000000000000000000000000
16b0141414141414141414141414b016000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000
05141414141414a71616161414141515000000000000000000000000000000001414141414141414343534363536141400000000000000000000000000000000
1614141414060615151514151506b016000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000
14141414140514751616167484a41515000000000000000000000000000000001414141414141434353634053435341400000000000000000071000000000000
261414140606151515061425b0061416000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0614141405050575161616a715151515000000000000000000000000000000001414141414141436343405051546461400000000000000000000000000000000
16141414060615151506161514b01416000000000000000000000072000000000000000000000000000000000000000000000000000000000000000000000000
06141405050505958484849615151515000000000000000000000000000000001414141414143534350515150535663400000000000000000000000000000000
16141414061515151516150514151516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06051515151515751414147515151515000000000000000000530000000000001414141414141415251515151505141400000000000000000000000000000000
16141414061515041516060615151516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06141574848484d6141474c605150515000000000000000000000000000000001414141414141415151515151515141400000000000000000000000000000000
16141414062615150516160615150606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
061515a7060606151414751405141515000000000000000000000000000000001616261414140515152515150514141400000000000000000000000000000000
16141414260616150515151515150606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
061516b4060505051414751414141414000000000000000000000000005000009784940614051515050515050514050500000000000000000072000000000000
06141414141414061606060616061616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06161616060505051515751514141406000000000000000000000000000000002626751626060515051515050525140500000000000000000000000000000000
26141414141414141414141516161626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06161616060505051515751516060606000000000000000000000000000000001606a71615050525050515151514151500000000000000000000000000000000
06141414141414142514150616161606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06161616160505151515b41506060606000000000000000000000000000000000606b41505250515150505151414151514000000000000000000000000000000
16141414141414141515051516261606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06161616161616151515151506060406000000000000000000000000000000000614141414141414141414141414141500500000000000000000000000000000
16161414141414051515161574848497000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06060606060606061505151506060606000000000000000000000000000000000606061616161616061616160606060600000000000000000000000000000000
161616261616161616151616a7161606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000707070707070707070707070707070707070707070707070707070707070707
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000011100000111000001100000011100000111000001100000111111100110000000000000000000000000000000000000
00000000000000000000000000000000011110001111000001100000011110001111000001100000111111100110000000000000000000000000000000000000
00000000000000000000000000000000011999011199900001199000011999011199900001199000119999900119900000000000000000000000000000000000
00000000000000000000000000000000011999911999900001199000011999911999900001199000119999900119900000000000000000000000000000000000
00000000000000000000000000000000011999999999900001199000011999999999900001199000119900000119900000000000000000000000000000000000
00000000000000000000000000000000011990999919900001199000011990999919900001199000119900000119900000000000000000000000000000000000
00000000000000000000000000000000011990099119900001199000011990099119900001199000119900000119900000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000119900000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000119900000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119900000009900000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119911100000000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000119911100110000000000000000000000000000000000000
00000000000000000000000000000000011990000119900001199000011990000119900001199000009999900119900000000000000000000000000000000000
00000000000000000000000000000000000990000009900000099000000990000009900000099000009999900009900000000000000000000000000000000000
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
00000000000000000000003330333033303330033000003330330033303330333030000000333003303030333033303330330033300000000000000000000000
00000000000000000000003330030033300300300000003030303003003330303030000000333030303030300033303000303003000000000000000000000000
00000000000000000000003030030030300300300000003330303003003030333030000000303030303030330030303300303003000000000000000000000000
00000000000000000000003030030030300300300000003030303003003030303030000000303030303330300030303000303003000000000000000000000000
00000000000000000000003030333030303330033000003030303033303030303033300000303033000300333030303330303003000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000003330333033303330333033303300000033300330000033303330303033300000333033300330000033300330333033300000000000000000
00000000000000003030303003000300300030303030000003003030000003003030303030000000030003003000000030003030303033300000000000000000
00000000000000003330333003000300330033003030000003003030000003003330330033000000030003003330000033003030330030300000000000000000
00000000000000003000303003000300300030303030000003003030000003003030303030000000030003000030000030003030303030300000000000000000
00000000000000003000303003000300333030303030000003003300000003003030303033300000333003003300000030003300303030300000000000000000
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
00000000000000000000000000000000000000000000000000000000888008808080888000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000888080808080800000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000808080808080880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000808080808880800000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000808088000800888000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000008888800088888000888880008888800000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088800880880088808880888088000880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088000880880008808800088088000880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088800880880088808800088088808880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000008888800088888000888880008888800000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000008880888088008080000000000000000000000000888088800880888088800000000000000000000000000000000000
00000000000000000000000000000000008880800080808080000000000000000000000000808080008000800008000000000000000000000000000000000000
00000000000000000000000000000000008080880080808080000000000000000000000000880088008880880008000000000000000000000000000000000000
00000000000000000000000000000000008080800080808080000000000000000000000000808080000080800008000000000000000000000000000000000000
00000000000000000000000000000000008080888080800880000000000000000000000000808088808800888008000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000088888000000000000000000000000000000000000088888000000000000000000000000000000000000000000
00000000000000000000000000000000000000880008800000000000000000000000000000000000880808800000000000000000000000000000000000000000
00000000000000000000000000000000000000880808800000000000000000000000000000000000888088800000000000000000000000000000000000000000
00000000000000000000000000000000000000880008800000000000000000000000000000000000880808800000000000000000000000000000000000000000
00000000000000000000000000000000000000088888000000000000000000000000000000000000088888000000000000000000000000000000000000000000
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

__gff__
0000000000000000000104100404000000000000000000000002000101000000000000000000000000020201000000000000000000000000000202000000000008100040404040020202020202020008040424404040400202020202000000080101214040404002020202020202000880000040404040020202020000000008
0808080808080808080808080808080802020202020000000800000000000000020202020000000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
60606060606060606060606060606060000000000000000000000000000000004141414161610b0b0b0b0b0b0b0b0b0b0000000000000000000000000000000060616162606060606060606060616060000000000000000000000000000000005760616161616060606061616060606100000000000000000000000000000000
60616061606260616160616260606062000000000000000000000000000000000b0b0b616261610b0b0b0b0b0b0b0b0b0000000000000000000000000000000060606160606060606061626062606060000000000000000000000000000000007a600b0b0b0b0b400b0b0b0b0b60616100000000000000000000000000000000
60606060616060616060626060606060000000000000000000000000000000000b0b6047487849610b0b0b0b0b0b0b0b00000000000000000000000000000000484c60626061606162606060606060600000000000000000000000000000000057610b0b0b0b0b0b0b0b0b0b0b0b616100000000000000000000000000000000
60606062606060606060606061606160000000000000000000000000000000000b606257400b6749600b0b0b0b0b0b0b0000000000000000000000000000000051576060604060606060606051606060000000000000000000000000000000005760414141414141414141414141416000000000000000004100000000000000
61606060616060606161626060606160000000000000000000000000000000000b0b60570b0b0b674c610b0b0b0b0b0b0000000000000000000000000000000051677848484c60614748496060516060000000000000000000000000000000006a48484878484848794848487848484800000000000000000007000000000000
60606060606060616060606060606060000000000000000000000000000000000b0b616a490b0b0b57600b0b0b0b0b0b000000000000000000000000000000005051515151674848580b7a5151516060000000000000000007000000000000005051515150606060515151515051505000000000000000000000000000000000
600b0b0b0b0b0b0b0b0b0b0b60604060000500000000000000000000000000000b0b0b6167490b0b57600b6060600b0b0000000000000000000000000000000050515151515151516a486c5151606060000000000000000000000000000000005150516060616060515051515160606100000000000000000000000000000000
60606060600b60606060606060616060000000000000000000000000000000000b0b0b0b6067784858606062606060600000000000000000000000000000000050515051515050515151515151616060002700000000000000000000000015005150606041515151515151516060606000000000050000000000000000000000
61606061600b0b606160616060606060000000000000000000000000000000000b0b0b0b6060606067496160606260600000000000000000000000000000000051515150515151515150774a51606060000000000000000000000000000000005161604141605151505151505160606100000000000000000000000000000000
6060626061600b0b0b60606062606060000000000000000000000000000000000b0b0b0b616060616067484848794961000000000000000000000000000700000b0b0b0b0b5151505151575150606060000005000000000000000000000000006061414141616060615150515150506000000000000000000000270000000000
62606060606060600b0b606060616060000000000000000000000015000000000b0b0b0b0b0b0b0b6060616160606a480000000000000000000000000000000051510b0b0b41415147796c516061606100000000000000000000000000000000600b0b0b41520b61605160605151506000000000000000000000000000000000
6060606060606260620b606060606260000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b60606061600000000000000000000000000000150050517748784848486c5151515150606000000000000000000000000000000000610b606060604141606060616060616100000000000000000000000000000000
4878484960606060600b606062606060000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b6060606060000000000000000000000000000000006050576050505051515151505051606000000000000000000000000000000000610b606160606061606051606060506000000000001500000000000000000000
6060606a48496060600b606060606060000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b6162626160000000000000000000000000000000006061576060500b0b515051515160606000000000000000000000000000000000600b606060616161515151515150505000000000000000000000000000000000
60616160616749606060606060606160000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b60616160610000050000000000000000000000000048486d6061605060605151506060606100000000000000000000000000000000600b606060616060605150505150505000000000000000000000000000000000
6260626060607a606060606260606060000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b0b0b6061610000000000000000000000000000000060606060606261606160606060606162000000000000000000000000000000006160606160606161615150505050505000000000000000000000000000000000
4141414141414141414141414141414100000000000000000000000000000000606060606060606060606060606060600000000000000000000000000000000061606261606060606160506160616060000000000000000000000000000000006061616060616161615050505751505000000000000000000000000000000000
4141414143414141416341414141414100000000000000000000000000000000606060606060606060606060606160610000000000150000000000000000000060616060606060616162615050626060000000000000000000000000000000006060606060616060605050476c51515100000000000000000000000000000000
4143434143436373415343414143414100000000000000000000000000000000616161606161616161616061474878480000000000000000000000000000000060626260616161626060616050506060000000000000000000000000000000006060606060615b484848486d5151505000000000000000000000000000000000
4163405343537343734343634343636300000000001700000000000000000000616061616261606161616161576060600000000000000000000000000000001560606161606060606160605151500161000000000000000000000000000000006160606060616060606161415050505000000000000000000000000000270000
43435363436343435373736343636343000000000000000000000000000000004878484961616147487848495760606100000000000000000000000000000000606161616062626060616050405060600000000000000000000000000000000061605a6060616160606061415050505000000000000000000000000000000000
43434377484878484879484a43515053000000000000000000000000000000006060615761616157515050676d60616100000000000000000000000000000000606060606060606161606050505060600000000000000000000000000000000061607a6060606160606061416060505000000000000000000000000000000000
4879486c61606061604161534350506300000000000000000000000000000000606061677948486d5161616160604161000000000000000000000000000000006062606160606062605150515051515000000000000000000000000000000000616067484960616061774a414160505000000000000000000000000000000000
616160616161616161615150505151514100000000000000000000000000000061616051505150515141414162414161000000000000000000000000000000006062626060606060605041505050615100000000000000000000000000000000516060607a616060615760414160505000000000000000000000000000000000
6141414141414141414141414141416000000000000000000000000000000000605151515050515051414141414141610000000000000000000000000000000060616060414141606051415051506050000000000000000000000000000000005050516159484878486c60414160505000000000000000000007000000000000
5041414141414141414160515050516000000000000000000000000000000000615151505051505147784a4141414161000000000000000000000000000000006160615241414141605041505150605100000000000000000000000000000000515047486c604141414141416060505000000000000000000000000000000000
504141514141414141606050515051510000000063000000000000000000000051515152514748486d4141414141616100000000000000000000000000000000606051504141414160504150505060500000000000000000000000000000000051517a6060414162414141416060505000000000000000150000000000000000
5051415060526041605151515150515100000000000000000000000000000000515250505257614141414141416260610000270000000000000000000000000062605050524141414141415060506060000000000000000000000000000000005050576041416261606041415151515000000000000000000000000000000000
515051516041606151515150515051510000000000000000000000000000000051515151517a614141414141414161610000000000000000000000000000000060605150416041414141415060506062000000000000000000000000000000005150574141416161606060505051405000000000000000000000000000000000
5050506061416160605050505150505100000000000000000000000000000000514051515167496141414141414160610000000000000000000000000000000062605150506141616161515161515061000000270000050000000000000000005050574141606060606061515151505000000005000000000000000000000000
5150606061416161606051515151515100000000000500000000002700000000515151515151576141616060414161600000000000000000050000000000000060615051506060606060626060606161000000000000000000000000000000005050576060606051525161616150505000000000000000000000000000000000
50505050505050505050505050505050000000000000000000000000000000005150505250507a6060606060606060600000000000000200000000000000000060606160616061616161616161616060000000000000000000000000000000005050576160615250515151606060606000000000000000000000000000000000
__sfx__
000400000653007500005002640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000417006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__music__
00 4d0e0f44

