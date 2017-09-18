package body MIDI_Synthesizer is
   function Create_Synthesizer return access Synthesizer is
      Ret    : constant access Synthesizer := new Synthesizer;
      Base   : Float                       := 8.1757989156;  -- MIDI note C1 0
   begin
      Ret.MIDI_Parser := Create_Parser (Ret);
      for I in Ret.MIDI_Notes'Range loop
         Ret.MIDI_Notes (I) := Base;
         Base               := Base * 1.059463094359;  -- 2^(1/12)
      end loop;
      return Ret;
   end Create_Synthesizer;

   function Next_Sample (Self : in out Synthesizer) return Float is
      Sample : Float;
   begin
      --  update generator
      Self.Generator0.PhaseAccumulator :=
        Self.Generator0.PhaseAccumulator + Self.Generator0.PhaseIncrement;
      if Self.Generator0.PhaseAccumulator > 1.0 then
         Self.Generator0.PhaseAccumulator :=
           Self.Generator0.PhaseAccumulator - 1.0;
      end if;

      --  update envelope
      case Self.ADSR0.State is
      when Idle => null;
      when Attack =>
         Self.ADSR0.Level := Self.ADSR0.Level + Self.ADSR0.Attack;
         if Self.ADSR0.Level >= 1.0 then
            Self.ADSR0.State := Decay;
            Self.ADSR0.Level := 1.0;
         end if;
      when Decay =>
         Self.ADSR0.Level := Self.ADSR0.Level - Self.ADSR0.Decay;
         if Self.ADSR0.Level <= Self.ADSR0.Sustain then
            Self.ADSR0.State := Sustain;
            Self.ADSR0.Level := Self.ADSR0.Sustain;
         end if;
      when Sustain => null;
      when Release =>
         Self.ADSR0.Level := Self.ADSR0.Level - Self.ADSR0.Release;
         if Self.ADSR0.Level <= 0.0 then
            Self.ADSR0.State := Idle;
            Self.ADSR0.Level := 0.0;
         end if;
      end case;

      --  return next sample, clipped to -1/+1
      Sample := (Self.Generator0.PhaseAccumulator - 0.5) * Self.ADSR0.Level;
      if Sample > 1.0 then
         Sample := 1.0;
      end if;
      if Sample < -1.0 then
         Sample := -1.0;
      end if;
      return Sample;
   end Next_Sample;

   procedure Parse_MIDI_Byte
     (Self     : in out Synthesizer;
      Received :        Unsigned_8)
   is
   begin
      Self.MIDI_Parser.Parse (Received);
   end Parse_MIDI_Byte;

   overriding procedure Note_On
     (Self     : in out Synthesizer;
      Channel  :        Unsigned_8;
      Note     :        Unsigned_8;
      Velocity :        Unsigned_8)
   is
      pragma Unreferenced (Channel);
      pragma Unreferenced (Velocity);
   begin
      Self.ADSR0.State := Attack;
      Self.ADSR0.Level := 0.0;
      Self.Generator0.PhaseIncrement :=
        Self.MIDI_Notes (Integer (Note)) / Samplerate;
   end Note_On;

   overriding procedure Note_Off
     (Self     : in out Synthesizer;
      Channel  :        Unsigned_8;
      Note     :        Unsigned_8;
      Velocity :        Unsigned_8)
   is
      pragma Unreferenced (Channel);
      pragma Unreferenced (Note);
      pragma Unreferenced (Velocity);
   begin
      Self.ADSR0.State := Release;
   end Note_Off;

   --  Testing with an AKAI MPK mini:
   --  The 8 rotary encoders are working in absolute mode.
   --  The following valus are sent:
   --  B1 0x yz
   --  where x is the knob number (1..8) and yz is the value (0..7f)
   --  (all values hex).
   overriding procedure Control_Change
     (Self              : in out Synthesizer;
      Channel           :        Unsigned_8;
      Controller_Number :        Unsigned_8;
      Controller_Value  :        Unsigned_8)
   is
      pragma Unreferenced (Channel);
   begin
      case Controller_Number is
      when 1 =>
         Self.ADSR0.Attack :=
           Float (128 - Controller_Value) * 0.5 / Samplerate;
      when 2 =>
         Self.ADSR0.Decay :=
           Float (128 - Controller_Value) * 0.5 / Samplerate;
      when 3 =>
         Self.ADSR0.Sustain :=
           Float (Controller_Value) * 0.007;
      when 4 =>
         Self.ADSR0.Release :=
           Float (128 - Controller_Value) * 0.02 / Samplerate;
         when others => null;
      end case;
   end Control_Change;

end MIDI_Synthesizer;
