import png
img = None
# character width
c_width = 4
with open('FontImage.png', 'rb') as fp:
  img = (png.Reader(file=fp)).read_flat()
  size = (img[0],img[1])
  img = list(img[2])

assert(size[0] % c_width == 0)

c_count = size[0] // c_width
#print('image data:',img)
#print('total pixels:',len(img))
#print('character count:',c_count)
chars = []
for c_idx in range(c_count):
  bits = []
  for row in range(size[1]):
    for col in range(c_width):
      pxidx = row*size[0] + c_idx*c_width + col
      bits.append(1 if (img[pxidx*3] == 0) else 0)
  v = 0
  for b in bits:
    v *= 2
    v += b
  chars.append(v)
#print(size)

charorder = "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,=,-,+,*,/,.,:,!,',^,PATETO,(,),<,>,#,_,P-HOR,P-VER,P-CUL,P-CUR,P-CDR,P-CDL,P-TU,P-TR,P-TD,P-TL,SPACE".split(',')
assert(len(charorder) == c_count)

#print(charorder)
out = ['; Most-significant bit is Upper Left pixel. Bits proceed right, then down.']
rowcomment = ''
rowdat = []
CHARS_PER_ROW = 6
for char_idx in range(len(charorder)):
  if char_idx % CHARS_PER_ROW == 0:
    if len(rowdat) != 0:
      out.append(rowcomment)
      out.append(f'.db {", ".join(rowdat)}')
    rowcomment = ';'
    rowdat = []
  rowcomment += f' {charorder[char_idx]}'
  hexval = f'{chars[char_idx]:04X}'
  rowdat.append(f'${hexval[:2]}, ${hexval[2:]}')
out.append(rowcomment)
out.append(f'.db {", ".join(rowdat)}')

for o in out:
  print(o)
