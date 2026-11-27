BEGIN
  -- 1. Eliminar triggers
  FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
    EXECUTE IMMEDIATE 'DROP TRIGGER "' || r.trigger_name || '"';
  END LOOP;

  -- 2. Eliminar vistas
  FOR r IN (SELECT view_name FROM user_views) LOOP
    EXECUTE IMMEDIATE 'DROP VIEW "' || r.view_name || '"';
  END LOOP;

  -- 3. Eliminar tablas (incluye restricciones y depende en cascada)
  FOR r IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE "' || r.table_name || '" CASCADE CONSTRAINTS PURGE';
  END LOOP;

  -- 4. Eliminar secuencias
  FOR r IN (SELECT sequence_name FROM user_sequences) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE "' || r.sequence_name || '"';
  END LOOP;

  -- 5. Eliminar procedimientos, funciones, paquetes y tipos
  FOR r IN (
    SELECT object_name, object_type
    FROM user_objects
    WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'TYPE')
  ) LOOP
    EXECUTE IMMEDIATE 'DROP ' || r.object_type || ' "' || r.object_name || '"';
  END LOOP;
END;
/

PURGE RECYCLEBIN;