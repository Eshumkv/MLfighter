import 
  game, 
  ecs,
  components

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc game_scene*(game: GameObj): GameObj =
  result = game

  result.em.add(
    newEntity(0, 0, 50, 50, 0, "player")
      .add(newColorComponent(19, 10, 10))
      .add(newPlayerInputComponent())
      .add(newCameraFollowComponent())
      .add(newCollisionComponent())
  )

  result.em.add(
    newEntity(200, 200, 50, 50, -1)
      .add(newColorComponent(200, 200, 200))
      .add(newCollisionComponent())
  )

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc intro*(game: GameObj): GameObj =
  result = game

  result.em.add(
    newEntity(0, 0, 1280, 720, 100, "wait")
      .add(newColorComponent(19, 10, 10))
      .add(newStaticScreenComponent())
      .add(newAnyInputOrWaitComponent(sec= 10,
        cb= proc (this: AnyInputOrWaitComponent, game: GameObj): GameObj =
          game.change_scene(true, game_scene)
      ))
  )


