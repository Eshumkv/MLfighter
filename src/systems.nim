import 
  ecs,
  components, 
  sdl2,
  game,
  basic2d

# Make all functions "pure", they should have no side-effects
{.push noSideEffect.}

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

  if entity.has(MoveTowardsComponent):
    let 
      move_comp = entity.get(MoveTowardsComponent)
      (ts_x, ts_y) = game.camera.get_screen_location(
        (move_comp.dest.x, move_comp.dest.y))
    var target = rect(ts_x, ts_y, 5, 5)
    game.renderer.setDrawColor(color.r, color.g, color.b)
    game.renderer.fillRect(target)

  game.renderer.setDrawColor(r, g, b, a)


proc handle_rendering*(game: GameObj, lag: float) = 
  for entity in game.all_entities:
    render_color_rect(game, entity, lag)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc is_collided(
    entity: Entity, 
    other_entities_list: seq[Entity],
    new_pos: Point2d): bool = 

  for other_entity in other_entities_list:
    if entity.id == other_entity.id or 
        not other_entity.has(CollisionComponent): continue
    let 
      player = Entity(
        x: new_pos.x, y: new_pos.y, 
        w: entity.w, h: entity.h, 
        z: entity.z, id: entity.id)
    if player.intersects(other_entity):
      return true
  return false

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

{.pop.}

#=> Player Input Update System
proc maybe_shoot(entity: Entity, game: GameObj, 
    target: Point2d, dt: float): GameObj =
  result = game
  if not entity.has(ShootComponent): return result

  let comp = entity.get(ShootComponent)
  comp.elapsed += dt

  if game.is_command(Command.Shoot) and comp.elapsed >= comp.speed:
    let 
      n_x = entity.x + entity.w / 2
      n_y = entity.y + entity.h / 2
      v_from = point2d(n_x, n_y)
      v_to = point2d(target.x, target.y)
    result = result.add_entity(
      newEntity(n_x, n_y, 10, 10, entity.z - 1)
        .add(newColorComponent(0, 255, 0))
        .add(newMoveTowardsComponent(v_from, v_to, 300f))
    )
    comp.elapsed = 0

proc player_input_update(
    game: GameObj, entity: var Entity, dt: float): GameObj = 
  result = game
  if not entity.has(PlayerInputComponent): return result

  var dpos = vector2d(0, 0)
  let input = entity.get(PlayerInputComponent)

  if game.is_command(Command.SpeedUp):
    input.velocity = 800
  else:
    input.velocity = 100
  
  if game.is_command(Command.Left):
    dpos.x = -input.velocity
  elif game.is_command(Command.Right):
    dpos.x = input.velocity
  if game.is_command(Command.Up):
    dpos.y = -input.velocity
  elif game.is_command(Command.Down):
    dpos.y = input.velocity
  
  # adjust for time
  dpos *= dt

  let 
    w2 = 1280 / 2
    h2 = 720 / 2
    ma_x = game.mouse.x.float + entity.x
    ma_y = game.mouse.y.float + entity.y
    mouse_pos = point2d(ma_x - w2, ma_y - h2)
  result = entity.maybe_shoot(result, mouse_pos, dt)

  var new_pos = entity.get_point() #entity.move(dpos[0], dpos[1], dt)
  new_pos.move(dpos)
  echo new_pos

  # Do we need collision?
  if (dpos.x != 0 or dpos.y != 0) and entity.has(CollisionComponent) and 
      entity.is_collided(result.all_entities, new_pos):
    # We collided, don't do anything right now
    discard
  else: 
    entity.x = new_pos.x
    entity.y = new_pos.y

{.push noSideEffect.}
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Camera Update System
proc camera_update(game: GameObj, entity: Entity, dt: float): GameObj = 
  result = game
  if not entity.has(CameraFollowComponent): return result
  result.camera.x = entity.x.int
  result.camera.y = entity.y.int

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
      position = vector2d(entity.x, entity.y)
      new_position = position + (comp.direction * comp.speed * dt)
    entity.x = new_position.x
    entity.y = new_position.y

    if (entity.x <= -2000 or entity.x >= 2000) or 
        (entity.y <= -2000 or entity.y >= 2000):
      result = result.remove_entity(entity)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

{.pop.}

proc handle_updates*(game: GameObj, dt: float): GameObj =
  result = game
  for entity in result.all_m_entities:
    result = player_input_update(result, entity, dt)
    result = general_update(result, entity, dt)
    result = camera_update(result, entity, dt)
  
{.push noSideEffect.}
{.pop.}