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
  Game* = ref GameObj
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

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc is_command_pressed*(game: Game, command: Command): bool = 
  let (pressed, repeat) = game.commands[command]
  return pressed and not repeat

proc is_command*(game: Game, command: Command): bool = 
  let (pressed, _) = game.commands[command]
  return pressed
  
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

from systems import nil

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newCamera(w, h: int): Camera2D = 
  new result
  result.halfWidth = w div 2
  result.halfHeight = h div 2

proc getScreenLocation*[T](camera: Camera2D, location: (T, T)): (cint, cint) = 
  var 
    screenX = (location[0].int - camera.x) + camera.halfWidth
    screenY = (location[1].int - camera.y) + camera.halfHeight
  
  result = (screenX.cint, screenY.cint)


#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc render*(game: Game, lag: float) = 
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

proc processSystemCommand(game: Game, command: Command) = 
  case command:
  of Command.Fullscreen:
    game.isFullscreen = not game.isFullscreen

    if game.setFullscreen != nil:
      if game.isFullscreen:
        game.setFullscreen(game.isFullscreen, FullscreenType.Desktop)
      else:
        game.setFullscreen(game.isFullscreen, FullscreenType.Windowed)
  else:
    discard

proc processInput*(game: var Game) = 
  var event = defaultEvent 

  while pollEvent(event):
    case event.kind:
    of QuitEvent:
      if game.quitCallback != nil:
        game.quitCallback()
      else:
        # TODO: log it? 
        echo "Trying to quit :("
    of KeyDown:
      let command = event.key.keysym.sym.toCommand
      game.commands[command] = (true, event.key.repeat)
      if not event.key.repeat:
        game.processSystemCommand(command)
    of KeyUp:
      game.commands[event.key.keysym.sym.toCommand] = (false, false)
    else:
      discard

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc update*(game: var Game, elapsed: float) = 
  systems.update(game, elapsed)
  systems.cameraUpdate(game, elapsed)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc quit*(game: Game) = 
  game.renderer.destroy()

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

proc newGame*(ren: RendererPtr, size: (cint, cint), fullscreenFn: (proc (isFullscreen: bool, ftype: FullscreenType): void), exitFn: (proc())): Game = 
  new result 
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
