-- You find yourself as the newest dev in Google, your first task is to redesign a database for a lighter version of Youtube that should 
-- give the users the ability to monetize their videos and also have a function/procedure to compute the profit on videos they make based 
-- on the countries they posted from using their exchange rate and also functions to let a viewer know how many hours he has spent on 
-- YouTube and also let the youtuber know how many times his video has been watched.

--CREATE DATABASE YouTube
USE YouTube;
CREATE TABLE countries(code int NOT NULL UNIQUE, name nvarchar(50) NOT NULL UNIQUE, region varchar(100));

CREATE TABLE countryRates(countryCode int NOT NULL UNIQUE, rate money NOT NULL);

CREATE TABLE socialmedia(code int NOT NULL, name varchar(100) NOT NULL UNIQUE);

CREATE TABLE licences(id int NOT NULL, name varchar(100) NOT NULL UNIQUE);

CREATE TABLE categories(code int NOT NULL IDENTITY(1,1) PRIMARY KEY, title varchar(255) NOT NULL);

CREATE TABLE contentProviders(id int NOT NULL, name nvarchar(200) NOT NULL, dateJoined date NOT NULL, description nvarchar(max), countryCode int NOT NULL, 
					emailAddress varchar(50) NOT NULL, numberOfSubscribers int NOT NULL, monetization bit NOT NULL, category varchar(100) NOT NULL, tags ntext);
-- assign default value of 0 for account with < 1k subs and < 4k public watch hours
ALTER TABLE contentProviders
ADD CONSTRAINT df_monetization
DEFAULT 0 FOR monetization;

CREATE TABLE sociallinks(contentProviderId int NOT NULL, socialcode int NOT NULL, httplink nvarchar(100) NOT NULL);

CREATE TABLE videos(id int NOT NULL, contentProviderId int NOT NULL, dateUploaded datetime NOT NULL, title varchar(100) NOT NULL UNIQUE, 
                   description varchar(max), numberOfViews bigint NOT NULL, likes int NOT NULL, dislikes int NOT NULL, licenseId int NOT NULL);
ALTER TABLE videos
ADD CONSTRAINT df_views
DEFAULT 0 FOR numberOfViews;

ALTER TABLE videos
ADD CONSTRAINT df_likes
DEFAULT 0 FOR likes;

ALTER TABLE videos
ADD CONSTRAINT df_dislikes
DEFAULT 0 FOR dislikes;

ALTER TABLE videos
ADD CONSTRAINT df_license
DEFAULT 1 FOR licenseId;

ALTER TABLE videos ADD categoryCode int CONSTRAINT df_category DEFAULT 1;
ALTER TABLE videos ALTER COLUMN categoryCode int NOT NULL;

-- CREATE TABLE subscriptions(contentProviderId int NOT NULL, title varchar(200) NOT NULL, dateSubscribed date NOT NULL);
CREATE TABLE earnings(contentProviderId int NOT NULL, videoId int NOT NULL, numberOfViews bigint NOT NULL, revenueGained money NOT NULL);
ALTER TABLE earnings
ADD CONSTRAINT df_revenue
DEFAULT 0 FOR revenueGained;

CREATE TABLE contentProviderActivityLog(contentProviderId int NOT NULL, videoId int NOT NULL, dateWatched date NOT NULL,
			timeStarted time NOT NULL, timeEnded time NOT NULL, comments varchar(500), liked bit NOT NULL, disliked bit NOT NULL);

CREATE TABLE consumers(id int NOT NULL, ipaddress nvarchar(16), countryCode int NOT NULL);

CREATE TABLE consumerActivityLog(consumerId int NOT NULL, videoId int NOT NULL, dateWatched date NOT NULL,
			timeStarted time NOT NULL, timeEnded time NOT NULL, comments varchar(500), liked bit NOT NULL, disliked bit NOT NULL);
			
