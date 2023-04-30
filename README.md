# PE
In this project, single-PE communication has been implemented using the row stationary concept described in the Eyeriss paper.  
There are two input feature maps, each with a size of 3x4x3, and two filters, each with a size of 3x3x3.
## Architecture
![architecture drawio (2)](https://user-images.githubusercontent.com/69788052/235361569-a632de7b-059a-4b93-85fa-4828e51c13c0.png)
## The function of each .v file
|  **Code**         | **Function**  |
|  ---------------  | ---  |
|  PE.v             | The top module designed for wiring purposes.  |
|  PE_controller.v  | It serves as the controller for the entire PE, determining the Spad address to be read or stored, as well as various control lines. |
|  Psum_Spad.v      | Used to occupy the buffer for storing partial sums. |
|  IfmapSpad.v      | Used to occupy the buffer for storing input feature maps. |
|  WeightSpad       | Used to occupy the buffer for storing filter. |
|  Mux_adder.v      | The addition element in the PE. |
|  Multiplier.v     | The multiplication element in the PE. |
|  Mux.v            | There are two of them. The first one controls the addition part, and the second one controls the output of partial sum data. |
