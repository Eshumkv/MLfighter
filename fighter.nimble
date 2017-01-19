# Package

version       = "0.1.0"
author        = "Eshumkv"
description   = "A Machine Learning Experiment"
license       = "MIT"

srcDir = "src"
binDir = "bin"
bin = @["fighter"]
skipExt = @["nim"]

# Variables

let libDir = "lib"
let resDir = "res"
let docDir = "docs"
# These files NEED to be in the libDir 
let libFiles = @["libjpeg-9.dll", "SDL2_image.dll"]

when defined(windows):
  let sep = "\\"
else: 
  let sep = "/"

# Dependencies

requires "nim >= 0.15.2"
requires "sdl2 >= 1.1"

# Tasks

proc toLib(path: string): string = 
  ## Return the path appended to the libDir. (Convenience function)
  libDir & sep & path

proc toBin(path: string): string = 
  ## Return the path appended to the binDir. (Convenience function)
  binDir & sep & path

proc getResFiles(dir: string = resDir, make: bool = true): seq[string]
proc toLine(str: string, token: string = "-"): string = 
  result = ""
  for s in str:
    result &= token

before build: 
  # Clear the build directory
  rmDir(binDir)

after build: 
  # Copy the library files to the bin folder
  for file in libFiles:
    cpFile(file.toLib, file.toBin)

  # Copy the resources to the bin folder
  let resFiles = getResFiles()
  for file in resFiles:
    cpFile(file, file.toBin)
  
  let msg = "BUILD SUCCESSFUL"
  echo msg.toLine
  echo msg
  echo msg.toLine

task clean, "Remove all unneeded files and clean the project":
  rmDir(nimcacheDir())

task run, "Run the binary":
  exec(bin[0].toExe.toBin)

task cb, "Clean, build and run the project":
  exec "nimble clean"
  exec "nimble build"

task br, "Build and run the project":
  exec "nimble build"
  exec "nimble run"

task cbr, "Clean, build and run the project":
  exec "nimble clean"
  exec "nimble build"
  exec "nimble run"

task docs, "Generate documentation":
  rmDir(docDir)
  let args = "doc2 --out:" & docDir & sep & bin[0] & 
    " --docSeeSrcUrl:txt --project " & srcDir & sep & bin[0] & ".nim"
  echo args
  exec "nim " & args

# Procedure implementations

proc getResFiles(dir: string = resDir, make: bool = true): seq[string] =
  ## Gets the all files in the resDir directory (including subfolders)
  ## For convenience sake, it also makes the necessary directories in the 
  ## binDir directory.
  let dirs = listDirs(dir)
  for dir in dirs: 
    let files = listFiles(dir)
    result = result & files
    if make: mkDir(dir.toBin)
    if files.len != 0:
      result = result & getResFiles(dir)