<?php
include 'config.php';

$usuario = $_POST['usuario'];
$contrasena = $_POST['contrasena'];

$sql = "SELECT * FROM usuarios WHERE nombre_usuario = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $usuario);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if ($row['bloqueado']) {
        echo "❌ Tu cuenta está bloqueada por 3 intentos fallidos.";
    } else {
        if ($row['contrasena'] === $contrasena) {
            // Contraseña correcta
            $conn->query("UPDATE usuarios SET intentos_fallidos = 0 WHERE id_usuario = {$row['id_usuario']}");
            echo "✅ Bienvenido, " . $row['nombre_usuario'];
        } else {
            // Contraseña incorrecta
            $intentos = $row['intentos_fallidos'] + 1;
            $bloqueo = ($intentos >= 3) ? 1 : 0;

            $conn->query("UPDATE usuarios SET intentos_fallidos = $intentos, bloqueado = $bloqueo WHERE id_usuario = {$row['id_usuario']}");

            if ($bloqueo) {
                echo "❌ Usuario bloqueado tras 3 intentos fallidos.";
            } else {
                echo "⚠️ Contraseña incorrecta. Intento $intentos de 3.";
            }
        }
    }
} else {
    echo "⚠️ Usuario no encontrado.";
}

$conn->close();
?>
