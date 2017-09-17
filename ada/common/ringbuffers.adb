package body Ringbuffers is

   procedure Write (Self : in out Ringbuffer; e : Item) is
   begin
      Self.Items (Self.Write_Index) := e;
      Self.Write_Index := Self.Write_Index + 1;
      if (Self.Write_Index = Size) then
         Self.Write_Index := 1;
      end if;
   end Write;

   function Read (Self : in out Ringbuffer) return Item is
      Result : Item;
   begin
      Result := Self.Items (Self.Read_Index);
      Self.Read_Index := Self.Read_Index + 1;
      if (Self.Read_Index = Size) then
         Self.Read_Index := 1;
      end if;
      return Result;
   end Read;

   function Is_Empty (Self : Ringbuffer) return Boolean is
   begin
      return Self.Write_Index = Self.Read_Index;
   end Is_Empty;

end Ringbuffers;
