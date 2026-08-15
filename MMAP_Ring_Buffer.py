#MMAP Ring Buffer using pythons mmap and struct modules

#mmap -> Exposing file contents dirctly in memory
#struct -> Convert data into raw bytes
#os -> Interact with the OS

import mmap
import struct
import os

BUFFER_SIZE = 1024     #number of orders in ring buffer 1024 slots
HEADER_SIZE = 16       #write pos + read pos, allocated 16 bytes, write pos =8 read pos = 8
OREDER_SIZE = 24       #24 bytes

FILESIZE = HEADER_SIZE + (BUFFER_SIZE * OREDER_SIZE)

ORDER_FORMAT = struct.Struct("QdQ")

HEADER_FORMAT = struct.Struct("QQ")

class MMapRingBuffer:
    
    def __init__(self, filename = "orders.mmap"):
        self.filename = filename
        
        self.fd = os.open(filename, os.O_RDWR | os.O_CREAT)
        
        os.ftruncate(self.fd, FILESIZE)
        
        self.mm = mmap.mmap(self.fd, FILESIZE, access=mmap.ACCESS_WRITE)
        
        write_pos, read_pos = HEADER_FORMAT.unpack_from(self.mm,0)
        
        if write_pos >= BUFFER_SIZE or read_pos >= BUFFER_SIZE:
            HEADER_FORMAT.pack_into(self.mm, 0, 0, 0)
            
    
    def getwritepos(self):
        
    
    def getreadpos(self):
        
    
    def write(self):
        
    
    def read(self):
        
ring = MMapRingBuffer("orders.mmap")
       
        