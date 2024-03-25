const std = @import("std");
const rl = @import("raylib");

const print = @import("std").debug.print;

const TILE_SIZE = 64;
const TILE_GAP = 5;

const LEVEL_WIDTH = 5;
const LEVEL_HEIGHT = 5;

const TileEnum = enum {
    GRASS,
    WATER,
    WOODBLOCK,
    HELLFLOOR,
    LAVA,
    EGG,
    DOORUNLOCKED,
    DOORLOCKED,
    GATE,
    SWITCH,
    HELLDWELLER,
    GHOST,
    EMPTY,

    fn setTextures(self: @This()) rl.Rectangle {
        return switch (self) {
            .GRASS => rl.Rectangle{ .x = 48, .y = 0, .width = 16, .height = 16 },
            .WATER => rl.Rectangle{ .x = 64, .y = 0, .width = 16, .height = 16 },
            .WOODBLOCK => rl.Rectangle{ .x = 80, .y = 0, .width = 16, .height = 16 },
            .HELLFLOOR => rl.Rectangle{ .x = 0, .y = 16, .width = 16, .height = 16 },
            .LAVA => rl.Rectangle{ .x = 16, .y = 16, .width = 16, .height = 16 },
            .EGG => rl.Rectangle{ .x = 32, .y = 16, .width = 16, .height = 16 },
            .DOORUNLOCKED => rl.Rectangle{ .x = 48, .y = 16, .width = 16, .height = 16 },
            .DOORLOCKED => rl.Rectangle{ .x = 64, .y = 16, .width = 16, .height = 16 },
            .GATE => rl.Rectangle{ .x = 80, .y = 0, .width = 16, .height = 16 },
            .SWITCH => rl.Rectangle{ .x = 96, .y = 16, .width = 16, .height = 16 },
            .HELLDWELLER => rl.Rectangle{ .x = 0, .y = 32, .width = 16, .height = 16 },
            .GHOST => rl.Rectangle{ .x = 16, .y = 32, .width = 16, .height = 16 },
            .EMPTY => rl.Rectangle{ .x = 48, .y = 32, .width = 16, .height = 16 },
        };
    }
};

const State = struct {};

const Player = struct {
    position: rl.Vector2,
    maxHealth: usize = 4,
    currentHealth: usize = 0,
};

pub fn DrawHealthBar(player: Player, texture: rl.Texture2D) void {
    const source = rl.Rectangle{
        .x = 32,
        .y = 32,
        .width = 16,
        .height = 16,
    };

    for ((player.maxHealth - player.currentHealth), 0..) |_, col| {
        const basePosition = rl.Vector2{
            .x = @as(f32, @floatFromInt((col * (TILE_SIZE + TILE_GAP)))) + 500.0,
            .y = 0.0 + 20.0,
        };

        const dest = rl.Rectangle{
            .x = basePosition.x,
            .y = basePosition.y,
            .width = 64,
            .height = 64,
        };
        rl.DrawTexturePro(texture, source, dest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.RED);
    }
}

const Tile = struct {
    type: TileEnum,
    base: bool = true,
    movable: bool = false,
    pickable: bool = false, //for egg
    canDamage: bool = false,
    tilepos: rl.Vector2,

    pub fn initTile(tileType: TileEnum) Tile {
        return Tile{
            .type = tileType,
            .base = switch (tileType) {
                .GRASS, .HELLFLOOR, .WATER, .LAVA, .DOORUNLOCKED, .DOORLOCKED, .GATE, .SWITCH, .HELLDWELLER, .GHOST => true,
                .WOODBLOCK,
                .EGG,
                .EMPTY,
                => false, // Example: WOODBLOCK and EGG are not base
            },
            .movable = switch (tileType) {
                .WOODBLOCK => true, // Example: These can be moved or interacted with
                else => false, // Default case for other tiles
            },
            .tilepos = rl.Vector2{ .x = 0, .y = 0 },
            .pickable = switch (tileType) {
                .EGG => true,
                else => false,
            },
            .canDamage = switch (tileType) {
                .GHOST, .HELLDWELLER => true,
                else => false,
            },
        };
    }
};

