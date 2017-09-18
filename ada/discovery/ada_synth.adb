------------------------------------------------------------------------------
--                                                                          --
--                        Copyright (C) 2017, AdaCore                       --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

--  based on the simple_audio example from the Ada_Drivers_Library
--  STM32F4-DISCOVERY board.

--  with Ada.Assertions;  use Ada.Assertions;
with HAL;                  use HAL;
with STM32.Device;         use STM32.Device;
with STM32.Board;          use STM32.Board;
with STM32.GPIO;    use STM32.GPIO;
with HAL.Audio;            use HAL.Audio;
with Audio_Stream;         use Audio_Stream;
with System;               use System;
with Interfaces;           use Interfaces;
with Sound_Gen_Interfaces; use Sound_Gen_Interfaces;
with MIDI_Synthesizer; use MIDI_Synthesizer;
with Serial_IO; use Serial_IO;

procedure Ada_Synth is

   --  start melody
   type Event is record
      Time : Integer;
      Note : Unsigned_8;
      Note_On : Boolean;
   end record;
   type Events is array (Integer range <>) of Event;
   Melody : constant Events := (
                                (100, 60, True),
                                (120, 60, False),
                                (140, 64, True),
                                (160, 64, False),
                                (180, 67, True),
                                (200, 67, False)
                               );
   Start_Time : Integer := 0;
   Melody_Index : Integer := Melody'First;

   --  audio buffers
   subtype Buffer is Audio_Buffer (1 .. 512);
   Audio_Data_0 : Buffer := (others => 0);
   Audio_Data_1 : Buffer := (others => 0);

   --  MIDI parser and sound generator
   Main_Synthesizer : constant access Synthesizer'Class := Create_Synthesizer;

   --  test output for measuring the runtime of the sound generator
   Test_Out : GPIO_Point := PD0;
   Configuration : GPIO_Port_Configuration;

   --  temporary variable
   Data : Unsigned_8;

   procedure Copy_Audio (Data : out Buffer);

   procedure Copy_Audio (Data : out Buffer)
   is
      Int_Sample : Integer_16 := 0;
   begin

      Test_Out.Set;

      for I in Data'Range loop
         Int_Sample := Integer_16 (Main_Synthesizer.Next_Sample * 32767.0);
         Data (I) := Int_Sample;
      end loop;

      Test_Out.Clear;

   end Copy_Audio;

begin
   Serial.Init (31_250);
   Enable_Clock (Test_Out);
   Configuration.Mode        := Mode_Out;
   Configuration.Output_Type := Push_Pull;
   Configuration.Speed       := Speed_100MHz;
   Configuration.Resistors   := Floating;
   Configure_IO (Test_Out, Configuration);

   --  Assert (
   --  Generator_Buffer_Length = Audio_Data_0'Length, "invalid buffer length");
   Initialize_LEDs;

   Initialize_Audio;

   STM32.Board.Audio_DAC.Set_Volume (60);

   STM32.Board.Audio_DAC.Play;

   Audio_TX_DMA_Int.Start (Destination =>
                             STM32.Board.Audio_I2S.Data_Register_Address,
                           Source_0    => Audio_Data_0'Address,
                           Source_1    => Audio_Data_1'Address,
                           Data_Count  => Audio_Data_0'Length);

   loop
      --  wait until last audio buffer is transferred
      Audio_TX_DMA_Int.Wait_For_Transfer_Complete;

      --  play a melody at start
      if Melody_Index <= Melody'Last then
         if Melody (Melody_Index).Time = Start_Time then
            if Melody (Melody_Index).Note_On then
               Main_Synthesizer.Note_On (0, Melody (Melody_Index).Note, 100);
            else
               Main_Synthesizer.Note_Off (0, Melody (Melody_Index).Note, 0);
            end if;
            Melody_Index := Melody_Index + 1;
         end if;
         Start_Time := Start_Time + 1;
      end if;

      --  read MIDI data and parse it
      while Serial.Available loop
         Serial.Read (Data);
         Main_Synthesizer.Parse_MIDI_Byte (Data);
      end loop;

      --  fill next audio buffer
      if Audio_TX_DMA_Int.Not_In_Transfer = Audio_Data_0'Address then
         Copy_Audio (Audio_Data_0);
      else
         Copy_Audio (Audio_Data_1);
      end if;
   end loop;
end Ada_Synth;
