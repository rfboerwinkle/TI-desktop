import os
import png
import sys

folder = sys.argv[1]

WIDTH = 48
HEIGHT = 59

radix = "0123456789ABCDEF"

def getByte(img, x, y):
  start = x*8*4
  b = img[y][start : start+8*4 : 4]
  out = 0
  out += (b[0] < 127) << 7
  out += (b[1] < 127) << 6
  out += (b[2] < 127) << 5
  out += (b[3] < 127) << 4
  out += (b[4] < 127) << 3
  out += (b[5] < 127) << 2
  out += (b[6] < 127) << 1
  out += (b[7] < 127) << 0
  return out

img = None
with open(folder.strip("/\\") + ".bin", "wb") as fout:
  files = sorted(os.listdir(folder))
  fout.write(len(files).to_bytes(1))
  for filename in files:
    with open(os.path.join(folder, filename), 'rb') as fp:
      img = (png.Reader(file=fp)).asRGBA8()
      img = [list(row) for row in img[2]]

    for x in range(WIDTH//8):
      for y in range(HEIGHT):
        b = getByte(img, x, y)
        b = b.to_bytes(1)
        fout.write(b)
