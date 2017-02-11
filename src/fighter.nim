import 
  times,
  sdl2,
  sdl2.image,
  game

type
  SDLException = object of Exception 

const 
  imageFlags = IMG_INIT_JPG
  MS_PER_UPDATE = 1 / 100f
  NUM_UPDATES = 5

var running = true

template sdlFailIf(cond: typed, reason: string) =
  if cond:
    raise SDLException.newException(reason & ", SDL ERROR: " & $getError())

proc exit() =
  running = false

proc main = 
  var
    windowWidth: cint = 1280
    windowHeight: cint = 720

  sdlFailIf(not sdl2.init(INIT_EVERYTHING)):
    "SDL init failed"
  defer: sdl2.quit() 

  sdlFailIf(image.init(imageFlags) != imageFlags):
    "SDL_Image init failed"
  defer: image.quit()
  
  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"
  
  let window = createWindow(
    title = "Fighter",
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED, 
    w = windowWidth, 
    h = windowHeight, 
    flags = SDL_WINDOW_SHOWN
  )
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer(
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync
  )
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  let fullscreenFn = proc (f: bool, ftype: FullscreenType) = 
    var flag: uint32

    case ftype:
    of FullscreenType.Desktop:
      flag = SDL_WINDOW_FULLSCREEN_DESKTOP
    of FullscreenType.Windowed:
      flag = 0
    else: # Fullscreen
      flag = SDL_WINDOW_FULLSCREEN

    discard window.setFullscreen(flag)

  var game = newGame(renderer, (windowWidth, windowHeight), fullscreenFn, exit)
  defer: game.quit()

  var previous = epochTime()
  var lag = 0.0f

  while running: 
    var current = epochTime()
    var elapsed = current - previous

    previous = current
    lag += elapsed

    game = game.processInput()

    var count = 0
    while lag >= MS_PER_UPDATE:
      game = game.update(elapsed)

      lag -= MS_PER_UPDATE
      count += 1
      if count >= NUM_UPDATES: 
        break
    
    game.render(lag / MS_PER_UPDATE)

main()