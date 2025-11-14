
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

INSERT INTO author VALUES (131,'Alex Michaelides','British-Cypriot','Alex Michaelides is a bestselling author known for psychological thrillers, particularly The Silent Patient. He has a background in screenwriting.',1977,NULL);
INSERT INTO author VALUES (125,'Stephanie Garber','American','Stephanie Garber is an American author best known for her Caraval series, a fantasy trilogy filled with magic, mystery, and romance.',1987,NULL);
INSERT INTO author VALUES (126,'B.A. Paris','British','B.A. Paris (pen name of Bernadette MacDougall) is a British author known for psychological thrillers including Behind Closed Doors and The Breakdown.',NULL,NULL);
INSERT INTO author VALUES (127,'Sarah Pinborough','British','Sarah Pinborough is a British author known for psychological thrillers and horror fiction. Her novel Behind Her Eyes became a Netflix series.',1972,NULL);
INSERT INTO author VALUES (128,'Alice Feeney','British','Alice Feeney is a British author known for psychological thrillers with unexpected twists, including Sometimes I Lie and Rock Paper Scissors.',NULL,NULL);
INSERT INTO author VALUES (129,'Freida McFadden','American','Freida McFadden is a practicing physician and bestselling author of psychological thrillers, particularly known for The Housemaid series.',NULL,NULL);
INSERT INTO author VALUES (130,'E. Lockhart','American','E. Lockhart (Emily Jenkins) is an American author known for young adult fiction, particularly the thriller We Were Liars.',1967,NULL);
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
-- The Inheritance Games Series by Jennifer Lynn Barnes
INSERT INTO book VALUES (140,'The Inheritance Games',2020,400,3,9,8.5,'The Inheritance Games',1,NULL,NULL);
INSERT INTO book VALUES (141,'The Hawthorne Legacy',2021,384,3,9,8.5,'The Inheritance Games',2,NULL,NULL);
INSERT INTO book VALUES (142,'The Final Gambit',2022,400,3,9,8.5,'The Inheritance Games',3,NULL,NULL);
INSERT INTO book VALUES (143,'The Brothers Hawthorne',2023,416,3,9,8.5,'The Inheritance Games',4,NULL,NULL);

