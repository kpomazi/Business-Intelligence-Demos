-- Mennyi az el�fizet�k �tlag�letkora? Hogyan oszlik el a koroszt�lyok k�z�tt (-17, 18-34, 35-59, 60-)?
select avg(age) from customer
select '-17', count(*) from customer where age<=17
select '18-34', count(*) from customer where age>17 and age <= 34
select '35-59', count(*) from customer where age>34 and age <= 59
select '60-', count(*) from customer where age>59




-- Mennyi id�t telefon�lnak �tlagosan az el�fizet�k az egyes heteken?

-- a DATEPART egy d�tumb�l vissza tudja adni az �vet, h�napot, napot, hetet
-- csoportos�tjuk el�fizet�nk�nt �s hetenk�nt �s vessz�k a telefon�l�s hosszok �tlag�t
select UserID, DATEPART(week, Timestamp) as week, avg(Length) as avg_on_week from CallLog
group by UserID, DATEPART(week, Timestamp)
order by UserID, week




-- A n�k vagy a f�rfiak telefon�lnak hosszabban? Sz�moljuk ki a leghosszabb h�v�st a k�t nemre,
-- de el�sz�r sz�rj�k ki az extr�m hossz� h�v�sokat (ezeket outliernek szok�s h�vni).
-- Egy lehets�ges m�dszer a kisz�r�sre, ha felt�telezz�k, hogy a h�v�sok norm�l eloszl�s szerint alakulnak
-- (val�s�gban: nem, ink�bb Posisson vagy Weibull), a k�tszeres sz�r�son t�li elemeket (5%) eldobjuk.

-- mind a k�t t�bl�ra sz�ks�g�nk lesz, nemenk�nt csoportos�tva a leghosszabb h�v�sra vagyunk k�v�ncsiak
select Gender, max(Length) as LongestCall
from CallLog join Customer on CallLog.UserID = Customer.UserID
join (
	-- ez a bels� lek�rdez�s sz�molja ki a nemenk�nti �tlagot �s a k�tszeres sz�r�st
select Gender as FilterGender, avg(Length) as AvgLength, 2*STDEVP(Length) StdDeviation
	from CallLog join Customer on CallLog.UserID = Customer.UserID
	group by Gender ) filter
on Gender = filter.FilterGender
-- ezzel sz�rj�k ki a k�tszeres sz�r�sn�l hosszabb h�v�sokat
and Length <= filter.AvgLength + filter.StdDeviation 
group by Gender






-- K�sz�ts�nk egy n�zetet, ami egy gyors jelent�sk�nt m�k�dhet. Ezt a n�zetet felhaszn�lhatjuk,
-- hogy �sszehasonl�tsunk k�t hetet. El�fizet�nk�nt szeretn�nk l�tni az el�z� hetet �s az aktu�lis
-- hetet, valamint, hogy milyen ir�nyba v�ltozott a telefon�l�sok �tlaga. Az egyszer�s�g kedv��rt
-- a v�ltoz�st egy + vagy � jellel jel�lj�k.

-- n�zet l�trehoz�sa
create view WeeklyAverage as
select UserID, DATEPART(week, Timestamp) as week, avg(Length) as avg_on_week from CallLog
group by UserID, DATEPART(week, Timestamp)

-- A + �s - jelhez egy seg�d f�ggv�ny.
CREATE FUNCTION PlusMinusNoChange(
	@val1 int, @val2 int
)
RETURNS char(1)
AS
BEGIN
	if @val1 < @val2
		return '-'
	else if @val1 > @val2
		return '+'
	return '='
END
GO

-- Futtassuk e heteket �sszehasonl�t� lek�rdez�st.
select top 5 w1.UserId, w1.week, w2.week, dbo.PlusMinusNoChange(w1.avg_on_week, w2.avg_on_week) as change
from WeeklyAverage w1 join WeeklyAverage w2 on w1.UserId = w2.UserId
where w1.week < w2.week
