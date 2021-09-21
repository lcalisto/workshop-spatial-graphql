CREATE TABLE app_public.population (
  id SERIAL PRIMARY KEY,
  dico character varying,
  m_residents INTEGER,
  f_residents INTEGER,
  households INTEGER,
  comments text,
  FOREIGN KEY (dico) REFERENCES app_public.municipalities_pt (dico)
);

CREATE INDEX ON "app_public"."population"("dico");

---------------------------------------------------------------------

ALTER TABLE app_public.municipality
    ADD CONSTRAINT municipality_dico_unique UNIQUE (dico);

ALTER TABLE app_public.population_stat
    ADD CONSTRAINT population_dico_unique UNIQUE (dico);

