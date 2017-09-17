with Interfaces; use Interfaces;
with Ada.Interrupts; use Ada.Interrupts;
with Ada.Interrupts.Names; use Ada.Interrupts.Names;
with STM32.USARTs; use STM32.USARTs;
with Ringbuffers;

package Serial_IO is

   package FIFO_Package is new Ringbuffers (256, Unsigned_8);
   subtype FIFO is FIFO_Package.Ringbuffer;

   protected type Serial_Port_Controller
   is
      procedure Init (Baud_Rate : Baud_Rates);

      function Available return Boolean;

      procedure Read (Result : out Unsigned_8);
      --  function Read return Unsigned_8;

      procedure Write (Data : Unsigned_8);

   private
      procedure Interrupt_Handler;
      pragma Attach_Handler (Interrupt_Handler, USART1_Interrupt);

      Input : FIFO;
      Output : FIFO;
      Initialized : Boolean := False;
   end Serial_Port_Controller;

   Serial : Serial_Port_Controller;

end Serial_IO;
