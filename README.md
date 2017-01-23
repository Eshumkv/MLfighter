# ML Fighter

Welcome to this repository. This is an attempt at learning machine learning. 

## The idea

The idea was to create a game that a computer could learn.
This game will be simple, just a dude running around with a gun.
There will be spots to "hide" from enemies.
Enemies will spawn in waves and there *might* be pickups.

## Afterwards

I plan to make a machine learning algorithm that actually **learns**
to play the game. Don't know exactly how yet. 
This section will be filled when I do know. 

# Build 
You will need Nim version 0.15.2 (minimum). 

After that, it's just: 
```bash
nimble build
```
to build the files into the `bin` folder. Just run the executable `fighter` to run the project.

You can also use 
```bash
nimble br
```
to build *and* run the project.