CREATE TABLE ntnxschema1.ntnxtable2 (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO ntnxschema1.ntnxtable2(id, name, email)
select 1,'test','test@email.com';
