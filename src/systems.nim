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

      # If the entity does not conform to the camera
      (screenX, screenY) = 
        if not entity.has(StaticScreenComponent): 
          game.camera.get_screen_location((aabb.x, aabb.y))
        else: 
          (aabb.x.cint, aabb.y.cint)

    var toDraw = rect(screenX, screenY, aabb.w.cint, aabb.h.cint)
    var r, g, b, a: uint8
    game.renderer.getDrawColor(r, g, b, a)
    game.renderer.setDrawColor(color.r, color.g, color.b)

    game.renderer.fillRect(toDraw)

    game.renderer.setDrawColor(r, g, b, a)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Player Input Update System
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

proc player_input_update*(game: GameObj, dt: float): GameObj = 
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
proc camera_update*(game: GameObj, dt: float): GameObj = 
  result = game
  for entity in game.em.entities:
    if not entity.has(AABB, CameraFollowComponent): continue

    let aabb = entity.get(AABB)
    result.camera.x = aabb.x
    result.camera.y = aabb.y

    # Only follow the first entity
    return result

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> General Update System
proc general_update*(game: var GameObj, dt: float) =
  for entity in game.em.entities:
    if entity.has(AnyInputOrWaitComponent):
      var comp = entity.get(AnyInputOrWaitComponent)

      comp.elapsed += dt

      if comp.elapsed >= comp.ms or game.is_command_pressed(Command.None):
        comp.callback(comp, game)
        if comp.is_timer:
          comp.elapsed = 0
        else:
          entity.remove(AnyInputOrWaitComponent)
    # else:

