
CREATE PROFILE library_profile LIMIT
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LOCK_TIME 1; 

CREATE ROLE client_role;
CREATE ROLE librarian_role;
CREATE ROLE manager_role;

GRANT CREATE SESSION TO client_role;
GRANT CREATE SESSION TO librarian_role;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO manager_role;

-- =====================================================
-- STEP 2: CREATE USERS WITH ROLES
-- =====================================================
CREATE USER nizar_manager IDENTIFIED BY "NizarMan10" PROFILE library_profile;
GRANT manager_role TO nizar_manager;

CREATE USER ghina_librarian IDENTIFIED BY "gh2005ina" PROFILE library_profile;
GRANT librarian_role TO ghina_librarian;

CREATE USER zeina_librarian IDENTIFIED BY "z1e2i3n4a5" PROFILE library_profile;
GRANT librarian_role TO zeina_librarian;

CREATE USER ahmad_client IDENTIFIED BY "AhMe21D6" PROFILE library_profile;
GRANT client_role TO ahmad_client;

CREATE USER rana_client IDENTIFIED BY "r55a0n01" PROFILE library_profile;
GRANT client_role TO rana_client;

CREATE USER maya_client IDENTIFIED BY "L712ay712am" PROFILE library_profile;
GRANT client_role TO maya_client;

COMMIT;

-- =====================================================
-- STEP 3: DROP EXISTING TABLES (CLEAN SLATE)
-- =====================================================
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE reservation CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE rating CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE loan CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE book_author CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE book CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE author CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE genre CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- =====================================================
-- STEP 4: CREATE TABLES WITH CORRECT PASSWORD COLUMN
-- =====================================================

-- Genre table
CREATE TABLE genre (
    genre_id     NUMBER PRIMARY KEY,
    name         VARCHAR2(100)
);

-- Users table with password_hash column for bcrypt
CREATE TABLE users (
    user_id       NUMBER PRIMARY KEY,
    full_name     VARCHAR2(100) NOT NULL,
    email         VARCHAR2(100) UNIQUE NOT NULL,
    password_hash VARCHAR2(100) NOT NULL,  -- For bcrypt hashed passwords
    role          VARCHAR2(20) NOT NULL,
    genre_id      NUMBER REFERENCES genre(genre_id),
    created_date  DATE DEFAULT SYSDATE,
    active        CHAR(1) DEFAULT 'Y' CHECK (active IN ('Y', 'N'))
);

-- Author table
CREATE TABLE author (
    author_id    NUMBER PRIMARY KEY,
    name         VARCHAR2(100) NOT NULL,
    nationality  VARCHAR2(100),
    bio          CLOB,
    birth_year   NUMBER,
    death_year   NUMBER
);

-- Book table
CREATE TABLE book (
    book_id          NUMBER PRIMARY KEY,
    title            VARCHAR2(200) NOT NULL,
    pub_year         NUMBER,
    pages            NUMBER,
    stock            NUMBER DEFAULT 0,
    genre_id         NUMBER REFERENCES genre(genre_id),
    price_per_month  NUMBER(5,2),
    series_name      VARCHAR2(200),
    series_number    NUMBER
);

-- Book-Author junction table
CREATE TABLE book_author (
    book_id   NUMBER REFERENCES book(book_id),
    author_id NUMBER REFERENCES author(author_id),
    PRIMARY KEY (book_id, author_id)
);

-- Loan table
CREATE TABLE loan (
    loan_id     NUMBER PRIMARY KEY,
    user_id     NUMBER REFERENCES users(user_id),
    book_id     NUMBER REFERENCES book(book_id),
    loan_date   DATE NOT NULL,
    due_date    DATE NOT NULL,
    return_date DATE,
    status      VARCHAR2(20) DEFAULT 'ongoing',
    fine_amount NUMBER(6,2) DEFAULT 0
);

-- Rating table
CREATE TABLE rating (
    rating_id    NUMBER PRIMARY KEY,
    user_id      NUMBER REFERENCES users(user_id),
    book_id      NUMBER REFERENCES book(book_id),
    rating       NUMBER(1) CHECK (rating BETWEEN 1 AND 5),
    review_text  CLOB,
    rating_date  DATE DEFAULT SYSDATE
);

