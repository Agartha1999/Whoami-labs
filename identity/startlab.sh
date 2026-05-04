#!/bin/bash

# --- CONFIGURACIÓN DE LA MÁQUINA ---
CONTAINERNAME="identity"
IMAGENAME="identity"
LABDISPLAYNAME="Identity (Junior Checklist #1)"
DIFFICULTY_STARS="★☆☆☆☆☆☆☆"
DIFFICULTY_POINTS="1"
DIFFICULTY_TEXT="fácil"
# ------------------------------------

# [SYSTEM_METADATA_INTEGRITY_CHECK]
_scr_m() { echo "$1" | base64 -d 2>/dev/null; }
_m0=$(_scr_m "L3Jvb3QvZmxhZy50eHQ=")
_m1=$(_scr_m "L2hvbWUvd2ViLWFkbWluL3VzZXIudHh0")

# Colores y Estética
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

# Limpieza al salir
cleanup() {
    echo -e "\n${RED}[!] Cerrando laboratorio... Limpiando entorno.${NC}"
    docker stop $CONTAINERNAME > /dev/null 2>&1
    docker rm $CONTAINERNAME > /dev/null 2>&1
    exit
}
trap cleanup INT TERM

clear
if ! command -v figlet >/dev/null 2>&1; then
    echo -e "${BLUE}Whoami - Labs${NC}"
else
    echo -e "${BLUE}"
    figlet "Whoami - Labs"
    echo -e "${NC}"
fi
echo -e "${YELLOW}------------------------------------------------------------${NC}"
echo -e "  LABORATORIO: ${GREEN}${LABDISPLAYNAME}${NC}"
echo -e "  DIFICULTAD:  ${RED}${DIFFICULTY_TEXT}${NC} [${YELLOW}${DIFFICULTY_STARS}${NC}]"
echo -e "  PUNTUACIÓN:  ${BLUE}${DIFFICULTY_POINTS} XP${NC}"
echo -e "${YELLOW}------------------------------------------------------------${NC}"

# Manejo de argumentos (para carga de .tar)
if [ "$1" != "" ] && [ -f "$1" ]; then
    echo -e "[*] Cargando imagen desde $1..."
    docker load -i "$1" > /dev/null
else
    echo -e "[*] Construyendo entorno local..."
    docker build -t $IMAGENAME . > /dev/null 2>&1
fi

# Limpieza previa
docker stop $CONTAINERNAME > /dev/null 2>&1
docker rm $CONTAINERNAME > /dev/null 2>&1

# Iniciar contenedor Docker (Solo exponiendo el puerto 80)
docker run -d \
    --name $CONTAINERNAME \
    -p 80:80 \
    $IMAGENAME > /dev/null

# Obtener IP interna de Docker
TARGET_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINERNAME)
START_TIME=$(date +%s)

echo -e "${YELLOW}--------------------------------------------------${NC}"
echo -e "${GREEN}  Laboratorio:  ${WHITE}${LABDISPLAYNAME}${NC}"
echo -e "${GREEN}  Dificultad:   ${WHITE}${DIFFICULTY_STARS}${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
echo -e "[>] OBJETIVO: ${BLUE}${TARGET_IP}${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"

# Funciones de utilidad
get_duration() {
    local END_TIME=$(date +%s)
    echo $((END_TIME - START_TIME))
}

format_time() {
    local T=$1
    local H=$((T/3600))
    local M=$((T%3600/60))
    local S=$((T%60))
    printf "%dh %dm %ds\n" $H $M $S
}

validate_flag() {
    local TYPE=$1
    local PATH_IN_DOCKER=$2
    local ATTEMPTS=0
    local MAX_ATTEMPTS=5

    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        echo -ne "\n${BLUE}[?] Introduce la flag de ${TYPE}:${NC} "
        read input_flag
        
        CORRECT_FLAG=$(docker exec $CONTAINERNAME cat $PATH_IN_DOCKER 2>/dev/null | tr -d '\r' | xargs)
        input_flag=$(echo "$input_flag" | xargs)
        
        if [ "$input_flag" == "$CORRECT_FLAG" ] && [ ! -z "$CORRECT_FLAG" ]; then
            echo -e "${GREEN}[V] ¡Correcto! Flag ${TYPE} validada.${NC}"
            return 0
        else
            ((ATTEMPTS++))
            echo -e "${RED}[X] Incorrecto. Intentos restantes: $((MAX_ATTEMPTS - ATTEMPTS))${NC}"
        fi
    done
    echo -e "${RED}[!] Has agotado tus intentos para la flag ${TYPE}.${NC}"
    cleanup
}

# Validación de flags
validate_flag "USUARIO" $_m1
validate_flag "ROOT" $_m0

# Finalización
TOTAL_SECONDS=$(get_duration)
DURATION=$(format_time $TOTAL_SECONDS)
echo -e "\n${YELLOW}************************************************************${NC}"
echo -e "${GREEN}  ¡FELICIDADES! HAS COMPLETADO EL LABORATORIO ${LABDISPLAYNAME}${NC}"
echo -e "  Tiempo total: ${BLUE}${DURATION}${NC}"
echo -e "  XP Obtenida:  ${BLUE}${DIFFICULTY_POINTS} Puntos${NC}"
echo -e "${YELLOW}************************************************************${NC}"

read -p "Presiona Enter para cerrar el laboratorio..."
cleanup
