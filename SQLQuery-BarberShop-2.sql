use [master];
go

if db_id('Barber') is not null
begin
	drop database [Barber];
end
go

create database [Barber];
go

use [Barber];
go

CREATE TABLE barbers (
    barber_id INT PRIMARY KEY,
    full_name NVARCHAR(100),
    gender NVARCHAR(10),
    phone_number NVARCHAR(20),
    email NVARCHAR(100),
    date_of_birth DATE,
    hire_date DATE,
    position NVARCHAR(50),
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20)
);

CREATE TABLE services (
    service_id INT PRIMARY KEY,
    barber_id INT,
    service_name NVARCHAR(100),
    price FLOAT,
    duration INT,
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id)
);

CREATE TABLE schedules (
    schedule_id INT PRIMARY KEY,
    barber_id INT,
    availability_date DATE,
    availability_time TIME,
    client_id INT,
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE clients (
    client_id INT PRIMARY KEY,
    full_name NVARCHAR(100),
    phone_number NVARCHAR(20),
    email NVARCHAR(100),
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20)
);

CREATE TABLE visits (
    visit_id INT PRIMARY KEY,
    client_id INT,
    barber_id INT,
    service_id INT,
    visit_date DATE,
    total_cost FLOAT,
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id)
);




 -- 1. ������� ���������� � �������, ������� �������� � ��� ������� ������ ����
 SELECT TOP 1 *
FROM barbers
ORDER BY DATEDIFF(day, hire_date, GETDATE()) DESC;

 -- 2. ������� ���������� � �������, ������� �������� ��� ��������� ���������� �������� � ��������� ������������. ���� ���������� � �������� ���������
 CREATE PROCEDURE GetMaxClientsBarber (@start_date DATE, @end_date DATE)
AS
BEGIN
    SELECT TOP 1 b.*
    FROM barbers b
    JOIN visits v ON b.barber_id = v.barber_id
    WHERE v.visit_date BETWEEN @start_date AND @end_date
    GROUP BY b.barber_id, b.full_name
    ORDER BY COUNT(*) DESC;
END;

 -- 3. ������� ���������� � �������, ������� ������� ������ ��� ������������ ���������� ���
 SELECT TOP 1 c.*, COUNT(*) as visit_count
FROM clients c
JOIN visits v ON c.client_id = v.client_id
GROUP BY c.client_id, c.full_name
ORDER BY COUNT(*) DESC;

-- 4. ������� ���������� � �������, ������� �������� � ��� ������� ������������ ���������� �����
SELECT TOP 1 c.*, SUM(v.total_cost) as total_spent
FROM clients c
JOIN visits v ON c.client_id = v.client_id
GROUP BY c.client_id, c.full_name
ORDER BY SUM(v.total_cost) DESC;

 -- 5. ������� ���������� � ����� ������� �� ������� ������ � ����������
 SELECT TOP 1 s.*
FROM services s
ORDER BY s.duration DESC;


--������� (����� 2 (������� 2))
--1. ������� ���������� � ����� ���������� ������� (��
--���������� ��������)
SELECT ClientVisitsArchive.BarberID, COUNT(ClientVisitsArchive.BarberID) AS 'Number of clients',
  Barbers.ID, Barbers.Name, Barbers.LastName, Barbers.Patronymic, Barbers.Gender, Barbers.Phone, Barbers.Email, 
  Barbers.DateOfBirth, Barbers.DateOfEmployment, Barbers.BarberPositionID, Barbers.ServicesID
FROM ClientVisitsArchive JOIN
Barbers ON ClientVisitsArchive.BarberID = Barbers.ID
GROUP BY ClientVisitsArchive.BarberID,
  Barbers.ID, Barbers.Name, Barbers.LastName, Barbers.Patronymic, Barbers.Gender, Barbers.Phone, Barbers.Email, 
  Barbers.DateOfBirth, Barbers.DateOfEmployment, Barbers.BarberPositionID, Barbers.ServicesID
HAVING COUNT(ClientVisitsArchive.BarberID) = (
  SELECT (MAX(ValueClients))
  FROM (
    SELECT ClientVisitsArchive.BarberID, COUNT(ClientVisitsArchive.BarberID) AS ValueClients
    FROM ClientVisitsArchive
    GROUP BY ClientVisitsArchive.BarberID
  ) AS ValueClients
)


--2. ������� ���-3 �������� �� ����� (�� ����� �����, ����������� ���������)
SELECT TOP 3 SUM(ListServices.Price) AS SumPrice,
      Barbers.ID, Barbers.Name, Barbers.LastName, Barbers.Patronymic, Barbers.Gender, Barbers.Phone, Barbers.Email, 
      Barbers.DateOfBirth, Barbers.DateOfEmployment, Barbers.BarberPositionID, Barbers.ServicesID
    FROM ListServices
    JOIN ClientVisitsArchive ON ClientVisitsArchive.ServicesID = ListServices.ID
    JOIN Clients ON ClientVisitsArchive.ClientID = Clients.ID
    JOIN Barbers ON ClientVisitsArchive.BarberID = Barbers.ID
    GROUP BY
      Barbers.ID, Barbers.Name, Barbers.LastName, Barbers.Patronymic, Barbers.Gender, Barbers.Phone, Barbers.Email, 
      Barbers.DateOfBirth, Barbers.DateOfEmployment, Barbers.BarberPositionID, Barbers.ServicesID
    ORDER BY SumPrice DESC


