This project demonstrate single level cache controller.

The controller job is to split the address given by the cpu and compare the tagbits of the cache memory. 

On "hit" case controller handovers the data to cpu immediatly on "miss" case controller asserts 'wait' signal to stall the cpu for 10 cycles.

A new block will replace in cache line by LRU replacement.

I have tested in 6 cases using testbench to validate the functionality of the controller.


<img width="1307" height="810" alt="wave1" src="https://github.com/user-attachments/assets/060f40a5-3914-4caa-af68-b3f7a87d67df" />

