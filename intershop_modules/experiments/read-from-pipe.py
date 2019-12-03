import os

pipename = 'myfifo'

try:
  os.mkfifo( pipename )
except FileExistsError as e:
  pass

while True:
  with open( pipename ) as fifo:
    for line in fifo:
      print( '^33321^', line.rstrip() )

