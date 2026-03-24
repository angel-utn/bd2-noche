IF EXISTS (SELECT * FROM sys.databases WHERE name = 'BDArchivos') BEGIN
    USE MASTER;
    DROP DATABASE BDArchivos;
END;

CREATE DATABASE BDArchivos
COLLATE Latin1_General_CI_AI;
GO
 
USE BDArchivos;
GO
 
CREATE TABLE TiposUsuario (
    IDTipoUsuario   INT IDENTITY (1, 1) NOT NULL,
    TipoUsuario     VARCHAR(50)     NOT NULL,
    CONSTRAINT PK_TiposUsuario PRIMARY KEY (IDTipoUsuario)
);
GO
 
CREATE TABLE Usuarios (
    IDUsuario       INT IDENTITY (1, 1)  NOT NULL,
    Nombre          VARCHAR(100)    NOT NULL,
    Apellido        VARCHAR(100)    NOT NULL,
    IDTipoUsuario   INT             NOT NULL,
    CONSTRAINT PK_Usuarios PRIMARY KEY (IDUsuario),
    CONSTRAINT FK_Usuarios_TiposUsuario
        FOREIGN KEY (IDTipoUsuario)
        REFERENCES TiposUsuario (IDTipoUsuario)
);
GO
 
CREATE TABLE TiposArchivos (
    IDTipoArchivo   INT IDENTITY (1, 1)  NOT NULL,
    TipoArchivo     VARCHAR(50)     NOT NULL,
    CONSTRAINT PK_TiposArchivos PRIMARY KEY (IDTipoArchivo)
);
GO
 
CREATE TABLE Permisos (
    IDPermiso       INT IDENTITY (1, 1) NOT NULL,
    Nombre          VARCHAR(100)    NOT NULL,
    CONSTRAINT PK_Permisos PRIMARY KEY (IDPermiso)
);
GO
 
CREATE TABLE Archivos (
    IDArchivo               INT IDENTITY (1, 1) NOT NULL,
    IDUsuarioDueño          INT             NOT NULL,
    Nombre                  VARCHAR(255)    NOT NULL,
    Extension               VARCHAR(20)     NOT NULL,
    Descripcion             VARCHAR(500)    NULL,
    IDTipoArchivo           INT             NOT NULL,
    Tamaño                  BIGINT          NOT NULL,   -- en bytes
    FechaCreacion           DATETIME        NOT NULL    DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME        NULL,
    Eliminado               BIT             NOT NULL    DEFAULT 0,
    CONSTRAINT PK_Archivos PRIMARY KEY (IDArchivo),
    CONSTRAINT FK_Archivos_Usuarios
        FOREIGN KEY (IDUsuarioDueño)
        REFERENCES Usuarios (IDUsuario),
    CONSTRAINT FK_Archivos_TiposArchivos
        FOREIGN KEY (IDTipoArchivo)
        REFERENCES TiposArchivos (IDTipoArchivo)
);
GO
CREATE TABLE ArchivosCompartidos (
    IDArchivo       INT             NOT NULL,
    IDUsuario       INT             NOT NULL,
    IDPermiso       INT             NOT NULL,
    FechaCompartido DATETIME        NOT NULL    DEFAULT GETDATE(),
    CONSTRAINT PK_ArchivosCompartidos PRIMARY KEY (IDArchivo, IDUsuario),
    CONSTRAINT FK_ArchivosCompartidos_Archivos
        FOREIGN KEY (IDArchivo)
        REFERENCES Archivos (IDArchivo),
    CONSTRAINT FK_ArchivosCompartidos_Usuarios
        FOREIGN KEY (IDUsuario)
        REFERENCES Usuarios (IDUsuario),
    CONSTRAINT FK_ArchivosCompartidos_Permisos
        FOREIGN KEY (IDPermiso)
        REFERENCES Permisos (IDPermiso)
);
