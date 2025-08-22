CREATE TABLE ntnxschema1.person_new (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO ntnxschema1.person_new(name, email)
select 'test','test@email.com';