-- Reservation table
CREATE TABLE reservation (
    reservation_id   NUMBER PRIMARY KEY,
    user_id          NUMBER REFERENCES users(user_id),
    book_id          NUMBER REFERENCES book(book_id),
    reservation_date DATE DEFAULT SYSDATE,
    status           VARCHAR2(20) DEFAULT 'pending'
);

-- =====================================================
-- STEP 5: GRANT PERMISSIONS
-- =====================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.genre        TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.users        TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.author       TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.book         TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.book_author  TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.loan         TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.rating       TO manager_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GZlibrary.reservation  TO manager_role;

GRANT SELECT, INSERT, UPDATE ON GZlibrary.book         TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON GZlibrary.loan         TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON GZlibrary.reservation  TO librarian_role;
GRANT SELECT ON GZlibrary.users  TO librarian_role;
GRANT SELECT ON GZlibrary.author TO librarian_role;
GRANT SELECT ON GZlibrary.genre  TO librarian_role;
GRANT SELECT ON GZlibrary.rating TO librarian_role;

GRANT SELECT ON GZlibrary.book        TO client_role;
GRANT SELECT ON GZlibrary.author      TO client_role;
GRANT SELECT ON GZlibrary.genre       TO client_role;
GRANT SELECT ON GZlibrary.book_author TO client_role;
GRANT SELECT ON GZlibrary.loan        TO client_role;
GRANT SELECT, INSERT ON GZlibrary.rating      TO client_role;
GRANT SELECT, INSERT ON GZlibrary.reservation TO client_role;

-- =====================================================
-- STEP 6: INSERT DATA - GENRES
-- =====================================================
INSERT INTO genre VALUES (1, 'romance/tragedy');
INSERT INTO genre VALUES (2, 'fiction/romance');
INSERT INTO genre VALUES (3, 'poetry');
INSERT INTO genre VALUES (4, 'finance/self-help');
INSERT INTO genre VALUES (5, 'fantasy');
INSERT INTO genre VALUES (6, 'comedy');
INSERT INTO genre VALUES (7, 'fiction/humor');
INSERT INTO genre VALUES (8, 'classic literature/romance');
INSERT INTO genre VALUES (9, 'mystery/thriller');
INSERT INTO genre VALUES (10, 'dystopian/fantasy');

-- =====================================================
-- STEP 7: INSERT DATA - USERS (with plain passwords - will be hashed by script)
-- =====================================================
INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (10, 'Nizar Hakam', 'nizar.manager@library.com', 'NizarMan10', 'manager', 1);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (20, 'Ghina Ayoub', 'ghina.librarian@library.com', 'gh2005ina', 'librarian', 2);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (21, 'Zeina Sarraf', 'zeina.librarian@library.com', 'z1e2i3n4a5', 'librarian', 3);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (30, 'Ahmad Ayash', 'ahmad.books@gmail.com', 'AhMe21D6', 'client', 4);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (31, 'Rana Salloum', 'rana.2001@gmail.com', 'r55a0n01', 'client', 5);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (32, 'Maya Ahmad', 'maya.reads@gmail.com', '712ay712am', 'client', 6);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (33, 'Lina Karam', 'lina.karam@gmail.com', 'leeeena656', 'client', 7);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (34, 'Ossama Hasan', 'ossama32@gmail.com', 'ossAMA435', 'client', 8);

INSERT INTO users (user_id, full_name, email, password_hash, role, genre_id) 
VALUES (35, 'Mira Zohbi', 'mira.beatles@gmail.com', 'itsmira8372', 'client', 9);

