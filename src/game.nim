import 
  times,
  os,
  sdl2,
  sdl2.image,
  sequtils,
  math,
  random,
  ecs,
  components

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#=> Enums
type
  Command* {.pure.} = enum 
    None,
    Fullscreen,
    Shoot,
    Left,
    Up, 
    Right, 
    Down,
    SpeedUp
    
  FullscreenType* {.pure.} = enum
    Windowed,
    Fullscreen,
    Desktop

type 
  #Game* = ref GameObj # In functional programming you never need it? 
  GameObj* = object 
    renderer*: RendererPtr
    em*: EntityManager
    player: Entity
    camera*: Camera2D
    commands: array[Command, (bool, bool)] # (pressed, repeat)
    setFullscreen: (proc (isFullscreen: bool, ftype: FullscreenType): void)
    isFullscreen: bool
    quitCallback: (proc (): void)
    
  Camera2D* = ref CameraObj
  CameraObj* = object 
    x*: int
    y*: int
    halfWidth: int
    halfHeight: int

  Scene* = ref object 
    render_fn*: (proc(game: GameObj, lag: float): void)
    update_fn*: (proc (game: var GameObj, dt: float): GameObj)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

# TODO: Fix this. This just doesn't work
proc is_command_pressed*(game: GameObj, command: Command): bool = 
  let (pressed, repeat) = game.commands[command]
  return pressed and not repeat

proc is_command*(game: GameObj, command: Command): bool = 
  let (pressed, _) = game.commands[command]
  return pressed

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newCamera(w, h: int): Camera2D = 
  new result
  result.halfWidth = w div 2
  result.halfHeight = h div 2

proc get_screen_location*[T](camera: Camera2D, location: (T, T)): (cint, cint) = 
  var 
    screenX = (location[0].int - camera.x) + camera.halfWidth
    screenY = (location[1].int - camera.y) + camera.halfHeight
  
  result = (screenX.cint, screenY.cint)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

from systems import nil

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc render*(game: GameObj, lag: float) = 
  ## This causes the game to render itself to the specified renderer
  game.renderer.clear()

  systems.render(game, lag)

  game.renderer.present()

proc toCommand(key: cint): Command = 
  case key:
  of K_F11:
    result = Command.Fullscreen
  of K_W:
    result = Command.Up
  of K_S:
    result = Command.Down
  of K_A:
    result = Command.Left
  of K_D:
    result = Command.Right
  of K_Space:
    result = Command.Shoot
  of K_LSHIFT:
    result = Command.SpeedUp
  else:
    result = Command.None

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc processSystemCommand(game: GameObj, command: Command): GameObj = 
  result = game
  case command:
  of Command.Fullscreen:
    result.isFullscreen = not game.isFullscreen

    if game.setFullscreen != nil:
      if game.isFullscreen:
        game.setFullscreen(game.isFullscreen, FullscreenType.Desktop)
      else:
        game.setFullscreen(game.isFullscreen, FullscreenType.Windowed)
  else:
    discard

proc processInput*(game: GameObj): GameObj = 
  result = game
  var event = defaultEvent 

  while pollEvent(event):
    case event.kind:
    of QuitEvent:
      if result.quitCallback != nil:
        result.quitCallback()
      else:
        # TODO: log it? 
        echo "Trying to quit :("
    of KeyDown:
      let command = event.key.keysym.sym.toCommand
      result.commands[command] = (true, event.key.repeat)
      if not event.key.repeat:
        result = result.processSystemCommand(command)
    of KeyUp:
      result.commands[event.key.keysym.sym.toCommand] = (false, false)
    else:
      discard

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc update*(game: GameObj, elapsed: float): GameObj = 
  result = systems.update(game, elapsed)
  result = systems.cameraUpdate(result, elapsed)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc quit*(game: GameObj) = 
  game.renderer.destroy()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newGame*(ren: RendererPtr, size: (cint, cint), fullscreenFn: (proc (isFullscreen: bool, ftype: FullscreenType): void), exitFn: (proc())): GameObj = 
  result.renderer = ren
  result.em = newEntityManager()
  result.camera = newCamera(size[0], size[1])
  result.setFullscreen = fullscreenFn
  result.quitCallback = exitFn

  randomize epochTime().int 
  
  discard result.renderer.setDrawColor(110, 132, 174)

  result.player = newEntity("player")
    .add(newAABB(0, 0, 50, 50))
    .add(newColorComponent(19, 10, 10))
    .add(newPlayerInputComponent())
    .add(newCameraFollowComponent())

  result.em.add(result.player)

  result.em.add(
    newEntity()
      .add(newAABB(200, 200, 50, 50))
      .add(newColorComponent(200, 200, 200))
  )
  
  # let appDir = getAppDir()
  # result.em.add(newEntity(
  #   newBoundingBoxPhysicsComponent(),
  #   newTextureGraphicsComponent(
  #     result.renderer, 
  #     ren.loadTexture(appDir / "res/img/bg.jpg"), 
  #     rect(-10, -10, 500, 500)),
  #   (500, 500),
  #   (-10, -10),
  #   -1
  # ))
