/*
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS bookstores CASCADE;
DROP TABLE IF EXISTS books_locations CASCADE;
DROP TABLE IF EXISTS collections CASCADE;
DROP TABLE IF EXISTS ownership CASCADE;
*/
--DROP DATABASE library;
--CREATE DATABASE library;
--Define tables
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(70) NOT NULL check(length(title) >= 2),
    publish_date DATE check(publish_date < CURRENT_DATE)
);
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL check(length(name) >= 2),
    surname VARCHAR(30) NOT NULL check(length(surname) >= 2),
    birthday DATE check(birthday < CURRENT_DATE)
);
CREATE TABLE ownership (
    book INT REFERENCES books(book_id),
    author INT REFERENCES authors(author_id),
    CONSTRAINT id_is_primary PRIMARY KEY (book, author)
);
CREATE TABLE collections (
    size INT DEFAULT check_size,
    col_id SERIAL PRIMARY KEY,
    name varchar(30)
);
CREATE TABLE bookstores (
    bs_id SERIAL PRIMARY KEY,
    name varchar(20) NOT NULL check(length(name) >= 2),
    collection INT REFERENCES collections(col_id)
);
CREATE TABLE books_locations (
    book INT REFERENCES books(book_id),
    collection INT REFERENCES collections(col_id)
);
--This function is being used for dynamically calculating collection size
CREATE
OR REPLACE FUNCTION check_size(collection_id INT) RETURNS INT AS $ $ DECLARE size INT;
BEGIN
SELECT
    COUNT(*) INTO size
FROM
    books_locations
    JOIN collections on books_locations.collection = collections.col_id
WHERE
    col_id = collection_id;
RETURN size;
END;
$ $ LANGUAGE plpgsql;
UPDATE
    collections
SET
    (size) = (check_size(col_id))
WHERE
    col_id > 0;
--Trigger function to calculate size once again every update of the books_location table
    CREATE
    OR REPLACE FUNCTION collection_size_t() RETURNS TRIGGER AS $ BODY $ BEGIN
UPDATE
    collections
SET
    size = check_size(col_id)
WHERE
    col_id > 0;
RETURN NULL;
END;
$ BODY $ LANGUAGE plpgsql;
-- TRIGGER for calculating size
CREATE
OR REPLACE TRIGGER collection_size_changed
AFTER
    DELETE
    OR
INSERT
    OR
UPDATE
    ON books_locations EXECUTE PROCEDURE collection_size_t();
--VIEW FOR DETAILED INFO ON BOOKS
    CREATE
    OR REPLACE VIEW books_detailed AS
SELECT
    b.title,
    a.name,
    a.surname,
    b.publish_date,
    c.col_id
FROM
    books b
    JOIN ownership o on b.book_id = o.book
    JOIN authors a on o.author = a.author_id
    JOIN books_locations bl on bl.book = b.book_id
    JOIN collections c on c.col_id = bl.collection;
