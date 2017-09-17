with Interfaces;  use Interfaces;
with Ada.Text_IO; use Ada.Text_IO;
with Ringbuffers;

procedure Test_Ringbuffer is
   package FIFO_Package is new Ringbuffers (256, Unsigned_8);
   subtype FIFO is FIFO_Package.Ringbuffer;
   Test : FIFO;

begin
   Test.Write (1);
   Test.Write (7);
   while not Test.Is_Empty loop
      Put_Line (Unsigned_8'Image (Test.Read));
   end loop;
end Test_Ringbuffer;
