with Interfaces; use Interfaces;
with Waves;      use Waves;
with Effects;    use Effects;
with MIDI;       use MIDI;

package MIDI_Synthesizer is

   type Freq_Table is array (0 .. 127) of Float;

   type ADSR_Config_Entry is record
      Controller_Index : Unsigned_8;
      Value            : Integer;
      Min_Value        : Integer;
      Max_Value        : Integer;
      Factor           : Float;
   end record;

   type ADSR_Config_Array is array (0 .. 3) of ADSR_Config_Entry;

   type Synthesizer is new I_Event_Listener with record
      MIDI_Parser : access Parser'Class;
      MIDI_Notes  : Freq_Table;
      Freq0       : access Fixed_Gen;
      Env0        : access ADSR;
      Mixer0      : access Mixer;
      ADSR_Config : ADSR_Config_Array;
   end record;

   function Create_Synthesizer return access Synthesizer;

   procedure Parse_MIDI_Byte
     (Self     : in out Synthesizer;
      Received :        Unsigned_8);

   overriding procedure Note_On
     (Self     : in out Synthesizer;
      Channel  :        Unsigned_8;
      Note     :        Unsigned_8;
      Velocity :        Unsigned_8);
   overriding procedure Note_Off
     (Self     : in out Synthesizer;
      Channel  :        Unsigned_8;
      Note     :        Unsigned_8;
      Velocity :        Unsigned_8);
   overriding procedure Control_Change
     (Self              : in out Synthesizer;
      Channel           :        Unsigned_8;
      Controller_Number :        Unsigned_8;
      Controller_Value  :        Unsigned_8);

private
      procedure Update_ADSR (Self : in out Synthesizer);

end MIDI_Synthesizer;
