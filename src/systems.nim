import 
  ecs,
  components, 
  sdl2,
  game,
  basic2d

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Render System
proc render_color_rect(game: GameObj, entity: Entity, lag: float) = 
  if not entity.has(ColorComponent): return 

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


proc handle_rendering*(game: GameObj, lag: float) = 
  for entity in game.em.entities:
    render_color_rect(game, entity, lag)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc is_collided(
    entity: Entity, 
    other_entities_list: seq[Entity],
    new_pos: (int, int)): bool = 

  for other_entity in other_entities_list:
    if entity.id == other_entity.id or 
        not other_entity.has(CollisionComponent): continue
    let player = Entity(
      x: new_pos[0], y: new_pos[1], 
      w: entity.w, h: entity.h, 
      z: entity.z, id: entity.id)
    if player.intersects(other_entity):
      return true
  return false

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Player Input Update System
proc move(e: Entity, xVel, yVel, dt: float): (int, int) = 
  let
    x = e.x + int(xVel * dt)
    y = e.y + int(yVel * dt)
  (x, y)

proc shoot(entity: Entity, game: GameObj, 
    target: (int, int), dt: float): GameObj =
  result = game
  if not entity.has(ShootComponent): return result

  let comp = entity.get(ShootComponent)
  comp.elapsed += dt

  if game.is_command(Command.Shoot) and comp.elapsed >= comp.speed:
    result.em.add(
      newEntity(entity.x, entity.y, 10, 10)
        .add(newColorComponent(0, 255, 0))
        .add(newMoveTowardsComponent((entity.x, entity.y), target, 300f))
    )
    comp.elapsed = 0


proc player_input_update(
    game: GameObj, entity: var Entity, dt: float): GameObj = 
  result = game
  if not entity.has(PlayerInputComponent): return result

  const zero = float(0)
  var dpos = (zero, zero)
  let input = entity.get(PlayerInputComponent)

  if game.is_command(Command.SpeedUp):
    input.velocity = 800
  else:
    input.velocity = 100
  
  if game.is_command(Command.Left):
    dpos = (-input.velocity, zero)
  elif game.is_command(Command.Right):
    dpos = (input.velocity, zero)
  if game.is_command(Command.Up):
    dpos = (dpos[0], -input.velocity)
  elif game.is_command(Command.Down):
    dpos = (dpos[0], input.velocity)
  
  let 
    w2 = 1280 / 2
    h2 = 720 / 2
    ma_x = game.mouse.x + entity.x
    ma_y = game.mouse.y + entity.y
    mouse_pos = (ma_x.float - w2, ma_y.float - h2)
  result = entity.shoot(result, (mouse_pos[0].int, mouse_pos[1].int), dt)

  let new_pos = entity.move(dpos[0], dpos[1], dt)

  # Do we need collision?
  if dpos != (zero, zero) and 
      entity.id == "player" and 
      entity.has(CollisionComponent):
      if not entity.is_collided(result.em.entities, new_pos):
        entity.x = new_pos[0]
        entity.y = new_pos[1]
  else: 
    entity.x = new_pos[0]
    entity.y = new_pos[1]

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Camera Update System
proc camera_update(game: GameObj, entity: Entity, dt: float): GameObj = 
  result = game
  if not entity.has(CameraFollowComponent): return result
  result.camera.x = entity.x
  result.camera.y = entity.y

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> General Update System
proc general_update(game: GameObj, entity: var Entity, dt: float): GameObj =
  result = game
  if entity.has(AnyInputOrWaitComponent):
    var comp = entity.get(AnyInputOrWaitComponent)
    comp.elapsed += dt
    if (comp.elapsed >= comp.sec or game.is_any_key()):
      result = comp.callback(comp, result)
      entity.remove(AnyInputOrWaitComponent)
  if entity.has(MoveTowardsComponent):
    let 
      comp = entity.get(MoveTowardsComponent)
      position = vector2d(entity.x.float, entity.y.float)
      new_position = position + (comp.direction * comp.speed * dt)
    entity.x = new_position.x.int
    entity.y = new_position.y.int


#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc handle_updates*(game: GameObj, dt: float): GameObj =
  result = game
  for entity in result.em.entities.mitems:
    result = player_input_update(result, entity, dt)
    result = general_update(result, entity, dt)
    result = camera_update(result, entity, dt)