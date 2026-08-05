-- Creating 2 tables here: test_runs and test_cases

-- test_runs table: 1 row per CI execution

CREATE TABLE test_runs(
    ingestion_id UUID PRIMARY KEY,
    team VARCHAR(50) NOT NULL,
    project VARCHAR(50) NOT NULL,
    commit_sha VARCHAR(40) NOT NULL,
    branch VARCHAR(100) NOT NULL,
    ci_run_id VARCHAR(100) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    total INTEGER NOT NULL,
    passed INTEGER NOT NULL,
    failed INTEGER NOT NULL
);

-- Index for filtering by team (common dashboard query)
CREATE INDEX idx_test_runs_team ON test_runs(team);

-- test_case table - 1 row individual test case

CREATE TABLE test_cases(
    id BIGSERIAL PRIMARY KEY,
    run_id UUID NOT NULL REFERENCES test_runs(ingestion_id),
    name VARCHAR(100) NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('pass', 'fail', 'skipped', 'error')),
    duration_ms INTEGER NOT NULL,
    critical BOOLEAN NOT NULL
);