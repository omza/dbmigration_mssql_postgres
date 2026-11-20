-- Datenbankweite Einstellungen.
-- Zeitzone: T-SQL GETDATE() liefert die Ortszeit des Servers. In PG hängen localtimestamp /
-- clock_timestamp()::timestamp von der Session-Zeitzone ab -> DB-Default auf Ortszeit setzen.
-- ACHTUNG: JDBC-Clients (Talend) setzen beim Connect die JVM-Zeitzone -> dort ebenfalls Europe/Berlin.
DO $$
BEGIN
    EXECUTE format('ALTER DATABASE %I SET timezone = %L', current_database(), 'Europe/Berlin');
END
$$;
SET timezone = 'Europe/Berlin';
