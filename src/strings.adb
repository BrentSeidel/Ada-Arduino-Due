package body strings is
   --
   --  Some string functions
   --
   --
   --  Convert a string and length to a bounded string
   --
   procedure to_bounded(b : in out bounded; s : String; l : Integer) is
   begin
      b.len := l;
      b.str(1 .. l) := s(s'First .. s'First + l - 1);
   end;
   --
   --  Convert a bounded string to a string
   --
   function to_string(self : not null access bounded'class) return String is
   begin
      return self.all.str(1 .. self.all.len);
   end;
   --
   --  Return length of a bounded string
   --
   function len(self : not null access bounded'class) return Integer is
   begin
      return self.all.len;
   end;
   --
   --  Convert string to uppercase
   --
   procedure uppercase(s : in out String) is
      offset : constant Integer := Character'Pos('a') - Character'Pos('A');
   begin
      for i in s'Range loop
         if (s(i) >= 'a') and (s(i) <= 'z') then
            s(i) := Character'Val(Character'Pos(s(i)) - offset);
         end if;
      end loop;
   end;
   --
   procedure uppercase(self : not null access bounded'class) is
      offset : constant Integer := Character'Pos('a') - Character'Pos('A');
   begin
      for i in self.all.str'Range loop
         if (self.all.str(i) >= 'a') and (self.all.str(i) <= 'z') then
            self.all.str(i) := Character'Val(Character'Pos(self.all.str(i)) - offset);
         end if;
      end loop;
   end;
   --
   --  See if a string starts with another string.  's' is the sample string,
   --  'l' is the number of characters in the sample, 'test' is typically a
   --  constant string to see if 's' starts with it.
   --
   function starts_with(s : String; l : Integer; test : String) return Boolean is
      test_len : constant Integer := test'Last - test'First + 1;
   begin
      --
      --  Make sure that s is not shorter than test.
      --
      if l < test_len then
         return False;
      end if;
      if s(s'First..test_len) = test then
         return True;
      else
         return False;
      end if;
   end;
   --
   function starts_with(self : not null access bounded'class; test : String) return Boolean is
      test_len : constant Integer := test'Last - test'First + 1;
   begin
      --
      --  Make sure that s is not shorter than test.
      --
      if self.all.len < test_len then
         return False;
      end if;
      if self.all.str(1..test_len) = test then
         return True;
      else
         return False;
      end if;
   end;
   --
   --  Extracts the first token and remainder of a string splitting on a specified
   --  character.  If the character is not found, token is a copy of the input
   --  string.
   --
   procedure token(self : not null access bounded'class; split : Character;
                   token : out bounded; remain : out bounded) is
      flag   : Boolean := false;
      offset : Integer;
   begin
      token.len  := 0;
      remain.len := 0;
      for i in 1 .. self.len loop
         if not flag and (self.str(i) = split) then
            flag := True;
            offset := i;
            token.len := i - 1;
         else
            if flag then
               remain.str(i - offset) := self.str(i);
            else
               token.str(i) := self.str(i);
            end if;
         end if;
      end loop;
      if not flag then
         token.len := self.len;
      end if;
      remain.len := self.len - offset;
   end;
   --
end strings;
