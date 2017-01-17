@echo off

RMDIR /S /Q doc
mkdir doc

nim doc2 --out:doc\fighter --docSeeSrcUrl:txt --project src\game.nim