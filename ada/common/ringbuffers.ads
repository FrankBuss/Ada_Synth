generic
   Size : Positive;
   type Item is private;
package Ringbuffers is

   type Ringbuffer is tagged private;

   procedure Write (Self : in out Ringbuffer; e : Item);
   function Read (Self : in out Ringbuffer) return Item;
   function Is_Empty (Self : Ringbuffer) return Boolean;

private

   type Item_Array is array (1 .. Size) of Item;
   pragma Volatile (Item_Array);
   type Ringbuffer is tagged record
      Read_Index  : Positive := 1;
      Write_Index : Positive := 1;
      Items       : Item_Array;
   end record;
   pragma Volatile (Ringbuffer);

end Ringbuffers;
