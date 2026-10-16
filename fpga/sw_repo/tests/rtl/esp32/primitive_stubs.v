// Functional pin ownership only: no package timing, analog or metastability model.
module OBUF(input I,output O); assign O=I; endmodule
module IOBUF(input I,input T,output O,inout IO);
 assign IO=T?1'bz:I; assign O=IO;
endmodule
