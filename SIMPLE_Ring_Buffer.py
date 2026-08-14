
#SIMPLE RING BUFFER IN PYTHON, WITHOUT MMAP


#class
"""task -> store and and read data in circular queue"""
"""this class will create circular buffer"""

class ringbuffer:
   
    #constructor
    def __init__(self, size):       #ring buffer size
        self.size = size
        
        """creating buffer"""
        
        self.buffer = [None] * size #list
        
        """[none,none,none,none] 4 empty slots"""
        
        #write position and read position
        self.write_pos = 0 #write positon first data slot 0, this tells us where the next pice of data written
        self.read_pos = 0  #read position, next data should be read from
    
        
    """add data in buffer"""
    
    def write(self, data):
        self.buffer[self.write_pos] = data #data store "order 1"
       #self.buffer[0] = "Order 1" ---> rb.write("order 1")
       #buffer->["Order 1", none,none,none]
       
       #move write position
        self.write_pos = (self.write_pos + 1) % self.size
                         #(0+1)%4 = 1
                         # % makes ring buffer circular
    
    """read data from buffer"""
    
    def read(self):
        data = self.buffer[self.read_pos]
               #self.buffer[0]
               #data = "Order 1"
               
        self.read_pos = (self.read_pos + 1) % self.size
        
        return data
    

"""OBJECT WITH 4 SIZE"""
#creates 4 slots in ring buffer

rb = ringbuffer(4)

rb.write("Order 1")
rb.write("Order 2")
rb.write("Order 3")
rb.write("Order 4")

print(rb.read())
print(rb.read())
print(rb.read())
print(rb.read())