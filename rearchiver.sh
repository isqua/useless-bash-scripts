#!/bin/bash

# Эта функция выводит руководство

function usage() {
  echo
  echo "Usage: bash rearchive [options]"
  echo
  echo "  -R        рекурсивно"
  echo "  -t <type> тип архива (по умолчанию 7z)"
  echo "  -o <dir>  папка, в которую складывать архивы (если необходимо)"
  echo "  -f        перезаписывать файлы, если файл с таким именем уже существует"
  echo "  -h        показать это руководство"
  echo "Запускайте этот скрипт в той папке, в которой надо проверить архивы"
  echo
  exit
}

# Задаём значения по умолчанию

RECURSIVE=0 # Не рекурсивно
TYPE="7z" # Тип архива по умолчанию
OUTPUT="" # Папка вывода по умолчанию
FOCRE="-i" # Спрашивать подверждение при замене файлов

if [ $# = 0 ]; then # Если аргументов нет, то
  echo "Введите тип архива (7z, zip и др):"
  read TYPE # Считываем тип архива
  echo "Введите папку, в которую нужно поместить архивы (иначе оставьте пустым):"
  read OUTPUT # Считываем папку вывода
  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    echo "Обойти папку рекурсивно?(y/n):"
    read a # Считываем рекурсию
    if [ "$a" = "y" ]; then # Если ответили y то
      RECURSIVE=1 # Делаем рекурсивно
    fi
  done
  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    echo "Перезаписывать файлы в случае совпадения имён?(y/n):" 
    read a # Считываем подтверждение
    if [ "$a" = "y" ]; then 
      FORCE="-f" # Если ответили да, то убираем подтверждение
    fi
  done
else 
  while getopts "t:o:hfR" OPTION; do # Считываем опции
    case "$OPTION" in 
      t)  TYPE="$OPTARG" ;; # Тип архива
      o)  OUTPUT="$OPTARG" ;; # Папка вывода
      R)  RECURSIVE=1 ;; # Рекурсия
      h)  usage ;; # Выводим справку
      f)  FORCE="-f" ;; # Убираем подтверждения
      *)  usage ;; # Выводим справку
    esac
  done
  shift $(($OPTIND - 1)) # Перемещаем указатель на следующий аргумент
fi

LOG=`pwd`"/""rearchive.log"
cat /dev/null > $LOG

if [ -n "$OUTPUT" ]; then # Если имя папки вывода не пусто
  t=`pwd` # Сохраняем текущее положение
  cd "$OUTPUT" # Заходим в папку вывода
  OUTPUT=`pwd` # Запоминаем полный путь до неё
  cd $t # Заходим обратно
  echo "Все архивы будут помещены в папку $OUTPUT"
fi

# Эта функция просматривает папку,
# переводит все архивы в ней,
# заходит во внутренние папки, если это необходимо

function listdir() {
  cd $1 # Заходим в папку, переданную в первом аргументе
  if [ "$1" = "./" ]; then # Если это текущая папка
    path=$1 # Сохраняем в этой переменной символ "./"
  else # Иначе
    path="$2""$1""/" # Сохраняем путь до этой папки оттуда, откуда мы начали обход
  fi
  for i in *; do # Для всех файлов в папке
    if [ -f "$i" ]; then # Если это файл
      if [ "`7z t $i | grep Everything`" = "Everything is Ok" ]; then # И если 7z считает его архивом
        convert $i $path # Конвертируем его
      fi
    fi
    if [ -d "$i" ]; then # Если у нас папка
      if [ `pwd`"/""$i" != "$OUTPUT" ]; then
        if [ "$RECURSIVE"="1" ]; then # Если рекурсивно
          listdir $i $path # То заходим в неё и выполняем в ней эту же функцю
        fi
      fi
    fi
  done
  cd .. # Выходим обратно
}

# Эта функция конвертирует архив

function convert {
  local i="$1" # Запоминаем имя архива
  local path="$2" # Запоминаем его положение
  local o=`expr match "$i" '\(.*\)\.'`"."$TYPE # Получаем имя нового архива
  if [ "$i" != "$o" ]; then # Если имя нового и старого архивов не совпадает
    echo "$path$i будет преобразован в $o"  # Выводим сообщение
    local t=`mktemp -d` # Создаём временную папку
    7z x "$i" "-o$t" >> "$LOG" # Распаковываем в неё архив
    7z a "$t/$o" "$t/*" >> "$LOG" # Архивируем эти файлы
    if [ -n "$OUTPUT" ]; then # Если папка вывода не пуста
      mv "$FORCE" -- "$t/$o" "$OUTPUT" 2>> "$LOG" # Перемещаем архив в неё
    else # Иначе
      mv "$FORCE" -- "$t/$o" ./ 2>> "$LOG" # Перемещаем архив на место
    fi
    rm -R $t # Удаляем временную папку
    rm "$i" # Удаляем первоначальный архив
  else # А если архив новый совпадает со старым
    echo "$path$i является архивом данного типа" # Сообщаем об этом
    if [ -n "$OUTPUT" ]; then # И если папка вывода не пуста
      cp "$FORCE" -- "$i" "$OUTPUT" 2>> "$LOG" # Копируем его туда
      rm "$i" # Удаляем первоначальный архив
    fi
  fi
}

if [ "$1" = "" ]; then
  listdir ./
else 
  listdir $1
fi
