const std = @import("std");
const raylib = @import("raylib");

const print = @import("std").debug.print;

var playerPos = raylib.Vector2{ .x = 100, .y = 100 };
const blockSize = 64;
//const blocks = 50;

const LEVEL_WIDTH = 10;
const LEVEL_HEIGHT = 5;

const TileEnum = enum { EMPTY, WALL, FLOOR };

const BlockType = struct {
    position: raylib.Vector2,
    type: TileEnum,
    draggable: bool = false,
    texture: raylib.Texture2D,
    sourceRect: raylib.Rectangle,
};

const GameWorld = struct {
    textureAtlas: raylib.Texture2D,
    blocks: [][]BlockType,
    blockSize: f32,
    levelData: [][]TileEnum,

    pub fn init(allocator: *std.mem.Allocator, blockSize2d: f32, levelData2d: [][]const TileEnum) !GameWorld {
        const textureAtlas = raylib.LoadTexture("estergamespritesheet.png");

        const wallSourceRect = raylib.Rectangle{ .x = 0, .y = 0, .width = blockSize2d, .height = blockSize2d };
        const floorSourceRect = raylib.Rectangle{ .x = blockSize2d, .y = 0, .width = blockSize2d, .height = blockSize2d };

        var blocks = try allocator.alloc([]BlockType, levelData2d.len);
        for (0..levelData2d.len) |y| {
            blocks[y] = try allocator.alloc(BlockType, levelData2d[y].len);
            for (0..levelData2d[y].len) |x| {
                const tile = levelData2d[y][x];
                const position = raylib.Vector2{ .x = @as(f32, x) * blockSize2d, .y = @as(f32, y) * blockSize2d };
                const draggable = false; // Update logic as needed
                const texture = textureAtlas; // Same texture for all blocks, for now

                const sourceRect = switch (tile) {
                    .WALL => wallSourceRect,
                    .FLOOR => floorSourceRect,
                    .EMPTY => {},
                };

                blocks[y][x] = BlockType{
                    .position = position,
                    .type = tile,
                    .draggable = draggable,
                    .texture = texture,
                    .sourceRect = sourceRect,
                };
            }
        }

        return GameWorld{
            .textureAtlas = textureAtlas,
            .blocks = blocks,
            .blockSize = blockSize2d,
            .levelData = levelData2d,
        };
    }

    // pub fn update(self: *GameWorld) void {
    //     // Update game world state (e.g., player movement, collision detection)
    // }

    // pub fn draw(self: GameWorld) void {
    //     raylib.BeginDrawing();
    //     raylib.ClearBackground(raylib.RAYWHITE);
    //     // Draw blocks and other game elements
    //     raylib.EndDrawing();
    // }
};

// Level data
const levelData = [LEVEL_HEIGHT][LEVEL_WIDTH]TileEnum{
    [_]TileEnum{ .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL },
    [_]TileEnum{ .WALL, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .WALL },
    [_]TileEnum{ .WALL, .FLOOR, .WALL, .WALL, .FLOOR, .FLOOR, .WALL, .WALL, .FLOOR, .WALL },
    [_]TileEnum{ .WALL, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .FLOOR, .WALL },
    [_]TileEnum{ .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL, .WALL },
};

pub fn main() void {
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    raylib.InitWindow(800, 600, "Hunter");
    raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    var canMove: bool = true;

    const textureAtlas = raylib.LoadTexture("src/estergamespritesheet.png");

    //const wallSourceRect = raylib.Rectangle{ .x = 0, .y = 0, .width = 16, .height = 16 };
    //const wallSourceRectDest = raylib.Rectangle{ .x = 100, .y = 100, .width = 64, .height = 64 };

    const playerAnimation: f32 = 3;
    const playerAnimationNumframes = 3;
    const playerRunframelen: f32 = 0.1;
    var player_current_frame: f32 = 0;
    var player_animation_frame_time: f32 = 0;

    while (!raylib.WindowShouldClose()) {
        //const nextPosition = playerPos;
        if (canMove) {
            if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_RIGHT)) {
                playerPos.x += blockSize + 10;
                canMove = false;
            } else if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_LEFT)) {
                playerPos.x -= blockSize + 10;
                canMove = false;
            } else if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_UP)) {
                playerPos.y -= blockSize + 10;
                canMove = false;
            } else if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_DOWN)) {
                playerPos.y += blockSize + 10;
                canMove = false;
            }
        }

        if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_RIGHT) or raylib.IsKeyReleased(raylib.KeyboardKey.KEY_LEFT) or raylib.IsKeyReleased(raylib.KeyboardKey.KEY_UP) or raylib.IsKeyReleased(raylib.KeyboardKey.KEY_DOWN)) {
            canMove = true;
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.WHITE);

        player_animation_frame_time += raylib.GetFrameTime();
        if (player_animation_frame_time > playerRunframelen) {
            player_current_frame += 1;
            player_animation_frame_time = 0;
            if (player_current_frame == playerAnimationNumframes) {
                player_current_frame = 0;
            }
        }

        const playersource = raylib.Rectangle{ .x = @as(f32, player_current_frame) * 48 / playerAnimation, .y = 0, .width = 48 / playerAnimation, .height = 16 };
        const playersourceDest = raylib.Rectangle{ .x = 100, .y = 100, .width = (64 * 3) / playerAnimation, .height = 64 };

        //raylib.DrawTexturePro(textureAtlas, wallSourceRect, wallSourceRectDest, raylib.Vector2{ .x = 0, .y = 0 }, 0, raylib.WHITE);
        raylib.DrawTexturePro(textureAtlas, playersource, playersourceDest, raylib.Vector2{ .x = 0, .y = 0 }, 0, raylib.WHITE);
        raylib.DrawFPS(10, 10);
    }
}
