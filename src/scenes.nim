import 
  game, 
  ecs,
  components

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc get_arena(middle: (int, int), w, h: int): seq[Entity] = 
  result = @[]

  let 
    x = middle[0].float - (w/2)
    y = middle[1].float - (h/2)
    arena_width = 1
    color = (r: 248.uint8, g: 134.uint8, b: 54.uint8)

  result.add(
    newEntity(x, y, arena_width, h, -10, "arenaLeft")
      .add(newColorComponent(color.r, color.g, color.b))
      .add(newCollisionComponent())
  )

  result.add(
    newEntity(x, y, w, arena_width, -10, "arenaTop")
      .add(newColorComponent(color.r, color.g, color.b))
      .add(newCollisionComponent())
  )

  result.add(
    newEntity(x + w.float, y, arena_width, h, -10, "arenaRight")
      .add(newColorComponent(color.r, color.g, color.b))
      .add(newCollisionComponent())
  )
  result.add(
    newEntity(x, y + h.float, w, arena_width, -10, "arenaBottom")
      .add(newColorComponent(color.r, color.g, color.b))
      .add(newCollisionComponent())
  )

proc game_scene*(game: GameObj): GameObj =
  result = game

  result = result.add_entity(
    newEntity(0, 0, 50, 50, 0, "player")
      .add(newColorComponent(19, 10, 10))
      .add(newPlayerInputComponent())
      .add(newCameraFollowComponent())
      .add(newCollisionComponent())
      .add(newShootComponent())
  )

  result = result.add_entity(
    newEntity(200, 200, 50, 50, -1)
      .add(newColorComponent(200, 200, 200))
      .add(newCollisionComponent())
  )

  for arena_part in get_arena(middle = (0, 0), w = 1000, h = 1000):
    result = result.add_entity(arena_part)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc intro*(game: GameObj): GameObj =
  result = game

  result = result.add_entity(
    newEntity(0, 0, 1280, 720, 100, "wait")
      .add(newColorComponent(19, 10, 10))
      .add(newStaticScreenComponent())
      .add(newAnyInputOrWaitComponent(sec= 10,
        cb= proc (this: AnyInputOrWaitComponent, game: GameObj): GameObj =
          game.change_scene(true, game_scene)
      ))
  )


