#!/bin/bash

# Comprobar si el contenedor está ejecutándose
echo "Comprobando el estado del servidor..."
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)

echo "Código de estado HTTP: $STATUS_CODE" 