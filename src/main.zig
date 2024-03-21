const std = @import("std");
const rl = @import("raylib");

const print = @import("std").debug.print;

const blockSize = 64;
//const blocks = 50;

const LEVEL_WIDTH = 10;
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
            .SWITCH => rl.Rectangle{ .x = 96, .y = 0, .width = 16, .height = 16 },
            .HELLDWELLER => rl.Rectangle{ .x = 0, .y = 32, .width = 16, .height = 16 },
            .GHOST => rl.Rectangle{ .x = 16, .y = 32, .width = 16, .height = 16 },
        };
    }
};

//for testing
pub fn drawLevelTexturesByType(pos: rl.Vector2, tiletype: TileEnum, textureAtlas: rl.Texture2D) !void {
    const Dest = rl.Rectangle{ .x = pos.x, .y = pos.y, .width = 64, .height = 64 };
    rl.DrawTexturePro(
        textureAtlas,
        tiletype.setTextures(),
        Dest,
        rl.Vector2{ .x = 0, .y = 0 },
        0,
        rl.WHITE,
    );
}

const State = struct {};

const Tile = struct {
    type: TileEnum,
    base: bool = true,
    movable: bool = false,
    tilepos: rl.Vector2,

    pub fn initTile(tileType: TileEnum) Tile {
        return Tile{
            .type = tileType,
            .base = switch (tileType) {
                .GRASS, .HELLFLOOR, .WATER, .LAVA, .DOORUNLOCKED, .DOORLOCKED, .GATE, .SWITCH, .HELLDWELLER, .GHOST => true,
                .WOODBLOCK, .EGG => false, // Example: WOODBLOCK and EGG are not base
            },
            .movable = switch (tileType) {
                .WOODBLOCK => true, // Example: These can be moved or interacted with
                else => false, // Default case for other tiles
            },
            .tilepos = rl.Vector2{ .x = 0, .y = 0 }, // Default position, should be updated when placing the tile
        };
    }
};

const Level = struct {
    playerStartPos: rl.Vector2,
    levelHeight: usize = 10,
    levelWidth: usize = 10,
    tiles: [][]Tile,

    pub fn drawLevel(
        self: Level,
        textureAtlas: rl.Texture2D,
    ) !void {
        const tileSize: usize = 64; // Size of each tile, adjust as needed
        const tileGap: usize = 5; // Gap between tiles, adjust as needed

        for (self.tiles, 0..) |row, rowIndex| {
            for (row, 0..) |tile, colIndex| {
                const basePosition = rl.Vector2{
                    .x = self.playerStartPos.x + @as(f32, @floatFromInt((colIndex * (tileSize + tileGap)))),
                    .y = self.playerStartPos.y + @as(f32, @floatFromInt((rowIndex * (tileSize + tileGap)))),
                };

                // Combine basePosition with tile's own position if necessary
                const finalPosition = rl.Vector2{
                    .x = basePosition.x + tile.tilepos.x,
                    .y = basePosition.y + tile.tilepos.y,
                };

                const texture = tile.type.setTextures();
                // Call the drawing function for the tile texture at finalPosition
                // This is a placeholder function. Replace it with your actual drawing code.
                drawTile(textureAtlas, texture, finalPosition);
            }
        }
    }
};

fn drawTile(textureAtlas: rl.Texture2D, texture: rl.Rectangle, position: rl.Vector2) void {
    const destRect = rl.Rectangle{ .x = position.x, .y = position.y, .width = 64, .height = 64 };
    const origin = rl.Vector2{ .x = 0, .y = 0 };
    rl.DrawTexturePro(textureAtlas, texture, destRect, origin, 0, rl.WHITE);
}

// pub fn draw(self: GameWorld) void {
//     rl.BeginDrawing();
//     rl.ClearBackground(rl.RAYWHITE);
//     // Draw blocks and other game elements
//     rl.EndDrawing();
// }

// pub fn update(self: *GameWorld) void {
//     // Update game world state (e.g., player movement, collision detection)
// }

// pub fn draw(self: GameWorld) void {
//     rl.BeginDrawing();
//     rl.ClearBackground(rl.RAYWHITE);
//     // Draw blocks and other game elements
//     rl.EndDrawing();
// }

pub fn main() void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    rl.InitWindow(800, 600, "Hunter");
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var canMove: bool = true;

    const textureAtlas = rl.LoadTexture("src/estergamespritesheet.png");

    var playerPos = rl.Vector2{ .x = 100, .y = 100 };
    // Initialize level tiles, for simplicity, only a few tiles are initialized here
    const tiles: [][]Tile = @constCast(&[_][]Tile{
        @constCast(&[_]Tile{ Tile.initTile(.GRASS), Tile.initTile(.WATER), Tile.initTile(.HELLFLOOR) }),
        @constCast(&[_]Tile{ Tile.initTile(.LAVA), Tile.initTile(.WOODBLOCK), Tile.initTile(.EGG) }),
        @constCast(&[_]Tile{ Tile.initTile(.DOORLOCKED), Tile.initTile(.GATE), Tile.initTile(.SWITCH) }),
    });
    // Initialize the level
    var level = Level{
        .playerStartPos = playerPos,
        .levelHeight = 3,
        .levelWidth = 3,
        .tiles = tiles,
    };

    //const wallSourceRect = rl.Rectangle{ .x = 0, .y = 0, .width = 16, .height = 16 };
    //const wallSourceRectDest = rl.Rectangle{ .x = 100, .y = 100, .width = 64, .height = 64 };

    const playerAnimation: f32 = 3;
    const playerAnimationNumframes = 3;
    const playerRunframelen: f32 = 0.1;
    var player_current_frame: f32 = 0;
    var player_animation_frame_time: f32 = 0;

    while (!rl.WindowShouldClose()) {
        //const nextPosition = playerPos;
        if (canMove) {
            if (rl.IsKeyPressed(rl.KeyboardKey.KEY_RIGHT)) {
                playerPos.x += blockSize + 5;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_LEFT)) {
                playerPos.x -= blockSize + 5;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_UP)) {
                playerPos.y -= blockSize + 5;
                canMove = false;
            } else if (rl.IsKeyPressed(rl.KeyboardKey.KEY_DOWN)) {
                playerPos.y += blockSize + 5;
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
            .x = playerPos.x,
            .y = playerPos.y,
            .width = (64 * 3) / playerAnimation,
            .height = 64,
        };

        //rl.DrawTexturePro(textureAtlas, wallSourceRect, wallSourceRectDest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);

        try level.drawLevel(textureAtlas);
        //try drawLevelTexturesByType(rl.Vector2{ .x = 100, .y = 100 }, .GRASS, textureAtlas);

        rl.DrawTexturePro(textureAtlas, playersource, playersourceDest, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);

        rl.DrawFPS(10, 10);
    }
}
