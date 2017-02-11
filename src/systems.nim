import 
  ecs,
  components, 
  sdl2,
  game

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Render System
proc render*(game: GameObj, lag: float) = 
  for entity in game.em.entities:
    if not entity.has(AABB, ColorComponent): continue 

    let 
      aabb = entity.get(AABB)
      color = entity.get(ColorComponent)
    
    let (screenX, screenY) = game.camera.get_screen_location((aabb.x, aabb.y))

    var toDraw = rect(screenX, screenY, aabb.w.cint, aabb.h.cint)
    var r, g, b, a: uint8
    game.renderer.getDrawColor(r, g, b, a)
    game.renderer.setDrawColor(color.r, color.g, color.b)

    game.renderer.fillRect(toDraw)

    game.renderer.setDrawColor(r, g, b, a)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Update System
proc move(aabb: var AABB, xVel, yVel, dt: float) = 
  aabb.x += int(xVel * dt)
  aabb.y += int(yVel * dt)

proc moveLeft(e: var AABB, velocity, dt: float) =
  e.move(-velocity, 0, dt)

proc moveRight(e: var AABB, velocity, dt: float) = 
  e.move(velocity, 0, dt)

proc moveUp(e: var AABB, velocity, dt: float) = 
  e.move(0, -velocity, dt)

proc moveDown(e: var AABB, velocity, dt: float) = 
  e.move(0, velocity, dt)

proc update*(game: GameObj, dt: float): GameObj = 
  result = game
  if game.is_command_pressed(Command.SpeedUp): echo "ZOOOM!"

  for entity in result.em.entities:
    if not entity.has(AABB, PlayerInputComponent): continue

    let 
      input = entity.get(PlayerInputComponent)

    var aabb = entity.get(AABB)

    if game.is_command(Command.SpeedUp):
      input.velocity = 800
    else:
      input.velocity = 100

    if game.isCommand(Command.Left):
      aabb.moveLeft(input.velocity, dt)
    elif game.isCommand(Command.Right):
      aabb.moveRight(input.velocity, dt)
    if game.isCommand(Command.Up):
      aabb.moveUp(input.velocity, dt)
    elif game.isCommand(Command.Down):
      aabb.moveDown(input.velocity, dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Camera Update System
proc cameraUpdate*(game: GameObj, dt: float): GameObj = 
  result = game
  for entity in game.em.entities:
    if not entity.has(AABB, CameraFollowComponent): continue

    let aabb = entity.get(AABB)
    result.camera.x = aabb.x
    result.camera.y = aabb.y

    # Only follow the first entity
    return result
