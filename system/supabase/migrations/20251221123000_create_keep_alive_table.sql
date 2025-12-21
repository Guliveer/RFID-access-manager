-- Tabela dedykowana dla keep-alive cron job
-- Zawiera tylko jeden rekord który jest aktualizowany przy każdym pingu
CREATE TABLE IF NOT EXISTS keep_alive (
    id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1), -- Tylko jeden rekord
    last_ping TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Wstaw początkowy rekord
INSERT INTO keep_alive (id, last_ping) VALUES (1, NOW())
ON CONFLICT (id) DO NOTHING;

-- Polityka RLS - tylko service_role może aktualizować
ALTER TABLE keep_alive ENABLE ROW LEVEL SECURITY;

-- Pozwól na odczyt dla authenticated users (opcjonalne, dla monitoringu)
CREATE POLICY "Allow read for authenticated users" ON keep_alive
    FOR SELECT TO authenticated USING (true);

-- Pozwól na update dla service_role
CREATE POLICY "Allow update for service_role" ON keep_alive
    FOR UPDATE TO service_role USING (true);
