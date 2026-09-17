# FPGA Brick Breaker

A hardware implementation of the classic **Brick Breaker** game developed in **Verilog** for the University of Toronto ECE241 Digital Systems course.

The game was implemented on the **DE1-SoC FPGA board** and rendered to a monitor through VGA. The project combines synchronous digital logic, finite-state-machine control, collision detection, user input, and real-time graphics.

> **Note:** This repository was uploaded in September 2026 for portfolio purposes. The project itself was completed in November 2025.

## Demo

[Watch the gameplay demo](https://drive.google.com/file/d/1PXHdBugdIXkIkk-DFYGJjgxFIQSlddU-/view?usp=sharing)

## Features

- 640 × 480 VGA video output
- Player-controlled paddle
- Ball movement using position and velocity vectors
- Collision detection with screen boundaries
- Ball bouncing from the top, left, and right edges
- Game-over detection when the ball reaches the bottom of the screen
- Paddle boundary constraints to prevent movement outside the visible display
- Synchronous game-state updates using finite-state-machine logic
- ModelSim simulation and waveform verification

## Hardware

- DE1-SoC FPGA development board
- VGA monitor
- On-board switches / controls

## Technologies

- **Verilog**
- **Intel Quartus Prime**
- **ModelSim**
- **FPGA / Digital Logic Design**
- **Finite State Machines (FSM)**
- **VGA Graphics**

## System Overview

The design separates the game into hardware modules responsible for movement, game logic, and VGA rendering.

### Ball Logic

The ball module stores the ball's:

- X position
- Y position
- X velocity
- Y velocity

On each enabled clock cycle, the next position is calculated from the current position and velocity.

Boundary conditions determine how the velocity changes:

- Left/right collision → reverse horizontal velocity
- Top collision → reverse vertical velocity
- Bottom boundary → trigger the game-over condition

### Paddle Logic

The paddle position is updated from user input and constrained to remain inside the 640-pixel-wide display.

The paddle moves horizontally in fixed increments while boundary checks prevent it from leaving the screen.

### VGA Rendering

The VGA subsystem writes game objects into the VGA adapter's video memory.

The paddle is rendered as a rectangular region by iterating through its pixels and generating:

- X coordinate
- Y coordinate
- Pixel colour
- VGA write signal

The VGA controller then reads the video memory and produces the appropriate VGA timing and colour signals for the monitor.

## Verification

ModelSim was used during development to verify digital logic and boundary behaviour.

Simulation testing included:

- Ball left-boundary collision
- Ball right-boundary collision
- Ball upper-boundary collision
- Ball lower-boundary / game-over behaviour
- Paddle left boundary
- Paddle right boundary
- Paddle movement and VGA logic

## My Contribution

This was a team project.

My primary contribution focused on the **VGA graphics and paddle rendering system**, including:

- Implementing 640 × 480 VGA output
- Developing paddle position and movement logic
- Rendering the paddle through the VGA adapter
- Implementing display-coordinate generation and pixel-writing logic
- Testing paddle behaviour using ModelSim
- Debugging synchronization between game-state updates and VGA rendering

Through this project, I gained practical experience with FPGA development, synchronous digital design, VGA graphics, hardware debugging, and modular Verilog development.

## Repository Structure

```text
FPGA-Brick-Breaker/
│
├── Final Game Code.v
├── vga_adapter/
└── README.md
