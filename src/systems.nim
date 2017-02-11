import 
  ecs,
  components, 
  sdl2,
  game

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Render System
proc render*(game: GameObj, lag: float) = 
  for entity in game.em.entities:
    if not entity.has(ColorComponent): continue 

    let 
      color = entity.get(ColorComponent)
      # If the entity does not conform to the camera
      (screenX, screenY) = 
        if not entity.has(StaticScreenComponent): 
          game.camera.get_screen_location((entity.x, entity.y))
        else: 
          (entity.x.cint, entity.y.cint)

    var toDraw = rect(screenX, screenY, entity.w.cint, entity.h.cint)
    var r, g, b, a: uint8
    game.renderer.getDrawColor(r, g, b, a)
    game.renderer.setDrawColor(color.r, color.g, color.b)

    game.renderer.fillRect(toDraw)

    game.renderer.setDrawColor(r, g, b, a)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Player Input Update System
proc move(e: var Entity, xVel, yVel, dt: float) = 
  e.x += int(xVel * dt)
  e.y += int(yVel * dt)

proc moveLeft(e: var Entity, velocity, dt: float) =
  e.move(-velocity, 0, dt)

proc moveRight(e: var Entity, velocity, dt: float) = 
  e.move(velocity, 0, dt)

proc moveUp(e: var Entity, velocity, dt: float) = 
  e.move(0, -velocity, dt)

proc moveDown(e: var Entity, velocity, dt: float) = 
  e.move(0, velocity, dt)

proc player_input_update*(game: GameObj, dt: float): GameObj = 
  result = game
  if game.is_command_pressed(Command.SpeedUp): echo "ZOOOM!"

  for entity in result.em.entities.mitems:
    if not entity.has(PlayerInputComponent): continue

    let 
      input = entity.get(PlayerInputComponent)

    if game.is_command(Command.SpeedUp):
      input.velocity = 800
    else:
      input.velocity = 100

    if game.isCommand(Command.Left):
      entity.moveLeft(input.velocity, dt)
    elif game.isCommand(Command.Right):
      entity.moveRight(input.velocity, dt)
    if game.isCommand(Command.Up):
      entity.moveUp(input.velocity, dt)
    elif game.isCommand(Command.Down):
      entity.moveDown(input.velocity, dt)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Camera Update System
proc camera_update*(game: GameObj, dt: float): GameObj = 
  result = game
  for entity in game.em.entities:
    if not entity.has(CameraFollowComponent): continue

    result.camera.x = entity.x
    result.camera.y = entity.y

    # Only follow the first entity
    return result

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> General Update System
proc general_update*(game: GameObj, dt: float): GameObj =
  result = game

  for entity in game.em.entities:
    if entity.has(AnyInputOrWaitComponent):
      var comp = entity.get(AnyInputOrWaitComponent)

      comp.elapsed += dt

      if (comp.elapsed >= comp.sec or game.is_any_key()):
        result = comp.callback(comp, result)
        entity.remove(AnyInputOrWaitComponent)
    # if entity.has(FadeComponent):