pub fn updateTilePosition(tilePosPtr: *rl.Vector2, newPos: rl.Vector2) void {
    tilePosPtr.* = newPos; // Dereference the pointer and assign the new position
}

const Level = struct {
    playerStartPos: *rl.Vector2,
    levelHeight: usize = 10,
    levelWidth: usize = 10,
    baseTiles: [][]Tile,
    topLayer: [][]Tile,

    pub fn drawLevel(
        self: Level,
        textureAtlas: rl.Texture2D,
    ) !void {
        const tileSize: usize = TILE_SIZE; // Size of each tile, adjust as needed
        const tileGap: usize = TILE_GAP; // Gap between tiles, adjust as needed

        for (self.baseTiles, 0..) |row, rowIndex| {
            for (row, 0..) |tile, colIndex| {
                const basePosition = rl.Vector2{
                    .x = @as(f32, @floatFromInt((colIndex * (tileSize + tileGap)))),
                    .y = @as(f32, @floatFromInt((rowIndex * (tileSize + tileGap)))),
                };

                // Combine basePosition with tile's own position if necessary
                const finalPosition = rl.Vector2{
                    .x = basePosition.x,
                    .y = basePosition.y,
                };

                // Since you want to modify tile, which is captured by value, use an index to access it as a pointer
                var tilePtr = &row[colIndex]; // Correctly obtaining a pointer to the tile for mutation
                updateTilePosition(&tilePtr.tilepos, basePosition);

                //print("base pos -> {} \n", .{tile.tilepos});

                const texture = tile.type.setTextures();
                // Call the drawing function for the tile texture at finalPosition
                // This is a placeholder function. Replace it with your actual drawing code.
                drawTile(textureAtlas, texture, finalPosition);
            }
        }

        for (self.topLayer, 0..) |row, rowIndex| {
            for (row, 0..) |tile, colIndex| {
                const basePosition = rl.Vector2{
                    .x = @as(f32, @floatFromInt((colIndex * (tileSize + tileGap)))),
                    .y = @as(f32, @floatFromInt((rowIndex * (tileSize + tileGap)))),
                };

                const finalPosition = rl.Vector2{
                    .x = basePosition.x,
                    .y = basePosition.y,
                };

                // Since you want to modify tile, which is captured by value, use an index to access it as a pointer
                var tilePtr = &row[colIndex]; // Correctly obtaining a pointer to the tile for mutation
                updateTilePosition(&tilePtr.tilepos, basePosition);

                //print("top pos -> {} \n", .{tile.tilepos});

                const texture = tile.type.setTextures();
                drawTile(textureAtlas, texture, finalPosition);
            }
        }
    }
};

fn drawTile(textureAtlas: rl.Texture2D, texture: rl.Rectangle, position: rl.Vector2) void {
    const destRect = rl.Rectangle{ .x = position.x + 100, .y = position.y + 100, .width = TILE_SIZE, .height = TILE_SIZE };
    const origin = rl.Vector2{ .x = 0, .y = 0 };
    rl.DrawTexturePro(textureAtlas, texture, destRect, origin, 0, rl.WHITE);
}

const MoveDir = struct {
    up: rl.Vector2 = rl.Vector2{ .x = 0, .y = -1 },
    down: rl.Vector2 = rl.Vector2{ .x = 0, .y = 1 },
    left: rl.Vector2 = rl.Vector2{ .x = -1, .y = 0 },
    right: rl.Vector2 = rl.Vector2{ .x = 1, .y = 0 },
};

