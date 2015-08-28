-- *******************************************
-- 2. feladat
-- staging t�bla l�trehoz�sa
CREATE TABLE [RawImport]
(
	[UserId] [int] NULL,
	[Timestamp] [datetime] NULL,
	[Length] [int] NULL,
	[UserGender] [char](1) NULL,
	[UserAge] [int] NULL
)
GO



-- *******************************************
-- 3. feladat
-- adatok import�l�sa CSV-b�l
BULK INSERT [RawImport]
FROM 'c:\import.csv'
WITH
(
	FIELDTERMINATOR =';',
	ROWTERMINATOR ='\n',
	FIRSTROW = 2
);



-- *******************************************
-- 5. feladat
-- adatok normaliz�l�sa: sz�tbont�s k�t t�bl�ra

-- t�bl�k l�trehoz�sa
CREATE TABLE [dbo].[Customer](
	[UserID] [int] NOT NULL,
	[Gender] [char](1) NULL,
	[Age] [int] NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([UserID] ASC)
)
GO
CREATE TABLE [dbo].[CallLog](
	[Timestamp] [datetime] NULL,
	[Length] [int] NULL,
	[UserID] [int] NULL
)
GO
ALTER TABLE [dbo].[CallLog]  WITH CHECK ADD  CONSTRAINT [FK_CallLog_Customer] FOREIGN KEY([UserID])
REFERENCES [dbo].[Customer] ([UserID])
GO


-- adatok sz�tpakol�sa a k�t t�bl�ba
-- kurzorhoz sz�ks�ges v�ltoz�k
declare @userid int
declare @length int
declare @userage int
declare @timestamp datetime
declare @usergender char(1)

-- kurzorhoz defini�l�sa �s az iter�l�s a kurzoron
declare cur cursor for select UserId, Timestamp, Length, UserGender, UserAge from RawImport FAST_FORWARD
open cur
fetch next from cur into @userid, @timestamp, @length, @usergender, @userage
while @@FETCH_STATUS = 0
begin
	-- �j Customer, ha m�g nem l�tezik
if not exists(select * from Customer where Customer.UserID = @userid)
	begin
		insert into Customer(UserId,Gender,Age) values (@userid, @usergender, @userage)
	end
	-- a nem felhaszn�l�i adatok felv�tele a m�sik t�lb�ba
insert into CallLog(Timestamp, Length, UserID) values(@timestamp, @length, @userid)

	fetch next from cur into @userid, @timestamp, @length, @usergender, @userage
end
close cur
deallocate cur

-- az import�lt adatok t�rl�se a staging t�bl�b�l
delete from RawImport
