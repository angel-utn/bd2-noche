USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'UTN_RRHH_Manager')
BEGIN
    ALTER DATABASE UTN_RRHH_Manager SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UTN_RRHH_Manager;
END
GO

CREATE DATABASE UTN_RRHH_Manager;
GO

USE UTN_RRHH_Manager;
GO

CREATE TABLE Empleados (
    idempleado INT IDENTITY(1,1) PRIMARY KEY,
    apellidos VARCHAR(100) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    diaslibres INT NOT NULL DEFAULT 0 -- Stock de días disponibles
);
GO

CREATE TABLE Feriados (
    fecha DATE PRIMARY KEY,
    descripcion VARCHAR(200) NOT NULL
);
GO

CREATE TABLE Sanciones (
    idsancion INT IDENTITY(1,1) PRIMARY KEY,
    idempleado INT NOT NULL,
    fechasancion DATE NOT NULL,
    observacion VARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_Sanciones_Empleados FOREIGN KEY (idempleado) REFERENCES Empleados(idempleado)
);
GO

CREATE TABLE SolicitudesDiasLibres (
    idsolicitud INT IDENTITY(1,1) PRIMARY KEY,
    idempleado INT NOT NULL,
    fechadialibre DATE NOT NULL,
    aprobada BIT DEFAULT 0,  
    razonrechazo VARCHAR(MAX) NULL,
    CONSTRAINT FK_Solicitudes_Empleados FOREIGN KEY (idempleado) REFERENCES Empleados(idempleado)
);
GO

INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 1, 1), 'Año Nuevo');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 3, 24), 'Día de la Memoria');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 4, 2), 'Día del Veterano y de los Caídos en la Guerra de Malvinas');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 5, 1), 'Día del Trabajador');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 5, 25),'Día de la Revolución de Mayo');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 6, 20), 'Paso a la Inmortalidad del Gral. Manuel Belgrano');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 7, 9), 'Día de la Independencia');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEFROMPARTS(YEAR(GETDATE()), 12, 25), 'Navidad');
INSERT INTO Feriados (fecha, descripcion) VALUES (DATEADD(day, 5, GETDATE()), 'Kloster Day');

INSERT INTO Empleados (apellidos, nombres, diaslibres) VALUES ('Lovelace', 'Ada', 14);
INSERT INTO Empleados (apellidos, nombres, diaslibres) VALUES ('Turing', 'Alan', 0);
INSERT INTO Empleados (apellidos, nombres, diaslibres) VALUES ('Ritchie', 'Dennis', 10);
INSERT INTO Empleados (apellidos, nombres, diaslibres) VALUES ('Hopper', 'Grace', 21);

INSERT INTO Sanciones (idempleado, fechasancion, observacion) 
VALUES (3, GETDATE(), 'Pidió memoria y se olvidó de liberarla.');

INSERT INTO Sanciones (idempleado, fechasancion, observacion) 
VALUES (1, DATEADD(month, -2, GETDATE()), 'No usa la posición 0 de los vectores.');


INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre, aprobada, razonrechazo)
VALUES (1, DATEFROMPARTS(GETDATE(), 2, 1), 1, NULL);

INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre, aprobada, razonrechazo)
VALUES (1, DATEFROMPARTS(YEAR(GETDATE()), 2, 2), 1, NULL);

INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre, aprobada, razonrechazo)
VALUES (2, DATEFROMPARTS(YEAR(GETDATE()), 3, 15), 0, 'No tiene días disponibles');

GO