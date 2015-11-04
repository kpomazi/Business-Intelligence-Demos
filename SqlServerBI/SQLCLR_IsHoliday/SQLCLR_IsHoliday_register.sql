-- Enged�lyezz�k a CLR integr�ci�t az SQL szerveren
sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO

-- A tov�bbiak a dem� adatb�zisunkon futtatand�.
use [BIDemo]
go

-- Regisztr�ljuk a .NET dll-t az SQL szerverben.
CREATE ASSEMBLY IsHolidayUdf FROM '<path-to-dll>\SQLCLR_IsHoliday.dll';
GO
CREATE FUNCTION dbo.IsHoliday(@dt datetime)
RETURNS BIT 
AS EXTERNAL NAME IsHolidayUdf.[SQLCLR_IsHoliday.IsHolidayHelper].IsHoliday;
GO


-- Tesztel�s: aktu�lis �vre �tlagoljuk az �nnepnapok telefon�l�sait, �s a t�bbi nap telefon�l�sait
select avg([length]) as avg_call_length_weekday
from [CallLog]
where datepart(year, [Timestamp]) = datepart(year, GETDATE())
and dbo.IsHoliday([Timestamp]) = 0

select avg([length]) as avg_call_length_holiday
from [CallLog]
where datepart(year, [Timestamp]) = datepart(year, GETDATE())
and dbo.IsHoliday([Timestamp]) = 1
