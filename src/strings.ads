--
--  This is a collection of simple string functions for Ada programs that can't
--  include the Ada.Strings functions.
--
--  Included are functions for both fixed length strings and for bounded strings.
--
package strings is
   --
   --  Definitions for bounded strings - to be moved to a separate package
   --
   type bounded(max : Integer) is tagged record
      len : Integer;
      str : String(1 .. max);
   end record;
   type bounded_ptr is access all bounded;
   --
   --  Some string functions
   --
   --
   --  Convert a string and length to a bounded string
   --
   procedure to_bounded(b : in out bounded; s : String; l : Integer);
   --
   --  Convert a bounded string to a string
   --
   function to_string(self : not null access bounded'class) return String;
   --
   --  Return length of a bounded string
   --
   function len(self : not null access bounded'class) return Integer;
   --
   --  Convert string to uppercase
   --
   procedure uppercase(s : in out String);
   procedure uppercase(self : not null access bounded'class);
   --
   --  See if a string starts with another string.  's' is the sample string,
   --  'l' is the number of characters in the sample, 'test' is typically a
   --  constant string to see if 's' starts with it.
   --
   function starts_with(s : String; l : Integer; test : String) return Boolean;
   function starts_with(self : not null access bounded'class; test : String) return Boolean;
   --
   --  Extracts the first token and remainder of a string splitting on a specified
   --  character.
   --
   procedure token(self : not null access bounded'class; split : Character;
                   token : out bounded; remain : out bounded);
end strings;
