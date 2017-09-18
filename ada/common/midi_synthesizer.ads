with Interfaces; use Interfaces;
with MIDI;       use MIDI;

package MIDI_Synthesizer is

   Samplerate : constant Float := 44100.0;

   type Freq_Table is array (0 .. 127) of Float;

   type Generator is record
      PhaseIncrement  : Float := 0.0;
      PhaseAccumulator : Float := 0.0;
   end record;

   type ADSR_State is (Idle, Attack, Decay, Sustain, Release);

   type ADSR is record
      Attack : Float := 50.0 / Samplerate;
      Decay  : Float := 50.0 / Samplerate;
      Sustain : Float := 0.9;
      Release : Float := 1.2 / Samplerate;
      Level : Float := 0.0;
      State : ADSR_State := Idle;
   end record;

   type Synthesizer is new I_Event_Listener with record
      MIDI_Parser : access Parser'Class;
      MIDI_Notes  : Freq_Table;
      Generator0  : Generator;
      ADSR0       : ADSR;
   end record;

   function Create_Synthesizer return access Synthesizer;

   function Next_Sample (Self : in out Synthesizer) return Float;

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

end MIDI_Synthesizer;
