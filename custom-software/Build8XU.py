"""
This was adapted from a visual basic script originally written by Brandon Wilson.
From his readme:

> OS2Tools v1.0
> Brandon Wilson
[...]
> brandonlw@gmail.com, brandonw.net, etc.

note: mine does no signing....
"""

import hashlib
import sys

def appendByteArray(array):
  global data, dataIndex
  for char in array:
    data[dataIndex] = char
    dataIndex += 1

def writeByteArray(f, array):
  for num in array:
    f.write(num.to_bytes(1, 'big'))

def toIntelHexString(address, array, offset, count):
  ret = ":"
  ret += f"{count:0>2X}"
  ret += f"{address:0>4X}"
  ret += "00"
  for i in range(offset, count + offset):
    ret += f"{array[i]:0>2X}"
  ret += f"{strToChecksum(ret):0>2X}"
  ret += "\r\n"
  return ret

def strToChecksum(line):
  return arrayToCheckSum(strToArray(line))

def strToArray(line):
  ret = []
  line = line.strip(": \r\n")

  if len(line) % 2 != 0:
    print("Invalid checksum line!")
    quit()

  length = len(line)//2
  for i in range(length):
    ret.append(int(line[i*2 : (i+1)*2], 16))
  return ret

def arrayToCheckSum(array):
  ret = 0
  for s in array:
    ret = (ret + s) & 255
  ret = (ret ^ 255) & 255
  ret += 1
  return ret & 255

def Signature(inHash):
  # this should be the proper one
  N = 0xEF5FEF0B0AB6E22731C17539658B2E91E53A59BF8E00FCC81D05758F26C1791CD35AF6101B1E3543AC3E78FD8BB8F37FC8FE85601C502EABC9132CEAD4711CB1
  D = 0x2A3E1B2010F318D9BD7C7E19300980B055A0E2A9554B77E7142E23CDF7C7CA13C233A3D462FDFC968B1F9CEAF2AC2CF305147992AD9E834192ACEBB517DB9941
  # this should be the community one
  # N = 0xBFA2309BF4997D8ED9850F907746E9919E7862511C1B6FEEC23043E6103A38BD84F5421AD04980F79D4EC7D6093D1D1FEF60334E93BF6CD46F82F19B7EF2AB6B
  # D = 0x70B9C23D9EF0E072259990AF5538C5A0F3CE57F379F2059B8149915A27A9C7050D1889078AC306D98A0154CFDDD44F74B7AB2DFA44643FEBF0E0916063D631E1
  H2 = 0
  for num in reversed(inHash):
    H2 <<= 8
    H2 += num
  return pow(H2, D, N)

# take args here...

key = 0x0A
majorVersion = 2
minorVersion = 0x2B
maxHardwareVersion = 3
# these were pulled from smileyos, long story...

LINES_PER_PAGE = 512
BYTES_PER_LINE = 32

outputFileName = "trial.8xu"

# PLEASE NOTE THE DIFFERENCE BETWEEN THE DIRECTORY AND THE PAGE
pages = {0x00: (0x0000, "../src/00/base.bin"), 0x1C: (0x0000, "../src/7C/base.bin")}

data = [0xFF] * ((0x7F * 0x4000) + 128)
dataIndex = 0

appendByteArray([0x80, 0xF, 0x0, 0x0, 0x0, 0x0])
appendByteArray([0x80, 0x11, key])
appendByteArray([0x80, 0x21, majorVersion])
appendByteArray([0x80, 0x31, minorVersion])
appendByteArray([0x80, 0xA1, maxHardwareVersion])
appendByteArray([0x80, 0x81, len(pages)])
appendByteArray([0x80, 0x7F, 0x0, 0x0, 0x0, 0x0])

for page in pages:
  pg = page
  offset = pages[page][0]
  fileName = pages[page][1]
  with open(fileName, "rb") as f:
    f.seek(offset)
    newArray = []
    byte = f.read(1)
    while byte != b"":
      newArray.append(int.from_bytes(byte, "big"))
      byte = f.read(1)
  start = dataIndex
  appendByteArray(newArray)
  dataIndex = start + 0x4000

b = bytearray(data[:dataIndex])
MD5Hash = hashlib.md5(b).digest()
sig = Signature(MD5Hash)

with open(outputFileName, "wb") as f:
  headerData = [0x2A, 0x2A, 0x54, 0x49, 0x46, 0x4C, 0x2A, 0x2A, 0x2, 0x40, 0x1, 0x88, 0x11, 0x26, 0x20, 0x7, 0x8, 0x62, 0x61, 0x73, 0x65, 0x63, 0x6F, 0x64, 0x65, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x73, 0x23, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
  writeByteArray(f, headerData)
  s = toIntelHexString(0, data, 0, 0x1B)
  f.write(s.encode(encoding="ascii"))
  s = ":00000001FF\r\n"
  f.write(s.encode(encoding="ascii"))

  pageHeaderBase = ":0200000200"
  pageHeader = ""
  checksum = 0
  ptr = 0
  for page in pages:
    pageHeader = pageHeaderBase + f"{page:0>2X}" + f"{(0xFC - page):0>2X}" + "\r\n"
    f.write(pageHeader.encode(encoding="ascii"))

    for i in range(LINES_PER_PAGE):
      line = ""
      address = i * BYTES_PER_LINE
      if page != 0:
        address = address | 0x4000

      checksum = BYTES_PER_LINE
      line = ":20" + f"{address:0>4X}" + "00"
      checksum += address & 0xFF
      checksum += ((address & 0xFF00) >> 8) & 0xFF

      for j in range(BYTES_PER_LINE):
        d = data[(address & 0x3FFF) + j + (ptr*0x4000) + 0x1B]
        line += f"{d:0>2X}"
        checksum += d
      line += f"{((((0xFF ^ (checksum & 0xFF)) & 0xFF) + 1) & 0xFF):0>2X}\r\n"

      f.write(line.encode(encoding="ascii"))
    ptr += 1

  s = ":00000001FF\r\n"
  f.write(s.encode(encoding="ascii"))

  validationData = [0xFF] * 0x43
  for i in range(64):
    validationData[i+3] = sig & 0xFF
    sig = sig >> 8
  if sig != 0:
    # Sorry, I don't really know what this code does, i'm just translating ;-;
    print("I'm not sure, but something might have gone horribly wrong with the signature...")
  validationData[0] = 0x02
  validationData[1] = 0x0D
  validationData[2] = 0x40

  s = toIntelHexString(0, validationData, 0x00, 0x20)
  f.write(s.encode(encoding="ascii"))
  s = toIntelHexString(0, validationData, 0x20, 0x20)
  f.write(s.encode(encoding="ascii"))
  s = toIntelHexString(0, validationData, 0x40, 0x03)
  f.write(s.encode(encoding="ascii"))
  s = ":00000001FF   -- CONVERT 2.6 --\r\n"
  f.write(s.encode(encoding="ascii"))
