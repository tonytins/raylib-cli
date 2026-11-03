import Raylib

InitWindow(800, 480, "Hello, World")

while !WindowShouldClose() {
    BeginDrawing()
    ClearBackground(.white)
    DrawText("Hello, world!", 12, 12, 20, .black)
    EndDrawing()
}

CloseWindow()