--3. ������� ���-3 �������� �� �� ����� (�� ������� ������).
--���������� ��������� �������� �� ������ 30
SELECT TOP 3 Feedbacks.Rating, Feedbacks.ClientReviews, Feedbacks.BarberFromId, Feedbacks.ClientWhomID
FROM Feedbacks
WHERE Feedbacks.Rating = '������'
GROUP BY Feedbacks.Rating, Feedbacks.ClientReviews, Feedbacks.BarberFromId, Feedbacks.ClientWhomID
HAVING COUNT(Feedbacks.ClientWhomID) >= 1 --(30)


--4. �������� ���������� �� ���� ����������� �������. ���������� � ������� � ��� ��������� � �������� ���������
CREATE PROC PrintScheduleBarbers
  @barberID int,
  @availabilityDateTime datetime
AS
  SELECT*
  FROM BarbersSchedule 
  JOIN Barbers ON BarbersSchedule.BarberID = Barbers.ID
  WHERE BarbersSchedule.BarberID = @barberID AND BarbersSchedule.AvailabilityDateTime = @availabilityDateTime
GO

EXEC PrintScheduleBarbers 1, '2024-05-05 10:00:00.000'
GO


--5. �������� ��������� ��������� ����� �� ������ ����������� �������. ���������� � ������� � ��� ���������
--� �������� ���������
CREATE PROC PrintBarbersFreeTime
  @barbersName nvarchar(100),
  @barbersSchedule datetime
AS
  SELECT Barbers.ID, Barbers.Name, Barbers.LastName, Barbers.Patronymic, Barbers.Gender, Barbers.Phone, Barbers.Email, 
      Barbers.DateOfBirth, Barbers.DateOfEmployment, Barbers.BarberPositionID, Barbers.ServicesID
  FROM BarbersSchedule
  JOIN Barbers ON BarbersSchedule.BarberID = Barbers.ID
  WHERE BarbersSchedule.AvailabilityDateTime != @barbersSchedule
    AND Barbers.Name = @barbersName
    AND (DATEDIFF(DAY, @barbersSchedule, GETDATE()) < 0
    OR DATEDIFF(MONTH, @barbersSchedule, GETDATE()) < 0
    OR DATEDIFF(YEAR, @barbersSchedule, GETDATE()) < 0)
GO

EXEC PrintBarbersFreeTime '����', '2024-05-10 10:00:00.000'
GO


--6. ��������� � ����� ���������� � ���� ��� �����������
--������� (��� �� ������, ������� ��������� � �������)


--7. ��������� ���������� ������� � ������� �� ��� �������
--����� � ����
CREATE TRIGGER IsFreeTime
ON BarbersSchedule
INSTEAD OF INSERT
AS
BEGIN
  IF EXISTS (SELECT 1 FROM INSERTED WHERE DATEDIFF(DAY, GETDATE(), INSERTED.AvailabilityDateTime) < 0) OR
     EXISTS (SELECT 1 FROM INSERTED WHERE DATEDIFF(MONTH, GETDATE(), INSERTED.AvailabilityDateTime) < 0) OR
     EXISTS (SELECT 1 FROM INSERTED WHERE DATEDIFF(YEAR, GETDATE(), INSERTED.AvailabilityDateTime) < 0) OR
     EXISTS (SELECT 1 FROM BarbersSchedule WHERE BarbersSchedule.AvailabilityDateTime IN (SELECT AvailabilityDateTime FROM INSERTED))
  BEGIN
    RAISERROR('���������� �������� ������: ����� ��� ������ ��� �� � �������!', 16, 1);
  END
  ELSE
  BEGIN
    INSERT INTO BarbersSchedule (AvailabilityDateTime, BarberID, ClientAppointmentDateTimeID)
        SELECT AvailabilityDateTime, BarberID, ClientAppointmentDateTimeID
    FROM inserted
  END
END

INSERT INTO BarbersSchedule (AvailabilityDateTime, BarberID, ClientAppointmentDateTimeID)
VALUES 
('2024-05-16 10:00:00.000', 1, 1)


--8. ��������� ���������� ������ �������-�������, ���� � ������ ��� �������� 5 �������-��������
DROP TRIGGER IsBarberAgeValid
CREATE TRIGGER JuniorBarberInsertRestriction
ON Barbers
INSTEAD OF INSERT
AS
BEGIN
  IF (SELECT COUNT(Barbers.BarberPositionID) FROM Barbers WHERE Barbers.BarberPositionID = 3) = 5
  BEGIN
    RAISERROR('�����������: � ������ ��� �������� 5 �������-��������', 16, 1);
  END
  ELSE
  BEGIN
    INSERT INTO Barbers (Name, LastName, Patronymic, Gender, Phone, Email, DateOfBirth, DateOfEmployment, BarberPositionID, ServicesID)
        SELECT Name, LastName, Patronymic, Gender, Phone, Email, DateOfBirth, DateOfEmployment, BarberPositionID, ServicesID 
    FROM INSERTED
  END
END

INSERT INTO Barbers (Name, LastName, Patronymic, Gender, Phone, Email, DateOfBirth, DateOfEmployment, BarberPositionID, ServicesID)
VALUES 
('������', '������', '��������', 'male', '1644543820', 'ser@gm.com', '2004-01-01', '2020-01-01', 3, 1)


--9. ������� ���������� � ��������, ������� �� ���������
--�� ������ ������� � �� ����� ������



--10.������� ���������� � ��������, ������� �� ��������
--��������� ����� ������ ����
SELECT*
FROM ClientVisitsArchive 
JOIN BarbersSchedule ON ClientVisitsArchive.DateID = BarbersSchedule.ID
JOIN ClientsAppointmentDateTime ON BarbersSchedule.ClientAppointmentDateTimeID = ClientsAppointmentDateTime.ID
