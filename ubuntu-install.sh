#!/bin/bash

# Instalador para Llama.cpp y Alpaca.cpp en diferentes distribuciones de Linux

# Verificar si el usuario tiene permisos de root
if [ "$(id -u)" != "0" ]; then
  echo "Este script debe ser ejecutado como root"
  exit 1
fi

# Crear una interfaz de usuario para que el usuario seleccione qué programa desea instalar
program=$(whiptail --title "Selección de programa" --menu "Seleccione qué programa desea instalar" 15 60 2 \
"Llama.cpp" " + modelo 8GB" \
"Alpaca.cpp" " + modelo 4GB" 3>&1 1>&2 2>&3)

# Instalar los paquetes necesarios para compilar los programas
if [ -f /etc/alpine-release ]; then
  apk add --no-cache git cmake make gcc g++ wget
elif [ -f /etc/debian_version ]; then
  apt-get update
  apt-get install -y git cmake make gcc g++ wget
elif [ -f /etc/oracle-release ]; then
  yum install -y git cmake make gcc-c++ wget
fi

if [ "$program" = "Llama.cpp" ]; then
  if [ -d "/opt/llama.cpp" ]; then
    respuesta=""
    while [[ "$respuesta" != "s" && "$respuesta" != "n" ]]; do
        read -p "Ya existe una instalación anterior de Llama. ¿Desea continuar con la instalación? (s/n) " respuesta
        respuesta="${respuesta,,}" # convertir a minúsculas para comparar
    done
    
    if [ "$respuesta" == "n" ]; then
        echo "Instalación cancelada."
        exit 1
    else
        rm -rf /opt/llama.cpp
    fi
  fi
  
  git clone https://github.com/ggerganov/llama.cpp
  mv llama.cpp /opt/
  cd /opt/llama.cpp/
  make
  wget https://huggingface.co/eachadea/legacy-ggml-vicuna-13b-4bit/resolve/main/ggml-vicuna-13b-4bit.bin
    if [ $(sha256sum ggml-vicuna-13b-4bit.bin | cut -d ' ' -f 1) = "c6eb3a970b687584b16987e0aedc8513e885ec368b9f4a51e8cd69de5740cb7b" ]; then
        echo "El archivo binario es válido"
      else
        echo "La suma de comprobación SHA256 no coincide"
        exit 1
     fi
  make -j
  if [ -x "/opt/llama.cpp/main" ]; then
    echo "/opt/llama.cpp/main -m /opt/llama.cpp/ggml-vicuna-13b-4bit.bin -n 256 --repeat_penalty 1.0 --color -i -r "User:" -f /opt/llama.cpp/prompts/chat-with-bob.txt" >> /usr/bin/llama
    chmod 777 /usr/bin/llama
  else
    echo "No se pudo compilar el binario de chat"
    exit 1
  fi
elif [ "$program" = "Alpaca.cpp" ]; then
  if [ -d "/opt/alpaca.cpp" ]; then
    respuesta=""
    while [[ "$respuesta" != "s" && "$respuesta" != "n" ]]; do
        read -p "Ya existe una instalación anterior de Alpaca. ¿Desea continuar con la instalación? (s/n) " respuesta
        respuesta="${respuesta,,}" # convertir a minúsculas para comparar
    done
    
    if [ "$respuesta" == "n" ]; then
        echo "Instalación cancelada."
        exit 1
    else
        rm -rf /opt/alpaca.cpp
    fi
  fi
  
  git clone https://github.com/antimatter15/alpaca.cpp
  mv alpaca.cpp /opt/
  cd /opt/alpaca.cpp && make chat
  if [ -x "/opt/alpaca.cpp/chat" ]; then
    echo "/opt/alpaca.cpp/chat -m /opt/alpaca.cpp/ggml-alpaca-7b-q4.bin" >> /usr/bin/alpaca
    chmod 777 /usr/bin/alpaca
    wget https://huggingface.co/Sosaka/Alpaca-native-4bit-ggml/resolve/main/ggml-alpaca-7b-q4.bin
    if [ $(sha256sum ggml-alpaca-7b-q4.bin | cut -d ' ' -f 1) = "9c1bb4808f40aa0059d5343d3aac05fb75d368c240b664878d53d16bf27ade2b" ]; then
      echo "El archivo binario es válido"
    else
      echo "La suma de comprobación SHA256 no coincide"
      exit 1
    fi
  else
    echo "No se pudo compilar el binario de chat"
    exit 1
  fi
fi



echo "La instalación ha finalizado con éxito"