-- =====================================================
-- STEP 8: INSERT DATA - AUTHORS
-- =====================================================
INSERT INTO author VALUES (111,'John Green','American','John Green is an American author and youtube content creator. He is known for his young adult novels including The fault in our stars and Looking for Alaska',1977,NULL);
INSERT INTO author VALUES (112,'Dustin Thao','American','Dustin Thao is a Vietnamese American writer known for his debut novel You''ve reached Sam, a hurtful story about love and loss',NULL,NULL);
INSERT INTO author VALUES (113,'Taylor Jenkins Reid','American','Taylor Jenkins Reid is a bestselling author known for her historical and contemporary fiction, including The seven husbands of Evelyn hugo and Daisy Jones and the six',1983,NULL);
INSERT INTO author VALUES (114,'Whitney Hanson','American','Whitney Hanson is a poet and author known for her contemporary poetry collections exploring theme of love, heartbreak and healing.',NULL,NULL);
INSERT INTO author VALUES (115,'Robert T. Kiyosaki','American','Robert Kiyosaki is an entrepreneur and author best known for Rich Dad Poor Dad, a personal finance book that has sold over 40 million copies worldwide.',1947,NULL);
INSERT INTO author VALUES (116,'Roald Dahl','British/Norwegian','Roald Dahl was a british novelist, short story writer, and screenwriter famous for his darkly humorous children''s books including Matilda, Charlie and the chocolate factory, and James and the Giant Peach',1916,1990);
INSERT INTO author VALUES (117,'Jerome K. Jerome','British','Jerome K. Jerome was an English writer and humorist best known for his comic novel Three Men in a Boat, published in 1889.',1859,1927);
INSERT INTO author VALUES (118,'Jeff Kinney','American','Jeff Kinney is an American author and cartoonist, best known for creating The Diary of a Wimpy Kid series, one of the popular children''s book series.',1971,NULL);
INSERT INTO author VALUES (119,'Nicholas Sparks','American','Nicholas Sparks is an American romance novelist known for his emotional love stories including The Notebook, A Walk to Remember and Dear John.',1965,NULL);
INSERT INTO author VALUES (120,'Jojo Moyes','British','Jojo Moyes is a british novelist known for her romance and historical fiction, particulary the bestselling novel Me Before You.',1969,NULL);
INSERT INTO author VALUES (121,'Jane Austen','British','Jane Austen was an English novelist known for her six major novels including Pride and Prejudice, Sense and Sensibility, and Emma. Her works critique the British landed gentry at the end of 18th century.',1775,1817);
INSERT INTO author VALUES (122,'Jennifer Lynn Barnes','American','Jennifer Lynn Barnes is an American author known for her young adult mystery and thriller novels, particulary The Naturals series. She holds advanced degrees in psychology, psychiatry and cognitive science.',1982,NULL);
INSERT INTO author VALUES (123,'Lauren Roberts','American','Lauren Roberts is a contemporary fantasy author best known for her Powerless series. She has quickly gained popularity in the Booktok community for her engaging dystopian romance novels.',NULL,NULL);

-- =====================================================
-- STEP 9: INSERT DATA - BOOKS
-- =====================================================
INSERT INTO book VALUES (120,'The Fault in Our Stars',2012,352,1,1,8,NULL,NULL);
INSERT INTO book VALUES (121,'You''ve Reached Sam',2021,320,1,2,6.5,NULL,NULL);
INSERT INTO book VALUES (122,'The Seven Husbands of Evelyn Hugo',2017,400,1,2,9,NULL,NULL);
INSERT INTO book VALUES (123,'Climate',2025,352,1,3,8,NULL,NULL);
INSERT INTO book VALUES (124,'Rich Dad Poor Dad',1997,207,1,4,5,NULL,NULL);
INSERT INTO book VALUES (125,'Matilda',1988,240,1,5,6,NULL,NULL);
INSERT INTO book VALUES (126,'Three Men in a Boat',1889,320,1,6,7,NULL,NULL);
INSERT INTO book VALUES (127,'Diary of a Wimpy Kid',2007,217,1,7,5.5,NULL,NULL);
INSERT INTO book VALUES (128,'The Notebook',1996,214,1,1,5.5,NULL,NULL);
INSERT INTO book VALUES (129,'Me before you',2012,369,1,2,9,NULL,NULL);
INSERT INTO book VALUES (130,'Pride and Prejudice',1813,432,1,8,10,NULL,NULL);
INSERT INTO book VALUES (131,'Looking for Alaska',2005,221,1,5,6,NULL,NULL);
INSERT INTO book VALUES (132,'The Giver of Stars',2019,480,1,2,10,NULL,NULL);
INSERT INTO book VALUES (133,'The Naturals',2013,320,1,9,7.5,'The Naturals',1);
INSERT INTO book VALUES (134,'Killer Instinct',2014,400,1,9,7.5,'The Naturals',2);
INSERT INTO book VALUES (135,'All In',2015,416,1,9,7.5,'The Naturals',3);
INSERT INTO book VALUES (136,'Bad Blood',2016,368,1,9,7.5,'The Naturals',4);
INSERT INTO book VALUES (137,'Powerless',2023,528,1,10,9.5,'The Powerless Trilogy',1);
INSERT INTO book VALUES (138,'Reckless',2024,624,1,10,9.5,'The Powerless Trilogy',2);
INSERT INTO book VALUES (139,'Fearless',2025,640,1,10,9.5,'The Powerless Trilogy',3);

