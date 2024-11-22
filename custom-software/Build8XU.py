"""
This was adapted from a visual basic script originally written by Brandon Wilson.
https://www.ticalc.org/archives/files/fileinfo/420/42044.html
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

def Signature(inHash, N, D):
  H2 = 0
  # No clue why this is reversed...
  for num in reversed(inHash):
    H2 <<= 8
    H2 += num
  # This is modular power: (H2 ^ D) % N
  return pow(H2, D, N)

def error(msg):
    print("--------------------------------------------------")
    print("Usage: Build8XU.py -k[OS key (1 byte)] -m[major version (1 byte)] -n[minor version (1 byte)] -h[max. HW version (1 byte)] -K[key filename] <[page]:[offset]:[filename]> ...")
    print("Builds a valid 8XU OS upgrade file from one or more binary files.")
    print()
    print("Examples: to build a 2-page OS from a 32KB ROM:")
    print("            Build8XU -k05 -m00 -n01 -h03 00:0000:os.rom 01:4000:os.rom")
    print("          to build a 3-page OS from separate binary files:")
    print("            Build8XU -k05 -m02 -n2B -h03 00:0000:page0.bin 01:0000:page1.bin 7C:0000:page2.bin")
    print("          to build a 2-page OS from BIN files and a ROM image:")
    print("            Build8XU -k05 -m02 -n42 -h03 00:0000:page0.bin 01:4000:83p.rom 7C:7C0000:83p.rom")
    print("All parameters are required. All values are hexadecimal.")
    print()
    print(msg)
    quit()

key = 0x0A
majorVersion = 2
minorVersion = 0x2B
maxHardwareVersion = 3
# these were pulled from smileyos, long story...

LINES_PER_PAGE = 512
BYTES_PER_LINE = 32

outputFileName = "trial.8xu"


# pages = [(page number, offset, filename) ...]
pages = [(0x7C, 0x0000, "../src/7C/base.bin"), (0x00, 0x0000, "../src/00/base.bin")]
# This implicitly sorts based on the first element, (page number).
pages.sort()

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
  offset = page[1]
  fileName = page[2]
  with open(fileName, "rb") as f:
    f.seek(offset)
    newArray = f.read(0x4000)
  data[dataIndex : dataIndex+len(newArray)] = newArray
  dataIndex += 0x4000

MD5Hash = hashlib.md5(data[:dataIndex])
N = 0xEF5FEF0B0AB6E22731C17539658B2E91E53A59BF8E00FCC81D05758F26C1791CD35AF6101B1E3543AC3E78FD8BB8F37FC8FE85601C502EABC9132CEAD4711CB1
D = 0x2A3E1B2010F318D9BD7C7E19300980B055A0E2A9554B77E7142E23CDF7C7CA13C233A3D462FDFC968B1F9CEAF2AC2CF305147992AD9E834192ACEBB517DB9941
sig = Signature(MD5Hash.digest(), N, D)

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
    pageNum = page[0]
    pageHeader = pageHeaderBase + f"{pageNum:0>2X}{(0xFC - pageNum):0>2X}\r\n"
    f.write(pageHeader.encode(encoding="ascii"))

    for i in range(LINES_PER_PAGE):
      line = ""
      address = i * BYTES_PER_LINE
      if pageNum != 0:
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
