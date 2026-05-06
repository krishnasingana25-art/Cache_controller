This project demonstrate single level cache controller.

The controller job is to split the address given by the cpu and compare the tagbits of the cache memory. 

On "hit" case controller handovers the data to cpu immediatly on "miss" case controller asserts 'wait' signal to stall the cpu for 10 cycles.

A new block will replace in cache line by LRU replacement.

I have tested in 6 cases using testbench to validate the functionality of the controller.

compulsary miss1 // accessing block number 64 and filling way0
<img width="700" height="350" alt="wave1" src="https://github.com/user-attachments/assets/060f40a5-3914-4caa-af68-b3f7a87d67df" />

compulsary miss2 // accessing block number 32 and filling way1

<img width="700" height="350" alt="wave2" src="https://github.com/user-attachments/assets/7ca260e3-0afa-4e43-ba0b-ed84a0392020" />

hit // accesing block number 32 again, now LRU of this set store LRU = 1 means way1 is recently accesed so other line in the set should replace in case of replacement
<img width="700" height="350" alt="wave3" src="https://github.com/user-attachments/assets/dcd96060-4476-4206-aba5-6772387e5dfd" />

Accessing 96 block which is mapped to same set, and it will replace the block 64
<img width="700" height="350" alt="wave4" src="https://github.com/user-attachments/assets/f3e4fb01-7bc5-4fe3-abbf-1704bb1baf24" />

writing to 32 block which is already there in cache // write hit 
<img width="700" height="350" alt="wave5" src="https://github.com/user-attachments/assets/5c68d347-e2a4-409b-a019-c7ef4bbc4db6" />

writing to block which is not in cache// write through policy.
<img width="700" height="350" alt="wave6" src="https://github.com/user-attachments/assets/bf0ed09e-e69c-452a-ab4e-6102ae6439cc" />