-- =====================================================
-- STEP 10: INSERT DATA - BOOK-AUTHOR RELATIONSHIPS
-- =====================================================
INSERT INTO book_author VALUES (120,111);
INSERT INTO book_author VALUES (121,112);
INSERT INTO book_author VALUES (122,113);
INSERT INTO book_author VALUES (123,114);
INSERT INTO book_author VALUES (124,115);
INSERT INTO book_author VALUES (125,116);
INSERT INTO book_author VALUES (126,117);
INSERT INTO book_author VALUES (127,118);
INSERT INTO book_author VALUES (128,119);
INSERT INTO book_author VALUES (129,120);
INSERT INTO book_author VALUES (130,121);
INSERT INTO book_author VALUES (131,111);
INSERT INTO book_author VALUES (132,120);
INSERT INTO book_author VALUES (133,122);
INSERT INTO book_author VALUES (134,122);
INSERT INTO book_author VALUES (135,122);
INSERT INTO book_author VALUES (136,122);
INSERT INTO book_author VALUES (137,123);
INSERT INTO book_author VALUES (138,123);
INSERT INTO book_author VALUES (139,123);

-- =====================================================
-- STEP 11: INSERT DATA - LOANS
-- =====================================================
INSERT INTO loan VALUES (340,31,124,DATE '2025-01-14',DATE '2025-03-14',DATE '2025-03-10','returned',0);
INSERT INTO loan VALUES (341,33,129,DATE '2025-03-24',DATE '2025-05-24',DATE '2025-05-20','returned',0);
INSERT INTO loan VALUES (342,30,128,DATE '2025-04-06',DATE '2025-06-06',DATE '2025-06-13','returned',7);
INSERT INTO loan VALUES (343,35,130,DATE '2025-05-10',DATE '2025-07-10',DATE '2025-07-25','returned',15);
INSERT INTO loan VALUES (344,31,122,DATE '2025-06-01',DATE '2025-08-01',DATE '2025-08-04','returned',3);
INSERT INTO loan VALUES (345,32,121,DATE '2025-06-15',DATE '2025-08-15',DATE '2025-07-20','returned',0);
INSERT INTO loan VALUES (346,33,125,DATE '2025-07-01',DATE '2025-09-01',DATE '2025-08-28','returned',0);
INSERT INTO loan VALUES (347,34,123,DATE '2025-09-01',DATE '2025-11-01',NULL,'ongoing',0);
INSERT INTO loan VALUES (348,32,137,DATE '2025-09-15',DATE '2025-11-15',NULL,'ongoing',0);
INSERT INTO loan VALUES (349,30,133,DATE '2025-08-01',DATE '2025-09-15',NULL,'overdue',15);
INSERT INTO loan VALUES (350,35,134,DATE '2025-07-20',DATE '2025-09-20',NULL,'overdue',10);
INSERT INTO loan VALUES (351,31,126,DATE '2025-08-15',DATE '2025-09-25',NULL,'overdue',5);
INSERT INTO loan VALUES (352,32,127,DATE '2025-05-10',DATE '2025-06-10',DATE '2025-06-09','returned',0);
INSERT INTO loan VALUES (353,33,131,DATE '2025-06-20',DATE '2025-08-20',DATE '2025-09-05','returned',16);
INSERT INTO loan VALUES (354,34,138,DATE '2025-08-25',DATE '2025-10-25',NULL,'ongoing',0);
INSERT INTO loan VALUES (355,35,120,DATE '2025-07-05',DATE '2025-08-20',DATE '2025-09-10','returned',21);

