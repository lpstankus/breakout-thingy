package breakout

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

SCREEN_WIDTH: i32 = 1080
SCREEN_HEIGHT: i32 = 1440

N_COLS: i32 = 12
N_ROWS: i32 = 24

BLOCK_WIDTH := SCREEN_WIDTH / N_COLS
BLOCK_HEIGHT := SCREEN_HEIGHT / N_ROWS

Block :: struct {
	x:   i32,
	y:   i32,
	col: rl.Color,
}

BALL_RADIUS: f32 = 30
BALL_SPEED: f32 = 400

Ball :: struct {
	x:   f32,
	y:   f32,
	vx:  f32,
	vy:  f32,
	col: rl.Color,
}

draw :: proc {
	draw_block,
	draw_ball,
}

draw_block :: proc(bl: Block) {
	rl.DrawRectangle(bl.x + 1, bl.y + 1, BLOCK_WIDTH - 2, BLOCK_HEIGHT - 2, bl.col)
}

draw_ball :: proc(bl: Ball) {
	rl.DrawCircle(i32(bl.x), i32(bl.y), BALL_RADIUS, rl.BLACK)
	rl.DrawCircle(i32(bl.x), i32(bl.y), BALL_RADIUS - 2, bl.col)
}

tick :: proc(ball: ^Ball, blocks: [dynamic]Block, dt: f32) {
	ball.x += ball.vx * dt
	ball.y += ball.vy * dt
	collide(ball, blocks)
}

collide :: proc {
	collide_ball,
	collide_ball_block,
}

collide_ball :: proc(ball: ^Ball, blocks: [dynamic]Block) {
	if ball.x - f32(BALL_RADIUS) <= 0 {
		ball.vx = BALL_SPEED
	}
	if ball.y - f32(BALL_RADIUS) <= 0 {
		ball.vy = BALL_SPEED
	}
	if ball.x + f32(BALL_RADIUS) >= f32(SCREEN_WIDTH) {
		ball.vx = -BALL_SPEED
	}
	if ball.y + f32(BALL_RADIUS) >= f32(SCREEN_HEIGHT) {
		ball.vy = -BALL_SPEED
	}

	block_x := i32(ball.x / f32(BLOCK_WIDTH))
	block_y := i32(ball.y / f32(BLOCK_HEIGHT))

	x: i32 = (ball.vx < 0) ? block_x - 1 : block_x + 1
	y: i32 = (ball.vy < 0) ? block_y - 1 : block_y + 1

	out_i := x < 0 || x >= N_COLS
	out_j := y < 0 || y >= N_ROWS

	collide(ball, &blocks[block_x * N_ROWS + block_y])
	if !out_i {collide(ball, &blocks[x * N_ROWS + block_y])}
	if !out_j {collide(ball, &blocks[block_x * N_ROWS + y])}
	if !(out_i || out_j) {collide(ball, &blocks[x * N_ROWS + y])}
}

collide_ball_block :: proc(ball: ^Ball, block: ^Block) {
	if ball.col == block.col {return}

	nx: f32
	switch {
	case ball.x < f32(block.x):
		nx = f32(block.x)
	case ball.x > f32(block.x + BLOCK_WIDTH):
		nx = f32(block.x + BLOCK_WIDTH)
	case:
		nx = ball.x
	}

	ny: f32
	switch {
	case ball.y < f32(block.y):
		ny = f32(block.y)
	case ball.y > f32(block.y + BLOCK_HEIGHT):
		ny = f32(block.y + BLOCK_HEIGHT)
	case:
		ny = ball.y
	}

	delta_x := ball.x - nx
	delta_y := ball.y - ny
	dist2 := delta_x * delta_x + delta_y * delta_y
	if dist2 >= BALL_RADIUS * BALL_RADIUS {return}

	switch {
	case abs(delta_x) < 1e-4:
		ball.vy = -ball.vy
	case abs(delta_y) < 1e-4:
		ball.vx = -ball.vx
	case:
		ball.vx = -ball.vx
		ball.vy = -ball.vy
	}

	block.col = ball.col
}

main :: proc() {
	assert(N_ROWS % 2 == 0, "N_ROWS must be even")
	assert(SCREEN_WIDTH % N_COLS == 0, "SCREEN_WIDTH must be divisible by N_COLS")
	assert(SCREEN_HEIGHT % N_ROWS == 0, "SCREEN_HEIGHT must be divisible by N_ROWS")
	assert(
		BALL_RADIUS <= f32(max(BLOCK_WIDTH, BLOCK_HEIGHT)),
		"BALL_RADIUS must be less than or equal to the length of a block",
	)

	blocks := [dynamic]Block{}
	for i in 0 ..< N_COLS {
		for j in 0 ..< N_ROWS {
			color := (j < SCREEN_HEIGHT / (2 * BLOCK_HEIGHT)) ? rl.RED : rl.BLUE
			append(&blocks, Block{x = i * BLOCK_WIDTH, y = j * BLOCK_HEIGHT, col = color})
		}
	}

	balls := []Ball {
		Ball{x = 200, y = 200, vx = BALL_SPEED, vy = BALL_SPEED, col = rl.RED},
		Ball{x = f32(SCREEN_WIDTH) - 200, y = 200, vx = BALL_SPEED, vy = BALL_SPEED, col = rl.RED},
		Ball {
			x = 200,
			y = f32(SCREEN_HEIGHT) - 200,
			vx = -BALL_SPEED,
			vy = -BALL_SPEED,
			col = rl.BLUE,
		},
		Ball {
			x = f32(SCREEN_WIDTH) - 200,
			y = f32(SCREEN_HEIGHT) - 200,
			vx = -BALL_SPEED,
			vy = -BALL_SPEED,
			col = rl.BLUE,
		},
	}

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Breakout")

	time: f32 = 0
	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		for &ball in balls {tick(&ball, blocks, dt)}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		for block in blocks {draw(block)}
		for ball in balls {draw(ball)}

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

