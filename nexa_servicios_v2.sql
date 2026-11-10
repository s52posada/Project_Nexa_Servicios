-- =====================================================================
-- Proyecto : Compras y Proveedores - Nexa Servicios
--            Ingeniería de Software II - Simón Atencio Posada y Pedro Juan Campuzano Echeverri
-- Archivo  : nexa_servicios_v2.sql
-- Motor    : MariaDB 10.5 o superior - InnoDB - utf8mb4 / utf8mb4_unicode_ci
-- Versión  : 2.0 (10/11/2026)
-- Base     : script final de la sesión de consola (versión 1.2 del documento),
--            ajustado para cubrir las HU y RN que ese script no soportaba.
--
-- Cambios frente al script anterior (cada uno indica la HU/RN que lo exige)
--   [C1] Campo activo en los 8 catálogos ............ HU-19, 23, 27, 31, 33, 35, 37, 39; MK-11 (OA-01)
--   [C2] Campo activo en solicitudes_compra, detalle_solicitud,
--        detalle_cotizacion y detalle_orden_compra .. HU-43, 49, 62, 72; RN-27 (OA-02)
--   [C3] Estado 'Cancelada' en estados_solicitud .... HU-45; RN-19 (OA-02)
--   [C4] Datos semilla de los 5 roles ............... Tabla de equivalencia actores-roles (OA-03)
--   [C5] UNIQUE (id_recepcion, id_detalle_orden) .... RN-16 (OA-04)
--   [C6] Triggers de cantidad recibida .............. RN-21 (OA-04)
--   [C7] Triggers de coherencia proveedor ........... RN-03 y RN-20 (factura y orden con
--                                                     el proveedor de la cotización)
--   [C8] Triggers de inactivación de proveedor ...... RN-28 (RN-07)
--
-- Ejecución: sobre una instancia SIN la base nexa_servicios. Si existe la versión
-- anterior y no tiene datos que conservar, elimínela primero con la línea siguiente.
-- =====================================================================

-- DROP DATABASE IF EXISTS nexa_servicios;

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Creación de la base de datos
-- ---------------------------------------------------------------------
CREATE DATABASE nexa_servicios CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nexa_servicios;


-- ---------------------------------------------------------------------
-- 2. Tablas maestras y catálogos
-- ---------------------------------------------------------------------
CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    correo VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_roles FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
) ENGINE=InnoDB;

CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    codigo_proveedor VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    identificacion_fiscal VARCHAR(30) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(150) NULL,
    direccion VARCHAR(200) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- [C1] Los ocho catálogos incorporan el campo activo