pub fn movePlayer(direction: *const rl.Vector2, tiles: [][]Tile, toptiles: [][]Tile, playerPos: rl.Vector2) !bool {
    print("player pos {}\n", .{playerPos});

    const targetPos = rl.Vector2{
        .x = playerPos.x + (direction.*.x * (TILE_SIZE + TILE_GAP)),
        .y = playerPos.y + (direction.*.y * (TILE_SIZE + TILE_GAP)),
    };
    print("targetPos {}\n", .{targetPos});

    const rowIndex: i64 = @intCast(@divFloor(@as(i64, @intFromFloat(@floor(targetPos.y))), (TILE_SIZE + TILE_GAP)));
    const colIndex: i64 = @intCast(@divFloor(@as(i64, @intFromFloat(@floor(targetPos.x))), (TILE_SIZE + TILE_GAP)));

    print("rowIndex {}\n", .{rowIndex});
    print("colIndex {}\n", .{colIndex});
    print("xtiles {}\n", .{tiles.len});
    print("ytiles {}\n", .{tiles[0].len});

    // Check if the target indices are within the bounds of the tilemap
    if (rowIndex < 0 or rowIndex > tiles.len - 1 or colIndex < 0 or colIndex > tiles[0].len - 1) {
        print("Target position is out of bounds, block the movement\n", .{});
        return false;
    }

    //prioritize checking the top layer for walkability,
    // and falling back to the base layer if the top tile is empty.
    const baseTile = tiles[@as(usize, @intCast(rowIndex))][@as(usize, @intCast(colIndex))];
    print("baseTile {}\n", .{baseTile});
    const topTile = toptiles[@as(usize, @intCast(rowIndex))][@as(usize, @intCast(colIndex))];
    print("topTile {}\n", .{topTile});
    const tileToCheck = if (topTile.type != TileEnum.EMPTY) topTile else baseTile;
    print("tileToCheck {}\n", .{tileToCheck});

    if (isWalkable(tileToCheck)) {
        //playerPos = targetPos; // Move player if the target position is walkable
        return true;
    }
    if (isMovable(tileToCheck)) {
        print("tileToCheckblock {}\n", .{tileToCheck});
        const blockTargetPos = rl.Vector2{
            .x = tileToCheck.tilepos.x + (direction.*.x * (TILE_SIZE + TILE_GAP)),
            .y = tileToCheck.tilepos.y + (direction.*.y * (TILE_SIZE + TILE_GAP)),
        };

        const rowIndexBlock: i64 = @intCast(@divFloor(@as(i64, @intFromFloat(@floor(blockTargetPos.y))), (TILE_SIZE + TILE_GAP)));
        const colIndexBlock: i64 = @intCast(@divFloor(@as(i64, @intFromFloat(@floor(blockTargetPos.x))), (TILE_SIZE + TILE_GAP)));

        if (rowIndexBlock < 0 or rowIndexBlock > tiles.len - 1 or colIndexBlock < 0 or colIndexBlock > tiles[0].len - 1) {
            print("Target position is out of bounds, block the movement\n", .{});
            return false;
        }

        const tileToCheckv2 = &toptiles[@as(usize, @intCast(rowIndex))][@as(usize, @intCast(colIndex))];
        const topTileBlock = &toptiles[@as(usize, @intCast(rowIndexBlock))][@as(usize, @intCast(colIndexBlock))];

        const temp = topTileBlock.*.type;
        topTileBlock.*.type = tileToCheckv2.*.type;
        tileToCheckv2.*.type = temp;

        return true;
    }
    if (isPickable(tileToCheck)) {
        const tileToCheckv2 = &toptiles[@as(usize, @intCast(rowIndex))][@as(usize, @intCast(colIndex))];
        tileToCheckv2.*.type = .GRASS;

        for (toptiles) |row| {
            for (row, 0..) |tile, colIndexz| {
                if (tile.type == .DOORLOCKED) {
                    const tilePtr = &row[colIndexz];
                    tilePtr.*.type = .DOORUNLOCKED;
                }
            }
        }

        return true;
    } else {
        return false;
    }

    return false;
}

fn isMovable(tile: Tile) bool {
    return switch (tile.type) {
        .WOODBLOCK => true,
        else => false,
    };
}

fn isWalkable(tile: Tile) bool {
    print("tile \n{}", .{tile});
    return switch (tile.type) {
        .GRASS, .EMPTY => true,
        else => false,
    };
}

fn isPickable(tile: Tile) bool {
    return switch (tile.type) {
        .EGG => true,
        else => false,
    };
}

