#!/bin/bash

# Эта функция выводит руководство

function usage() {
  echo
  echo "Usage: bash $0 [options] files"
  echo
  echo " -c сжать файлы"
  echo " -f пропускать предупреждения"
  echo " -h показать это руководство"
  echo " -R удалять папки рекурсивно"
  echo
  exit
}

# Задание переменных по-умолчанию

FORCE="-i" # Показывать предупреждения
TYPE="" # Без сжатия
LOG=`pwd`"/myrm.log"
FILELIST=""
cat /dev/null > "$LOG" # Создаём лог-файл

if [ $# = 0 ]; then # Если аргументов нет, то

  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Сжать данные?(y/n): " a # Считываем тип архива
    [ "$a" = "y" ] && TYPE=".7z"
  done

  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Спрашивать подтверждение?(y/n): " a # Считываем подтверждение
    [ "$a" = "n" ] && FORCE="-f" # Если ответили нет, то убираем подтверждение
  done

  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Удалять папки рекурсивно?(y/n): " a # Считваем рекурсивность
    [ "$a" = "y" ] && REC="-R"
  done
  
  read -p "Какие файлы следует удалить? " FILELIST

else
  while getopts "cfRh" OPTION; do # Считываем опции
    case "$OPTION" in
      c)  TYPE=".7z" ;; # Тип архива
      R)  REC="-R" ;; # Рекурсия
      h)  usage ;; # Выводим справку
      f)  FORCE="-f" ;; # Убираем подтверждения
      *)  usage ;; # Выводим справку
    esac
  done
  shift $(($OPTIND - 1)) # Перемещаем указатель на следующий аргумент
fi

: ${R_TIME:=86400} # Задаём время в 24 часа (в секундах) если не задано

: ${R_DIR:="$HOME/recycler"} # Задаём папку корзины если она не задана

if ! [ -d "$R_DIR" ]; then # Если не существует такой корзины
  if ! mkdir "$R_DIR"; then # Пытаемся её создать
    echo "Cannot find Recycler Directory" # И если не удаётся, сообщаем об этом
    exit # И выходим
  fi
fi

find $R_DIR \! -newermt "$R_TIME seconds ago" -delete # Удаляем все файлы из корзины, помещённые туда раньше r_time

if [ -z "$FILELIST" ]; then
  FILELIST=$@
fi

for i in "$FILELIST" # Для каждого аргумента
do
  if [ -e "$i" ]; then # Если файл существует

    o="$i$TYPE" # Получаем имя архива

    if [ "$i" = "$o" ]; then # Если имена совпадают ($TYPE = "")
      cp "$i" "$R_DIR/$o" >> "$LOG" # Копируем файл в корзину
    else
      7z a "$R_DIR/$o" "$i" >> "$LOG" # Иначе архивируем файл в корзину
    fi

    if [ -f "$i" ]; then # Если это файл
      if ! rm "$FORCE" "$i"; then # Удаляем его, а если не получилось
        rm -f "$R_DIR/$o" # Удаляем его из корзины
      fi
    elif [ -d "$i" ]; then # А если папка
      if ! rm "$REC" "$FORCE" "$i"; then # Удаляем её, а если не получилось
        rm -Rf "$R_DIR/$o" # Удаляем её из корзины
      fi
    else
      rm -f "$R_DIR/$o"
    fi

  fi
done

