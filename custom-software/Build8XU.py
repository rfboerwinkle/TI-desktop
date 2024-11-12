"""
This was adapted from a visual basic script originally written by Brandon Wilson.
From his readme:

> OS2Tools v1.0
> Brandon Wilson
[...]
> brandonlw@gmail.com, brandonw.net, etc.

NOTE: His is signed with a community key. This one requires you to provide one.
      Assuming you're working on a TI84PSE, you should use the 0x0A key.
"""

import hashlib
import sys

def toIntelHexString(address, array, offset, count):
  ret = f":{count:0>2X}{address:0>4X}00"
  checksum = count + (address & 0xFF) + ((address >> 8) & 0xFF)
  for i in range(offset, count + offset):
    ret += f"{array[i]:0>2X}"
    checksum += array[i]
    checksum &= 0xFF
  checksum = (checksum ^ 0xFF) & 0xFF
  checksum = (checksum + 1) & 0xFF
  ret += f"{checksum:0>2X}\r\n"
  return ret

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

#                 fill    (pages * pagesize) + header...?
data = bytearray([0xFF] * ((0x7F * 0x4000) + 128))
dataIndex = 0

OsHeader = b'\x80\x0F\x00\x00\x00\x00' \
 + b'\x80\x11' + key.to_bytes(1) \
 + b'\x80\x21' + majorVersion.to_bytes(1) \
 + b'\x80\x31' + minorVersion.to_bytes(1) \
 + b'\x80\xA1' + maxHardwareVersion.to_bytes(1) \
 + b'\x80\x81' + len(pages).to_bytes(1) \
 + b'\x80\x7F\x00\x00\x00\x00'
OsHeaderLen = len(OsHeader)
data[:OsHeaderLen] = OsHeader
dataIndex += OsHeaderLen

for page in pages:
  pg = page
  offset = pages[page][0]
  fileName = pages[page][1]
  with open(fileName, "rb") as f:
    f.seek(offset)
    newArray = f.read(0x4000)
  data[dataIndex : dataIndex+len(newArray)] = newArray
  dataIndex += 0x4000

MD5Hash = hashlib.md5(data[:dataIndex])
sig = Signature(MD5Hash.digest())

with open(outputFileName, "wb") as f:
  TiflHeader = b'\x2A\x2A\x54\x49\x46\x4C\x2A\x2A\x02\x40\x01\x88\x11\x26\x20\x07\x08\x62\x61\x73\x65\x63\x6F\x64\x65\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x73\x23\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
  f.write(TiflHeader)
  s = toIntelHexString(0, data, 0, OsHeaderLen)
  f.write(s.encode(encoding="ascii"))
  s = ":00000001FF\r\n"
  f.write(s.encode(encoding="ascii"))

  pageHeaderBase = ":0200000200"
  pageHeader = ""
  ptr = 0
  for page in pages:
    pageHeader = pageHeaderBase + f"{page:0>2X}{(0xFC - page):0>2X}\r\n"
    f.write(pageHeader.encode(encoding="ascii"))

    for i in range(LINES_PER_PAGE):
      line = ""
      address = i * BYTES_PER_LINE
      if page != 0:
        address = address | 0x4000
      offset = (address & 0x3FFF) + (ptr*0x4000) + OsHeaderLen
      line = toIntelHexString(address, data, offset, BYTES_PER_LINE)
      f.write(line.encode(encoding="ascii"))
    ptr += 1

  s = ":00000001FF\r\n"
  f.write(s.encode(encoding="ascii"))

  validationData = bytearray([0xFF] * 0x43)
  for i in range(64):
    validationData[i+3] = sig & 0xFF
    sig = sig >> 8
  if sig != 0:
    # Sorry, I don't really know what this code does, i'm just translating ;-;
    print("I'm not sure, but something might have gone horribly wrong with the signature...")
  validationData[:3] = b'\x02\x0D\x40'

  s = toIntelHexString(0, validationData, 0x00, 0x20)
  f.write(s.encode(encoding="ascii"))
  s = toIntelHexString(0, validationData, 0x20, 0x20)
  f.write(s.encode(encoding="ascii"))
  s = toIntelHexString(0, validationData, 0x40, 0x03)
  f.write(s.encode(encoding="ascii"))
  s = ":00000001FF   -- CONVERT 2.6 --\r\n"
  f.write(s.encode(encoding="ascii"))