pub fn main() void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    rl.InitWindow(800, 600, "Hunter");
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var canMove: bool = true;

    const textureAtlas = rl.LoadTexture("src/estergamespritesheet.png");

    // Initialize level tiles, for simplicity, only a few tiles are initialized here
    const tiles: [][]Tile = @constCast(&[_][]Tile{
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS) }),
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS) }),
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS) }),
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS) }),
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS), Tile.initTile(.GRASS) }),
    });
    const toptiles: [][]Tile = @constCast(&[_][]Tile{
        @constCast(&[_]Tile{ Tile.initTile(.EMPTY), Tile.initTile(.WOODBLOCK), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY) }),
        @constCast(&[_]Tile{ Tile.initTile(.EMPTY), Tile.initTile(.EMPTY), Tile.initTile(.SWITCH), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY) }),
        @constCast(&[_]Tile{ Tile.initTile(.GHOST), Tile.initTile(.EMPTY), Tile.initTile(.WOODBLOCK), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY) }),
        @constCast(&[_]Tile{ Tile.initTile(.EGG), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY), Tile.initTile(.EMPTY), Tile.initTile(.GHOST) }),
        @constCast(&[_]Tile{ Tile.initTile(.EMPTY), Tile.initTile(.GHOST), Tile.initTile(.SWITCH), Tile.initTile(.WOODBLOCK), Tile.initTile(.DOORLOCKED) }),
    });

    const playerPos = rl.Vector2{ .x = 0, .y = 0 };
    var player = Player{
        .position = playerPos,
    };

    // Initialize the level
    var level = Level{
        .playerStartPos = &player.position,
        .levelHeight = LEVEL_HEIGHT,
        .levelWidth = LEVEL_WIDTH,
        .baseTiles = tiles,
        .topLayer = toptiles,
    };

    const playerAnimation: f32 = 3;
    const playerAnimationNumframes = 3;
    const playerRunframelen: f32 = 0.1;
    var player_current_frame: f32 = 0;
    var player_animation_frame_time: f32 = 0;

    const m = MoveDir{};

    while (!rl.WindowShouldClose()) {
        //const nextPosition = playerPos;
        if (canMove) {
            if (rl.IsKeyPressed(rl.KeyboardKey.KEY_RIGHT) and try movePlayer(&m.right, tiles, toptiles, player.position)) {
                player.position.x += TILE_SIZE + TILE_GAP;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_LEFT) and try movePlayer(&m.left, tiles, toptiles, player.position)) {
                player.position.x -= TILE_SIZE + TILE_GAP;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_UP) and try movePlayer(&m.up, tiles, toptiles, player.position)) {
                player.position.y -= TILE_SIZE + TILE_GAP;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_DOWN) and try movePlayer(&m.down, tiles, toptiles, player.position)) {
                player.position.y += TILE_SIZE + TILE_GAP;
                canMove = false;
            }
        }

        if (rl.IsKeyReleased(rl.KeyboardKey.KEY_RIGHT) or rl.IsKeyReleased(rl.KeyboardKey.KEY_LEFT) or rl.IsKeyReleased(rl.KeyboardKey.KEY_UP) or rl.IsKeyReleased(rl.KeyboardKey.KEY_DOWN)) {
            canMove = true;
        }

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.DARKPURPLE);

        player_animation_frame_time += rl.GetFrameTime();
        if (player_animation_frame_time > playerRunframelen) {
            player_current_frame += 1;
            player_animation_frame_time = 0;
            if (player_current_frame == playerAnimationNumframes) {
                player_current_frame = 0;
            }
        }

        const playersource = rl.Rectangle{
            .x = @as(f32, player_current_frame) * 48 / playerAnimation,
            .y = 0,
            .width = 48 / playerAnimation,
            .height = 16,
        };
        const playersourceDest = rl.Rectangle{
            .x = player.position.x + 100,
            .y = player.position.y + 100,
            .width = (TILE_SIZE * 3) / playerAnimation,
            .height = TILE_SIZE,
        };

        try level.drawLevel(textureAtlas);

        rl.DrawTexturePro(textureAtlas, playersource, playersourceDest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);

        DrawHealthBar(player, textureAtlas);
    }
}
