-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 23-04-2025 a las 23:25:46
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `hospital`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ActualizarEstadoCita` (IN `p_id_cita` INT, IN `p_estado` ENUM('Pendiente','Confirmada','Cancelada','Completada'))   BEGIN
    UPDATE citas SET estado = p_estado WHERE id_cita = p_id_cita;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarCita` (IN `p_id_cita` INT)   BEGIN
    DELETE FROM citas WHERE id_cita = p_id_cita;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarCita` (IN `p_id_paciente` INT, IN `p_id_medico` INT, IN `p_fecha_hora` DATETIME, IN `p_motivo` VARCHAR(255))   BEGIN
    INSERT INTO citas (id_paciente, id_medico, fecha_hora, motivo)
    VALUES (p_id_paciente, p_id_medico, p_fecha_hora, p_motivo);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login_usuario` (IN `p_usuario` VARCHAR(50), IN `p_contrasena` VARCHAR(255))   BEGIN
    DECLARE stored_pass VARCHAR(255);
    DECLARE user_id INT;
    DECLARE user_blocked BOOLEAN;

    SELECT id_usuario, contrasena, bloqueado
    INTO user_id, stored_pass, user_blocked
    FROM usuarios
    WHERE nombre_usuario = p_usuario;

    IF user_blocked THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuario bloqueado';
    ELSEIF stored_pass = p_contrasena THEN
        UPDATE usuarios SET intentos_fallidos = 0 WHERE id_usuario = user_id;
        SELECT 'Login exitoso' AS mensaje;
    ELSE
        UPDATE usuarios
        SET intentos_fallidos = intentos_fallidos + 1
        WHERE id_usuario = user_id;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Contraseña incorrecta';
    END IF;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `capacidad_restante` (`sede_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE usados INT DEFAULT 0;

    -- Asegúrate de tener una tabla usuarios_sede con usuarios asignados a cada sede
    SELECT COUNT(*) INTO usados
    FROM usuarios_sede
    WHERE id_sede = sede_id;

    RETURN (SELECT capacidad_usuarios FROM sedes WHERE id_sede = sede_id) - usados;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `citas`
--

CREATE TABLE `citas` (
  `id_cita` int(11) NOT NULL,
  `id_paciente` int(11) DEFAULT NULL,
  `id_medico` int(11) DEFAULT NULL,
  `fecha_hora` datetime DEFAULT NULL,
  `estado` enum('Pendiente','Confirmada','Cancelada','Completada') DEFAULT 'Pendiente',
  `motivo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `especialidades`
--

CREATE TABLE `especialidades` (
  `id_especialidad` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `especialidades`
--

INSERT INTO `especialidades` (`id_especialidad`, `nombre`) VALUES
(1, 'Cardiología'),
(4, 'Dermatología'),
(5, 'Gastroenterología'),
(3, 'Neurología'),
(2, 'Pediatría');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturacion`
--

CREATE TABLE `facturacion` (
  `id_factura` int(11) NOT NULL,
  `id_paciente` int(11) NOT NULL,
  `fecha_emision` date NOT NULL DEFAULT curdate(),
  `total` decimal(10,2) NOT NULL CHECK (`total` >= 0),
  `estado` enum('Pendiente','Pagada','Anulada') NOT NULL DEFAULT 'Pendiente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `facturacion`
--

INSERT INTO `facturacion` (`id_factura`, `id_paciente`, `fecha_emision`, `total`, `estado`) VALUES
(1, 1, '2025-03-01', 150.00, 'Pendiente'),
(2, 2, '2025-03-02', 200.00, 'Pagada'),
(3, 1, '2025-03-05', 180.00, 'Pendiente'),
(4, 2, '2025-03-06', 250.00, 'Pagada');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura_detalle`
--

CREATE TABLE `factura_detalle` (
  `id_detalle` int(11) NOT NULL,
  `id_factura` int(11) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `cantidad` int(11) NOT NULL CHECK (`cantidad` > 0),
  `precio` decimal(10,2) NOT NULL CHECK (`precio` >= 0),
  `subtotal` decimal(10,2) NOT NULL CHECK (`subtotal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `factura_detalle`
--

INSERT INTO `factura_detalle` (`id_detalle`, `id_factura`, `descripcion`, `cantidad`, `precio`, `subtotal`) VALUES
(1, 1, 'Consulta médica general', 1, 150.00, 150.00),
(2, 2, 'Consulta pediátrica', 1, 200.00, 200.00),
(3, 3, 'Consulta especializada', 1, 180.00, 180.00),
(4, 4, 'Examen de laboratorio', 1, 250.00, 250.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `formulas_medicas`
--

CREATE TABLE `formulas_medicas` (
  `id_formula` int(11) NOT NULL,
  `id_paciente` int(11) NOT NULL,
  `id_medico` int(11) NOT NULL,
  `fecha` date NOT NULL DEFAULT curdate(),
  `duracion` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `formulas_medicas`
--

INSERT INTO `formulas_medicas` (`id_formula`, `id_paciente`, `id_medico`, `fecha`, `duracion`) VALUES
(1, 1, 1, '2025-03-01', ''),
(2, 2, 2, '2025-03-02', ''),
(3, 1, 1, '2025-03-07', ''),
(4, 2, 2, '2025-03-08', '');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `formula_medicamento`
--

CREATE TABLE `formula_medicamento` (
  `id_formula` int(11) NOT NULL,
  `id_medicamento` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL CHECK (`cantidad` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `formula_medicamento`
--

INSERT INTO `formula_medicamento` (`id_formula`, `id_medicamento`, `cantidad`) VALUES
(1, 1, 1),
(2, 2, 1),
(3, 1, 2),
(4, 2, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `habitaciones`
--

CREATE TABLE `habitaciones` (
  `id_habitacion` int(11) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `tipo` enum('Individual','Doble','Suite') NOT NULL,
  `estado` enum('Disponible','Ocupada','Mantenimiento') NOT NULL DEFAULT 'Disponible'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `habitaciones`
--

INSERT INTO `habitaciones` (`id_habitacion`, `numero`, `tipo`, `estado`) VALUES
(1, '101', 'Individual', 'Disponible'),
(2, '202', 'Doble', 'Disponible'),
(3, '303', 'Suite', 'Ocupada'),
(4, '404', 'Doble', 'Mantenimiento');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historias_clinicas`
--

CREATE TABLE `historias_clinicas` (
  `id_historia` int(11) NOT NULL,
  `id_paciente` int(11) NOT NULL,
  `fecha` date NOT NULL DEFAULT curdate(),
  `diagnostico` text NOT NULL,
  `notas` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historias_clinicas`
--

INSERT INTO `historias_clinicas` (`id_historia`, `id_paciente`, `fecha`, `diagnostico`, `notas`) VALUES
(1, 1, '2025-03-01', 'Hipertensión arterial', 'Se recomienda dieta baja en sodio'),
(2, 2, '2025-03-02', 'Alergia estacional', 'Administrar antihistamínico'),
(3, 1, '2025-03-09', 'Dermatitis', 'Usar crema hidratante y evitar alérgenos'),
(4, 2, '2025-03-10', 'Gastritis', 'Evitar comidas irritantes y tomar omeprazol');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `hospitalizaciones`
--

CREATE TABLE `hospitalizaciones` (
  `id_hospitalizacion` int(11) NOT NULL,
  `id_paciente` int(11) NOT NULL,
  `id_habitacion` int(11) NOT NULL,
  `fecha_ingreso` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_salida` datetime DEFAULT NULL,
  `estado` enum('En curso','Finalizada') NOT NULL DEFAULT 'En curso',
  `fecha_egreso` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `hospitalizaciones`
--

INSERT INTO `hospitalizaciones` (`id_hospitalizacion`, `id_paciente`, `id_habitacion`, `fecha_ingreso`, `fecha_salida`, `estado`, `fecha_egreso`) VALUES
(1, 1, 1, '2025-02-20 14:00:00', NULL, 'En curso', NULL),
(2, 2, 2, '2025-02-22 09:30:00', NULL, 'Finalizada', NULL),
(3, 1, 3, '2025-03-11 08:00:00', NULL, 'En curso', NULL),
(4, 2, 4, '2025-03-12 10:00:00', '2025-03-15 12:00:00', 'Finalizada', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medicamentos`
--

CREATE TABLE `medicamentos` (
  `id_medicamento` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `stock` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `medicamentos`
--

INSERT INTO `medicamentos` (`id_medicamento`, `nombre`, `descripcion`, `stock`) VALUES
(1, 'Enalapril', 'Medicamento para la hipertensión', 50),
(2, 'Loratadina', 'Antihistamínico para alergias', 30),
(3, 'Omeprazol', 'Inhibidor de la bomba de protones para gastritis', 40),
(4, 'Hidrocortisona', 'Antiinflamatorio tópico para dermatitis', 20);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medicos`
--

CREATE TABLE `medicos` (
  `id_medico` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo_electronico` varchar(100) DEFAULT NULL,
  `id_especialidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `medicos`
--

INSERT INTO `medicos` (`id_medico`, `nombre`, `apellido`, `telefono`, `correo_electronico`, `id_especialidad`) VALUES
(1, 'Carlos', 'Ramírez', '3105678901', 'carlos.ramirez@email.com', 1),
(2, 'Laura', 'Fernández', '3156789012', 'laura.fernandez@email.com', 2),
(3, 'Ana', 'Torres', '3209876543', 'ana.torres@email.com', 4),
(4, 'Javier', 'López', '3176543210', 'javier.lopez@email.com', 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pacientes`
--

CREATE TABLE `pacientes` (
  `id_paciente` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `fecha_nacimiento` date NOT NULL,
  `genero` enum('Masculino','Femenino','Otro') NOT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo_electronico` varchar(100) DEFAULT NULL,
  `tipo_documento` enum('CC','TI','Pasaporte') NOT NULL,
  `numero_documento` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pacientes`
--

INSERT INTO `pacientes` (`id_paciente`, `nombre`, `apellido`, `fecha_nacimiento`, `genero`, `direccion`, `telefono`, `correo_electronico`, `tipo_documento`, `numero_documento`) VALUES
(1, 'Juan', 'Pérez', '1985-06-15', 'Masculino', 'Calle 123', '3012345678', 'juan.perez@email.com', 'CC', '1000123456'),
(2, 'María', 'Gómez', '1992-09-22', 'Femenino', 'Avenida 45', '3123456789', 'maria.gomez@email.com', 'CC', '1000234567'),
(3, 'Pedro', 'Martínez', '1980-05-10', 'Masculino', 'Calle 456', '3045678901', 'pedro.martinez@email.com', 'CC', '1000345678'),
(4, 'Luisa', 'Rodríguez', '1995-11-30', 'Femenino', 'Carrera 789', '3136789012', 'luisa.rodriguez@email.com', 'CC', '1000456789'),
(5, 'Cangreliano', 'Quintero', '1989-08-20', 'Masculino', 'Calle 43, Avenida Brasil', '3203456456', 'cangre@gmail.com', 'CC', '1077625627');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sedes`
--

CREATE TABLE `sedes` (
  `id_sede` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `ubicacion` text NOT NULL,
  `imagen` longblob DEFAULT NULL,
  `capacidad_usuarios` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sedes`
--

INSERT INTO `sedes` (`id_sede`, `nombre`, `ubicacion`, `imagen`, `capacidad_usuarios`) VALUES
(1, 'Sede Central', 'Bogotá, Colombia', 0x68747470733a2f2f6578616d706c652e636f6d2f696d6167656e65732f736564655f63656e7472616c2e6a7067, 500),
(2, 'Sede Norte', 'Medellín, Colombia', 0x68747470733a2f2f6578616d706c652e636f6d2f696d6167656e65732f736564655f6e6f7274652e6a7067, 300),
(3, 'Sede Sur', 'Cali, Colombia', 0x68747470733a2f2f6578616d706c652e636f6d2f696d6167656e65732f736564655f7375722e6a7067, 250),
(4, 'Sede Oriente', 'Bucaramanga, Colombia', 0x68747470733a2f2f6578616d706c652e636f6d2f696d6167656e65732f736564655f6f7269656e74652e6a7067, 200),
(5, 'Sede Occidente', 'Cartagena, Colombia', 0x68747470733a2f2f6578616d706c652e636f6d2f696d6167656e65732f736564655f6f63636964656e74652e6a7067, 350);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tratamientos`
--

CREATE TABLE `tratamientos` (
  `id_tratamiento` int(11) NOT NULL,
  `id_historia` int(11) NOT NULL,
  `descripcion` text NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tratamientos`
--

INSERT INTO `tratamientos` (`id_tratamiento`, `id_historia`, `descripcion`, `fecha_inicio`, `fecha_fin`) VALUES
(1, 1, 'Control de presión arterial con enalapril', '2025-03-01', '2025-06-01'),
(2, 2, 'Antihistamínicos durante 15 días', '2025-03-02', '2025-03-17'),
(3, 3, 'Tratamiento tópico con hidrocortisona', '2025-03-11', '2025-03-25'),
(4, 4, 'Dieta especial y omeprazol', '2025-03-12', '2025-04-10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(50) NOT NULL,
  `contrasena` varchar(255) NOT NULL,
  `intentos_fallidos` int(11) DEFAULT 0,
  `bloqueado` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `contrasena`, `intentos_fallidos`, `bloqueado`) VALUES
(1, 'gisella', '$2y$10$N9qo8uLOickgx2ZMRZo5i.ezE6i0As/XnDFeZ8IMpD4tzApo0Rg4m', 3, 1),
(2, 'yusy', '$2y$10$7HdiCVUblL4EX0cHV/ZrYObFJ1X5fZcxJDul3yqgYkqLU/N8U4hZC', 0, 0),
(3, 'carloslopez', '$2y$10$LJjzTqKzTbqG.8T/2ZHraOL9vbtk1pWnpUmCuf3p0RUUWa5h6jSge', 0, 0),
(4, 'laurafernandez', '$2y$10$R3eT0c9PIaHKvA.6UehSoOoM9tzRBIg3NW8u8oJmh9P9HcTgzfDta', 0, 0),
(5, 'pedroalvarez', '$2y$10$fVH8e28OQRj9tqiDXs1e1uEvI9k3dP.WdZ/yfrDFeTvo35PhYXk3G', 0, 0);

--
-- Disparadores `usuarios`
--
DELIMITER $$
CREATE TRIGGER `bloquear_usuario` BEFORE UPDATE ON `usuarios` FOR EACH ROW BEGIN
    IF NEW.intentos_fallidos >= 3 THEN
        SET NEW.bloqueado = TRUE;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_cinco_primeras_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_cinco_primeras_especialidades` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_cinco_ultimas_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_cinco_ultimas_especialidades` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas` (
`id_cita` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_canceladas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_canceladas` (
`id_cita` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_confirmadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_confirmadas` (
`id_cita` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_detalladas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_detalladas` (
`id_cita` int(11)
,`paciente` varchar(100)
,`medico` varchar(100)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_medicos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_medicos` (
`id_cita` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`especialidad` varchar(100)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_pacientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_pacientes` (
`id_cita` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_pendientes` (
`id_cita` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_por_especialidad`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_por_especialidad` (
`especialidad` varchar(100)
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_citas_ultimo_mes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_citas_ultimo_mes` (
`id_cita` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_consultas_por_dia`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_consultas_por_dia` (
`fecha` date
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_consultas_por_especialidad`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_consultas_por_especialidad` (
`especialidad` varchar(100)
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_consultas_por_medico`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_consultas_por_medico` (
`nombre` varchar(100)
,`total_consultas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_conteo_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_conteo_especialidades` (
`total_especialidades` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_c`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_c` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_capitalizado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_capitalizado` (
`id_especialidad` int(11)
,`nombre` varchar(400)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_cardio`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_cardio` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_concatenadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_concatenadas` (
`especialidad` varchar(114)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_consonante_final`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_consonante_final` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_con_numeros`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_con_numeros` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_con_z`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_con_z` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_cortas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_cortas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_dermato`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_dermato` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_duplicadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_duplicadas` (
`nombre` varchar(100)
,`cantidad` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_id_impar`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_id_impar` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_id_par`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_id_par` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_inverso`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_inverso` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_largas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_largas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_longitud_impar`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_longitud_impar` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_mas_solicitadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_mas_solicitadas` (
`nombre` varchar(100)
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_mayusculas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_mayusculas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_med`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_med` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_minusculas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_minusculas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_misma_letra`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_misma_letra` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_multipalabra`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_multipalabra` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_muy_cortas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_muy_cortas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_ocho_caracteres`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_ocho_caracteres` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_ordenadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_ordenadas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_por_longitud`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_por_longitud` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_simetricas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_simetricas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_sin_a`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_sin_a` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_sin_espacios`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_sin_espacios` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_sin_o`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_sin_o` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_terminadas_ia`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_terminadas_ia` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_especialidades_vocales_repetidas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_especialidades_vocales_repetidas` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion` (
`id_factura` int(11)
,`id_paciente` int(11)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion_detallada`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion_detallada` (
`id_factura` int(11)
,`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_emision` date
,`descripcion` varchar(255)
,`cantidad` int(11)
,`precio` decimal(10,2)
,`subtotal` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion_mensual`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion_mensual` (
`mes` int(2)
,`año` int(4)
,`total_facturado` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion_por_paciente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion_por_paciente` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`total_facturado` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion_total_por_paciente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion_total_por_paciente` (
`nombre` varchar(100)
,`apellido` varchar(100)
,`total_pagado` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturas_anuladas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturas_anuladas` (
`id_factura` int(11)
,`id_paciente` int(11)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturas_pacientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturas_pacientes` (
`id_factura` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturas_pagadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturas_pagadas` (
`id_factura` int(11)
,`id_paciente` int(11)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturas_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturas_pendientes` (
`id_factura` int(11)
,`id_paciente` int(11)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_factura_detalle`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_factura_detalle` (
`id_detalle` int(11)
,`id_factura` int(11)
,`descripcion` varchar(255)
,`cantidad` int(11)
,`precio` decimal(10,2)
,`subtotal` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_factura_detalle_completo`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_factura_detalle_completo` (
`id_detalle` int(11)
,`id_factura` int(11)
,`paciente` varchar(100)
,`descripcion` varchar(255)
,`cantidad` int(11)
,`precio` decimal(10,2)
,`subtotal` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_formulas_medicas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_formulas_medicas` (
`id_formula` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha` date
,`duracion` varchar(50)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_formulas_medicas_recientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_formulas_medicas_recientes` (
`id_formula` int(11)
,`id_paciente` int(11)
,`id_medico` int(11)
,`fecha` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_habitaciones`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_habitaciones` (
`id_habitacion` int(11)
,`numero` varchar(10)
,`tipo` enum('Individual','Doble','Suite')
,`estado` enum('Disponible','Ocupada','Mantenimiento')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_habitaciones_disponibles`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_habitaciones_disponibles` (
`id_habitacion` int(11)
,`numero` varchar(10)
,`tipo` enum('Individual','Doble','Suite')
,`estado` enum('Disponible','Ocupada','Mantenimiento')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_habitaciones_ocupadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_habitaciones_ocupadas` (
`id_habitacion` int(11)
,`numero` varchar(10)
,`tipo` enum('Individual','Doble','Suite')
,`estado` enum('Disponible','Ocupada','Mantenimiento')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_historial_medico`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_historial_medico` (
`id_historia` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha` date
,`diagnostico` text
,`notas` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_historial_reciente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_historial_reciente` (
`id_historia` int(11)
,`id_paciente` int(11)
,`fecha` date
,`diagnostico` text
,`notas` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_historias_clinicas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_historias_clinicas` (
`id_historia` int(11)
,`paciente` varchar(100)
,`fecha` date
,`diagnostico` text
,`notas` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizaciones`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizaciones` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`id_hospitalizacion` int(11)
,`fecha_ingreso` datetime
,`fecha_egreso` varchar(15)
,`estado` enum('En curso','Finalizada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizaciones_activas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizaciones_activas` (
`id_hospitalizacion` int(11)
,`id_paciente` int(11)
,`id_habitacion` int(11)
,`fecha_ingreso` datetime
,`fecha_salida` datetime
,`estado` enum('En curso','Finalizada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizaciones_en_curso`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizaciones_en_curso` (
`id_hospitalizacion` int(11)
,`id_paciente` int(11)
,`id_habitacion` int(11)
,`fecha_ingreso` datetime
,`fecha_salida` datetime
,`estado` enum('En curso','Finalizada')
,`fecha_egreso` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizaciones_finalizadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizaciones_finalizadas` (
`id_hospitalizacion` int(11)
,`id_paciente` int(11)
,`id_habitacion` int(11)
,`fecha_ingreso` datetime
,`fecha_salida` datetime
,`estado` enum('En curso','Finalizada')
,`fecha_egreso` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizaciones_pacientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizaciones_pacientes` (
`id_hospitalizacion` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_ingreso` datetime
,`fecha_salida` datetime
,`estado` enum('En curso','Finalizada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_hospitalizados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_hospitalizados` (
`id_hospitalizacion` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_ingreso` datetime
,`estado` enum('En curso','Finalizada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_ingresos_por_especialidad`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_ingresos_por_especialidad` (
`especialidad` varchar(100)
,`ingresos` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_ingresos_por_fecha`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_ingresos_por_fecha` (
`fecha_emision` date
,`total_ingresos` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicamentos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicamentos` (
`id_medicamento` int(11)
,`nombre` varchar(100)
,`descripcion` text
,`stock` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicamentos_bajo_stock`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicamentos_bajo_stock` (
`id_medicamento` int(11)
,`nombre` varchar(100)
,`descripcion` text
,`stock` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicamentos_mas_prescritos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicamentos_mas_prescritos` (
`id_medicamento` int(11)
,`nombre` varchar(100)
,`veces_prescrito` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicos_con_especialidad`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicos_con_especialidad` (
`id_medico` int(11)
,`nombre` varchar(100)
,`especialidad` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicos_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicos_especialidades` (
`id_medico` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`especialidad` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_medicos_mas_citas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_medicos_mas_citas` (
`id_medico` int(11)
,`nombre` varchar(100)
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_ocupacion_habitaciones`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_ocupacion_habitaciones` (
`numero` varchar(10)
,`tipo` enum('Individual','Doble','Suite')
,`estado` enum('Disponible','Ocupada','Mantenimiento')
,`veces_ocupada` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_citas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_citas` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`id_cita` int(11)
,`fecha_hora` datetime
,`estado` enum('Pendiente','Confirmada','Cancelada','Completada')
,`motivo` varchar(255)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_con_facturas_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_con_facturas_pendientes` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`total` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_con_multiples_hospitalizaciones`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_con_multiples_hospitalizaciones` (
`nombre` varchar(100)
,`apellido` varchar(100)
,`total_hospitalizaciones` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_facturas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_facturas` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`id_factura` int(11)
,`fecha_emision` date
,`total` decimal(10,2)
,`estado` enum('Pendiente','Pagada','Anulada')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_frecuentes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_frecuentes` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`total_citas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_historias`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_historias` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`id_historia` int(11)
,`fecha` date
,`diagnostico` text
,`notas` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_jovenes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_jovenes` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_nacimiento` date
,`genero` enum('Masculino','Femenino','Otro')
,`direccion` varchar(255)
,`telefono` varchar(20)
,`correo_electronico` varchar(100)
,`tipo_documento` enum('CC','TI','Pasaporte')
,`numero_documento` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_mas_hospitalizados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_mas_hospitalizados` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`total_hospitalizaciones` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_mayores`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_mayores` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_nacimiento` date
,`genero` enum('Masculino','Femenino','Otro')
,`direccion` varchar(255)
,`telefono` varchar(20)
,`correo_electronico` varchar(100)
,`tipo_documento` enum('CC','TI','Pasaporte')
,`numero_documento` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_por_genero`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_por_genero` (
`genero` enum('Masculino','Femenino','Otro')
,`cantidad` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_que_no_han_pagado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_que_no_han_pagado` (
`nombre` varchar(100)
,`apellido` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pacientes_sin_hospitalizacion`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pacientes_sin_hospitalizacion` (
`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`fecha_nacimiento` date
,`genero` enum('Masculino','Femenino','Otro')
,`direccion` varchar(255)
,`telefono` varchar(20)
,`correo_electronico` varchar(100)
,`tipo_documento` enum('CC','TI','Pasaporte')
,`numero_documento` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_todas_especialidades`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_todas_especialidades` (
`id_especialidad` int(11)
,`nombre` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_total_citas_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_total_citas_pendientes` (
`total` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_total_hospitalizados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_total_hospitalizados` (
`total` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tratamientos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tratamientos` (
`id_tratamiento` int(11)
,`id_historia` int(11)
,`descripcion` text
,`fecha_inicio` date
,`fecha_fin` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tratamientos_activos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tratamientos_activos` (
`id_tratamiento` int(11)
,`id_historia` int(11)
,`id_paciente` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`descripcion` text
,`fecha_inicio` date
,`fecha_fin` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tratamientos_en_curso`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tratamientos_en_curso` (
`id_tratamiento` int(11)
,`id_historia` int(11)
,`descripcion` text
,`fecha_inicio` date
,`fecha_fin` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tratamientos_pacientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tratamientos_pacientes` (
`id_tratamiento` int(11)
,`nombre` varchar(100)
,`apellido` varchar(100)
,`descripcion` text
,`fecha_inicio` date
,`fecha_fin` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_usuarios_activos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_usuarios_activos` (
`id_usuario` int(11)
,`nombre_usuario` varchar(50)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_cinco_primeras_especialidades`
--
DROP TABLE IF EXISTS `vista_cinco_primeras_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_cinco_primeras_especialidades`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` LIMIT 0, 5 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_cinco_ultimas_especialidades`
--
DROP TABLE IF EXISTS `vista_cinco_ultimas_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_cinco_ultimas_especialidades`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ORDER BY `especialidades`.`id_especialidad` DESC LIMIT 0, 5 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas`
--
DROP TABLE IF EXISTS `vista_citas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas`  AS SELECT `citas`.`id_cita` AS `id_cita`, `citas`.`id_paciente` AS `id_paciente`, `citas`.`id_medico` AS `id_medico`, `citas`.`fecha_hora` AS `fecha_hora`, `citas`.`estado` AS `estado`, `citas`.`motivo` AS `motivo` FROM `citas` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_canceladas`
--
DROP TABLE IF EXISTS `vista_citas_canceladas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_canceladas`  AS SELECT `citas`.`id_cita` AS `id_cita`, `citas`.`id_paciente` AS `id_paciente`, `citas`.`id_medico` AS `id_medico`, `citas`.`fecha_hora` AS `fecha_hora`, `citas`.`estado` AS `estado`, `citas`.`motivo` AS `motivo` FROM `citas` WHERE `citas`.`estado` = 'Cancelada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_confirmadas`
--
DROP TABLE IF EXISTS `vista_citas_confirmadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_confirmadas`  AS SELECT `citas`.`id_cita` AS `id_cita`, `citas`.`id_paciente` AS `id_paciente`, `citas`.`id_medico` AS `id_medico`, `citas`.`fecha_hora` AS `fecha_hora`, `citas`.`estado` AS `estado`, `citas`.`motivo` AS `motivo` FROM `citas` WHERE `citas`.`estado` = 'Confirmada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_detalladas`
--
DROP TABLE IF EXISTS `vista_citas_detalladas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_detalladas`  AS SELECT `c`.`id_cita` AS `id_cita`, `p`.`nombre` AS `paciente`, `m`.`nombre` AS `medico`, `c`.`fecha_hora` AS `fecha_hora`, `c`.`estado` AS `estado`, `c`.`motivo` AS `motivo` FROM ((`citas` `c` join `pacientes` `p` on(`c`.`id_paciente` = `p`.`id_paciente`)) join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_medicos`
--
DROP TABLE IF EXISTS `vista_citas_medicos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_medicos`  AS SELECT `c`.`id_cita` AS `id_cita`, `m`.`nombre` AS `nombre`, `m`.`apellido` AS `apellido`, `e`.`nombre` AS `especialidad`, `c`.`fecha_hora` AS `fecha_hora`, `c`.`estado` AS `estado` FROM ((`citas` `c` join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_pacientes`
--
DROP TABLE IF EXISTS `vista_citas_pacientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_pacientes`  AS SELECT `c`.`id_cita` AS `id_cita`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `c`.`fecha_hora` AS `fecha_hora`, `c`.`estado` AS `estado`, `c`.`motivo` AS `motivo` FROM (`citas` `c` join `pacientes` `p` on(`c`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_pendientes`
--
DROP TABLE IF EXISTS `vista_citas_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_pendientes`  AS SELECT `citas`.`id_cita` AS `id_cita`, `citas`.`id_paciente` AS `id_paciente`, `citas`.`id_medico` AS `id_medico`, `citas`.`fecha_hora` AS `fecha_hora`, `citas`.`estado` AS `estado`, `citas`.`motivo` AS `motivo` FROM `citas` WHERE `citas`.`estado` = 'Pendiente' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_por_especialidad`
--
DROP TABLE IF EXISTS `vista_citas_por_especialidad`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_por_especialidad`  AS SELECT `e`.`nombre` AS `especialidad`, count(`c`.`id_cita`) AS `total_citas` FROM ((`citas` `c` join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) GROUP BY `e`.`nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_citas_ultimo_mes`
--
DROP TABLE IF EXISTS `vista_citas_ultimo_mes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_citas_ultimo_mes`  AS SELECT `citas`.`id_cita` AS `id_cita`, `citas`.`id_paciente` AS `id_paciente`, `citas`.`id_medico` AS `id_medico`, `citas`.`fecha_hora` AS `fecha_hora`, `citas`.`estado` AS `estado`, `citas`.`motivo` AS `motivo` FROM `citas` WHERE `citas`.`fecha_hora` >= current_timestamp() - interval 1 month ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_consultas_por_dia`
--
DROP TABLE IF EXISTS `vista_consultas_por_dia`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_consultas_por_dia`  AS SELECT cast(`citas`.`fecha_hora` as date) AS `fecha`, count(`citas`.`id_cita`) AS `total_citas` FROM `citas` GROUP BY cast(`citas`.`fecha_hora` as date) ORDER BY cast(`citas`.`fecha_hora` as date) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_consultas_por_especialidad`
--
DROP TABLE IF EXISTS `vista_consultas_por_especialidad`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_consultas_por_especialidad`  AS SELECT `e`.`nombre` AS `especialidad`, count(`c`.`id_cita`) AS `total_citas` FROM ((`citas` `c` join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) GROUP BY `e`.`nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_consultas_por_medico`
--
DROP TABLE IF EXISTS `vista_consultas_por_medico`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_consultas_por_medico`  AS SELECT `m`.`nombre` AS `nombre`, count(`c`.`id_cita`) AS `total_consultas` FROM (`citas` `c` join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) GROUP BY `m`.`nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_conteo_especialidades`
--
DROP TABLE IF EXISTS `vista_conteo_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_conteo_especialidades`  AS SELECT count(0) AS `total_especialidades` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades`
--
DROP TABLE IF EXISTS `vista_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_c`
--
DROP TABLE IF EXISTS `vista_especialidades_c`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_c`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like 'C%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_capitalizado`
--
DROP TABLE IF EXISTS `vista_especialidades_capitalizado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_capitalizado`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, concat(ucase(left(`especialidades`.`nombre`,1)),lcase(substr(`especialidades`.`nombre`,2))) AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_cardio`
--
DROP TABLE IF EXISTS `vista_especialidades_cardio`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_cardio`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '%cardio%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_concatenadas`
--
DROP TABLE IF EXISTS `vista_especialidades_concatenadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_concatenadas`  AS SELECT concat(`especialidades`.`id_especialidad`,' - ',`especialidades`.`nombre`) AS `especialidad` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_consonante_final`
--
DROP TABLE IF EXISTS `vista_especialidades_consonante_final`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_consonante_final`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` regexp '[^aeiouAEIOU]$' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_con_numeros`
--
DROP TABLE IF EXISTS `vista_especialidades_con_numeros`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_con_numeros`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` regexp '[0-9]' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_con_z`
--
DROP TABLE IF EXISTS `vista_especialidades_con_z`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_con_z`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '%z%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_cortas`
--
DROP TABLE IF EXISTS `vista_especialidades_cortas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_cortas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE octet_length(`especialidades`.`nombre`) < 6 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_dermato`
--
DROP TABLE IF EXISTS `vista_especialidades_dermato`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_dermato`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '%dermato%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_duplicadas`
--
DROP TABLE IF EXISTS `vista_especialidades_duplicadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_duplicadas`  AS SELECT `especialidades`.`nombre` AS `nombre`, count(0) AS `cantidad` FROM `especialidades` GROUP BY `especialidades`.`nombre` HAVING `cantidad` > 1 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_id_impar`
--
DROP TABLE IF EXISTS `vista_especialidades_id_impar`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_id_impar`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`id_especialidad` MOD 2 <> 0 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_id_par`
--
DROP TABLE IF EXISTS `vista_especialidades_id_par`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_id_par`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`id_especialidad` MOD 2 = 0 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_inverso`
--
DROP TABLE IF EXISTS `vista_especialidades_inverso`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_inverso`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ORDER BY `especialidades`.`nombre` DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_largas`
--
DROP TABLE IF EXISTS `vista_especialidades_largas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_largas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE octet_length(`especialidades`.`nombre`) > 10 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_longitud_impar`
--
DROP TABLE IF EXISTS `vista_especialidades_longitud_impar`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_longitud_impar`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE octet_length(`especialidades`.`nombre`) MOD 2 <> 0 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_mas_solicitadas`
--
DROP TABLE IF EXISTS `vista_especialidades_mas_solicitadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_mas_solicitadas`  AS SELECT `e`.`nombre` AS `nombre`, count(0) AS `total_citas` FROM ((`especialidades` `e` join `medicos` `m` on(`e`.`id_especialidad` = `m`.`id_especialidad`)) join `citas` `c` on(`m`.`id_medico` = `c`.`id_medico`)) GROUP BY `e`.`nombre` ORDER BY count(0) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_mayusculas`
--
DROP TABLE IF EXISTS `vista_especialidades_mayusculas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_mayusculas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, ucase(`especialidades`.`nombre`) AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_med`
--
DROP TABLE IF EXISTS `vista_especialidades_med`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_med`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '%med%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_minusculas`
--
DROP TABLE IF EXISTS `vista_especialidades_minusculas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_minusculas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, lcase(`especialidades`.`nombre`) AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_misma_letra`
--
DROP TABLE IF EXISTS `vista_especialidades_misma_letra`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_misma_letra`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE left(`especialidades`.`nombre`,1) = right(`especialidades`.`nombre`,1) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_multipalabra`
--
DROP TABLE IF EXISTS `vista_especialidades_multipalabra`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_multipalabra`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '% %' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_muy_cortas`
--
DROP TABLE IF EXISTS `vista_especialidades_muy_cortas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_muy_cortas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE octet_length(`especialidades`.`nombre`) < 5 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_ocho_caracteres`
--
DROP TABLE IF EXISTS `vista_especialidades_ocho_caracteres`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_ocho_caracteres`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE octet_length(`especialidades`.`nombre`) = 8 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_ordenadas`
--
DROP TABLE IF EXISTS `vista_especialidades_ordenadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_ordenadas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ORDER BY `especialidades`.`nombre` ASC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_por_longitud`
--
DROP TABLE IF EXISTS `vista_especialidades_por_longitud`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_por_longitud`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ORDER BY octet_length(`especialidades`.`nombre`) ASC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_simetricas`
--
DROP TABLE IF EXISTS `vista_especialidades_simetricas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_simetricas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` = reverse(`especialidades`.`nombre`) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_sin_a`
--
DROP TABLE IF EXISTS `vista_especialidades_sin_a`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_sin_a`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` not like '%a%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_sin_espacios`
--
DROP TABLE IF EXISTS `vista_especialidades_sin_espacios`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_sin_espacios`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, replace(`especialidades`.`nombre`,' ','') AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_sin_o`
--
DROP TABLE IF EXISTS `vista_especialidades_sin_o`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_sin_o`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` not like '%o%' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_terminadas_ia`
--
DROP TABLE IF EXISTS `vista_especialidades_terminadas_ia`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_terminadas_ia`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` like '%ía' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_especialidades_vocales_repetidas`
--
DROP TABLE IF EXISTS `vista_especialidades_vocales_repetidas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_especialidades_vocales_repetidas`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` WHERE `especialidades`.`nombre` regexp '(.*[aeiou])\\1' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion`
--
DROP TABLE IF EXISTS `vista_facturacion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion`  AS SELECT `facturacion`.`id_factura` AS `id_factura`, `facturacion`.`id_paciente` AS `id_paciente`, `facturacion`.`fecha_emision` AS `fecha_emision`, `facturacion`.`total` AS `total`, `facturacion`.`estado` AS `estado` FROM `facturacion` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion_detallada`
--
DROP TABLE IF EXISTS `vista_facturacion_detallada`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion_detallada`  AS SELECT `f`.`id_factura` AS `id_factura`, `f`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `f`.`fecha_emision` AS `fecha_emision`, `d`.`descripcion` AS `descripcion`, `d`.`cantidad` AS `cantidad`, `d`.`precio` AS `precio`, `d`.`subtotal` AS `subtotal` FROM ((`facturacion` `f` join `factura_detalle` `d` on(`f`.`id_factura` = `d`.`id_factura`)) join `pacientes` `p` on(`f`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion_mensual`
--
DROP TABLE IF EXISTS `vista_facturacion_mensual`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion_mensual`  AS SELECT month(`facturacion`.`fecha_emision`) AS `mes`, year(`facturacion`.`fecha_emision`) AS `año`, sum(`facturacion`.`total`) AS `total_facturado` FROM `facturacion` GROUP BY year(`facturacion`.`fecha_emision`), month(`facturacion`.`fecha_emision`) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion_por_paciente`
--
DROP TABLE IF EXISTS `vista_facturacion_por_paciente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion_por_paciente`  AS SELECT `f`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, sum(`f`.`total`) AS `total_facturado` FROM (`facturacion` `f` join `pacientes` `p` on(`f`.`id_paciente` = `p`.`id_paciente`)) GROUP BY `f`.`id_paciente` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion_total_por_paciente`
--
DROP TABLE IF EXISTS `vista_facturacion_total_por_paciente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion_total_por_paciente`  AS SELECT `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, sum(`f`.`total`) AS `total_pagado` FROM (`pacientes` `p` join `facturacion` `f` on(`p`.`id_paciente` = `f`.`id_paciente`)) GROUP BY `p`.`id_paciente` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturas_anuladas`
--
DROP TABLE IF EXISTS `vista_facturas_anuladas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturas_anuladas`  AS SELECT `facturacion`.`id_factura` AS `id_factura`, `facturacion`.`id_paciente` AS `id_paciente`, `facturacion`.`fecha_emision` AS `fecha_emision`, `facturacion`.`total` AS `total`, `facturacion`.`estado` AS `estado` FROM `facturacion` WHERE `facturacion`.`estado` = 'Anulada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturas_pacientes`
--
DROP TABLE IF EXISTS `vista_facturas_pacientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturas_pacientes`  AS SELECT `f`.`id_factura` AS `id_factura`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `f`.`fecha_emision` AS `fecha_emision`, `f`.`total` AS `total`, `f`.`estado` AS `estado` FROM (`facturacion` `f` join `pacientes` `p` on(`f`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturas_pagadas`
--
DROP TABLE IF EXISTS `vista_facturas_pagadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturas_pagadas`  AS SELECT `facturacion`.`id_factura` AS `id_factura`, `facturacion`.`id_paciente` AS `id_paciente`, `facturacion`.`fecha_emision` AS `fecha_emision`, `facturacion`.`total` AS `total`, `facturacion`.`estado` AS `estado` FROM `facturacion` WHERE `facturacion`.`estado` = 'Pagada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturas_pendientes`
--
DROP TABLE IF EXISTS `vista_facturas_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturas_pendientes`  AS SELECT `facturacion`.`id_factura` AS `id_factura`, `facturacion`.`id_paciente` AS `id_paciente`, `facturacion`.`fecha_emision` AS `fecha_emision`, `facturacion`.`total` AS `total`, `facturacion`.`estado` AS `estado` FROM `facturacion` WHERE `facturacion`.`estado` = 'Pendiente' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_factura_detalle`
--
DROP TABLE IF EXISTS `vista_factura_detalle`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_factura_detalle`  AS SELECT `factura_detalle`.`id_detalle` AS `id_detalle`, `factura_detalle`.`id_factura` AS `id_factura`, `factura_detalle`.`descripcion` AS `descripcion`, `factura_detalle`.`cantidad` AS `cantidad`, `factura_detalle`.`precio` AS `precio`, `factura_detalle`.`subtotal` AS `subtotal` FROM `factura_detalle` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_factura_detalle_completo`
--
DROP TABLE IF EXISTS `vista_factura_detalle_completo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_factura_detalle_completo`  AS SELECT `fd`.`id_detalle` AS `id_detalle`, `f`.`id_factura` AS `id_factura`, `p`.`nombre` AS `paciente`, `fd`.`descripcion` AS `descripcion`, `fd`.`cantidad` AS `cantidad`, `fd`.`precio` AS `precio`, `fd`.`subtotal` AS `subtotal` FROM ((`factura_detalle` `fd` join `facturacion` `f` on(`fd`.`id_factura` = `f`.`id_factura`)) join `pacientes` `p` on(`f`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_formulas_medicas`
--
DROP TABLE IF EXISTS `vista_formulas_medicas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_formulas_medicas`  AS SELECT `formulas_medicas`.`id_formula` AS `id_formula`, `formulas_medicas`.`id_paciente` AS `id_paciente`, `formulas_medicas`.`id_medico` AS `id_medico`, `formulas_medicas`.`fecha` AS `fecha`, `formulas_medicas`.`duracion` AS `duracion` FROM `formulas_medicas` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_formulas_medicas_recientes`
--
DROP TABLE IF EXISTS `vista_formulas_medicas_recientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_formulas_medicas_recientes`  AS SELECT `formulas_medicas`.`id_formula` AS `id_formula`, `formulas_medicas`.`id_paciente` AS `id_paciente`, `formulas_medicas`.`id_medico` AS `id_medico`, `formulas_medicas`.`fecha` AS `fecha` FROM `formulas_medicas` WHERE `formulas_medicas`.`fecha` >= curdate() - interval 30 day ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_habitaciones`
--
DROP TABLE IF EXISTS `vista_habitaciones`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_habitaciones`  AS SELECT `habitaciones`.`id_habitacion` AS `id_habitacion`, `habitaciones`.`numero` AS `numero`, `habitaciones`.`tipo` AS `tipo`, `habitaciones`.`estado` AS `estado` FROM `habitaciones` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_habitaciones_disponibles`
--
DROP TABLE IF EXISTS `vista_habitaciones_disponibles`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_habitaciones_disponibles`  AS SELECT `habitaciones`.`id_habitacion` AS `id_habitacion`, `habitaciones`.`numero` AS `numero`, `habitaciones`.`tipo` AS `tipo`, `habitaciones`.`estado` AS `estado` FROM `habitaciones` WHERE `habitaciones`.`estado` = 'Disponible' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_habitaciones_ocupadas`
--
DROP TABLE IF EXISTS `vista_habitaciones_ocupadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_habitaciones_ocupadas`  AS SELECT `habitaciones`.`id_habitacion` AS `id_habitacion`, `habitaciones`.`numero` AS `numero`, `habitaciones`.`tipo` AS `tipo`, `habitaciones`.`estado` AS `estado` FROM `habitaciones` WHERE `habitaciones`.`estado` = 'Ocupada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_historial_medico`
--
DROP TABLE IF EXISTS `vista_historial_medico`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_historial_medico`  AS SELECT `hc`.`id_historia` AS `id_historia`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `hc`.`fecha` AS `fecha`, `hc`.`diagnostico` AS `diagnostico`, `hc`.`notas` AS `notas` FROM (`historias_clinicas` `hc` join `pacientes` `p` on(`hc`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_historial_reciente`
--
DROP TABLE IF EXISTS `vista_historial_reciente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_historial_reciente`  AS SELECT `historias_clinicas`.`id_historia` AS `id_historia`, `historias_clinicas`.`id_paciente` AS `id_paciente`, `historias_clinicas`.`fecha` AS `fecha`, `historias_clinicas`.`diagnostico` AS `diagnostico`, `historias_clinicas`.`notas` AS `notas` FROM `historias_clinicas` ORDER BY `historias_clinicas`.`fecha` DESC LIMIT 0, 10 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_historias_clinicas`
--
DROP TABLE IF EXISTS `vista_historias_clinicas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_historias_clinicas`  AS SELECT `hc`.`id_historia` AS `id_historia`, `p`.`nombre` AS `paciente`, `hc`.`fecha` AS `fecha`, `hc`.`diagnostico` AS `diagnostico`, `hc`.`notas` AS `notas` FROM (`historias_clinicas` `hc` join `pacientes` `p` on(`hc`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizaciones`
--
DROP TABLE IF EXISTS `vista_hospitalizaciones`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizaciones`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `h`.`id_hospitalizacion` AS `id_hospitalizacion`, `h`.`fecha_ingreso` AS `fecha_ingreso`, coalesce(`h`.`fecha_egreso`,'No especificado') AS `fecha_egreso`, `h`.`estado` AS `estado` FROM (`pacientes` `p` join `hospitalizaciones` `h` on(`p`.`id_paciente` = `h`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizaciones_activas`
--
DROP TABLE IF EXISTS `vista_hospitalizaciones_activas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizaciones_activas`  AS SELECT `hospitalizaciones`.`id_hospitalizacion` AS `id_hospitalizacion`, `hospitalizaciones`.`id_paciente` AS `id_paciente`, `hospitalizaciones`.`id_habitacion` AS `id_habitacion`, `hospitalizaciones`.`fecha_ingreso` AS `fecha_ingreso`, `hospitalizaciones`.`fecha_salida` AS `fecha_salida`, `hospitalizaciones`.`estado` AS `estado` FROM `hospitalizaciones` WHERE `hospitalizaciones`.`estado` = 'En curso' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizaciones_en_curso`
--
DROP TABLE IF EXISTS `vista_hospitalizaciones_en_curso`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizaciones_en_curso`  AS SELECT `hospitalizaciones`.`id_hospitalizacion` AS `id_hospitalizacion`, `hospitalizaciones`.`id_paciente` AS `id_paciente`, `hospitalizaciones`.`id_habitacion` AS `id_habitacion`, `hospitalizaciones`.`fecha_ingreso` AS `fecha_ingreso`, `hospitalizaciones`.`fecha_salida` AS `fecha_salida`, `hospitalizaciones`.`estado` AS `estado`, `hospitalizaciones`.`fecha_egreso` AS `fecha_egreso` FROM `hospitalizaciones` WHERE `hospitalizaciones`.`estado` = 'En curso' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizaciones_finalizadas`
--
DROP TABLE IF EXISTS `vista_hospitalizaciones_finalizadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizaciones_finalizadas`  AS SELECT `hospitalizaciones`.`id_hospitalizacion` AS `id_hospitalizacion`, `hospitalizaciones`.`id_paciente` AS `id_paciente`, `hospitalizaciones`.`id_habitacion` AS `id_habitacion`, `hospitalizaciones`.`fecha_ingreso` AS `fecha_ingreso`, `hospitalizaciones`.`fecha_salida` AS `fecha_salida`, `hospitalizaciones`.`estado` AS `estado`, `hospitalizaciones`.`fecha_egreso` AS `fecha_egreso` FROM `hospitalizaciones` WHERE `hospitalizaciones`.`estado` = 'Finalizada' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizaciones_pacientes`
--
DROP TABLE IF EXISTS `vista_hospitalizaciones_pacientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizaciones_pacientes`  AS SELECT `h`.`id_hospitalizacion` AS `id_hospitalizacion`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `h`.`fecha_ingreso` AS `fecha_ingreso`, `h`.`fecha_salida` AS `fecha_salida`, `h`.`estado` AS `estado` FROM (`hospitalizaciones` `h` join `pacientes` `p` on(`h`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_hospitalizados`
--
DROP TABLE IF EXISTS `vista_hospitalizados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_hospitalizados`  AS SELECT `h`.`id_hospitalizacion` AS `id_hospitalizacion`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `h`.`fecha_ingreso` AS `fecha_ingreso`, `h`.`estado` AS `estado` FROM (`hospitalizaciones` `h` join `pacientes` `p` on(`h`.`id_paciente` = `p`.`id_paciente`)) WHERE `h`.`estado` = 'En curso' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_ingresos_por_especialidad`
--
DROP TABLE IF EXISTS `vista_ingresos_por_especialidad`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_ingresos_por_especialidad`  AS SELECT `e`.`nombre` AS `especialidad`, sum(`f`.`total`) AS `ingresos` FROM (((`facturacion` `f` join `citas` `c` on(`f`.`id_paciente` = `c`.`id_paciente`)) join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) GROUP BY `e`.`nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_ingresos_por_fecha`
--
DROP TABLE IF EXISTS `vista_ingresos_por_fecha`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_ingresos_por_fecha`  AS SELECT `facturacion`.`fecha_emision` AS `fecha_emision`, sum(`facturacion`.`total`) AS `total_ingresos` FROM `facturacion` GROUP BY `facturacion`.`fecha_emision` ORDER BY `facturacion`.`fecha_emision` DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicamentos`
--
DROP TABLE IF EXISTS `vista_medicamentos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicamentos`  AS SELECT `medicamentos`.`id_medicamento` AS `id_medicamento`, `medicamentos`.`nombre` AS `nombre`, `medicamentos`.`descripcion` AS `descripcion`, `medicamentos`.`stock` AS `stock` FROM `medicamentos` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicamentos_bajo_stock`
--
DROP TABLE IF EXISTS `vista_medicamentos_bajo_stock`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicamentos_bajo_stock`  AS SELECT `medicamentos`.`id_medicamento` AS `id_medicamento`, `medicamentos`.`nombre` AS `nombre`, `medicamentos`.`descripcion` AS `descripcion`, `medicamentos`.`stock` AS `stock` FROM `medicamentos` WHERE `medicamentos`.`stock` < 10 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicamentos_mas_prescritos`
--
DROP TABLE IF EXISTS `vista_medicamentos_mas_prescritos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicamentos_mas_prescritos`  AS SELECT `fm`.`id_medicamento` AS `id_medicamento`, `m`.`nombre` AS `nombre`, count(0) AS `veces_prescrito` FROM (`formula_medicamento` `fm` join `medicamentos` `m` on(`fm`.`id_medicamento` = `m`.`id_medicamento`)) GROUP BY `fm`.`id_medicamento` ORDER BY count(0) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicos_con_especialidad`
--
DROP TABLE IF EXISTS `vista_medicos_con_especialidad`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicos_con_especialidad`  AS SELECT `m`.`id_medico` AS `id_medico`, `m`.`nombre` AS `nombre`, `e`.`nombre` AS `especialidad` FROM (`medicos` `m` join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicos_especialidades`
--
DROP TABLE IF EXISTS `vista_medicos_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicos_especialidades`  AS SELECT `m`.`id_medico` AS `id_medico`, `m`.`nombre` AS `nombre`, `m`.`apellido` AS `apellido`, `e`.`nombre` AS `especialidad` FROM (`medicos` `m` join `especialidades` `e` on(`m`.`id_especialidad` = `e`.`id_especialidad`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_medicos_mas_citas`
--
DROP TABLE IF EXISTS `vista_medicos_mas_citas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_medicos_mas_citas`  AS SELECT `m`.`id_medico` AS `id_medico`, `m`.`nombre` AS `nombre`, count(`c`.`id_cita`) AS `total_citas` FROM (`citas` `c` join `medicos` `m` on(`c`.`id_medico` = `m`.`id_medico`)) GROUP BY `m`.`id_medico` ORDER BY count(`c`.`id_cita`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_ocupacion_habitaciones`
--
DROP TABLE IF EXISTS `vista_ocupacion_habitaciones`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_ocupacion_habitaciones`  AS SELECT `h`.`numero` AS `numero`, `h`.`tipo` AS `tipo`, `h`.`estado` AS `estado`, count(`ho`.`id_hospitalizacion`) AS `veces_ocupada` FROM (`habitaciones` `h` left join `hospitalizaciones` `ho` on(`h`.`id_habitacion` = `ho`.`id_habitacion`)) GROUP BY `h`.`id_habitacion` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_citas`
--
DROP TABLE IF EXISTS `vista_pacientes_citas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_citas`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `c`.`id_cita` AS `id_cita`, `c`.`fecha_hora` AS `fecha_hora`, `c`.`estado` AS `estado`, `c`.`motivo` AS `motivo` FROM (`pacientes` `p` join `citas` `c` on(`p`.`id_paciente` = `c`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_con_facturas_pendientes`
--
DROP TABLE IF EXISTS `vista_pacientes_con_facturas_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_con_facturas_pendientes`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `f`.`total` AS `total` FROM (`pacientes` `p` join `facturacion` `f` on(`p`.`id_paciente` = `f`.`id_paciente`)) WHERE `f`.`estado` = 'Pendiente' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_con_multiples_hospitalizaciones`
--
DROP TABLE IF EXISTS `vista_pacientes_con_multiples_hospitalizaciones`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_con_multiples_hospitalizaciones`  AS SELECT `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, count(`h`.`id_hospitalizacion`) AS `total_hospitalizaciones` FROM (`pacientes` `p` join `hospitalizaciones` `h` on(`p`.`id_paciente` = `h`.`id_paciente`)) GROUP BY `p`.`id_paciente` HAVING `total_hospitalizaciones` > 1 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_facturas`
--
DROP TABLE IF EXISTS `vista_pacientes_facturas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_facturas`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `f`.`id_factura` AS `id_factura`, `f`.`fecha_emision` AS `fecha_emision`, `f`.`total` AS `total`, `f`.`estado` AS `estado` FROM (`pacientes` `p` join `facturacion` `f` on(`p`.`id_paciente` = `f`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_frecuentes`
--
DROP TABLE IF EXISTS `vista_pacientes_frecuentes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_frecuentes`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, count(`c`.`id_cita`) AS `total_citas` FROM (`pacientes` `p` join `citas` `c` on(`p`.`id_paciente` = `c`.`id_paciente`)) GROUP BY `p`.`id_paciente` ORDER BY count(`c`.`id_cita`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_historias`
--
DROP TABLE IF EXISTS `vista_pacientes_historias`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_historias`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `h`.`id_historia` AS `id_historia`, `h`.`fecha` AS `fecha`, `h`.`diagnostico` AS `diagnostico`, `h`.`notas` AS `notas` FROM (`pacientes` `p` join `historias_clinicas` `h` on(`p`.`id_paciente` = `h`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_jovenes`
--
DROP TABLE IF EXISTS `vista_pacientes_jovenes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_jovenes`  AS SELECT `pacientes`.`id_paciente` AS `id_paciente`, `pacientes`.`nombre` AS `nombre`, `pacientes`.`apellido` AS `apellido`, `pacientes`.`fecha_nacimiento` AS `fecha_nacimiento`, `pacientes`.`genero` AS `genero`, `pacientes`.`direccion` AS `direccion`, `pacientes`.`telefono` AS `telefono`, `pacientes`.`correo_electronico` AS `correo_electronico`, `pacientes`.`tipo_documento` AS `tipo_documento`, `pacientes`.`numero_documento` AS `numero_documento` FROM `pacientes` WHERE year(curdate()) - year(`pacientes`.`fecha_nacimiento`) < 18 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_mas_hospitalizados`
--
DROP TABLE IF EXISTS `vista_pacientes_mas_hospitalizados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_mas_hospitalizados`  AS SELECT `p`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, count(`h`.`id_hospitalizacion`) AS `total_hospitalizaciones` FROM (`pacientes` `p` join `hospitalizaciones` `h` on(`p`.`id_paciente` = `h`.`id_paciente`)) GROUP BY `p`.`id_paciente` ORDER BY count(`h`.`id_hospitalizacion`) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_mayores`
--
DROP TABLE IF EXISTS `vista_pacientes_mayores`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_mayores`  AS SELECT `pacientes`.`id_paciente` AS `id_paciente`, `pacientes`.`nombre` AS `nombre`, `pacientes`.`apellido` AS `apellido`, `pacientes`.`fecha_nacimiento` AS `fecha_nacimiento`, `pacientes`.`genero` AS `genero`, `pacientes`.`direccion` AS `direccion`, `pacientes`.`telefono` AS `telefono`, `pacientes`.`correo_electronico` AS `correo_electronico`, `pacientes`.`tipo_documento` AS `tipo_documento`, `pacientes`.`numero_documento` AS `numero_documento` FROM `pacientes` WHERE year(curdate()) - year(`pacientes`.`fecha_nacimiento`) > 60 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_por_genero`
--
DROP TABLE IF EXISTS `vista_pacientes_por_genero`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_por_genero`  AS SELECT `pacientes`.`genero` AS `genero`, count(0) AS `cantidad` FROM `pacientes` GROUP BY `pacientes`.`genero` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_que_no_han_pagado`
--
DROP TABLE IF EXISTS `vista_pacientes_que_no_han_pagado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_que_no_han_pagado`  AS SELECT DISTINCT `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido` FROM (`pacientes` `p` join `facturacion` `f` on(`p`.`id_paciente` = `f`.`id_paciente`)) WHERE `f`.`estado` = 'Pendiente' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pacientes_sin_hospitalizacion`
--
DROP TABLE IF EXISTS `vista_pacientes_sin_hospitalizacion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pacientes_sin_hospitalizacion`  AS SELECT `pacientes`.`id_paciente` AS `id_paciente`, `pacientes`.`nombre` AS `nombre`, `pacientes`.`apellido` AS `apellido`, `pacientes`.`fecha_nacimiento` AS `fecha_nacimiento`, `pacientes`.`genero` AS `genero`, `pacientes`.`direccion` AS `direccion`, `pacientes`.`telefono` AS `telefono`, `pacientes`.`correo_electronico` AS `correo_electronico`, `pacientes`.`tipo_documento` AS `tipo_documento`, `pacientes`.`numero_documento` AS `numero_documento` FROM `pacientes` WHERE !(`pacientes`.`id_paciente` in (select distinct `hospitalizaciones`.`id_paciente` from `hospitalizaciones`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_todas_especialidades`
--
DROP TABLE IF EXISTS `vista_todas_especialidades`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_todas_especialidades`  AS SELECT `especialidades`.`id_especialidad` AS `id_especialidad`, `especialidades`.`nombre` AS `nombre` FROM `especialidades` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_total_citas_pendientes`
--
DROP TABLE IF EXISTS `vista_total_citas_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_total_citas_pendientes`  AS SELECT count(0) AS `total` FROM `citas` WHERE `citas`.`estado` = 'Pendiente' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_total_hospitalizados`
--
DROP TABLE IF EXISTS `vista_total_hospitalizados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_total_hospitalizados`  AS SELECT count(0) AS `total` FROM `hospitalizaciones` WHERE `hospitalizaciones`.`estado` = 'En curso' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tratamientos`
--
DROP TABLE IF EXISTS `vista_tratamientos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tratamientos`  AS SELECT `tratamientos`.`id_tratamiento` AS `id_tratamiento`, `tratamientos`.`id_historia` AS `id_historia`, `tratamientos`.`descripcion` AS `descripcion`, `tratamientos`.`fecha_inicio` AS `fecha_inicio`, `tratamientos`.`fecha_fin` AS `fecha_fin` FROM `tratamientos` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tratamientos_activos`
--
DROP TABLE IF EXISTS `vista_tratamientos_activos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tratamientos_activos`  AS SELECT `t`.`id_tratamiento` AS `id_tratamiento`, `t`.`id_historia` AS `id_historia`, `h`.`id_paciente` AS `id_paciente`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `t`.`descripcion` AS `descripcion`, `t`.`fecha_inicio` AS `fecha_inicio`, `t`.`fecha_fin` AS `fecha_fin` FROM ((`tratamientos` `t` join `historias_clinicas` `h` on(`t`.`id_historia` = `h`.`id_historia`)) join `pacientes` `p` on(`h`.`id_paciente` = `p`.`id_paciente`)) WHERE `t`.`fecha_fin` is null ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tratamientos_en_curso`
--
DROP TABLE IF EXISTS `vista_tratamientos_en_curso`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tratamientos_en_curso`  AS SELECT `tratamientos`.`id_tratamiento` AS `id_tratamiento`, `tratamientos`.`id_historia` AS `id_historia`, `tratamientos`.`descripcion` AS `descripcion`, `tratamientos`.`fecha_inicio` AS `fecha_inicio`, `tratamientos`.`fecha_fin` AS `fecha_fin` FROM `tratamientos` WHERE `tratamientos`.`fecha_fin` is null ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tratamientos_pacientes`
--
DROP TABLE IF EXISTS `vista_tratamientos_pacientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tratamientos_pacientes`  AS SELECT `t`.`id_tratamiento` AS `id_tratamiento`, `p`.`nombre` AS `nombre`, `p`.`apellido` AS `apellido`, `t`.`descripcion` AS `descripcion`, `t`.`fecha_inicio` AS `fecha_inicio`, `t`.`fecha_fin` AS `fecha_fin` FROM ((`tratamientos` `t` join `historias_clinicas` `hc` on(`t`.`id_historia` = `hc`.`id_historia`)) join `pacientes` `p` on(`hc`.`id_paciente` = `p`.`id_paciente`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_usuarios_activos`
--
DROP TABLE IF EXISTS `vista_usuarios_activos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_usuarios_activos`  AS SELECT `usuarios`.`id_usuario` AS `id_usuario`, `usuarios`.`nombre_usuario` AS `nombre_usuario` FROM `usuarios` WHERE `usuarios`.`bloqueado` = 0 ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `citas`
--
ALTER TABLE `citas`
  ADD PRIMARY KEY (`id_cita`),
  ADD KEY `id_paciente` (`id_paciente`),
  ADD KEY `id_medico` (`id_medico`);

--
-- Indices de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  ADD PRIMARY KEY (`id_especialidad`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD PRIMARY KEY (`id_factura`),
  ADD KEY `id_paciente` (`id_paciente`);

--
-- Indices de la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_factura` (`id_factura`);

--
-- Indices de la tabla `formulas_medicas`
--
ALTER TABLE `formulas_medicas`
  ADD PRIMARY KEY (`id_formula`),
  ADD KEY `id_paciente` (`id_paciente`),
  ADD KEY `id_medico` (`id_medico`);

--
-- Indices de la tabla `formula_medicamento`
--
ALTER TABLE `formula_medicamento`
  ADD PRIMARY KEY (`id_formula`,`id_medicamento`),
  ADD KEY `id_medicamento` (`id_medicamento`);

--
-- Indices de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  ADD PRIMARY KEY (`id_habitacion`),
  ADD UNIQUE KEY `numero` (`numero`);

--
-- Indices de la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  ADD PRIMARY KEY (`id_historia`),
  ADD KEY `id_paciente` (`id_paciente`);

--
-- Indices de la tabla `hospitalizaciones`
--
ALTER TABLE `hospitalizaciones`
  ADD PRIMARY KEY (`id_hospitalizacion`),
  ADD KEY `id_paciente` (`id_paciente`),
  ADD KEY `id_habitacion` (`id_habitacion`);

--
-- Indices de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  ADD PRIMARY KEY (`id_medicamento`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `medicos`
--
ALTER TABLE `medicos`
  ADD PRIMARY KEY (`id_medico`),
  ADD UNIQUE KEY `correo_electronico` (`correo_electronico`),
  ADD KEY `id_especialidad` (`id_especialidad`);

--
-- Indices de la tabla `pacientes`
--
ALTER TABLE `pacientes`
  ADD PRIMARY KEY (`id_paciente`),
  ADD UNIQUE KEY `numero_documento` (`numero_documento`),
  ADD UNIQUE KEY `correo_electronico` (`correo_electronico`);

--
-- Indices de la tabla `sedes`
--
ALTER TABLE `sedes`
  ADD PRIMARY KEY (`id_sede`);

--
-- Indices de la tabla `tratamientos`
--
ALTER TABLE `tratamientos`
  ADD PRIMARY KEY (`id_tratamiento`),
  ADD KEY `id_historia` (`id_historia`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `nombre_usuario` (`nombre_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  MODIFY `id_especialidad` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  MODIFY `id_factura` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `formulas_medicas`
--
ALTER TABLE `formulas_medicas`
  MODIFY `id_formula` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  MODIFY `id_habitacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  MODIFY `id_historia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `hospitalizaciones`
--
ALTER TABLE `hospitalizaciones`
  MODIFY `id_hospitalizacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  MODIFY `id_medicamento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `medicos`
--
ALTER TABLE `medicos`
  MODIFY `id_medico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `pacientes`
--
ALTER TABLE `pacientes`
  MODIFY `id_paciente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `sedes`
--
ALTER TABLE `sedes`
  MODIFY `id_sede` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `tratamientos`
--
ALTER TABLE `tratamientos`
  MODIFY `id_tratamiento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `citas`
--
ALTER TABLE `citas`
  ADD CONSTRAINT `citas_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`),
  ADD CONSTRAINT `citas_ibfk_2` FOREIGN KEY (`id_medico`) REFERENCES `medicos` (`id_medico`);

--
-- Filtros para la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD CONSTRAINT `facturacion_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`);

--
-- Filtros para la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  ADD CONSTRAINT `factura_detalle_ibfk_1` FOREIGN KEY (`id_factura`) REFERENCES `facturacion` (`id_factura`);

--
-- Filtros para la tabla `formulas_medicas`
--
ALTER TABLE `formulas_medicas`
  ADD CONSTRAINT `formulas_medicas_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`),
  ADD CONSTRAINT `formulas_medicas_ibfk_2` FOREIGN KEY (`id_medico`) REFERENCES `medicos` (`id_medico`);

--
-- Filtros para la tabla `formula_medicamento`
--
ALTER TABLE `formula_medicamento`
  ADD CONSTRAINT `formula_medicamento_ibfk_1` FOREIGN KEY (`id_formula`) REFERENCES `formulas_medicas` (`id_formula`),
  ADD CONSTRAINT `formula_medicamento_ibfk_2` FOREIGN KEY (`id_medicamento`) REFERENCES `medicamentos` (`id_medicamento`);

--
-- Filtros para la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  ADD CONSTRAINT `historias_clinicas_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`);

--
-- Filtros para la tabla `hospitalizaciones`
--
ALTER TABLE `hospitalizaciones`
  ADD CONSTRAINT `hospitalizaciones_ibfk_1` FOREIGN KEY (`id_paciente`) REFERENCES `pacientes` (`id_paciente`),
  ADD CONSTRAINT `hospitalizaciones_ibfk_2` FOREIGN KEY (`id_habitacion`) REFERENCES `habitaciones` (`id_habitacion`);

--
-- Filtros para la tabla `medicos`
--
ALTER TABLE `medicos`
  ADD CONSTRAINT `medicos_ibfk_1` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidades` (`id_especialidad`);

--
-- Filtros para la tabla `tratamientos`
--
ALTER TABLE `tratamientos`
  ADD CONSTRAINT `tratamientos_ibfk_1` FOREIGN KEY (`id_historia`) REFERENCES `historias_clinicas` (`id_historia`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
