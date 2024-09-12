import streams, os, strutils, memfiles


type
  fileinfo = tuple[name: string, offset: uint32, size: uint32]


proc ArrToStr(inAr: array[0..12, char]): string =
  var
    c: char = 'a'
  result = newString(13)
  for i in 0..12:
    if inAr[i] == '\0': break
    result[i] = inAr[i]


proc load(fn: string) =
  var
    table: seq[fileinfo] = @[]
    s = newFileStream(fn, fmRead)
    nfi: fileinfo
    str: array[0..12, char]
    fNumber: uint32 #uint16
    i: uint16

  echo "Starting parse of the ", fn

  s.setPosition(5) #Set cursor in file, skipping EALIB signature
  fNumber = uint32(readInt16(s)) #scan number of packed files
  for i in 0..fNumber: #for all of them
    for c in 0..12: #scanning filename of fixed length of 13 characters,
      str[c] = s.readChar() # file name (8.3 style), padded with nulls to 12 characters, and null terminated. 
    nfi.name = ArrToStr(str) 
    discard uint8(s.readChar())
    nfi.offset = uint32(s.readInt32())
    table.add(nfi)

  for i in 0..table.len-2:
    table[i].size = table[i+1].offset - table[i].offset

  echo fNumber, " entries found, start unpacking"

  var
    dirName:string = getCurrentDir() & "\\" & split(fn,'.')[0]
    buffer:seq[char]
    cur: fileinfo

  createDir(dirName)
  setCurrentDir(dirName)

  echo "The following files will be unpacked into ", dirName, " :"

  for i in 0..table.len()-2:
    cur = table[i]
    buffer = newSeq[char]()


    s.setPosition(int(cur.offset))
    for p in 1..cur.size:
      buffer.add( s.readChar())

    var
      o = system.open(cur.name, fmWrite)


    write(stdout, $(i+1) & ". " & cur.name & " (offset: " & $cur.offset & ", size: " & $cur.size & " )")

    discard writeChars(o, buffer, 0, cur.size)
    echo "   - done"
    o.close()

  s.close()
  echo "Unpack finished"

load(paramStr(1))
