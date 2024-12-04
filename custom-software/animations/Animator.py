import os
import png
import sys

folder = sys.argv[1]

WIDTH = 48
HEIGHT = 59

radix = "0123456789ABCDEF"

def getByte(img, x, y):
  start = y*WIDTH + x*8
  b = img[start : start+8]
  out = 0
  out += (not bool(b[0])) << 7
  out += (not bool(b[1])) << 6
  out += (not bool(b[2])) << 5
  out += (not bool(b[3])) << 4
  out += (not bool(b[4])) << 3
  out += (not bool(b[5])) << 2
  out += (not bool(b[6])) << 1
  out += (not bool(b[7])) << 0
  return out

img = None
with open(folder.strip("/\\") + ".bin", "wb") as fout:
  files = sorted(os.listdir(folder))
  fout.write(len(files).to_bytes(1))
  for filename in files:
    with open(os.path.join(folder, filename), 'rb') as fp:
      img = (png.Reader(file=fp)).read_flat()
      img = list(img[2])

    for x in range(WIDTH//8):
      for y in range(HEIGHT):
        b = getByte(img, x, y)
        b = b.to_bytes(1)
        fout.write(b)