-- =====================================================
-- STEP 12: INSERT DATA - RATINGS
-- =====================================================
INSERT INTO rating VALUES (1,31,124,5,'One of the best finance books I''ve ever read, simple yet powerful lessons.',DATE '2025-03-15');
INSERT INTO rating VALUES (2,33,129,4,'Very touching and emotional, though a little predictable.',DATE '2025-05-25');
INSERT INTO rating VALUES (3,30,128,5,'An unforgettable romance, made me cry more than once.',DATE '2025-06-20');
INSERT INTO rating VALUES (4,35,130,3,'A classic worth reading, but the style is old-fashioned.',DATE '2025-07-28');
INSERT INTO rating VALUES (5,31,122,4,'Engaging story, loved the Hollywood setting and twists.',DATE '2025-08-10');
INSERT INTO rating VALUES (6,32,121,2,'Characters felt flat, I couldn''t get into it.',DATE '2025-07-25');
INSERT INTO rating VALUES (7,33,125,3,'Funny at times, but not really my style of humor.',DATE '2025-08-30');
INSERT INTO rating VALUES (8,34,123,4,'Interesting and poetic, though slightly repetitive.',DATE '2025-09-12');
INSERT INTO rating VALUES (9,32,137,5,'Absolutely loved this fantasy! Epic world-building, can''t wait for more.',DATE '2025-09-22');
INSERT INTO rating VALUES (10,30,133,4,'A thrilling read, sharp characters and fast-paced.',DATE '2025-09-25');
INSERT INTO rating VALUES (11,35,120,5,'Beautifully heartbreaking, John Green never disappoints.',DATE '2025-09-15');
INSERT INTO rating VALUES (12,31,126,3,'Classic British humor, light but sometimes dragged on.',DATE '2025-09-28');
INSERT INTO rating VALUES (13,33,131,4,'Loved the mysterious vibes, very thought-provoking.',DATE '2025-09-10');
INSERT INTO rating VALUES (14,34,138,5,'Even better than the first book, an amazing sequel!',DATE '2025-09-26');
INSERT INTO rating VALUES (15,32,127,4,'Funny and easy to read, perfect for a quick escape.',DATE '2025-06-12');

-- =====================================================
-- STEP 13: INSERT DATA - RESERVATIONS
-- =====================================================
INSERT INTO reservation VALUES (1,31,124,DATE '2025-01-10','fulfilled');
INSERT INTO reservation VALUES (2,33,129,DATE '2025-03-20','fulfilled');
INSERT INTO reservation VALUES (3,30,128,DATE '2025-04-01','fulfilled');
INSERT INTO reservation VALUES (4,35,130,DATE '2025-05-01','fulfilled');
INSERT INTO reservation VALUES (5,31,122,DATE '2025-05-28','fulfilled');
INSERT INTO reservation VALUES (6,32,121,DATE '2025-06-10','fulfilled');
INSERT INTO reservation VALUES (7,33,125,DATE '2025-06-25','fulfilled');
INSERT INTO reservation VALUES (8,34,123,DATE '2025-08-28','fulfilled');
INSERT INTO reservation VALUES (9,32,137,DATE '2025-09-10','fulfilled');
INSERT INTO reservation VALUES (10,32,127,DATE '2025-05-05','fulfilled');
INSERT INTO reservation VALUES (11,33,131,DATE '2025-06-15','fulfilled');
INSERT INTO reservation VALUES (12,34,138,DATE '2025-08-20','fulfilled');
INSERT INTO reservation VALUES (13,35,120,DATE '2025-07-01','fulfilled');
INSERT INTO reservation VALUES (14,31,123,DATE '2025-09-10','pending');
INSERT INTO reservation VALUES (15,33,137,DATE '2025-09-20','pending');
INSERT INTO reservation VALUES (16,31,133,DATE '2025-09-18','pending');
INSERT INTO reservation VALUES (17,32,134,DATE '2025-09-22','pending');
INSERT INTO reservation VALUES (18,33,126,DATE '2025-09-26','pending');
INSERT INTO reservation VALUES (19,30,130,DATE '2025-05-05','cancelled');
INSERT INTO reservation VALUES (20,35,137,DATE '2025-09-16','cancelled');

COMMIT;

SELECT user_id, full_name, email, password_hash, role 
FROM users;