-- Stored Procedures/Functions
--CREATE PROCEDURE ShowAllData @tableName TABLE
--AS
--SELECT * FROM @tableName;
--GO

CREATE PROCEDURE UpdateViews @videoId int
AS
UPDATE videos SET numberOfViews += 1 WHERE id = @videoId;
UPDATE earnings SET numberOfViews +=1 WHERE videoId = @videoId;
GO

CREATE PROCEDURE UpdateLikesinVideos @videoId int
AS
UPDATE videos SET likes +=  
(SELECT /*COUNT()*/ liked FROM contentProviderActivityLog WHERE videoId = @videoId)
WHERE id = @videoId;
GO

CREATE PROCEDURE UpdateDislikesinVideos @videoId int
AS
UPDATE videos SET dislikes += 
(SELECT disliked FROM contentProviderActivityLog WHERE videoId = @videoId)
WHERE id = @videoId;
GO

CREATE PROCEDURE UpdateEarnings @videoId int
AS
IF EXISTS (SELECT @videoId FROM earnings WHERE videoId = @videoId)
	BEGIN
		-- UPDATE earnings SET numberOfViews = (SELECT numberOfViews FROM videos WHERE @videoId = earnings.videoId); -- WHERE videoId = @videoId;
		UPDATE earnings SET revenueGained += (SELECT videos.numberOfViews * countryRates.rate FROM videos, countryRates 
		WHERE countryCode = (SELECT countryCode FROM contentProviders 
		WHERE contentProviders.id = (SELECT contentProviderId FROM videos WHERE id = @videoId)) AND videos.id = @videoId);
	END
ELSE
	BEGIN
		INSERT INTO earnings(contentProviderId, videoId, numberOfViews) SELECT contentProviderId, id, numberOfViews FROM videos WHERE id = @videoId;
		UPDATE earnings SET revenueGained += (SELECT videos.numberOfViews * countryRates.rate FROM videos, countryRates 
		WHERE countryCode = (SELECT countryCode FROM contentProviders 
		WHERE contentProviders.id = (SELECT contentProviderId FROM videos WHERE id = @videoId)) AND videos.id = @videoId);
	END
GO

SELECT videos.contentProviderId ,videos.id, videos.title, countryRates.countryCode, countryRates.rate, videos.numberOfViews * countryRates.rate AS revenue 
FROM videos, countryRates 
WHERE countryCode = (SELECT countryCode FROM contentProviders 
WHERE contentProviders.id = (SELECT contentProviderId FROM videos WHERE id = 100)) --AND videos.id = 2;

SELECT * FROM countryRates;
SELECT * FROM videos;
-- populating database and DBOs
--Countries
INSERT INTO countries VALUES('United States', 'North America');
INSERT INTO countries VALUES('United Kingdom', 'Europe');
INSERT INTO countries VALUES('India', 'Asia & Pacific');
INSERT INTO countries VALUES('Brazil', 'South America');
INSERT INTO countries VALUES('Canada', 'North America');
INSERT INTO countries VALUES('Burundi', 'Africa');
INSERT INTO countries VALUES('Nigeria', 'Africa');
INSERT INTO countries VALUES('Ghana', 'Africa');
INSERT INTO countries VALUES('Germany', 'Europe');
INSERT INTO countries VALUES('Argentina', 'South America');
SELECT * FROM countries;

-- Profit per country
INSERT INTO countryRates VALUES(382);
INSERT INTO countryRates VALUES(520);
INSERT INTO countryRates VALUES(5.19);
INSERT INTO countryRates VALUES(72);
INSERT INTO countryRates VALUES(301);
INSERT INTO countryRates VALUES(0.19);
INSERT INTO countryRates VALUES(200);
INSERT INTO countryRates VALUES(65);
INSERT INTO countryRates VALUES(465);
INSERT INTO countryRates VALUES(4.47);
SELECT * FROM countryRates;

