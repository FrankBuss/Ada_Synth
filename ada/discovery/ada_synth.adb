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

--  based on the simple_audio example from the Ada_Drivers_Library STM32F4-DISCOVERY board.

--  with Ada.Assertions;  use Ada.Assertions;
with HAL;                  use HAL;
with STM32.Device;         use STM32.Device;
with STM32.Board;          use STM32.Board;
with HAL.Audio;            use HAL.Audio;
with Audio_Stream;         use Audio_Stream;
with System;               use System;
with Interfaces;           use Interfaces;
with Sound_Gen_Interfaces; use Sound_Gen_Interfaces;
with Utils;
with MIDI_Synthesizer; use MIDI_Synthesizer;

procedure Ada_Synth is

   subtype Buffer is Audio_Buffer (1 .. 512);
   Audio_Data_0 : Buffer;
   Audio_Data_1 : Buffer;
   Main_Synthesizer : constant access Synthesizer'Class := Create_Synthesizer;

   procedure Copy_Audio (Data : out Buffer);

   procedure Copy_Audio (Data : out Buffer)
   is
      function Sample_To_Int16 is new Utils.Sample_To_Int (Short_Integer);
      Int_Sample : Integer_16 := 0;
   begin

      Next_Steps;
      Main_Synthesizer.Mixer0.Next_Samples;

      for I in Integer range 0 .. (Data'Length - 1) loop
         Int_Sample := Integer_16 (Sample_To_Int16 (
                                   Main_Synthesizer.Mixer0.Buffer (
                                     Main_Synthesizer.Mixer0.Buffer'First +
                                       B_Range_T (I))));
         --  Data (Data'First + I) := Int_Sample;
         Data (Data'First + I) := Integer_16 (I * 432452) + Int_Sample;
      end loop;

   end Copy_Audio;

begin
   --  Assert (Generator_Buffer_Length = Audio_Data_0'Length, "invalid buffer length");
   Initialize_LEDs;

   Initialize_Audio;

   STM32.Board.Audio_DAC.Set_Volume (60);

   STM32.Board.Audio_DAC.Play;

   Audio_TX_DMA_Int.Start (Destination => STM32.Board.Audio_I2S.Data_Register_Address,
                           Source_0    => Audio_Data_0'Address,
                           Source_1    => Audio_Data_1'Address,
                           Data_Count  => Audio_Data_0'Length);

   Main_Synthesizer.Note_On (0, 60, 0);

   loop
      Audio_TX_DMA_Int.Wait_For_Transfer_Complete;

      if Audio_TX_DMA_Int.Not_In_Transfer = Audio_Data_0'Address then
         Copy_Audio (Audio_Data_0);
      else
         Copy_Audio (Audio_Data_1);
      end if;
   end loop;
end Ada_Synth;

