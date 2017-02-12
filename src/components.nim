import 
  ecs,
  game

type   
  ColorComponent* = ref object of Component
    r*, g*, b*: uint8

  PlayerInputComponent* = ref object of Component
    velocity*: float

  CameraFollowComponent* = ref object of Component
  StaticScreenComponent* = ref object of Component

  AnyInputOrWaitComponent* = ref object of Component
    sec*: float
    elapsed*: float
    callback*: (proc (this: AnyInputOrWaitComponent, game: GameObj): GameObj)

  FadeComponent* = ref object of Component
    sec*: float
    elapsed*: float
    callback*: (proc (game: GameObj, entity: Entity): GameObj)

  CollisionComponent* = ref object of Component

  Dummy* = ref object of Component

proc newDummy*(): Dummy = new result

proc newColorComponent*(r, g, b: uint8): ColorComponent =
  new result
  result.r = r
  result.g = g
  result.b = b

proc newPlayerInputComponent*(): PlayerInputComponent =
  new result 
  result.velocity = 100

proc newCameraFollowComponent*(): CameraFollowComponent = 
  new result

proc newStaticScreenComponent*(): StaticScreenComponent = 
  new result

proc newAnyInputOrWaitComponent*(
    sec: float, 
    cb: (proc (this: AnyInputOrWaitComponent, game: GameObj): GameObj)
    ): AnyInputOrWaitComponent = 
  new result
  result.sec = sec
  result.elapsed = 0f
  result.callback = cb

proc newFadeComponent*(sec: float, 
    cb: (proc (game: GameObj, entity: Entity): GameObj)): FadeComponent = 
  new result
  result.sec = sec
  result.callback = cb

proc newCollisionComponent*(): CollisionComponent = 
  new result