-- Social media
INSERT INTO socialmedia VALUES('Twitter');
INSERT INTO socialmedia VALUES('Linkedin');
INSERT INTO socialmedia VALUES('Facebook');
INSERT INTO socialmedia VALUES('Instagram');
INSERT INTO socialmedia VALUES('Udemy Courses');
INSERT INTO socialmedia VALUES('Patreon');
INSERT INTO socialmedia VALUES('Paypal Donate');
SELECT * FROM socialmedia;

--Licenses
INSERT INTO licences VALUES('Standard YouTube License');
INSERT INTO licences VALUES('Creative Commons - Attribution');
SELECT * FROM licences;

--Categories for videos
INSERT INTO categories VALUES ('People and Blogs');
INSERT INTO categories VALUES ('Cars and Vehicles');
INSERT INTO categories VALUES ('Music');
INSERT INTO categories VALUES ('Pets and Animals');
INSERT INTO categories VALUES ('Sports');
INSERT INTO categories VALUES ('Travel and Events');
INSERT INTO categories VALUES ('Gaming');
INSERT INTO categories VALUES ('Comedy');
INSERT INTO categories VALUES ('Entertainment');
INSERT INTO categories VALUES ('News and Politics');
INSERT INTO categories VALUES ('How-to and style');
INSERT INTO categories VALUES ('Education');
SELECT * FROM categories;

