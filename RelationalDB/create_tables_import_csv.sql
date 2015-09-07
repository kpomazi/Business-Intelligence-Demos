-- *******************************************
-- 2. feladat
-- staging t�bla l�trehoz�sa
CREATE TABLE [Import]
(
	[UserId] [int] NULL,
	[Timestamp] [datetime] NULL,
	[Type] [char](1) NULL,
	[Length] [int] NULL,
	[UserGender] [char](1) NULL,
	[UserAge] [int] NULL
)
GO



-- *******************************************
-- 3. feladat
-- adatok import�l�sa CSV-b�l
BULK INSERT [Import]
FROM 'GY-traffic-log-csv.csv'
WITH
(
	FIELDTERMINATOR =',',
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
CREATE TABLE [dbo].[Traffic](
	[Timestamp] [datetime] NULL, 
	[Type] [char](1) NULL,
	[Length] [int] NULL,
	[UserID] [int] NULL
)
GO
ALTER TABLE [dbo].[Traffic]  WITH CHECK ADD  CONSTRAINT [FK_Traffic_Customer] FOREIGN KEY([UserID])
REFERENCES [dbo].[Customer] ([UserID])
GO



-- adatok sz�tpakol�sa a k�t t�bl�ba
-- kurzorhoz sz�ks�ges v�ltoz�k
declare @userid int
declare @type char(1)
declare @length int
declare @userage int
declare @timestamp datetime
declare @usergender char(1)

-- kurzorhoz defini�l�sa �s az iter�l�s a kurzoron
declare cur cursor for select [UserId], [Timestamp], [Type], [Length], [UserGender], [UserAge] from [Import] FAST_FORWARD
open cur
fetch next from cur into @userid, @timestamp, @type, @length, @usergender, @userage
while @@FETCH_STATUS = 0
begin
	-- �j Customer, ha m�g nem l�tezik
	if not exists(select * from Customer where Customer.UserID = @userid)
	begin
		insert into Customer([UserId],[Gender],[Age]) values (@userid, @usergender, @userage)
	end
	-- a nem felhaszn�l�i adatok felv�tele a m�sik t�lb�ba
	insert into Traffic([Timestamp],[Type],[Length],[UserID]) values(@timestamp, @type, @length, @userid)

	fetch next from cur into @userid, @timestamp, @type, @length, @usergender, @userage
end
close cur
deallocate cur

-- az import�lt adatok t�rl�se a staging t�bl�b�l
delete from [Import]