CREATE TABLE estados_solicitud (
    id_estado_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE prioridades (
    id_prioridad INT AUTO_INCREMENT PRIMARY KEY,
    nombre_prioridad VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE tipos_item (
    id_tipo_item INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE tipos_decision (
    id_tipo_decision INT AUTO_INCREMENT PRIMARY KEY,
    nombre_decision VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE estados_cotizacion (
    id_estado_cotizacion INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE estados_orden (
    id_estado_orden INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE estados_recepcion (
    id_estado_recepcion INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE estados_factura (
    id_estado_factura INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- 3. Tablas transaccionales
-- ---------------------------------------------------------------------
CREATE TABLE solicitudes_compra (
    id_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    codigo_solicitud VARCHAR(20) NOT NULL UNIQUE,
    id_solicitante INT NOT NULL,
    id_responsable INT NULL,
    id_estado_solicitud INT NOT NULL,
    id_prioridad INT NOT NULL,
    descripcion TEXT NOT NULL,
    justificacion TEXT NOT NULL,
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,                       -- [C2] RN-27
    CONSTRAINT fk_solicitudes_solicitante
        FOREIGN KEY (id_solicitante)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_solicitudes_responsable
        FOREIGN KEY (id_responsable)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_solicitudes_estado
        FOREIGN KEY (id_estado_solicitud)
        REFERENCES estados_solicitud(id_estado_solicitud),
    CONSTRAINT fk_solicitudes_prioridad
        FOREIGN KEY (id_prioridad)
        REFERENCES prioridades(id_prioridad)
) ENGINE=InnoDB;

CREATE TABLE detalle_solicitud (
    id_detalle_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud INT NOT NULL,
    id_tipo_item INT NOT NULL,
    descripcion_item VARCHAR(255) NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    unidad_medida VARCHAR(30) NULL,
    valor_estimado DECIMAL(15,2) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,                       -- [C2] RN-27
    CONSTRAINT chk_detalle_solicitud_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_solicitud_valor
        CHECK (valor_estimado IS NULL OR valor_estimado >= 0),
    CONSTRAINT fk_detalle_solicitud_solicitud
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_compra(id_solicitud),
    CONSTRAINT fk_detalle_solicitud_tipo
        FOREIGN KEY (id_tipo_item)
        REFERENCES tipos_item(id_tipo_item)
) ENGINE=InnoDB;

CREATE TABLE aprobaciones (
    id_aprobacion INT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud INT NOT NULL,
    id_usuario INT NOT NULL,
    id_tipo_decision INT NOT NULL,
    motivo TEXT NULL,
    fecha_decision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_aprobaciones_solicitud
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_compra(id_solicitud),
    CONSTRAINT fk_aprobaciones_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_aprobaciones_decision
        FOREIGN KEY (id_tipo_decision)
        REFERENCES tipos_decision(id_tipo_decision)
) ENGINE=InnoDB;

CREATE TABLE cotizaciones (
    id_cotizacion INT AUTO_INCREMENT PRIMARY KEY,
    codigo_cotizacion VARCHAR(30) NOT NULL UNIQUE,
    id_solicitud INT NOT NULL,
    id_proveedor INT NOT NULL,
    fecha_cotizacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE NULL,
    tiempo_entrega_dias INT NULL,
    condiciones_pago VARCHAR(100) NULL,
    valor_subtotal DECIMAL(15,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_impuestos DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_total DECIMAL(15,2) AS (valor_subtotal - descuento + valor_impuestos) STORED,
    id_estado_cotizacion INT NOT NULL,
    observaciones TEXT NULL,
    CONSTRAINT chk_cotizacion_vencimiento
        CHECK (fecha_vencimiento IS NULL OR fecha_vencimiento >= fecha_cotizacion),
    CONSTRAINT chk_cotizacion_entrega
        CHECK (tiempo_entrega_dias IS NULL OR tiempo_entrega_dias >= 0),
    CONSTRAINT chk_cotizacion_subtotal CHECK (valor_subtotal >= 0),
    CONSTRAINT chk_cotizacion_descuento CHECK (descuento >= 0),
    CONSTRAINT chk_cotizacion_impuestos CHECK (valor_impuestos >= 0),
    CONSTRAINT fk_cotizaciones_solicitud
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_compra(id_solicitud),
    CONSTRAINT fk_cotizaciones_proveedor
        FOREIGN KEY (id_proveedor)
        REFERENCES proveedores(id_proveedor),
    CONSTRAINT fk_cotizaciones_estado
        FOREIGN KEY (id_estado_cotizacion)
        REFERENCES estados_cotizacion(id_estado_cotizacion)
) ENGINE=InnoDB;

CREATE TABLE detalle_cotizacion (
    id_detalle_cotizacion INT AUTO_INCREMENT PRIMARY KEY,
    id_cotizacion INT NOT NULL,
    id_detalle_solicitud INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2) AS (cantidad * precio_unitario) STORED,
    activo BOOLEAN NOT NULL DEFAULT TRUE,                       -- [C2] RN-27
    CONSTRAINT uq_cotizacion_detalle UNIQUE (id_cotizacion, id_detalle_solicitud),
    CONSTRAINT chk_det_cot_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_det_cot_precio CHECK (precio_unitario >= 0),
    CONSTRAINT fk_det_cot_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizaciones(id_cotizacion),
    CONSTRAINT fk_det_cot_solicitud
        FOREIGN KEY (id_detalle_solicitud)
        REFERENCES detalle_solicitud(id_detalle_solicitud)
) ENGINE=InnoDB;

CREATE TABLE ordenes_compra (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    codigo_orden VARCHAR(30) NOT NULL UNIQUE,
    id_solicitud INT NOT NULL,
    id_cotizacion INT NOT NULL,
    id_comprador INT NOT NULL,
    fecha_orden DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_subtotal DECIMAL(15,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_impuestos DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_total DECIMAL(15,2) AS (valor_subtotal - descuento + valor_impuestos) STORED,
    id_estado_orden INT NOT NULL,
    observaciones TEXT NULL,
    CONSTRAINT chk_orden_subtotal CHECK (valor_subtotal >= 0),
    CONSTRAINT chk_orden_descuento CHECK (descuento >= 0),
    CONSTRAINT chk_orden_impuestos CHECK (valor_impuestos >= 0),
    CONSTRAINT fk_orden_solicitud
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_compra(id_solicitud),
    CONSTRAINT fk_orden_cotizacion
        FOREIGN KEY (id_cotizacion)
        REFERENCES cotizaciones(id_cotizacion),
    CONSTRAINT fk_orden_comprador
        FOREIGN KEY (id_comprador)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_orden_estado
        FOREIGN KEY (id_estado_orden)
        REFERENCES estados_orden(id_estado_orden)
) ENGINE=InnoDB;

CREATE TABLE detalle_orden_compra (
    id_detalle_orden INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_detalle_solicitud INT NOT NULL,
    id_detalle_cotizacion INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(15,2) NOT NULL,
    descuento DECIMAL(15,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(15,2) AS (cantidad * precio_unitario - descuento) STORED,
    activo BOOLEAN NOT NULL DEFAULT TRUE,                       -- [C2] RN-27
    CONSTRAINT uq_orden_detalle_solicitud UNIQUE (id_orden, id_detalle_solicitud),
    CONSTRAINT chk_det_orden_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_det_orden_precio CHECK (precio_unitario >= 0),
    CONSTRAINT chk_det_orden_descuento CHECK (descuento >= 0),
    CONSTRAINT fk_det_orden_orden
        FOREIGN KEY (id_orden)
        REFERENCES ordenes_compra(id_orden),
    CONSTRAINT fk_det_orden_solicitud
        FOREIGN KEY (id_detalle_solicitud)
        REFERENCES detalle_solicitud(id_detalle_solicitud),
    CONSTRAINT fk_det_orden_cotizacion
        FOREIGN KEY (id_detalle_cotizacion)
        REFERENCES detalle_cotizacion(id_detalle_cotizacion)
) ENGINE=InnoDB;

CREATE TABLE recepciones (
    id_recepcion INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_recepcion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_estado_recepcion INT NOT NULL,
    conforme BOOLEAN NOT NULL DEFAULT FALSE,
    observaciones TEXT NULL,
    CONSTRAINT fk_recepciones_orden
        FOREIGN KEY (id_orden)
        REFERENCES ordenes_compra(id_orden),
    CONSTRAINT fk_recepciones_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_recepciones_estado
        FOREIGN KEY (id_estado_recepcion)
        REFERENCES estados_recepcion(id_estado_recepcion)
) ENGINE=InnoDB;

CREATE TABLE detalle_recepcion (
    id_detalle_recepcion INT AUTO_INCREMENT PRIMARY KEY,
    id_recepcion INT NOT NULL,
    id_detalle_orden INT NOT NULL,
    cantidad_recibida DECIMAL(10,2) NOT NULL,
    cantidad_aceptada DECIMAL(10,2) NOT NULL,
    cantidad_rechazada DECIMAL(10,2) AS (cantidad_recibida - cantidad_aceptada) STORED,
    observacion TEXT NULL,
    CONSTRAINT uq_recepcion_detalle_orden UNIQUE (id_recepcion, id_detalle_orden),  -- [C5] RN-16
    CONSTRAINT chk_det_rec_recibida CHECK (cantidad_recibida >= 0),
    CONSTRAINT chk_det_rec_aceptada
        CHECK (cantidad_aceptada >= 0 AND cantidad_aceptada <= cantidad_recibida),
    CONSTRAINT fk_det_rec_recepcion
        FOREIGN KEY (id_recepcion)
        REFERENCES recepciones(id_recepcion),
    CONSTRAINT fk_det_rec_orden
        FOREIGN KEY (id_detalle_orden)
        REFERENCES detalle_orden_compra(id_detalle_orden)
) ENGINE=InnoDB;

CREATE TABLE facturas (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    numero_factura VARCHAR(50) NOT NULL,
    id_proveedor INT NOT NULL,
    id_orden INT NOT NULL,
    fecha_factura DATE NOT NULL DEFAULT (CURRENT_DATE),
    valor_subtotal DECIMAL(15,2) NOT NULL,
    descuento DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_impuestos DECIMAL(15,2) NOT NULL DEFAULT 0,
    valor_total DECIMAL(15,2) AS (valor_subtotal - descuento + valor_impuestos) STORED,
    id_estado_factura INT NOT NULL,
    observaciones TEXT NULL,
    CONSTRAINT uq_factura_proveedor_numero UNIQUE (id_proveedor, numero_factura),
    CONSTRAINT chk_factura_subtotal CHECK (valor_subtotal >= 0),
    CONSTRAINT chk_factura_descuento CHECK (descuento >= 0),
    CONSTRAINT chk_factura_impuestos CHECK (valor_impuestos >= 0),
    CONSTRAINT fk_facturas_proveedor
        FOREIGN KEY (id_proveedor)
        REFERENCES proveedores(id_proveedor),
    CONSTRAINT fk_facturas_orden
        FOREIGN KEY (id_orden)
        REFERENCES ordenes_compra(id_orden),
    CONSTRAINT fk_facturas_estado
        FOREIGN KEY (id_estado_factura)
        REFERENCES estados_factura(id_estado_factura)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- 4. Auditoría
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
    id_auditoria BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro BIGINT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT NULL,
    CONSTRAINT chk_auditoria_accion CHECK (accion IN ('INSERT','UPDATE','DELETE')),
    CONSTRAINT fk_auditoria_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
    INDEX idx_auditoria_tabla (tabla_afectada),
    INDEX idx_auditoria_registro (id_registro),
    INDEX idx_auditoria_accion (accion),
    INDEX idx_auditoria_fecha (fecha_hora)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- 5. Triggers de reglas de negocio
--    Rechazan la operación con SQLSTATE 45000 y un mensaje para el usuario (RN-12).
-- ---------------------------------------------------------------------
DELIMITER //

-- [C6] RN-21: la suma de lo recibido de una línea de orden no supera lo ordenado
CREATE TRIGGER trg_det_rec_cantidad_bi
BEFORE INSERT ON detalle_recepcion
FOR EACH ROW
BEGIN
    DECLARE v_ordenada DECIMAL(10,2);
    DECLARE v_recibida DECIMAL(10,2);
    SELECT cantidad INTO v_ordenada
      FROM detalle_orden_compra
     WHERE id_detalle_orden = NEW.id_detalle_orden;
    SELECT COALESCE(SUM(cantidad_recibida), 0) INTO v_recibida
      FROM detalle_recepcion
     WHERE id_detalle_orden = NEW.id_detalle_orden;
    IF v_recibida + NEW.cantidad_recibida > v_ordenada THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-21: la cantidad recibida supera la cantidad ordenada';
    END IF;
END//

CREATE TRIGGER trg_det_rec_cantidad_bu
BEFORE UPDATE ON detalle_recepcion
FOR EACH ROW
BEGIN
    DECLARE v_ordenada DECIMAL(10,2);
    DECLARE v_recibida DECIMAL(10,2);
    SELECT cantidad INTO v_ordenada
      FROM detalle_orden_compra
     WHERE id_detalle_orden = NEW.id_detalle_orden;
    SELECT COALESCE(SUM(cantidad_recibida), 0) INTO v_recibida
      FROM detalle_recepcion
     WHERE id_detalle_orden = NEW.id_detalle_orden
       AND id_detalle_recepcion <> OLD.id_detalle_recepcion;
    IF v_recibida + NEW.cantidad_recibida > v_ordenada THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-21: la cantidad recibida supera la cantidad ordenada';
    END IF;
END//

-- [C7] RN-03 y RN-20: la orden pertenece a la misma solicitud que su cotización
CREATE TRIGGER trg_orden_cotizacion_bi
BEFORE INSERT ON ordenes_compra
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cotizaciones
                    WHERE id_cotizacion = NEW.id_cotizacion
                      AND id_solicitud = NEW.id_solicitud) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-20: la cotización no corresponde a la solicitud de la orden';
    END IF;
END//

CREATE TRIGGER trg_orden_cotizacion_bu
BEFORE UPDATE ON ordenes_compra
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cotizaciones
                    WHERE id_cotizacion = NEW.id_cotizacion
                      AND id_solicitud = NEW.id_solicitud) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-20: la cotización no corresponde a la solicitud de la orden';
    END IF;
END//

-- [C7] RN-03 y RN-20: la factura es del proveedor de la cotización que originó la orden
CREATE TRIGGER trg_factura_proveedor_bi
BEFORE INSERT ON facturas
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM ordenes_compra o
                     JOIN cotizaciones c ON c.id_cotizacion = o.id_cotizacion
                    WHERE o.id_orden = NEW.id_orden
                      AND c.id_proveedor = NEW.id_proveedor) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-20: el proveedor de la factura no coincide con el de la orden';
    END IF;
END//

CREATE TRIGGER trg_factura_proveedor_bu
BEFORE UPDATE ON facturas
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM ordenes_compra o
                     JOIN cotizaciones c ON c.id_cotizacion = o.id_cotizacion
                    WHERE o.id_orden = NEW.id_orden
                      AND c.id_proveedor = NEW.id_proveedor) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-20: el proveedor de la factura no coincide con el de la orden';
    END IF;
END//

-- [C8] RN-28: no se inactiva un proveedor con órdenes que no estén cerradas o canceladas
CREATE TRIGGER trg_proveedor_inactivar_bu
BEFORE UPDATE ON proveedores
FOR EACH ROW
BEGIN
    IF OLD.activo = TRUE AND NEW.activo = FALSE AND EXISTS (
           SELECT 1
             FROM ordenes_compra o
             JOIN cotizaciones c ON c.id_cotizacion = o.id_cotizacion
             JOIN estados_orden e ON e.id_estado_orden = o.id_estado_orden
            WHERE c.id_proveedor = OLD.id_proveedor
              AND e.nombre_estado NOT IN ('Cerrada', 'Cancelada')) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN-28: el proveedor tiene órdenes de compra en curso';
    END IF;
END//

DELIMITER ;


-- ---------------------------------------------------------------------
-- 6. Datos iniciales
-- ---------------------------------------------------------------------
-- [C4] Roles de la tabla de equivalencia entre actores y roles
INSERT INTO roles (nombre_rol, descripcion) VALUES
    ('Administrador', 'Gestiona roles, usuarios, auditoría, proveedores y catálogos (HU-01 a HU-31)'),
    ('Solicitante',   'Actor Empleado: registra y gestiona solicitudes de compra (HU-40 a HU-49)'),
    ('Aprobador',     'Actor Jefe de Área: aprueba, rechaza o devuelve solicitudes (HU-50 a HU-53)'),
    ('Comprador',     'Actor Responsable de Compras: cotizaciones, órdenes y facturas (HU-32 a HU-39, HU-54 a HU-73, HU-82 a HU-86)'),
    ('Receptor',      'Actor Responsable de Compras al recibir: recepciones (HU-74 a HU-81)');

-- [C3] Se agrega 'Cancelada' al catálogo de estados de solicitud (HU-45)
INSERT INTO estados_solicitud (nombre_estado) VALUES
    ('Pendiente'),
    ('En revision'),
    ('Aprobada'),
    ('Rechazada'),
    ('Devuelta'),
    ('En cotizacion'),
    ('Comprada'),
    ('Cerrada'),
    ('Cancelada');

INSERT INTO prioridades (nombre_prioridad) VALUES
    ('Baja'),
    ('Media'),
    ('Alta'),
    ('Urgente');

INSERT INTO tipos_item (nombre_tipo) VALUES
    ('Producto'),
    ('Servicio');

INSERT INTO tipos_decision (nombre_decision) VALUES
    ('Aprobada'),
    ('Rechazada'),
    ('Devuelta');

INSERT INTO estados_cotizacion (nombre_estado) VALUES
    ('Recibida'),
    ('Seleccionada'),
    ('Descartada');

INSERT INTO estados_orden (nombre_estado) VALUES
    ('Generada'),
    ('Enviada'),
    ('Recibida'),
    ('Cerrada'),
    ('Cancelada');

INSERT INTO estados_recepcion (nombre_estado) VALUES
    ('Pendiente'),
    ('Recibida'),
    ('Conforme'),
    ('Con inconsistencias');

INSERT INTO estados_factura (nombre_estado) VALUES
    ('Pendiente'),
    ('Verificada'),
    ('Rechazada');


-- ---------------------------------------------------------------------
-- 7. Verificación
-- ---------------------------------------------------------------------
SHOW TABLES;
SHOW TRIGGERS;