-- Psychological Thrillers
INSERT INTO book VALUES (144,'Sometimes I Lie',2017,320,2,9,7.5,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES (145,'Beautiful Ugly',2023,272,2,9,7.5,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES (146,'Behind Her Eyes',2017,352,2,9,7.5,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES (147,'Behind Closed Doors',2016,320,2,9,7.5,NULL,NULL,NULL,NULL);

-- Caraval Series by Stephanie Garber
INSERT INTO book VALUES (148,'Caraval',2017,416,3,5,8.5,'Caraval',1,NULL,NULL);
INSERT INTO book VALUES (149,'Legendary',2018,448,3,5,8.5,'Caraval',2,NULL,NULL);
INSERT INTO book VALUES (150,'Finale',2019,480,3,5,8.5,'Caraval',3,NULL,NULL);

-- More Psychological Thrillers
INSERT INTO book VALUES (151,'The Silent Patient',2019,336,2,9,8,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES (152,'Never Lie',2022,320,2,9,7.5,NULL,NULL,NULL,NULL);

-- The Housemaid Series by Freida McFadden
INSERT INTO book VALUES (153,'The Housemaid',2022,336,3,9,8,'The Housemaid',1,NULL,NULL);
INSERT INTO book VALUES (154,'The Housemaid''s Secret',2023,336,3,9,8,'The Housemaid',2,NULL,NULL);

-- Young Adult Thrillers
INSERT INTO book VALUES (155,'We Were Liars',2014,240,2,9,7,NULL,NULL,NULL,NULL);
INSERT INTO book VALUES (156,'Family of Liars',2022,288,2,9,7,NULL,NULL,NULL,NULL);

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

INSERT INTO book_author VALUES (140,122);
INSERT INTO book_author VALUES (141,122);
INSERT INTO book_author VALUES (142,122);
INSERT INTO book_author VALUES (143,122);

-- Sometimes I Lie & Beautiful Ugly (Alice Feeney - author_id 128)
INSERT INTO book_author VALUES (144,128);
INSERT INTO book_author VALUES (145,128);

-- Behind Her Eyes (Sarah Pinborough - author_id 127)
INSERT INTO book_author VALUES (146,127);

-- Behind Closed Doors (B.A. Paris - author_id 126)
INSERT INTO book_author VALUES (147,126);

-- Caraval series (Stephanie Garber - author_id 125)
INSERT INTO book_author VALUES (148,125);
INSERT INTO book_author VALUES (149,125);
INSERT INTO book_author VALUES (150,125);

-- The Silent Patient (Alex Michaelides - author_id 124)
INSERT INTO book_author VALUES (151,131);

-- Never Lie (Freida McFadden - author_id 129)
INSERT INTO book_author VALUES (152,129);

-- The Housemaid series (Freida McFadden - author_id 129)
INSERT INTO book_author VALUES (153,129);
INSERT INTO book_author VALUES (154,129);

-- We Were Liars & Family of Liars (E. Lockhart - author_id 130)
INSERT INTO book_author VALUES (155,130);
INSERT INTO book_author VALUES (156,130);

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

ALTER TABLE BOOK ADD SUMMARY CLOB;

UPDATE BOOK SET SUMMARY = 'Despite the tumor-shrinking medical miracle that has bought her a few years, Hazel has never been anything but terminal, her final chapter inscribed upon diagnosis. But when a gorgeous plot twist named Augustus Waters suddenly appears at Cancer Kid Support Group, Hazel''s story is about to be completely rewritten. Insightful, bold, irreverent, and raw, The Fault in Our Stars is award-winning author John Green''s most ambitious and heartbreaking work yet, brilliantly exploring the funny, thrilling, and tragic business of being alive and in love.' WHERE BOOK_ID = 120;

UPDATE BOOK SET SUMMARY = 'Seventeen-year-old Julie has her future all planned out—move out of her small town with her boyfriend Sam, attend college in the city, spend a summer in Japan. But then Sam dies. And everything changes.

Heartbroken, Julie skips his funeral, throws out his things, and tries everything to forget him and the tragic way he died. But a message Sam left behind in her yearbook forces back memories. Desperate to hear his voice one more time, Julie calls Sam’s cellphone just to listen to his voicemail.

And Sam picks up the phone.

In a miraculous turn of events, Julie’s been given a second chance at goodbye. The connection is temporary. But hearing Sam’s voice makes her fall for him all over again, and with each call it becomes harder to let him go. However, keeping her otherworldly calls with Sam a secret isn’t easy, especially when Julie witnesses the suffering Sam’s family is going through. Unable to stand by the sidelines and watch their shared loved ones in pain, Julie is torn between spilling the truth about her calls with Sam and risking their connection and losing him forever.' WHERE BOOK_ID = 121;

UPDATE BOOK SET SUMMARY = 'Aging and reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life. But when she chooses unknown magazine reporter Monique Grant for the job, no one is more astounded than Monique herself. Why her? Why now?

Monique is not exactly on top of the world. Her husband has left her, and her professional life is going nowhere. Regardless of why Evelyn has selected her to write her biography, Monique is determined to use this opportunity to jumpstart her career.' WHERE BOOK_ID = 122;

UPDATE BOOK SET SUMMARY = 'The only constant in life is change. Climate is a journey in embracing change both internally and externally. It guides readers through all the weather they face. From heartbreak to the storms we create inside our brain, Climate reminds readers to embrace the sun, storm, and rain. Most importantly, it emphasizes the beauty, value, and consistency of change.' WHERE BOOK_ID = 123;

UPDATE BOOK SET SUMMARY = 'Rich Dad Poor Dad is Robert's story of growing up with two dads — his real father and the father of his best friend, his rich dad — and the ways in which both men shaped his thoughts about money and investing. The book explodes the myth that you need to earn a high income to be rich and explains the difference between working for money and having your money work for you.' WHERE BOOK_ID = 124;

UPDATE BOOK SET SUMMARY = 'Matilda is a little girl who is far too good to be true. At age five-and-a-half she''s knocking off double-digit multiplication problems and blitz-reading Dickens. Even more remarkably, her classmates love her even though she''s a super-nerd and the teacher''s pet. But everything is not perfect in Matilda''s world. For starters she has two of the most idiotic, self-centered parents who ever lived. Then there''s the large, busty nightmare of a school principal, Miss Trunchbull, a former hammer-throwing champion who flings children at will, and is approximately as sympathetic as a bulldozer. Fortunately for Matilda, she has the inner resources to deal with such annoyances: astonishing intelligence, saintly patience, and an innate predilection for revenge.' WHERE BOOK_ID = 125;
UPDATE BOOK SET SUMMARY = '"We agree that we are overworked, and need a rest - A week on the rolling deep? - George suggests the river -"

And with the co-operation of several hampers of food and a covered boat, the three men (not forgetting the dog) set out on a hilarious voyage of mishaps up the Thames. When not falling in the river and getting lost in Hampton Court Maze, Jerome K. Jerome finds time to express his ideas on the world around - many of which have acquired a deeper fascination since the day at the end of the 19th century when this excursion was so lightly undertaken.' WHERE BOOK_ID = 126;

UPDATE BOOK SET SUMMARY = 'Greg Heffley finds himself thrust into a new year and a new school where undersize weaklings share the corridors with kids who are taller, meaner and already shaving. Desperate to prove his new found maturity, which only going up a grade can bring, Greg is happy to have his not-quite-so-cool sidekick, Rowley, along for the ride. But when Rowley''s star starts to rise, Greg tries to use his best friend''s popularity to his own advantage. Recorded in his diary with comic pictures and his very own words, this test of Greg and Rowley''s friendship unfolds with hilarious results.' WHERE BOOK_ID = 127;

UPDATE BOOK SET SUMMARY = 'Set amid the austere beauty of the North Carolina coast begins the story of Noah Calhoun, a rural Southerner recently returned from the Second World War. Noah is restoring a plantation home to its former glory, and he is haunted by images of the beautiful girl he met fourteen years earlier, a girl he loved like no other. Unable to find her, yet unwilling to forget the summer they spent together, Noah is content to live with only memories...until she unexpectedly returns to his town to see him once again.

Like a puzzle within a puzzle, the story of Noah and Allie is just the beginning. As it unfolds, their tale miraculously becomes something different, with much higher stakes. The result is a deeply moving portrait of love itself, the tender moments and the fundamental changes that affect us all. It is a story of miracles and emotions that will stay with you forever.' WHERE BOOK_ID = 128;

UPDATE BOOK SET SUMMARY = 'They had nothing in common until love gave them everything to lose . . .

Louisa Clark is an ordinary girl living an exceedingly ordinary life—steady boyfriend, close family—who has barely been farther afield than their tiny village. She takes a badly needed job working for ex–Master of the Universe Will Traynor, who is wheelchair bound after an accident. Will has always lived a huge life—big deals, extreme sports, worldwide travel—and now he’s pretty sure he cannot live the way he is.

Will is acerbic, moody, bossy—but Lou refuses to treat him with kid gloves, and soon his happiness means more to her than she expected. When she learns that Will has shocking plans of his own, she sets out to show him that life is still worth living.

A Love Story for this generation and perfect for fans of John Green’s The Fault in Our Stars, Me Before You brings to life two people who couldn’t have less in common—a heartbreakingly romantic novel that asks, What do you do when making the person you love happy also means breaking your own heart?' WHERE BOOK_ID = 129;

UPDATE BOOK SET SUMMARY = 'Pride and Prejudice has charmed generations of readers for more than two centuries. Jane Austen''s much-adapted novel is famed for its witty, spirited heroine, sensational romances, and deft remarks on the triumphs and pitfalls of social convention. Author Jane Austen was an English novelist whose works of social realism achieved unprecedented critical and popular success, though Austen herself remained an anonymous writer throughout her life.' WHERE BOOK_ID = 130;

UPDATE BOOK SET SUMMARY = 'Before. Miles “Pudge” Halter is done with his safe life at home. His whole life has been one big non-event, and his obsession with famous last words has only made him crave “the Great Perhaps” even more (Francois Rabelais, poet). He heads off to the sometimes crazy and anything-but-boring world of Culver Creek Boarding School, and his life becomes the opposite of safe. Because down the hall is Alaska Young. The gorgeous, clever, funny, sexy, self-destructive, screwed up, and utterly fascinating Alaska Young. She is an event unto herself. She pulls Pudge into her world, launches him into the Great Perhaps, and steals his heart. Then. . . .
After. Nothing is ever the same.' WHERE BOOK_ID = 131;

UPDATE BOOK SET SUMMARY = 'From the author of Me Before You, set in Depression-era America, a breathtaking story of five extraordinary women and their remarkable journey through the mountains of Kentucky and beyond.

Alice Wright marries handsome American Bennett Van Cleve hoping to escape her stifling life in England. But small-town Kentucky quickly proves equally claustrophobic, especially living alongside her overbearing father-in-law. So when a call goes out for a team of women to deliver books as part of Eleanor Roosevelt’s new traveling library, Alice signs on enthusiastically.

The leader, and soon Alice’s greatest ally, is Margery, a smart-talking, self-sufficient woman who’s never asked a man’s permission for anything. They will be joined by three other singular women who become known as the Packhorse Librarians of Kentucky.

What happens to them–and to the men they love–becomes an unforgettable drama of loyalty, justice, humanity and passion. These heroic women refuse to be cowed by men or by convention. And though they face all kinds of dangers in a landscape that is at times breathtakingly beautiful, at others brutal, they’re committed to their job: bringing books to people who have never had any, arming them with facts that will change their lives.

Based on a true story rooted in America’s past, The Giver of Stars is unparalleled in its scope and epic in its storytelling. Funny, heartbreaking, enthralling, it is destined to become a modern classic–a richly rewarding novel of women’s friendship, of true love, and of what happens when we reach beyond our grasp for the great beyond.' WHERE BOOK_ID = 132;

UPDATE BOOK SET SUMMARY = 'Seventeen-year-old Cassie is a natural at reading people. Piecing together the tiniest details, she can tell you who you are and what you want. But it’s not a skill that she’s ever taken seriously. That is, until the FBI come knocking: they’ve begun a classified program that uses exceptional teenagers to crack infamous cold cases, and they need Cassie.

What Cassie doesn’t realize is that there’s more at risk than a few unsolved homicides—especially when she’s sent to live with a group of teens whose gifts are as unusual as her own. Sarcastic, privileged Michael has a knack for reading emotions, which he uses to get inside Cassie’s head—and under her skin. Brooding Dean shares Cassie’s gift for profiling, but keeps her at arm’s length.

Soon, it becomes clear that no one in the Naturals program is what they seem. And when a new killer strikes, danger looms closer than Cassie could ever have imagined. Caught in a lethal game of cat and mouse with a killer, the Naturals are going to have to use all of their gifts just to survive.' WHERE BOOK_ID = 133;

UPDATE BOOK SET SUMMARY = 'Seventeen-year-old Cassie Hobbes has a gift for profiling people. Her talent has landed her a spot in an elite FBI program for teens with innate crime-solving abilities, and into some harrowing situations. After barely escaping a confrontation with an unbalanced killer obsessed with her mother’s murder, Cassie hopes she and the rest of the team can stick to solving cold cases from a distance.

But when victims of a brutal new serial killer start turning up, the Naturals are pulled into an active case that strikes too close to home: the killer is a perfect copycat of Dean’s incarcerated father—a man he’d do anything to forget. Forced deeper into a murderer’s psyche than ever before, will the Naturals be able to outsmart the enigmatic killer’s brutal mind games before this copycat twists them into his web for good?

With her trademark wit, brilliant plotting, and twists that no one will see coming, Jennifer Lynn Barnes will keep readers on the edge of their seats (and looking over their shoulders) as they race through the pages of this thrilling novel.' WHERE BOOK_ID = 134;

UPDATE BOOK SET SUMMARY = 'Three casinos. Three bodies. Three days.

After a string of brutal murders in Las Vegas, Cassie Hobbes and the Naturals are called in to investigate. But even with the team's unique profiling talents, these murders seem baffling: unlike many serial killers, this one uses different methods every time. All of the victims were killed in public, yet the killer does not show up on any tape. And each victim has a string of numbers tattooed on their wrist. Hidden in the numbers is a code—and the closer the Naturals come to unraveling the mystery, the more perilous the case becomes.

Meanwhile, Cassie is dealing with an equally dangerous and much more painful mystery. For the first time in years, there's been a break in her mother's case. As personal issues and tensions between the team mount, Cassie and the Naturals will be faced with impossible odds—and impossible choices.' WHERE BOOK_ID = 135;

UPDATE BOOK SET SUMMARY = 'New victims. New betrayals. New secrets.

When Cassie Hobbes joined the FBI’s Naturals program, she had one goal: uncover the truth about her mother’s murder. But now, everything Cassie thought she knew about what happened that night has been called into question. Her mother is alive, and the people holding her captive are more powerful—and dangerous—than anything the Naturals have faced so far. As Cassie and the team work to uncover the secrets of a group that has been killing in secret for generations, they find themselves racing a ticking clock.

The bodies begin piling up, the deaths hit closer and closer to home, and it soon becomes apparent that this time, the Naturals aren’t just hunting serial killers..' WHERE BOOK_ID = 136;

UPDATE BOOK SET SUMMARY = 'She is the very thing he’s spent his whole life hunting.
He is the very thing she’s spent her whole life pretending to be.

Only the extraordinary belong in the kingdom of Ilya—the exceptional, the empowered, the Elites.

The powers these Elites have possessed for decades were graciously gifted to them by the Plague, though not all were fortunate enough to both survive the sickness and reap the reward. Those born Ordinary are just that—ordinary. And when the king decreed that all Ordinaries be banished in order to preserve his Elite society, lacking an ability suddenly became a crime—making Paedyn Gray a felon by fate and a thief by necessity.

Surviving in the slums as an Ordinary is no simple task, and Paedyn knows this better than most. Having been trained by her father to be overly observant since she was a child, Paedyn poses as a Psychic in the crowded city, blending in with the Elites as best she can in order to stay alive and out of trouble. Easier said than done.

When Paeydn unsuspectingly saves one of Ilyas princes, she finds herself thrown into the Purging Trials. The brutal competition exists to showcase the Elites’ powers—the very thing Paedyn lacks. If the Trials and the opponents within them don’t kill her, the prince she’s fighting feelings for certainly will if he discovers what she is—completely Ordinary.' WHERE BOOK_ID = 137;

UPDATE BOOK SET SUMMARY = 'Paedyn and Kai battle with duty and desire in this highly anticipated second installment in the sizzling and epic romantic fantasy trilogy that’s packed with spicy tension and edge-of-your-seat betrayal.

The kingdom of Ilya is in turmoil…

After surviving the Purging Trials, Ordinary-born Paedyn Gray has killed the King and kickstarted a Resistance throughout the land. Now she’s running from the one person she had wanted to run to.

Kai Azer is now Ilya’s Enforcer, loyal to his brother Kitt, the new King. He has vowed to find Paedyn and bring her to justice.

Across the deadly Scorches, and deep into the hostile city of Dor, Kai pursues the one person he wishes he didn’t have to. But in a city without Elites, the balance between the hunter and hunted shifts—and the battle between duty and desire is deadly.' WHERE BOOK_ID = 138;

UPDATE BOOK SET SUMMARY = 'She fled as a betrayer. She returned as a bride-to-be. Ordinary-born Paedyn Gray was prepared for a death sentence, not a proposal. After killing the king, marriage to his son, Kitt, was the last thing she or the kingdom expected. But with her role as queen, Paedyn would have the chance to unite Ilya and create a kingdom where Ordinaries live alongside Elites without fear. With a decision looming, Paedyn battles between her head, her heart, and the hidden trials she now faces. Through it all, Kai Azer fights to call her his, even if it means defying his king. Are vows strong enough to unite a kingdom? Or will betrayal break them? The choice between sacrifice and self has never been more difficult or deadly. The final installment in the epic and sizzling fantasy romance trilogy that has taken the world by storm.' WHERE BOOK_ID = 139;

COMMIT;

SELECT BOOK_ID, TITLE, STOCK FROM BOOK;

-- Make these books unavailable (stock = 0)
UPDATE BOOK SET STOCK = 0 WHERE BOOK_ID IN (121, 124, 127, 130, 133, 136, 139);
COMMIT;
ALTER TABLE BOOK ADD COVER_URL VARCHAR2(500);
COMMIT;
SELECT GENRE_ID, NAME FROM GENRE ORDER BY GENRE_ID;

SELECT user_id, full_name, email, password_hash, role 
FROM users;

SELECT AUTHOR_ID, NAME FROM AUTHOR ORDER BY AUTHOR_ID DESC FETCH FIRST 5 ROWS ONLY;

-- Check BOOK_AUTHOR table to see what's there
SELECT * FROM BOOK_AUTHOR WHERE BOOK_ID = 140;

-- Check if book 140 exists
SELECT * FROM BOOK WHERE BOOK_ID = 140;

SELECT COLUMN_NAME FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'BOOK';

SELECT BOOK_ID, TITLE, COVER_URL FROM BOOK WHERE BOOK_ID = 140;
SELECT author_id, name FROM author ORDER BY author_id;