--ContentProviders/Account holders
INSERT INTO contentProviders(name, dateJoined, description, countryCode , emailAddress, numberOfSubscribers)
VALUES('Morgan Jay', '2013-05-13', '.NET videos and more...', 70, 'james.morgan@thebulb.africa', 3);
INSERT INTO contentProviders(name, dateJoined, description, countryCode, emailAddress, numberOfSubscribers) 
VALUES('Chiamaka Fortune', '2020-10-18', 'Am-a-class guru, watch my videos and you will live long', 70, 'chiamaka@thebulb.africa', 20);
INSERT INTO contentProviders (name, dateJoined, description, countryCode, emailAddress, numberOfSubscribers, monetization)
VALUES('THE NET NINJA','2015-04-08','Black-belt your web development skills.', 20,'netninja@gmail.com', 630, 0), 
('MindValley','2010-03-28','Free your mind and jump out of the valley', 10,'mindvalley@xyz.com', 500000, 1),
('Ghost Stuff','2020-07-18','Ghost boy, you can"t see me', 30,'unknown@ghost.com', 100,0),
('La Liga','2000-01-01','All your La Liga football matches', 40,'laliga@fifa.com', 30, 0),
('Traversy Media','2016-08-08','Upskill and have fun!', 50,'traversymedia@outlook.com', 1000000, 1),
('Bedimcode','2020-02-23','Hi, I am a freelance web developer passionate about creating 
	and designing beautiful desktop and mobile web interfaces developed in HTML CSS & JavaScript.  
	It is a pleasure to have you here. SUBSCRIBE, and see you in a next video.', 100,'', 164000, 1),
('MFM Ministries','2011-04-27','This is the Official YouTube  Channel of Mountain Of Fire and 
	Miracles Ministries which is a full gospel ministry devoted to the Revival of Apostolic Signs, 
	Holy Ghost fireworks and the unlimited demonstration of the power of God to deliver to the uttermost.', 50,'mfm@google.com', 117000, 1),
('NLU','2013-05-28','You can find us ANYWHERE you listen to your podcasts! Apple, Spotify, Stitcher...etc', 90,'nextlevelstuff@gmail.co.uk', 413, 0),
('CS50','2012-12-15','A focused topic, but broadly applicable skills. CS50 is the quintessential Harvard (and Yale!) course.', 60,'cs50@outlook.com', 619000, 1),
('Simon Sinek','2009-09-15','Simon Sinek is an unshakable optimist. He believes in a bright future and our ability to build it together.', 80,'simonsinek@yahoo.com', 1020000, 1);
SELECT * FROM contentProviders;


--Social Links
INSERT INTO sociallinks(contentProviderId, socialcode, httplink) VALUES (100, 10, 'https://twitter.com/jay__jm');
INSERT INTO sociallinks(contentProviderId, socialcode, httplink) VALUES (200, 20, 'https://google.com');
SELECT * FROM sociallinks;

-- Videos/content created
INSERT INTO videos (contentProviderId, dateUploaded, title)
VALUES(100, '2020-12-26', 'Cloudinary Tutorial');
INSERT INTO videos (contentProviderId, dateUploaded, title, categoryCode)
VALUES(100, '2020-12-29', 'My Music Compilation', 3);
INSERT INTO videos(contentProviderId, dateUploaded, title, description, licenseId, categoryCode)
VALUES(200, '2021-01-02', 'Making money from youtube', 'Carry out a random act of kindness, with no expectation of reward, safe in the knowledge that one day someone might do the same for you.',1, 11);
INSERT INTO videos(contentProviderId, dateUploaded, title, description, licenseId, categoryCode)
VALUES(200, SYSDATETIME(), 'Me at the Zoo', 'Second video on Youtube.', 1 , 4);
INSERT INTO videos(contentProviderId, dateUploaded, title, description, licenseId, categoryCode)
VALUES(300, '2019-02-03', 'Full React Course', 'Learn React in 1 hour.', 1, 6),
(400, '2015-12-23', 'Becoming Smart', 'HAHAHA', 1, 4),
(500, '2020-11-03', '.....', '....', 2, 9),
(600, SYSDATETIME(), 'Sevilla vs Barcelona 2020/2021 Highlights', 'Match Summary', 1, 3),
(700, '2020-12-30', 'Web Development in 2021', 'Become a spiderman', 1, 2),
(800, '2021-01-03', 'Something Nice', '0023ujdusuud', 2, 8),
(900, '2014-12-09', 'Fire prayers for 24 hours', '', 1, 7),
(1000, '2020-05-13', 'Learn how to survive life', 'LOVE, HEALTH and WEALTH', 1, 5);

SELECT * FROM videos;

-- ContentProviderActivity
INSERT INTO contentProviderActivityLog VALUES(100, 3, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), '4:10 PM', 'hey', 1, 0);
EXEC UpdateViews @videoId = 3;
EXEC UpdateEarnings @videoId = 3;

INSERT INTO contentProviderActivityLog 
VALUES(200, 1, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), '12:10 AM', '', 1, 0);
EXEC UpdateViews @videoId = 1;
EXEC UpdateEarnings @videoId = 1;

INSERT INTO contentProviderActivityLog 
VALUES(100, 1, '2020-12-31', '9:00AM', '10:10 AM', 'I loved this!', 1, 0);
EXEC UpdateViews @videoId = 1;
EXEC UpdateEarnings @videoId = 1;

INSERT INTO contentProviderActivityLog VALUES(100, 4, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), '12:10 AM', '', 1, 0);
EXEC UpdateViews @videoId = 4;
EXEC UpdateEarnings @videoId = 4;

INSERT INTO contentProviderActivityLog VALUES(400, 11, '2016-07-29', CAST(GETDATE() AS TIME), '12:10 AM', '', 0, 1);
EXEC UpdateViews @videoId = 11;
EXEC UpdateEarnings @videoId = 11;

INSERT INTO contentProviderActivityLog VALUES(300, 3, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME), '4:10 AM', 'good video', 1, 0);
INSERT INTO contentProviderActivityLog VALUES(200, 5, '2021-01-01', CAST(GETDATE() AS TIME), '12:10 AM', '', 1, 0);

SELECT * FROM contentProviderActivityLog;
TRUNCATE TABLE earnings;
TRUNCATE TABLE videos;
SELECT * FROM videos;
SELECT * FROM earnings;

-- Consumer


-- Consumer activity