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

#calculating total size of mmap file
FILESIZE = HEADER_SIZE + (BUFFER_SIZE * OREDER_SIZE)

ORDER_FORMAT = struct.Struct("QdQ")    #arrangement of order i.e. order id, price, quantity
#Q -> 8 byte unsigned int
#d -> 8 byte float

HEADER_FORMAT = struct.Struct("QQ")   #binary layout of ring buffer
#contains 2 values Q -> writepos (8 byt), Q -> readpos(8 bytes)

class MMapRingBuffer:
    
    def __init__(self, filename = "orders.mmap"):   #init constructor with self parametr and default filename
        self.filename = filename
        
        self.fd = os.open(filename, os.O_RDWR | os.O_CREAT)  #create a file
        #self.fd -> file descriptor OS provided identifier for the opened file
        #os.O_RDWR -> open file read and write
        #os.O_CREAT -> create the file
        
        os.ftruncate(self.fd, FILESIZE)    #set file size
        
        #mmap object creation
        self.mm = mmap.mmap(self.fd, FILESIZE, access=mmap.ACCESS_WRITE)
        #self.mm - stores the object returned by mmap.mmap()
        #mmap.mmap -> map file in memory

        write_pos, read_pos = HEADER_FORMAT.unpack_from(self.mm,0)
        #unpack_from -> reads binary data
        #self.mm -> mmap memory region
        #0 -> starting from 0 byte
        
        if write_pos >= BUFFER_SIZE or read_pos >= BUFFER_SIZE:
            HEADER_FORMAT.pack_into(self.mm, 0, 0, 0)
            #pack_into -> take data,convert into binary bytes, write into mmap memory
            #0 -> starting byte position
            #0,0 -> write pos, read pos 
            
    
    def getwritepos(self):
        
        return struct.unpack_from("Q", self.mm, 0)[0]
        
        #unpack the data -- get the first value --- return that value
        #struct.unpack_from -> Reads 8 bytes from self.mm starting from 0
        #self.mm -> memory mapping region
        #0 -> start pos
        #Q -> 8 byts unsigned int
        #unpack_from()-> returns a tuple
        #[0] -> grts the first value of the tuple
    
    
    def getreadpos(self):
        
        return struct.unpack_from("Q", self.mm, 8)[0]
        
        #read the value--stored in header -- return that value
        #struct.unpack_from -> Reads 8 bytes from self.mm starting from 8 offset
        #self.mm -> memory mapping region
        #8 -> start reading from 8 byte offset
        #Q -> 8 byts unsigned int
        #unpack_from()-> returns a tuple
        #[0] -> grts the first value of the tuple
    
    def write(self):
        """write data"""
        
    def read(self):
        """read data"""
        
ring = MMapRingBuffer("orders.mmap")
       
        