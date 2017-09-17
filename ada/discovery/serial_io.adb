
with HAL;          use HAL;
with STM32;         use STM32;
with STM32.GPIO;    use STM32.GPIO;
with STM32.Device;          use STM32.Device;

package body Serial_IO is

   protected body Serial_Port_Controller is

      procedure Init (Baud_Rate : Baud_Rates) is
         Tx_Pin     : constant GPIO_Point    := PB6;
         Rx_Pin    : constant  GPIO_Point    := PB7;
         Device_Pins   : constant GPIO_Points := Rx_Pin & Tx_Pin;
         Configuration : GPIO_Port_Configuration;
      begin
         --  configure UART 1
         Enable_Clock (USART_1);
         Disable (USART_1);
         Set_Baud_Rate    (USART_1, Baud_Rate);
         Set_Mode         (USART_1, Tx_Rx_Mode);
         Set_Stop_Bits    (USART_1, Stopbits_1);
         Set_Word_Length  (USART_1, Word_Length_8);
         Set_Parity       (USART_1, No_Parity);
         Set_Flow_Control (USART_1, No_Flow_Control);
         Enable (USART_1);

         --  configure pins
         Enable_Clock (Device_Pins);
         Configuration.Mode        := Mode_AF;
         Configuration.Speed       := Speed_50MHz;
         Configuration.Output_Type := Push_Pull;
         Configuration.Resistors   := Pull_Up;
         Configure_IO (Device_Pins, Configuration);
         Configure_Alternate_Function (Device_Pins, GPIO_AF_USART1_7);

         --  enable interrupt
         Enable_Interrupts (USART_1, Received_Data_Not_Empty);
         Enable_Interrupts (USART_1, Transmission_Complete);

         Initialized := True;
      end Init;

      function Available return Boolean is
      begin
         return not Input.Is_Empty;
      end Available;

      procedure Read (Result : out Unsigned_8) is
      begin
         Result := Input.Read;
      end Read;

      --  doesn't work, because in protected functions I can't modify variables
      --  function Read return Unsigned_8 is
      --  begin
      --     return Input.Read;
      --  end;

      procedure Write (Data : Unsigned_8) is
      begin
         if Output.Is_Empty then
            --  if the output FIFO is empty, start transfer
            Transmit (USART_1, UInt9 (Data));
         else
            --  else add to the FIFO: TODO: possible race condition?
            output.Write (Data);
         end if;
      end Write;

      procedure Interrupt_Handler is
         Received_Char : Unsigned_8;
      begin
         --  check for data arrival
         if Status (USART_1, Read_Data_Register_Not_Empty) and
           Interrupt_Enabled (USART_1, Received_Data_Not_Empty)
         then
            Received_Char := Unsigned_8 (Current_Input (USART_1) and 255);
            Input.Write (Received_Char);
         end if;

         --  check for transmission ready
         if Status (USART_1, Transmission_Complete_Indicated) and
           Interrupt_Enabled (USART_1, Transmission_Complete)
         then
            if not Output.Is_Empty then
               Transmit (USART_1, UInt9 (Output.Read));
            end if;
            Clear_Status (USART_1, Transmission_Complete_Indicated);
         end if;
      end Interrupt_Handler;

   end Serial_Port_Controller;

end Serial_IO;
