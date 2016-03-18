with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Eval_Callback;
with Reader;
with Smart_Pointers;
with Types;
with Types.Hash_Map;
with Types.Vector;

package body Core is

   use Types;

   -- primitive functions on Smart_Pointer,
   function "+" is new Arith_Op ("+", "+");
   function "-" is new Arith_Op ("-", "-");
   function "*" is new Arith_Op ("*", "*");
   function "/" is new Arith_Op ("/", "/");

   function "<" is new Rel_Op ("<", "<");
   function "<=" is new Rel_Op ("<=", "<=");
   function ">" is new Rel_Op (">", ">");
   function ">=" is new Rel_Op (">=", ">=");


   function Eval_As_Boolean (MH : Types.Mal_Handle) return Boolean is
      use Types;
      Res : Boolean;
   begin
      case Deref (MH).Sym_Type is
         when Bool => 
            Res := Deref_Bool (MH).Get_Bool;
         when Sym =>
            return not (Deref_Sym (MH).Get_Sym = "nil");
--         when List =>
--            declare
--               L : List_Mal_Type;
--            begin
--               L := Deref_List (MH).all;
--               Res := not Is_Null (L);
--            end;
         when others => -- Everything else
            Res := True;
      end case;
      return Res;
   end Eval_As_Boolean;


   function Do_Eval (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return Eval_Callback.Eval.all (First_Param, Env);
   end Do_Eval;


   function Throw (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      Types.Mal_Exception_Value := First_Param;
      raise Mal_Exception;
      return First_Param;  -- Keep the compiler happy.
   end Throw;


   function Is_True (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = Bool and then
         Deref_Bool (First_Param).Get_Bool);
   end Is_True;


   function Is_False (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = Bool and then
         not Deref_Bool (First_Param).Get_Bool);
   end Is_False;


   function Is_Nil (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = Sym and then
         Deref_Sym (First_Param).Get_Sym = "nil");
   end Is_Nil;


   function Meta (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return Deref (First_Param).Get_Meta;
   end Meta;


   function With_Meta (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Meta_Param, Res : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      Rest_List := Deref_List (Cdr (Rest_List)).all;
      Meta_Param := Car (Rest_List);
      Res := Copy (First_Param);
      Deref (Res).Set_Meta (Meta_Param);
      return Res;
   end With_Meta;


   function New_Atom (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Atom_Mal_Type (First_Param);
   end New_Atom;

   function Is_Atom (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type (Deref (First_Param).Sym_Type = Atom);
   end Is_Atom;


   function Deref (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return Deref_Atom (First_Param).Get_Atom;
   end Deref;


   function Reset (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Atom_Param, New_Val : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Atom_Param := Car (Rest_List);
      Rest_List := Deref_List (Cdr (Rest_List)).all;
      New_Val := Car (Rest_List);
      Deref_Atom (Atom_Param).Set_Atom (New_Val);
      return New_Val;
   end Reset;


   function Swap (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Atom_Param, Atom_Val, New_Val : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
      Rest_List_Class : Types.List_Class_Ptr;
      Func_Param, Param_List : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Atom_Param := Car (Rest_List);
      Rest_List := Deref_List (Cdr (Rest_List)).all;
      Func_Param := Car (Rest_List);
      Param_List := Cdr (Rest_List);

      Rest_List_Class := Deref_List_Class (Param_List);
      Param_List := Rest_List_Class.Duplicate;
      Atom_Val := Deref_Atom (Atom_Param).Get_Atom;
      Param_List := Prepend (Atom_Val, Deref_List (Param_List).all);
      case Deref (Func_Param).Sym_Type is
         when Lambda =>
            New_Val := Deref_Lambda (Func_Param).Apply (Param_List);
         when Func =>
            New_Val := Deref_Func (Func_Param).Call_Func (Param_List, Env);
         when others => raise Mal_Exception with "Swap with bad func";
      end case;
      Deref_Atom (Atom_Param).Set_Atom (New_Val);
      return New_Val;
   end Swap;


   function Is_List (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type = List_List);
   end Is_List;


   function Is_Vector (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type = Vector_List);
   end Is_Vector;


   function Is_Map (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type = Hashed_List);
   end Is_Map;


   function Is_Sequential (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type /= Hashed_List);
   end Is_Sequential;


   function Is_Empty (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      List : List_Class_Ptr;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      List := Deref_List_Class (First_Param);
      return New_Bool_Mal_Type (Is_Null (List.all));
   end Is_Empty;


   function Eval_As_List (MH : Types.Mal_Handle) return List_Mal_Type is
   begin
      case Deref (MH).Sym_Type is
         when List =>  return Deref_List (MH).all;
         when Sym =>
            if Deref_Sym (MH).Get_Sym = "nil" then
               return Null_List (List_List);
            end if;
         when others => null;
      end case;
      raise Evaluation_Error with "Expecting a List";
      return Null_List (List_List);
   end Eval_As_List;


   function Count (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      L : List_Mal_Type;
      Rest_List : Types.List_Mal_Type;
      N : Natural;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      if Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type = Vector_List then
         N := Deref_List_Class (First_Param).Length;
      else
         L := Eval_As_List (First_Param);
         N := L.Length;
      end if;
      return New_Int_Mal_Type (N);
   end Count;


   function Cons (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param, List_Handle : Mal_Handle;
      List : List_Mal_Type;
      List_Class : List_Class_Ptr;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      List_Handle := Cdr (Rest_List);
      List := Deref_List (List_Handle).all;
      List_Handle := Car (List);
      List_Class := Deref_List_Class (List_Handle);
      return Prepend (First_Param, List_Class.all);
   end Cons;


   function Concat (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      return Types.Concat (Rest_List, Env);
   end Concat;


   function First (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_List : Types.List_Class_Ptr;
      First_Param : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      if Deref (First_Param).Sym_Type = Sym then
         return New_Symbol_Mal_Type ("nil");
      end if;
      First_List := Deref_List_Class (First_Param);
      if Is_Null (First_List.all) then
         return New_Symbol_Mal_Type ("nil");
      else
         return Types.Car (First_List.all);
      end if;
   end First;


   function Rest (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param, Container : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      if Deref (First_Param).Sym_Type = Sym then
         -- Assuming it's nil
         return New_List_Mal_Type (List_List);
      end if;
      Container := Deref_List_Class (First_Param).Cdr;
      return Deref_List_Class (Container).Duplicate;
   end Rest;


   function Nth (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      -- Rest_List, First_List : Types.List_Mal_Type;
      Rest_List : Types.List_Mal_Type;
      First_List : Types.List_Class_Ptr;
      First_Param, List_Handle, Num_Handle : Mal_Handle;
      List : List_Mal_Type;
      Index : Types.Int_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      First_List := Deref_List_Class (First_Param);
      List_Handle := Cdr (Rest_List);
      List := Deref_List (List_Handle).all;
      Num_Handle := Car (List);
      Index := Deref_Int (Num_Handle).all;
      return Types.Nth (First_List.all, Natural (Index.Get_Int_Val));
   end Nth;


   function Apply (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Results_Handle, First_Param : Mal_Handle;
      Rest_List : List_Mal_Type;
      Results_List : List_Ptr;

   begin

      -- The rest of the line.
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      Rest_List := Deref_List (Cdr (Rest_List)).all;

      Results_Handle := New_List_Mal_Type (List_List);
      Results_List := Deref_List (Results_Handle);

      -- The last item is a list or a vector which gets flattened so that
      -- (apply f (A B) C (D E)) becomes (f (A B) C D E)
      while not Is_Null (Rest_List) loop
         declare
            Part_Handle : Mal_Handle;
         begin
            Part_Handle := Car (Rest_List);
            Rest_List := Deref_List (Cdr (Rest_List)).all;

            -- Is Part_Handle the last item in the list?
            if Is_Null (Rest_List) then
               declare
                  The_List : List_Class_Ptr;
                  List_Item : Mal_Handle;
                  Next_List : Mal_Handle;
               begin
                  The_List := Deref_List_Class (Part_Handle);
                  while not Is_Null (The_List.all) loop
                     List_Item := Car (The_List.all);
                     Append (Results_List.all, List_Item);
                     Next_List := Cdr (The_List.all);
                     The_List := Deref_List_Class (Next_List);
                  end loop;
               end;
            else
               Append (Results_List.all, Part_Handle);
            end if;
         end;
      end loop;
      if Deref (First_Param).Sym_Type = Func then
         return Call_Func (Deref_Func (First_Param).all, Results_Handle, Env);
      elsif Deref (First_Param).Sym_Type = Lambda then
         declare

            L : Lambda_Mal_Type;
            E : Envs.Env_Handle;
            Param_Names : List_Mal_Type;
            Res : Mal_Handle;

         begin

            L := Deref_Lambda (First_Param).all;
            E := Envs.New_Env (L.Get_Env);

            Param_Names := Deref_List (L.Get_Params).all;

            if Envs.Bind (E, Param_Names, Results_List.all) then

               return Eval_Callback.Eval.all (L.Get_Expr, E);

            else

               raise Mal_Exception with "Bind failed in Apply";

            end if;

         end;

      else  -- neither a Lambda or a Func
         raise Mal_Exception;
      end if;

--      return Eval_Callback.Eval.all (New_List_Mal_Type (Results_List), Env);
   end Apply;


   function Map (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Rest_List, Results_List : List_Mal_Type;
      Func_Handle, List_Handle, Results_Handle : Mal_Handle;

   begin

      -- The rest of the line.
      Rest_List := Deref_List (Rest_Handle).all;

      Func_Handle := Car (Rest_List);
      List_Handle := Nth (Rest_List, 1);

      Results_Handle := New_List_Mal_Type (List_List);
      Results_List := Deref_List (Results_Handle).all;

      while not Is_Null (Deref_List_Class (List_Handle).all) loop

         declare
            Parts_Handle : Mal_Handle;
         begin
            Parts_Handle :=
              Make_New_List
                ((1 => Func_Handle,
                  2 => Make_New_List
                         ((1 => Car (Deref_List_Class (List_Handle).all)))));
 
            List_Handle := Cdr (Deref_List_Class (List_Handle).all);

            Append
              (Results_List,
               Apply (Parts_Handle, Env));

         end;

      end loop;

      return New_List_Mal_Type (Results_List);

   end Map;


   function Symbol (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Sym_Handle, Res : Mal_Handle;
      Rest_List : List_Mal_Type;

   begin

      -- The rest of the line.
      Rest_List := Deref_List (Rest_Handle).all;

      Sym_Handle := Car (Rest_List);

      declare
        The_String : Mal_String :=
          Deref_String (Sym_Handle).Get_String;
      begin

         Res := New_Symbol_Mal_Type
                  (The_String (The_String'First + 1 .. The_String'Last - 1));

      end;
      return Res;
   end Symbol;


   function Is_Symbol (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Sym_Handle : Mal_Handle;
      Rest_List : List_Mal_Type;
      Res : Boolean;

   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Sym_Handle := Car (Rest_List);
      if Deref (Sym_Handle).Sym_Type = Sym then
         Res := Deref_Sym (Sym_Handle).Get_Sym (1) /= ':';
      else
         Res := False;
      end if;
      return New_Bool_Mal_Type (Res);
   end Is_Symbol;


   function Keyword (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Sym_Handle, Res : Mal_Handle;
      Rest_List : List_Mal_Type;

   begin

      -- The rest of the line.
      Rest_List := Deref_List (Rest_Handle).all;

      Sym_Handle := Car (Rest_List);

      declare
        The_String : Mal_String :=
          Deref_String (Sym_Handle).Get_String;
      begin

         Res := New_Symbol_Mal_Type
                  (':' & The_String (The_String'First + 1 .. The_String'Last - 1));

      end;
      return Res;
   end Keyword;


   function Is_Keyword (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is

      Sym_Handle : Mal_Handle;
      Rest_List : List_Mal_Type;
      Res : Boolean;

   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Sym_Handle := Car (Rest_List);
      if Deref (Sym_Handle).Sym_Type = Sym then
         Res := Deref_Sym (Sym_Handle).Get_Sym (1) = ':';
      else
         Res := False;
      end if;
      return New_Bool_Mal_Type (Res);
   end Is_Keyword;


   function New_List (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      return New_List_Mal_Type (The_List => Rest_List);
   end New_List;


   function New_Vector (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Res : Mal_Handle;
      use Types.Vector;
   begin
      Res := New_Vector_Mal_Type;
      Rest_List := Deref_List (Rest_Handle).all;
      while not Is_Null (Rest_List) loop
         Deref_Vector (Res).Append (Car (Rest_List));
         Rest_List := Deref_List (Cdr (Rest_List)).all;
      end loop;
      return Res;
   end New_Vector;


   function New_Map (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Res : Mal_Handle;
   begin
      Res := Hash_Map.New_Hash_Map_Mal_Type;
      Rest_List := Deref_List (Rest_Handle).all;
      while not Is_Null (Rest_List) loop
         Hash_Map.Deref_Hash (Res).Append (Car (Rest_List));
         Rest_List := Deref_List (Cdr (Rest_List)).all;
      end loop;
      return Res;
   end New_Map;


   function Assoc (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Mal_Handle;
      Map : Hash_Map.Hash_Map_Mal_Type;
   begin
      Rest_List := Rest_Handle;
      Map := Hash_Map.Deref_Hash (Car (Deref_List (Rest_List).all)).all;
      Rest_List := Cdr (Deref_List (Rest_List).all);
      return Hash_Map.Assoc (Map, Rest_List);
   end Assoc;


   function Dis_Assoc (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Mal_Handle;
      Map : Hash_Map.Hash_Map_Mal_Type;
   begin
      Rest_List := Rest_Handle;
      Map := Hash_Map.Deref_Hash (Car (Deref_List (Rest_List).all)).all;
      Rest_List := Cdr (Deref_List (Rest_List).all);
      return Hash_Map.Dis_Assoc (Map, Rest_List);
   end Dis_Assoc;


   function Get_Key (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Map : Hash_Map.Hash_Map_Mal_Type;
      Map_Param, Key : Mal_Handle;
      The_Sym : Sym_Types;
   begin

      Rest_List := Deref_List (Rest_Handle).all;
      Map_Param := Car (Rest_List);
      The_Sym := Deref (Map_Param).Sym_Type;
      if The_Sym = Sym then
         -- Either its nil or its some other atom
         -- which makes no sense!
         return New_Symbol_Mal_Type ("nil");
      end if;

      -- Assume a map from here on in.
      Map := Hash_Map.Deref_Hash (Car (Rest_List)).all;
      Rest_List := Deref_List (Cdr (Rest_List)).all;
      Key := Car (Rest_List);

      return Map.Get (Key);

   end Get_Key;


   function Contains_Key (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Map : Hash_Map.Hash_Map_Mal_Type;
      Key : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Map := Hash_Map.Deref_Hash (Car (Rest_List)).all;
      Rest_List := Deref_List (Cdr (Rest_List)).all;
      Key := Car (Rest_List);
      return New_Bool_Mal_Type (Hash_Map.Contains (Map, Key));
   end Contains_Key;


   function All_Keys (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Map : Hash_Map.Hash_Map_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Map := Hash_Map.Deref_Hash (Car (Rest_List)).all;
      return Hash_Map.All_Keys (Map);
   end All_Keys;


   function All_Values (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      Map : Hash_Map.Hash_Map_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      Map := Hash_Map.Deref_Hash (Car (Rest_List)).all;
      return Hash_Map.All_Values (Map);
   end All_Values;


   -- Take a list with two parameters and produce a single result
   -- using the Op access-to-function parameter.
   function Reduce2
     (Op : Binary_Func_Access; LH : Mal_Handle; Env : Envs.Env_Handle)
   return Mal_Handle is
      Left, Right : Mal_Handle;
      L, Rest_List : List_Mal_Type;
   begin
      L := Deref_List (LH).all;
      Left := Car (L);
      Rest_List := Deref_List (Cdr (L)).all;
      Right := Car (Rest_List);
      return Op (Left, Right);
   end Reduce2;


   function Plus (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("+"'Access, Rest_Handle, Env);
   end Plus;


   function Minus (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("-"'Access, Rest_Handle, Env);
   end Minus;


   function Mult (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("*"'Access, Rest_Handle, Env);
   end Mult;


   function Divide (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("/"'Access, Rest_Handle, Env);
   end Divide;


   function LT (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("<"'Access, Rest_Handle, Env);
   end LT;


   function LTE (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("<="'Access, Rest_Handle, Env);
   end LTE;


   function GT (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (">"'Access, Rest_Handle, Env);
   end GT;


   function GTE (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (">="'Access, Rest_Handle, Env);
   end GTE;


   function EQ (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (Types."="'Access, Rest_Handle, Env);
   end EQ;


   function Pr_Str (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : Unbounded_String;
   begin
      return New_String_Mal_Type ('"' & Deref_List (Rest_Handle).Pr_Str & '"');
   end Pr_Str;


   function Prn (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
   begin
      Ada.Text_IO.Put_Line (Deref_List (Rest_Handle).Pr_Str);
      return New_Symbol_Mal_Type ("nil");
   end Prn;


   function Println (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : String := Deref_List (Rest_Handle).Pr_Str (False);
   begin
      Ada.Text_IO.Put_Line (Res);
      return New_Symbol_Mal_Type ("nil");
   end Println;


   function Str (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : String := Deref_List (Rest_Handle).Cat_Str (False);
   begin
      return New_String_Mal_Type ('"' & Res & '"');
   end Str;


   function Read_String (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      declare
         Str_Param : String := Deref_String (First_Param).Get_String;
         Unquoted_Str : String(1 .. Str_Param'Length-2) :=
           Str_Param (Str_Param'First+1 .. Str_Param'Last-1);
         -- i.e. strip out the double-qoutes surrounding the string.
      begin
         return Reader.Read_Str (Unquoted_Str);
      end;
   end Read_String;


   function Read_Line (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param : Mal_Handle;
      S : String (1..Reader.Max_Line_Len);
      Last : Natural;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      declare
         Prompt : String := Deref_String (First_Param).Get_String;
      begin
         -- Print the prompt, less the quote marks.
         Ada.Text_IO.Put (Prompt (2 .. Prompt'Last - 1));
      end;
      Ada.Text_IO.Get_Line (S, Last);
      return New_String_Mal_Type ('"' & S (1 .. Last) & '"');
   end Read_Line;


   function Slurp (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      declare
         Str_Param : String := Deref_String (First_Param).Get_String;
         Unquoted_Str : String(1 .. Str_Param'Length-2) :=
           Str_Param (Str_Param'First+1 .. Str_Param'Last-1);
         -- i.e. strip out the double-qoutes surrounding the string.
         use Ada.Text_IO;
         Fn : Ada.Text_IO.File_Type;
         Line_Str : String (1..Reader.Max_Line_Len);
         File_Str : Ada.Strings.Unbounded.Unbounded_String :=
           Ada.Strings.Unbounded.To_Unbounded_String ("""");
         Last : Natural;
         I : Natural := 0;
      begin
         Ada.Text_IO.Open (Fn, In_File, Unquoted_Str);
         while not End_Of_File (Fn) loop
            Get_Line (Fn, Line_Str, Last);
            if Last > 0 then
               Ada.Strings.Unbounded.Append (File_Str, Line_Str (1 .. Last));
               Ada.Strings.Unbounded.Append (File_Str, Ada.Characters.Latin_1.LF);
            end if;
         end loop;
         Ada.Text_IO.Close (Fn);
         Ada.Strings.Unbounded.Append (File_Str, '"');
         return New_String_Mal_Type (Ada.Strings.Unbounded.To_String (File_Str));
      end;
   end Slurp;


   function Conj (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : List_Mal_Type;
      First_Param, Res : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      Rest_List := Deref_List (Cdr (Rest_List)).all;

      -- Is this a List or a Vector?
      case Deref_List (First_Param).Get_List_Type is
         when List_List =>
            Res := Copy (First_Param);
            while not Is_Null (Rest_List) loop
               Res := Prepend (To_List => Deref_List (Res).all, Op => Car (Rest_List));
               Rest_List := Deref_List (Cdr (Rest_List)).all;
            end loop;
            return Res;
         when Vector_List =>
            Res := Copy (First_Param);
            while not Is_Null (Rest_List) loop
               Vector.Append (Vector.Deref_Vector (Res).all, Car (Rest_List));
               Rest_List := Deref_List (Cdr (Rest_List)).all;
            end loop;
            return Res;
         when Hashed_List => raise Mal_Exception with "Conj on Hashed_Map";
      end case;
   end Conj;


   procedure Init (Repl_Env : Envs.Env_Handle) is
   begin

      Envs.Set (Repl_Env, "*host-language*", Types.New_Symbol_Mal_Type ("ada"));

      Envs.Set (Repl_Env, "true", Types.New_Bool_Mal_Type (True));

      Envs.Set (Repl_Env,
           "true?",
           New_Func_Mal_Type ("true?", Is_True'access));

      Envs.Set (Repl_Env, "false", Types.New_Bool_Mal_Type (False));

      Envs.Set (Repl_Env,
           "false?",
           New_Func_Mal_Type ("false?", Is_False'access));

      Envs.Set (Repl_Env, "nil", Types.New_Symbol_Mal_Type ("nil"));

      Envs.Set (Repl_Env,
           "meta",
           New_Func_Mal_Type ("meta", Meta'access));

      Envs.Set (Repl_Env,
           "with-meta",
           New_Func_Mal_Type ("with-meta", With_Meta'access));

      Envs.Set (Repl_Env,
           "nil?",
           New_Func_Mal_Type ("nil?", Is_Nil'access));

      Envs.Set (Repl_Env,
           "throw",
           New_Func_Mal_Type ("throw", Throw'access));

      Envs.Set (Repl_Env,
           "atom",
           New_Func_Mal_Type ("atom", New_Atom'access));

      Envs.Set (Repl_Env,
           "atom?",
           New_Func_Mal_Type ("atom?", Is_Atom'access));

      Envs.Set (Repl_Env,
           "deref",
           New_Func_Mal_Type ("deref", Core.Deref'access));

      Envs.Set (Repl_Env,
           "reset!",
           New_Func_Mal_Type ("reset!", Reset'access));

      Envs.Set (Repl_Env,
           "swap!",
           New_Func_Mal_Type ("swap!", Swap'access));

      Envs.Set (Repl_Env,
           "list",
           New_Func_Mal_Type ("list", New_List'access));

      Envs.Set (Repl_Env,
           "list?",
           New_Func_Mal_Type ("list?", Is_List'access));

      Envs.Set (Repl_Env,
           "vector",
           New_Func_Mal_Type ("vector", New_Vector'access));

      Envs.Set (Repl_Env,
           "vector?",
           New_Func_Mal_Type ("vector?", Is_Vector'access));

      Envs.Set (Repl_Env,
           "hash-map",
           New_Func_Mal_Type ("hash-map", New_Map'access));

      Envs.Set (Repl_Env,
           "assoc",
           New_Func_Mal_Type ("assoc", Assoc'access));

      Envs.Set (Repl_Env,
           "dissoc",
           New_Func_Mal_Type ("dissoc", Dis_Assoc'access));

      Envs.Set (Repl_Env,
           "get",
           New_Func_Mal_Type ("get", Get_Key'access));

      Envs.Set (Repl_Env,
           "keys",
           New_Func_Mal_Type ("keys", All_Keys'access));

      Envs.Set (Repl_Env,
           "vals",
           New_Func_Mal_Type ("vals", All_Values'access));

      Envs.Set (Repl_Env,
           "map?",
           New_Func_Mal_Type ("map?", Is_Map'access));

      Envs.Set (Repl_Env,
           "contains?",
           New_Func_Mal_Type ("contains?", Contains_Key'access));

      Envs.Set (Repl_Env,
           "sequential?",
           New_Func_Mal_Type ("sequential?", Is_Sequential'access));

      Envs.Set (Repl_Env,
           "empty?",
           New_Func_Mal_Type ("empty?", Is_Empty'access));

      Envs.Set (Repl_Env,
           "count",
           New_Func_Mal_Type ("count", Count'access));

      Envs.Set (Repl_Env,
           "cons",
           New_Func_Mal_Type ("cons", Cons'access));

      Envs.Set (Repl_Env,
           "concat",
           New_Func_Mal_Type ("concat", Concat'access));

      Envs.Set (Repl_Env,
           "first",
           New_Func_Mal_Type ("first", First'access));

      Envs.Set (Repl_Env,
           "rest",
           New_Func_Mal_Type ("rest", Rest'access));

      Envs.Set (Repl_Env,
           "nth",
           New_Func_Mal_Type ("nth", Nth'access));

      Envs.Set (Repl_Env,
           "map",
           New_Func_Mal_Type ("map", Map'access));

      Envs.Set (Repl_Env,
           "apply",
           New_Func_Mal_Type ("apply", Apply'access));

      Envs.Set (Repl_Env,
           "symbol",
           New_Func_Mal_Type ("symbol", Symbol'access));

      Envs.Set (Repl_Env,
           "symbol?",
           New_Func_Mal_Type ("symbol?", Is_Symbol'access));

      Envs.Set (Repl_Env,
           "keyword",
           New_Func_Mal_Type ("keyword", Keyword'access));

      Envs.Set (Repl_Env,
           "keyword?",
           New_Func_Mal_Type ("keyword?", Is_Keyword'access));

      Envs.Set (Repl_Env,
           "pr-str",
           New_Func_Mal_Type ("pr-str", Pr_Str'access));

      Envs.Set (Repl_Env,
           "str",
           New_Func_Mal_Type ("str", Str'access));

      Envs.Set (Repl_Env,
           "prn",
           New_Func_Mal_Type ("prn", Prn'access));

      Envs.Set (Repl_Env,
           "println",
           New_Func_Mal_Type ("println", Println'access));

--      Envs.Set (Repl_Env,
--           "eval",
--           New_Func_Mal_Type ("eval", Do_Eval'access));

      Envs.Set (Repl_Env,
           "read-string",
           New_Func_Mal_Type ("read-string", Read_String'access));

      Envs.Set (Repl_Env,
           "readline",
           New_Func_Mal_Type ("readline", Read_Line'access));

      Envs.Set (Repl_Env,
           "slurp",
           New_Func_Mal_Type ("slurp", Slurp'access));

      Envs.Set (Repl_Env,
           "conj",
           New_Func_Mal_Type ("conj", Conj'access));

      Envs.Set (Repl_Env,
           "+",
           New_Func_Mal_Type ("+", Plus'access));

      Envs.Set (Repl_Env,
           "-",
           New_Func_Mal_Type ("-", Minus'access));

      Envs.Set (Repl_Env,
           "*",
           New_Func_Mal_Type ("*", Mult'access));

      Envs.Set (Repl_Env,
           "/",
           New_Func_Mal_Type ("/", Divide'access));

      Envs.Set (Repl_Env,
           "<",
           New_Func_Mal_Type ("<", LT'access));

      Envs.Set (Repl_Env,
           "<=",
           New_Func_Mal_Type ("<=", LTE'access));

      Envs.Set (Repl_Env,
           ">",
           New_Func_Mal_Type (">", GT'access));

      Envs.Set (Repl_Env,
           ">=",
           New_Func_Mal_Type (">=", GTE'access));

      Envs.Set (Repl_Env,
           "=",
           New_Func_Mal_Type ("=", EQ'access));

   end Init;


end Core;
