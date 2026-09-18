ALTER TABLE users
  ADD COLUMN relationship_status TEXT,
  ADD COLUMN relationship_length TEXT;

ALTER TABLE users
  ADD CONSTRAINT users_relationship_status_check CHECK (
    relationship_status IS NULL
    OR relationship_status IN ('dating', 'engaged', 'married', 'long_distance')
  ),
  ADD CONSTRAINT users_relationship_length_check CHECK (
    relationship_length IS NULL
    OR relationship_length IN (
      'under_3_months',
      '3_to_12_months',
      '1_to_3_years',
      '3_plus_years'
    )
  );
