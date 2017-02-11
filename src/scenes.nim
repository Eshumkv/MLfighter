import 
  game, 
  ecs,
  components

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc intro*(game: GameObj): GameObj =
  result = game

  result.em.add(
    newEntity("wait")
      .add(newAABB(0, 0, 1280, 720))
      .add(newColorComponent(19, 10, 10))
      .add(newAnyInputOrWaitComponent(25))
  )

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc game*(game: GameObj): GameObj =
  result = game

  result.em.add(
    newEntity("player")
      .add(newAABB(0, 0, 50, 50))
      .add(newColorComponent(19, 10, 10))
      .add(newPlayerInputComponent())
      .add(newCameraFollowComponent())
  )

  result.em.add(
    newEntity()
      .add(newAABB(200, 200, 50, 50))
      .add(newColorComponent(200, 200, 200))
  )


